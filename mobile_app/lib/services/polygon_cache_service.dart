import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../models/polygon_model.dart';
import 'polygon_generator.dart';

/// Caches deterministically-generated danger polygons keyed by incident ID.
///
/// Day 27: Polygon geometry is never transmitted over the network. Every device
/// derives identical polygons from the same incident data (id, lat, lon, type)
/// using [PolygonGenerator]. This service caches the results so polygons are
/// computed only once per incident create/update.
class PolygonCacheService {
  final PolygonGenerator _generator;
  final Map<String, DangerPolygon> _cache = {};

  PolygonCacheService(this._generator);

  /// Generates a polygon from the incident and stores it in the cache.
  /// If the incident already has a cached polygon, it is replaced.
  void updateFromIncident(Incident incident) {
    final polygon = _generator.generatePolygonFromIncident(incident);
    _cache[incident.id] = polygon;
    debugPrint('[PolygonCache] POLYGON_CACHE_UPDATED: ${incident.id}');
  }

  /// Batch-updates the cache from a list of incidents.
  void updateFromIncidents(List<Incident> incidents) {
    for (final incident in incidents) {
      updateFromIncident(incident);
    }
  }

  /// Returns the cached polygon for the given incident ID, or null.
  DangerPolygon? getPolygon(String incidentId) {
    return _cache[incidentId];
  }

  /// Returns all currently cached polygons.
  List<DangerPolygon> getAllPolygons() {
    return _cache.values.toList();
  }

  /// Removes a polygon from the cache.
  void removePolygon(String incidentId) {
    _cache.remove(incidentId);
    debugPrint('[PolygonCache] POLYGON_CACHE_REMOVED: $incidentId');
  }

  /// Number of cached polygons.
  int get length => _cache.length;
}
