import 'package:latlong2/latlong.dart';
import '../models/route_result.dart';
import '../core/config.dart';
import 'osrm_service.dart';

/// Abstract service defined for routing features within the application.
abstract class RoutingService {
  /// Fetches a route between two coordinate points.
  Future<RouteResult?> getRoute(LatLng start, LatLng end);
}

/// OSRM-based implementation of the [RoutingService].
class OsrmRoutingService implements RoutingService {
  final OSRMService _osrmService;
  final RoutingConfig _config;

  OsrmRoutingService({
    required OSRMService osrmService,
    RoutingConfig? config,
  })  : _osrmService = osrmService,
        _config = config ?? RoutingConfig();

  @override
  Future<RouteResult?> getRoute(LatLng start, LatLng end) async {
    // Utilize the OSRMService logic but instruct it on the base URL based on config mode
    return _osrmService.fetchRoute(
      start: start,
      end: end,
      baseUrlOverride: _config.activeOsrmUrl,
    );
  }
}
