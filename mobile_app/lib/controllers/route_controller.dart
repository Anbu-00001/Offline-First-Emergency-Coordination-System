import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import '../models/models.dart';
import '../models/route_result.dart';
import '../services/routing_service.dart';
import '../services/route_cache_service.dart';
import '../services/route_avoidance_service.dart';
import '../services/polygon_avoidance_service.dart';
import '../data/repositories/incident_repository.dart';

/// Controller to manage route requests and emit the current active route.
///
/// Checks [RouteCacheService] before hitting OSRM to reduce network calls.
class RouteController {
  final RoutingService _routingService;
  final RouteCacheService _cacheService;
  final RouteAvoidanceService _avoidanceService;
  final PolygonAvoidanceService _polygonAvoidanceService;
  final IncidentRepository _incidentRepository;

  // Stream controller to broadcast the latest route to the UI layer
  final StreamController<RouteResult?> _routeStreamController =
      StreamController<RouteResult?>.broadcast();

  RouteController(
    this._routingService,
    this._cacheService,
    this._avoidanceService,
    this._polygonAvoidanceService,
    this._incidentRepository,
  );

  Stream<RouteResult?> get routeStream => _routeStreamController.stream;

  bool _isRouteSafe(List<LatLng> geometry, List<Incident> incidents) {
    if (!_avoidanceService.isRouteSafe(geometry, incidents)) return false;
    if (!_polygonAvoidanceService.isRouteSafeWithPolygons(geometry)) return false;
    return true;
  }

  /// Requests a route from start to end and emits the result.
  /// Checks local cache first; falls back to OSRM on miss.
  Future<void> requestRoute({
    required LatLng start,
    required LatLng end,
  }) async {
    // Clear previous route immediately
    _routeStreamController.add(null);

    // 1. Fetch incidents
    final incidents = await _incidentRepository.getAllIncidents();

    // 2. Check cache first
    final cached = _cacheService.lookup(start, end);
    if (cached != null) {
      debugPrint('RouteController: Cache HIT — reusing cached route');
      debugPrint('ROUTE_EVALUATION_STARTED');
      if (_isRouteSafe(cached.geometry, incidents)) {
        debugPrint('SAFE_ROUTE_SELECTED');
        _routeStreamController.add(cached);
        return;
      } else {
        debugPrint('ROUTE_MARKED_UNSAFE');
        debugPrint('Cached route unsafe, re-fetching...');
      }
    }

    // 3. Fetch from RoutingService
    debugPrint('RouteController: Fetching initial route from RoutingService');
    final initialRoutes = await _routingService.getRoute(start, end, alternatives: false);

    if (initialRoutes.isEmpty) {
      _routeStreamController.add(null);
      return;
    }

    final originalRoute = initialRoutes.first;

    // 4. Pass route to RouteAvoidanceService
    debugPrint('ROUTE_EVALUATION_STARTED');
    if (_isRouteSafe(originalRoute.geometry, incidents)) {
      // If SAFE -> emit route
      debugPrint('SAFE_ROUTE_SELECTED');
      _cacheService.store(start, end, originalRoute);
      _routeStreamController.add(originalRoute);
      return;
    }

    // If UNSAFE -> request alternatives
    debugPrint('ROUTE_MARKED_UNSAFE');
    debugPrint('RouteController: Requesting alternatives...');
    
    final alternateRoutes = await _routingService.getRoute(start, end, alternatives: true);

    // Evaluate each alternative
    for (final route in alternateRoutes) {
      if (_isRouteSafe(route.geometry, incidents)) {
        debugPrint('SAFE_ROUTE_SELECTED');
        _cacheService.store(start, end, route);
        _routeStreamController.add(route);
        return;
      }
    }

    // If none SAFE -> fallback to original/shortest route
    debugPrint('FALLBACK_ROUTE_USED');
    _cacheService.store(start, end, originalRoute);
    _routeStreamController.add(originalRoute);
  }

  void clearRoute() {
    _routeStreamController.add(null);
  }

  void dispose() {
    _routeStreamController.close();
  }
}
