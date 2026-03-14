import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:mobile_app/models/route_result.dart';
import 'package:mobile_app/services/route_cache_service.dart';

void main() {
  group('RouteCacheService', () {
    late RouteCacheService cache;

    setUp(() {
      cache = RouteCacheService(maxEntries: 2, toleranceMeters: 200.0);
    });

    final start1 = const LatLng(13.0, 80.0);
    final end1 = const LatLng(13.1, 80.1);
    final route1 = RouteResult(
      geometry: [start1, end1],
      distanceMeters: 1000,
      durationSeconds: 100,
      steps: [],
    );

    test('stores and retrieves exact match', () {
      cache.store(start1, end1, route1);
      final result = cache.lookup(start1, end1);
      expect(result, isNotNull);
      expect(result!.distanceMeters, 1000);
      expect(cache.length, 1);
    });

    test('returns null for cache miss', () {
      cache.store(start1, end1, route1);
      final diffStart = const LatLng(14.0, 81.0);
      expect(cache.lookup(diffStart, end1), isNull);
    });

    test('reuses route within tolerance radius (200m)', () {
      cache.store(start1, end1, route1);

      // Shift start by ~100m (roughly 0.0009 degrees)
      final nearStart = const LatLng(13.0 + 0.0009, 80.0);
      // Shift end by ~100m
      final nearEnd = const LatLng(13.1 - 0.0009, 80.1);

      final result = cache.lookup(nearStart, nearEnd);
      expect(result, isNotNull);
      expect(result!.distanceMeters, 1000);
    });

    test('does not reuse route outside tolerance radius', () {
      cache.store(start1, end1, route1);

      // Shift start by ~300m (roughly 0.0027 degrees)
      final farStart = const LatLng(13.0 + 0.0027, 80.0);

      final result = cache.lookup(farStart, end1);
      expect(result, isNull);
    });

    test('evicts least recently used (LRU) entry when full', () {
      final start2 = const LatLng(14.0, 81.0);
      final end2 = const LatLng(14.1, 81.1);
      final route2 = RouteResult(
        geometry: [start2, end2],
        distanceMeters: 2000,
        durationSeconds: 200,
        steps: [],
      );

      final start3 = const LatLng(15.0, 82.0);
      final end3 = const LatLng(15.1, 82.1);
      final route3 = RouteResult(
        geometry: [start3, end3],
        distanceMeters: 3000,
        durationSeconds: 300,
        steps: [],
      );

      cache.store(start1, end1, route1);
      cache.store(start2, end2, route2);
      expect(cache.length, 2);

      // Looking up route1 promotes it to most-recently-used
      cache.lookup(start1, end1);

      // Storing route3 should evict route2 (since route1 was just used)
      cache.store(start3, end3, route3);

      expect(cache.length, 2);
      expect(cache.lookup(start1, end1), isNotNull, reason: 'route1 should be kept');
      expect(cache.lookup(start3, end3), isNotNull, reason: 'route3 should be kept');
      expect(cache.lookup(start2, end2), isNull, reason: 'route2 should be evicted');
    });

    test('updates existing entry for same location', () {
      final updatedRoute = RouteResult(
        geometry: [start1, end1],
        distanceMeters: 1500,
        durationSeconds: 150,
        steps: [],
      );

      cache.store(start1, end1, route1);
      cache.store(start1, end1, updatedRoute);

      expect(cache.length, 1);
      final result = cache.lookup(start1, end1);
      expect(result!.distanceMeters, 1500);
    });

    test('clear empties the cache', () {
      cache.store(start1, end1, route1);
      expect(cache.length, 1);
      cache.clear();
      expect(cache.length, 0);
      expect(cache.lookup(start1, end1), isNull);
    });
  });
}
