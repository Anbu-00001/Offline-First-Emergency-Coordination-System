import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import '../models/polygon_model.dart';
import 'polygon_cache_service.dart';
import '../utils/geo_spatial_utils.dart';

/// Day 27: Evaluates route safety against cached danger polygons.
///
/// Reads pre-computed polygons from [PolygonCacheService] instead of
/// regenerating on every call. This guarantees consistency with the
/// deterministic polygon pipeline.
class PolygonAvoidanceService {
  final PolygonCacheService _cacheService;

  PolygonAvoidanceService(this._cacheService);

  bool isRouteSafeWithPolygons(List<LatLng> route) {
    final List<DangerPolygon> polygons = _cacheService.getAllPolygons();

    if (polygons.isEmpty) return true;

    for (final polygon in polygons) {
      if (doesPolylineIntersectPolygon(route, polygon.points)) {
        debugPrint('POLYGON_INTERSECTION_DETECTED: ${polygon.incidentId}');
        return false;
      }
    }
    return true;
  }
}

