import 'dart:io';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/data/repositories/incident_repository.dart';
import 'package:mobile_app/data/database.dart';
import 'package:mobile_app/services/p2p_service.dart';
import 'package:mobile_app/services/polygon_generator.dart';
import 'package:mobile_app/services/polygon_cache_service.dart';
import 'package:mobile_app/core/api_client.dart';
import 'package:mobile_app/models/models.dart';
import 'package:mobile_app/models/network_envelope.dart';

class MockApiClient implements ApiClient {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('Day-21 CRDT Sync & Conflict Resolution Tests', () {
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
      await Future.delayed(const Duration(milliseconds: 100)); // wait for ws
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

    test('TEST 1 — Basic P2P propagation', () async {
      await repository.createIncident(IncidentCreateDto(
        type: 'fire',
        lat: 10.0,
        lon: 20.0,
        priority: 'high',
        status: 'PENDING',
        clientId: 'device_A',
        sequenceNum: 1,
      ));

      await Future.delayed(const Duration(milliseconds: 50));
      expect(broadcastCaptured.length, 1);
      final broadcast = broadcastCaptured.first;
      expect(broadcast.msgType, 'incident_create');
      expect(broadcast.payload['status'], 'PENDING');
      expect(broadcast.payload['device_id'], 'local_user');
      
      // We expect the local incident to be saved too
      final all = await repository.getAllIncidents();
      expect(all.length, 1);
    });

    test('TEST 2 — Deduplication', () async {
      final env = {
        'msg_id': 'm1',
        'msg_type': 'incident_create',
        'origin_peer': 'peer_B',
        'clock': 1,
        'payload': {
          'incident_id': 'inc_dedup',
          'type': 'flood',
          'status': 'PENDING',
          'device_id': 'peer_B'
        }
      };

      // Inject the exact same message twice
      injectMessage(env);
      injectMessage(env);

      await Future.delayed(const Duration(milliseconds: 100));

      final all = await repository.getAllIncidents();
      expect(all.length, 1); // Should only insert once
      expect(all.first.id, 'inc_dedup');
    });

    test('TEST 3 — Late Join Sync', () async {
      // simulate sync request from late joiner
      injectMessage({
        'msg_id': 'sync_req_1',
        'msg_type': 'sync_request',
        'origin_peer': 'peer_Late',
        'timestamp': 1000,
        'payload': {}
      });

      await Future.delayed(const Duration(milliseconds: 50));
      // local has nothing, so no response sent yet
      expect(broadcastCaptured.length, 0);

      // Now create a local incident
      await repository.createIncident(IncidentCreateDto(
        type: 'medical', lat: 0, lon: 0, priority: 'critical', status: 'PENDING', clientId: 'local', sequenceNum: 1
      ));
      broadcastCaptured.clear(); // clear broadcast

      injectMessage({
        'msg_id': 'sync_req_2',
        'msg_type': 'sync_request',
        'origin_peer': 'peer_Late2',
        'timestamp': 1000,
        'payload': {}
      });

      await Future.delayed(const Duration(milliseconds: 100));
      // Should broadcast a sync_response
      final syncResponses = broadcastCaptured.where((e) => e.msgType == 'sync_response').toList();
      expect(syncResponses.length, 1);
      final payload = syncResponses.first.payload;
      expect(payload['incidents'].length, 1);
    });

    test('TEST 4 — Causal Ordering', () async {
      // Inject message 2 which depends on message 1. Message 1 is missing.
      injectMessage({
        'msg_id': 'm2',
        'msg_type': 'incident_create',
        'origin_peer': 'peer_B',
        'clock': 2,
        'prev_msg_ids': ['m1'],
        'payload': {
          'incident_id': 'inc_causal',
          'type': 'fire',
          'status': 'ASSIGNED',
          'clock': 2,
        }
      });
      await Future.delayed(const Duration(milliseconds: 50));

      // Should not be applied yet
      var all = await repository.getAllIncidents();
      expect(all.length, 0);

      // Inject dependency message 1
      injectMessage({
        'msg_id': 'm1',
        'msg_type': 'incident_create',
        'origin_peer': 'peer_B',
        'clock': 1,
        'payload': {
          'incident_id': 'inc_causal_m1',
          'type': 'fire',
          'status': 'PENDING',
          'clock': 1,
        }
      });
      await Future.delayed(const Duration(milliseconds: 50));

      // Now both m1 and m2 should be applied
      all = await repository.getAllIncidents();
      expect(all.length, 2);
    });

    test('TEST 5 — HEAD Sync', () async {
       injectMessage({
        'msg_id': 'hx1',
        'msg_type': 'head_exchange',
        'origin_peer': 'peer_C',
        'timestamp': 1000,
        'payload': { 'heads': ['remote_head_1'] }
      });
      await Future.delayed(const Duration(milliseconds: 50));
      
      expect(broadcastCaptured.length, 1);
      expect(broadcastCaptured.first.msgType, 'message_request');
      expect((broadcastCaptured.first.payload['requested_ids'] as List).contains('remote_head_1'), true);
    });

    test('TEST 6 — Sync Engine Stability', () async {
      injectMessage({
        'msg_id': 'hx2',
        'msg_type': 'head_exchange',
        'origin_peer': 'peer_D',
        'timestamp': 1000,
        'payload': { 'heads': ['known_head'] }
      });
      
      // satisfy immediately
      injectMessage({
        'msg_id': 'resp1',
        'msg_type': 'message_response',
        'origin_peer': 'peer_D',
        'payload': {
          'messages': [
            {
               'msg_id': 'known_head',
               'msg_type': 'incident_create',
               'origin_peer': 'peer_D',
               'clock': 1,
               'payload': { 'incident_id': 'inc_head', 'status': 'PENDING', 'clock': 1 }
            }
          ]
        }
      });
      await Future.delayed(const Duration(milliseconds: 100));
      
      broadcastCaptured.clear();
      // send duplicate head_exchange
      injectMessage({
        'msg_id': 'hx3',
        'msg_type': 'head_exchange',
        'origin_peer': 'peer_D',
        'timestamp': 1000,
        'payload': { 'heads': ['known_head'] }
      });
      await Future.delayed(const Duration(milliseconds: 50));
      
      // Should not loop or re-request
      expect(broadcastCaptured.length, 0);
    });

    test('TEST 7 — CRDT Conflict Resolution', () async {
      // 1. Initial incident created as ASSIGNED
      injectMessage({
        'msg_id': 'm1',
        'msg_type': 'incident_create',
        'origin_peer': 'peer_A',
        'clock': 1,
        'payload': {
          'incident_id': 'inc_conflict',
          'type': 'medical',
          'status': 'ASSIGNED',
          'clock': 1,
        }
      });
      await Future.delayed(const Duration(milliseconds: 50));

      final all1 = await repository.getAllIncidents();
      expect(all1.length, 1);
      expect(all1.first.status, 'ASSIGNED');

      // 2. Peer B broadcasts same incident as RESOLVED
      injectMessage({
        'msg_id': 'm2',
        'msg_type': 'incident_create',
        'origin_peer': 'peer_B',
        'clock': 2,
        'payload': {
          'incident_id': 'inc_conflict',
          'type': 'medical',
          'status': 'RESOLVED',
          'clock': 2,
        }
      });
      await Future.delayed(const Duration(milliseconds: 50));

      final all2 = await repository.getAllIncidents();
      expect(all2.length, 1);
      expect(all2.first.status, 'RESOLVED'); // Resolved wins!
    });

    test('TEST 8 — Same-State Conflict', () async {
      // 1. Initial incident created as ASSIGNED with clock 5
      injectMessage({
        'msg_id': 'm1',
        'msg_type': 'incident_create',
        'origin_peer': 'peer_A',
        'clock': 5,
        'payload': {
          'incident_id': 'inc_clock',
          'type': 'medical',
          'status': 'ASSIGNED',
          'clock': 5,
        }
      });
      await Future.delayed(const Duration(milliseconds: 50));

      final all1 = await repository.getAllIncidents();
      expect(all1.first.status, 'ASSIGNED');
      expect(all1.first.sequenceNum, 5);

      // 2. Peer B broadcasts same incident as ASSIGNED with clock 7
      injectMessage({
        'msg_id': 'm2',
        'msg_type': 'incident_create',
        'origin_peer': 'peer_B',
        'clock': 7,
        'payload': {
          'incident_id': 'inc_clock',
          'type': 'medical',
          'status': 'ASSIGNED',
          'clock': 7,
        }
      });
      await Future.delayed(const Duration(milliseconds: 50));

      final all2 = await repository.getAllIncidents();
      expect(all2.first.status, 'ASSIGNED');
      expect(all2.first.sequenceNum, 7); // Clock 7 wins!

      // 3. Peer C broadcasts same incident as ASSIGNED with clock 3 (should be ignored)
      injectMessage({
        'msg_id': 'm3',
        'msg_type': 'incident_create',
        'origin_peer': 'peer_C',
        'clock': 3,
        'payload': {
          'incident_id': 'inc_clock',
          'type': 'medical',
          'status': 'ASSIGNED',
          'clock': 3,
        }
      });
      await Future.delayed(const Duration(milliseconds: 50));

      final all3 = await repository.getAllIncidents();
      expect(all3.first.sequenceNum, 7); // Still clock 7
    });

    test('TEST 9 — No Rollback', () async {
      // 1. Initial incident created as RESOLVED
      injectMessage({
        'msg_id': 'm1',
        'msg_type': 'incident_create',
        'origin_peer': 'peer_A',
        'clock': 10,
        'payload': {
          'incident_id': 'inc_norollback',
          'type': 'medical',
          'status': 'RESOLVED',
          'clock': 10,
        }
      });
      await Future.delayed(const Duration(milliseconds: 50));

      // 2. Peer B broadcasts same incident as ASSIGNED (with higher clock)
      injectMessage({
        'msg_id': 'm2',
        'msg_type': 'incident_create',
        'origin_peer': 'peer_B',
        'clock': 11,
        'payload': {
          'incident_id': 'inc_norollback',
          'type': 'medical',
          'status': 'ASSIGNED',
          'clock': 11,
        }
      });
      await Future.delayed(const Duration(milliseconds: 50));

      final all = await repository.getAllIncidents();
      expect(all.first.status, 'RESOLVED'); // Should ignore ASSIGNED because RESOLVED has higher priority
    });

    test('TEST 10 — Multi-device convergence', () async {
      // Sync response payload containing conflicting states of same incident
      injectMessage({
        'msg_id': 'sync_resp_1',
        'msg_type': 'sync_response',
        'origin_peer': 'peer_Z',
        'timestamp': 1000,
        'payload': {
          'incidents': [
            {
               'incident_id': 'inc_multi',
               'status': 'PENDING',
               'clock': 1,
            },
            {
               'incident_id': 'inc_multi',
               'status': 'ASSIGNED',
               'clock': 5,
            },
            {
               'incident_id': 'inc_multi',
               'status': 'RESOLVED',
               'clock': 6,
            },
            {
               'incident_id': 'inc_multi',
               'status': 'ASSIGNED',
               'clock': 10,
            }
          ]
        }
      });
      await Future.delayed(const Duration(milliseconds: 100));

      final all = await repository.getAllIncidents();
      expect(all.length, 1);
      // RESOLVED wins because of priority, even though last ASSIGNED had higher clock
      expect(all.first.status, 'RESOLVED');
    });
  });
}
