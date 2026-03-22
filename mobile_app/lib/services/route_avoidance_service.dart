import 'package:latlong2/latlong.dart';
import '../models/models.dart';
import '../utils/geo_utils.dart';

/// Service to evaluate route safety based on proximity to active incidents.
class RouteAvoidanceService {
  /// Defines how close a route can get to an incident before being marked UNSAFE.
  static const double dangerRadiusMeters = 200;

  /// Evaluates whether a route is safe by checking the distance of all its points
  /// to any active incidents.
  ///
  /// Returns `true` if SAFE, `false` if UNSAFE.
  bool isRouteSafe(List<LatLng> routePoints, List<Incident> incidents) {
    for (final incident in incidents) {
      final incidentLoc = LatLng(incident.lat, incident.lon);

      for (final point in routePoints) {
        final distance = calculateDistanceMeters(point, incidentLoc);
        if (distance < dangerRadiusMeters) {
          // Route comes too close to a danger zone
          return false;
        }
      }
    }

    return true; // All clear
  }
}
