import 'dart:math' as math;
import 'package:latlong2/latlong.dart';

/// Calculates the great-circle distance between two points in meters
/// using the Haversine formula.
/// Fully offline, FOSS compliant, no external API.
double calculateDistanceMeters(LatLng a, LatLng b) {
  const double earthRadiusMeters = 6371000;

  final double dLat = _degreesToRadians(b.latitude - a.latitude);
  final double dLon = _degreesToRadians(b.longitude - a.longitude);

  final double lat1 = _degreesToRadians(a.latitude);
  final double lat2 = _degreesToRadians(b.latitude);

  final double aVal = math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.sin(dLon / 2) *
          math.sin(dLon / 2) *
          math.cos(lat1) *
          math.cos(lat2);

  final double c = 2 * math.asin(math.sqrt(aVal));
  return earthRadiusMeters * c;
}

double _degreesToRadians(double degrees) {
  return degrees * math.pi / 180.0;
}
