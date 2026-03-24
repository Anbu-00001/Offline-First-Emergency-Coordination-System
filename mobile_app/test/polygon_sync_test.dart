import 'dart:io';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/data/repositories/incident_repository.dart';
import 'package:mobile_app/data/database.dart' as db;
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
  group('Day 27 — Deterministic Polygon Sync Tests', () {
    // ─── Unit-level: PolygonGenerator determinism ──────────────────────────

    test('TEST 1 — Same incident produces identical polygon on two generators', () {
      final generatorA = PolygonGenerator();
      final generatorB = PolygonGenerator();

      final incident = Incident(
        id: 'inc_1',
        reporterId: 'user_A',
        type: 'fire',
        lat: 12.9716,
        lon: 77.5946,
        priority: 'high',
        status: 'PENDING',
        clientId: 'device_A',
        sequenceNum: 1,
        updatedAt: DateTime(2026, 3, 24),
      );

      final polyA = generatorA.generatePolygonFromIncident(incident);
      final polyB = generatorB.generatePolygonFromIncident(incident);

      expect(polyA.points.length, polyB.points.length);
      for (int i = 0; i < polyA.points.length; i++) {
        expect(polyA.points[i].latitude, polyB.points[i].latitude);
        expect(polyA.points[i].longitude, polyB.points[i].longitude);
      }
      expect(polyA.id, polyB.id);
      expect(polyA.incidentId, polyB.incidentId);
    });

    test('TEST 2 — Different incident types produce different radii', () {
      final generator = PolygonGenerator();

      final fire = Incident(
        id: 'inc_fire', reporterId: 'u', type: 'fire', lat: 10, lon: 20,
        priority: 'high', status: 'PENDING', clientId: 'c', sequenceNum: 1,
        updatedAt: DateTime(2026),
      );
      final flood = Incident(
        id: 'inc_flood', reporterId: 'u', type: 'flood', lat: 10, lon: 20,
        priority: 'high', status: 'PENDING', clientId: 'c', sequenceNum: 1,
        updatedAt: DateTime(2026),
      );

      final firePoly = generator.generatePolygonFromIncident(fire);
      final floodPoly = generator.generatePolygonFromIncident(flood);

      // Flood radius (300m) > Fire radius (150m), so flood polygon should be larger
      // Compare first point's distance from center
      final fireOffset = (firePoly.points[0].latitude - fire.lat).abs();
      final floodOffset = (floodPoly.points[0].latitude - flood.lat).abs();
      expect(floodOffset > fireOffset, isTrue);
    });

    test('TEST 3 — Polygon has exactly 12 points', () {
      final generator = PolygonGenerator();
      final incident = Incident(
        id: 'inc_pts', reporterId: 'u', type: 'accident', lat: 10, lon: 20,
        priority: 'medium', status: 'PENDING', clientId: 'c', sequenceNum: 1,
        updatedAt: DateTime(2026),
      );

      final poly = generator.generatePolygonFromIncident(incident);
      expect(poly.points.length, 12);
    });

    // ─── PolygonCacheService tests ─────────────────────────────────────────

    test('TEST 4 — PolygonCacheService stores and retrieves polygons', () {
      final cache = PolygonCacheService(PolygonGenerator());
      final incident = Incident(
        id: 'inc_cache', reporterId: 'u', type: 'fire', lat: 10, lon: 20,
        priority: 'high', status: 'PENDING', clientId: 'c', sequenceNum: 1,
        updatedAt: DateTime(2026),
      );

      expect(cache.getPolygon('inc_cache'), isNull);
      cache.updateFromIncident(incident);

      expect(cache.getPolygon('inc_cache'), isNotNull);
      expect(cache.getPolygon('inc_cache')!.incidentId, 'inc_cache');
      expect(cache.length, 1);
    });

    test('TEST 5 — PolygonCacheService batch update', () {
      final cache = PolygonCacheService(PolygonGenerator());
      final incidents = List<Incident>.generate(5, (i) => Incident(
        id: 'inc_$i', reporterId: 'u', type: 'fire', lat: 10.0 + i, lon: 20.0,
        priority: 'high', status: 'PENDING', clientId: 'c', sequenceNum: 1,
        updatedAt: DateTime(2026),
      ));

      cache.updateFromIncidents(incidents);
      expect(cache.length, 5);
      expect(cache.getAllPolygons().length, 5);
    });

    test('TEST 6 — Two caches with same incidents produce identical polygons', () {
      final cacheA = PolygonCacheService(PolygonGenerator());
      final cacheB = PolygonCacheService(PolygonGenerator());

      final incidents = [
        Incident(
          id: 'inc_x1', reporterId: 'u', type: 'fire', lat: 12.9716, lon: 77.5946,
          priority: 'high', status: 'PENDING', clientId: 'c', sequenceNum: 1,
          updatedAt: DateTime(2026),
        ),
        Incident(
          id: 'inc_x2', reporterId: 'u', type: 'flood', lat: 13.0, lon: 77.6,
          priority: 'high', status: 'PENDING', clientId: 'c', sequenceNum: 2,
          updatedAt: DateTime(2026),
        ),
      ];

      cacheA.updateFromIncidents(incidents);
      cacheB.updateFromIncidents(incidents);

      for (final inc in incidents) {
        final polyA = cacheA.getPolygon(inc.id)!;
        final polyB = cacheB.getPolygon(inc.id)!;
        expect(polyA.points.length, polyB.points.length);
        for (int i = 0; i < polyA.points.length; i++) {
          expect(polyA.points[i].latitude, polyB.points[i].latitude);
          expect(polyA.points[i].longitude, polyB.points[i].longitude);
        }
      }
    });

    test('TEST 7 — removePolygon evicts correctly', () {
      final cache = PolygonCacheService(PolygonGenerator());
      final incident = Incident(
        id: 'inc_rm', reporterId: 'u', type: 'fire', lat: 10, lon: 20,
        priority: 'high', status: 'PENDING', clientId: 'c', sequenceNum: 1,
        updatedAt: DateTime(2026),
      );

      cache.updateFromIncident(incident);
      expect(cache.length, 1);
      cache.removePolygon('inc_rm');
      expect(cache.length, 0);
      expect(cache.getPolygon('inc_rm'), isNull);
    });

    // ─── P2P integration: polygon cache updated after P2P incident ────────

    late db.AppDatabase database;
    late P2PService p2pService;
    late PolygonCacheService polygonCache;
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
      database = db.AppDatabase.memory();
      polygonCache = PolygonCacheService(PolygonGenerator());
      repository = IncidentRepository(database, MockApiClient(), p2pService, polygonCache);

      p2pService.connect();
      await Future.delayed(const Duration(milliseconds: 100));
    });

    tearDown(() async {
      p2pService.dispose();
      await database.close();
      await activeWs?.close();
      await mockDaemon.close(force: true);
    });

    void injectMessage(Map<String, dynamic> msg) {
      if (msg['origin_peer'] == null) msg['origin_peer'] = 'peer_B';
      activeWs?.add(jsonEncode(msg));
    }

    test('TEST 8 — P2P incident triggers polygon cache update', () async {
      injectMessage({
        'msg_id': 'poly_m1',
        'msg_type': 'incident_create',
        'origin_peer': 'peer_B',
        'clock': 1,
        'payload': {
          'incident_id': 'inc_p2p_poly',
          'type': 'fire',
          'lat': 12.9716,
          'lon': 77.5946,
          'status': 'PENDING',
          'clock': 1,
        }
      });

      await Future.delayed(const Duration(milliseconds: 200));

      // Verify incident was stored
      final incidents = await repository.getAllIncidents();
      expect(incidents.length, 1);
      expect(incidents.first.id, 'inc_p2p_poly');

      // Verify polygon was cached
      final polygon = polygonCache.getPolygon('inc_p2p_poly');
      expect(polygon, isNotNull);
      expect(polygon!.points.length, 12);
      expect(polygon.incidentId, 'inc_p2p_poly');
    });

    test('TEST 9 — Local incident creation triggers polygon cache update', () async {
      await repository.createIncident(IncidentCreateDto(
        type: 'flood',
        lat: 13.0,
        lon: 77.6,
        priority: 'high',
        status: 'PENDING',
        clientId: 'device_A',
        sequenceNum: 1,
      ));

      await Future.delayed(const Duration(milliseconds: 50));

      // Cache should contain the polygon
      expect(polygonCache.length, 1);
      final poly = polygonCache.getAllPolygons().first;
      expect(poly.points.length, 12);
    });

    test('TEST 10 — P2P payload does NOT contain polygon data', () async {
      await repository.createIncident(IncidentCreateDto(
        type: 'fire',
        lat: 12.0,
        lon: 77.0,
        priority: 'high',
        status: 'PENDING',
        clientId: 'device_A',
        sequenceNum: 1,
      ));

      await Future.delayed(const Duration(milliseconds: 100));

      expect(broadcastCaptured.length, 1);
      final payload = broadcastCaptured.first.payload;

      // Must NOT contain polygon keys
      expect(payload.containsKey('polygon_points'), isFalse);
      expect(payload.containsKey('polygon'), isFalse);
      expect(payload.containsKey('radius'), isFalse);
      expect(payload.containsKey('danger_polygon'), isFalse);

      // Must contain incident data
      expect(payload.containsKey('type'), isTrue);
      expect(payload.containsKey('lat'), isTrue);
      expect(payload.containsKey('lon'), isTrue);
      expect(payload.containsKey('incident_id'), isTrue);
    });

    test('TEST 11 — CRDT merge updates polygon cache', () async {
      // Insert initial incident as PENDING
      injectMessage({
        'msg_id': 'crdt_m1',
        'msg_type': 'incident_create',
        'origin_peer': 'peer_A',
        'clock': 1,
        'payload': {
          'incident_id': 'inc_crdt_poly',
          'type': 'fire',
          'lat': 12.0,
          'lon': 77.0,
          'status': 'PENDING',
          'clock': 1,
        }
      });
      await Future.delayed(const Duration(milliseconds: 200));

      expect(polygonCache.getPolygon('inc_crdt_poly'), isNotNull);
      final polyBefore = polygonCache.getPolygon('inc_crdt_poly')!;

      // CRDT merge: update same incident to RESOLVED (higher priority)
      injectMessage({
        'msg_id': 'crdt_m2',
        'msg_type': 'incident_create',
        'origin_peer': 'peer_B',
        'clock': 2,
        'payload': {
          'incident_id': 'inc_crdt_poly',
          'type': 'fire',
          'lat': 12.0,
          'lon': 77.0,
          'status': 'RESOLVED',
          'clock': 2,
        }
      });
      await Future.delayed(const Duration(milliseconds: 200));

      // Polygon should still exist and match
      final polyAfter = polygonCache.getPolygon('inc_crdt_poly');
      expect(polyAfter, isNotNull);
      // Same location → same polygon points
      for (int i = 0; i < polyBefore.points.length; i++) {
        expect(polyAfter!.points[i].latitude, polyBefore.points[i].latitude);
        expect(polyAfter.points[i].longitude, polyBefore.points[i].longitude);
      }
    });

    test('TEST 12 — Sync response merges incidents and caches polygons', () async {
      injectMessage({
        'msg_id': 'sync_resp_poly',
        'msg_type': 'sync_response',
        'origin_peer': 'peer_Z',
        'timestamp': 1000,
        'payload': {
          'incidents': [
            {
              'incident_id': 'sync_inc_1',
              'type': 'fire',
              'lat': 12.0,
              'lon': 77.0,
              'status': 'PENDING',
              'clock': 1,
            },
            {
              'incident_id': 'sync_inc_2',
              'type': 'flood',
              'lat': 13.0,
              'lon': 78.0,
              'status': 'ASSIGNED',
              'clock': 2,
            },
          ]
        }
      });
      await Future.delayed(const Duration(milliseconds: 300));

      final incidents = await repository.getAllIncidents();
      expect(incidents.length, 2);

      // Both polygons should be cached
      expect(polygonCache.getPolygon('sync_inc_1'), isNotNull);
      expect(polygonCache.getPolygon('sync_inc_2'), isNotNull);
      expect(polygonCache.length, 2);
    });
  });
}
