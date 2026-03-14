import 'dart:async';
import 'package:latlong2/latlong.dart';
import '../models/route_result.dart';
import '../services/osrm_service.dart';

/// Controller to manage route requests and emit the current active route
class RouteController {
  final OSRMService _osrmService;

  // Stream controller to broadcast the latest route to the UI layer
  final StreamController<RouteResult?> _routeStreamController =
      StreamController<RouteResult?>.broadcast();

  RouteController(this._osrmService);

  Stream<RouteResult?> get routeStream => _routeStreamController.stream;

  /// Requests a route from start to end and emits the result.
  /// Emits null first to clear any old route.
  Future<void> requestRoute({
    required LatLng start,
    required LatLng end,
  }) async {
    // Clear previous route immediately
    _routeStreamController.add(null);

    final result = await _osrmService.fetchRoute(start: start, end: end);
    _routeStreamController.add(result);
  }

  void clearRoute() {
    _routeStreamController.add(null);
  }

  void dispose() {
    _routeStreamController.close();
  }
}
