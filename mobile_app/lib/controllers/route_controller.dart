import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import '../models/route_result.dart';
import '../services/osrm_service.dart';
import '../services/route_cache_service.dart';

/// Controller to manage route requests and emit the current active route.
///
/// Checks [RouteCacheService] before hitting OSRM to reduce network calls.
class RouteController {
  final OSRMService _osrmService;
  final RouteCacheService _cacheService;

  // Stream controller to broadcast the latest route to the UI layer
  final StreamController<RouteResult?> _routeStreamController =
      StreamController<RouteResult?>.broadcast();

  RouteController(this._osrmService, this._cacheService);

  Stream<RouteResult?> get routeStream => _routeStreamController.stream;

  /// Requests a route from start to end and emits the result.
  /// Checks local cache first; falls back to OSRM on miss.
  Future<void> requestRoute({
    required LatLng start,
    required LatLng end,
  }) async {
    // Clear previous route immediately
    _routeStreamController.add(null);

    // 1. Check cache
    final cached = _cacheService.lookup(start, end);
    if (cached != null) {
      debugPrint('RouteController: Cache HIT — reusing cached route');
      _routeStreamController.add(cached);
      return;
    }

    // 2. Fetch from OSRM
    debugPrint('RouteController: Cache MISS — fetching from OSRM');
    final result = await _osrmService.fetchRoute(start: start, end: end);

    // 3. Store in cache on success
    if (result != null) {
      _cacheService.store(start, end, result);
    }

    _routeStreamController.add(result);
  }

  void clearRoute() {
    _routeStreamController.add(null);
  }

  void dispose() {
    _routeStreamController.close();
  }
}
