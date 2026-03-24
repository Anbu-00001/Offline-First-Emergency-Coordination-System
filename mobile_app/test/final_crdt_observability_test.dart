import 'dart:io';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/data/repositories/incident_repository.dart';
import 'package:mobile_app/data/database.dart';
import 'package:mobile_app/services/p2p_service.dart';
import 'package:mobile_app/services/polygon_generator.dart';
import 'package:mobile_app/services/polygon_cache_service.dart';
import 'package:mobile_app/core/api_client.dart';
import 'package:mobile_app/models/network_envelope.dart';

class MockApiClient implements ApiClient {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('Day-21 Final Observability & Sync Terminal Tests', () {
    late AppDatabase db;
    late P2PService p2pService;
    late IncidentRepository repository;
    late HttpServer mockDaemon;
    WebSocket? activeWs;
    late List<NetworkEnvelope> broadcastCaptured;

    setUp(() async {
      broadcastCaptured = [];
      activeWs = null;

      mockDaemon = await HttpServer.bind('127.0.0.1', 0);
      mockDaemon.listen((req) async {
        if (req.uri.path == '/broadcast') {
          final body = await utf8.decoder.bind(req).join();
          final json = jsonDecode(body);
          broadcastCaptured.add(NetworkEnvelope.fromJson(json));
          req.response.statusCode = 202;
          req.response.close();
        } else if (req.uri.path == '/events' && WebSocketTransformer.isUpgradeRequest(req)) {
          activeWs = await WebSocketTransformer.upgrade(req);
        } else {
          req.response.statusCode = 404;
          req.response.close();
        }
      });

      p2pService = P2PService(hostUrl: 'http://127.0.0.1', port: mockDaemon.port);
      db = AppDatabase.memory();
      final polygonCache = PolygonCacheService(PolygonGenerator());
      repository = IncidentRepository(db, MockApiClient(), p2pService, polygonCache);

      p2pService.connect();
      await Future.delayed(const Duration(milliseconds: 100)); // wait for ws binding
    });

    tearDown(() async {
      p2pService.dispose();
      await db.close();
      await activeWs?.close();
      await mockDaemon.close(force: true);
    });

    void injectMessage(Map<String, dynamic> msg) {
      if (msg['origin_peer'] == null) msg['origin_peer'] = 'peer_B';
      activeWs?.add(jsonEncode(msg));
    }

    test('TEST — Multi-peer conflict (PART 5)', () async {
      // 1. Device A: ASSIGNED (clock 5)
      injectMessage({
        'msg_id': 'm_a',
        'msg_type': 'incident_create',
        'origin_peer': 'Device_A',
        'clock': 5,
        'payload': {
          'incident_id': 'inc_multi_conflict',
          'type': 'medical',
          'status': 'ASSIGNED',
          'clock': 5,
          'device_id': 'Device_A'
        }
      });
      await Future.delayed(const Duration(milliseconds: 50));

      final all1 = await repository.getAllIncidents();
      expect(all1.length, 1);
      expect(all1.first.status, 'ASSIGNED');
      expect(all1.first.sequenceNum, 5);

      // 2. Device B: RESOLVED (clock 6)
      injectMessage({
        'msg_id': 'm_b',
        'msg_type': 'incident_create',
        'origin_peer': 'Device_B',
        'clock': 6,
        'payload': {
          'incident_id': 'inc_multi_conflict',
          'type': 'medical',
          'status': 'RESOLVED',
          'clock': 6,
          'device_id': 'Device_B'
        }
      });
      await Future.delayed(const Duration(milliseconds: 50));

      final all2 = await repository.getAllIncidents();
      expect(all2.first.status, 'RESOLVED');
      expect(all2.first.sequenceNum, 6);

      // 3. Device C: ASSIGNED (clock 10)
      injectMessage({
        'msg_id': 'm_c',
        'msg_type': 'incident_create',
        'origin_peer': 'Device_C',
        'clock': 10,
        'payload': {
          'incident_id': 'inc_multi_conflict',
          'type': 'medical',
          'status': 'ASSIGNED',
          'clock': 10,
          'device_id': 'Device_C'
        }
      });
      await Future.delayed(const Duration(milliseconds: 50));

      final all3 = await repository.getAllIncidents();
      expect(all3.length, 1);
      // RESOLVED should dominate ASSIGNED regardless of higher clock 10.
      expect(all3.first.status, 'RESOLVED');
      expect(all3.first.sequenceNum, 6);
    });

    test('TEST — Sync termination without missing messages (PART 7)', () async {
      broadcastCaptured.clear();
      
      // Simulate remote peer giving heads that are ALREADY known to us, or we have nothing missing
      // We will first insert a known head
      injectMessage({
        'msg_id': 'known_head',
        'msg_type': 'incident_create',
        'origin_peer': 'peer_Termination',
        'clock': 1,
        'payload': {
          'incident_id': 'inc_term',
          'type': 'fire',
          'status': 'PENDING',
          'clock': 1,
        }
      });
      await Future.delayed(const Duration(milliseconds: 50));
      broadcastCaptured.clear();

      // remote peer shares head_exchange with exact same head
      injectMessage({
        'msg_id': 'hx_term',
        'msg_type': 'head_exchange',
        'origin_peer': 'peer_Termination',
        'timestamp': 1000,
        'payload': { 'heads': ['known_head'] }
      });
      await Future.delayed(const Duration(milliseconds: 50));
      
      // We should NOT request anything because we already have 'known_head'
      final requests = broadcastCaptured.where((e) => e.msgType == 'message_request').toList();
      expect(requests.length, 0);

      // (In logs, SYNC_COMPLETED will be visible as specified in P2PService)
    });
  });
}
