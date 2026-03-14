import 'dart:math';
import 'package:latlong2/latlong.dart';
import '../models/route_result.dart';

/// In-memory LRU cache for computed routes.
///
/// Caches up to [maxEntries] routes and supports spatial reuse:
/// if a new request's start/end fall within [toleranceMeters] of a
/// cached entry, the cached [RouteResult] is returned.
class RouteCacheService {
  final int maxEntries;
  final double toleranceMeters;

  /// Ordered list – most-recently-used at the end.
  final List<_CacheEntry> _entries = [];

  RouteCacheService({
    this.maxEntries = 100,
    this.toleranceMeters = 200.0,
  });

  /// Look up a cached route whose start/end are within [toleranceMeters]
  /// of the given coordinates.  Returns `null` on cache miss.
  RouteResult? lookup(LatLng start, LatLng end) {
    for (int i = _entries.length - 1; i >= 0; i--) {
      final e = _entries[i];
      if (_withinTolerance(start, e.start) &&
          _withinTolerance(end, e.end)) {
        // Promote to most-recently-used
        _entries.removeAt(i);
        _entries.add(e);
        return e.result;
      }
    }
    return null;
  }

  /// Store a [RouteResult] in the cache, evicting the LRU entry if full.
  void store(LatLng start, LatLng end, RouteResult result) {
    // Remove existing entry for same location (dedup)
    _entries.removeWhere(
        (e) => _withinTolerance(start, e.start) && _withinTolerance(end, e.end));

    if (_entries.length >= maxEntries) {
      _entries.removeAt(0); // Evict LRU (oldest)
    }

    _entries.add(_CacheEntry(start: start, end: end, result: result));
  }

  /// Clear the entire cache.
  void clear() => _entries.clear();

  /// Current number of cached entries (exposed for testing).
  int get length => _entries.length;

  // ── helpers ──────────────────────────────────────────────────────────

  bool _withinTolerance(LatLng a, LatLng b) {
    return _haversineMeters(a, b) <= toleranceMeters;
  }

  /// Haversine distance in meters between two points.
  static double _haversineMeters(LatLng a, LatLng b) {
    const earthRadius = 6371000.0; // meters
    final dLat = _toRad(b.latitude - a.latitude);
    final dLon = _toRad(b.longitude - a.longitude);
    final sinLat = sin(dLat / 2);
    final sinLon = sin(dLon / 2);
    final h = sinLat * sinLat +
        cos(_toRad(a.latitude)) * cos(_toRad(b.latitude)) * sinLon * sinLon;
    return 2 * earthRadius * asin(sqrt(h));
  }

  static double _toRad(double deg) => deg * pi / 180;
}

class _CacheEntry {
  final LatLng start;
  final LatLng end;
  final RouteResult result;

  _CacheEntry({
    required this.start,
    required this.end,
    required this.result,
  });
}
