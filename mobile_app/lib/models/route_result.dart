import 'package:latlong2/latlong.dart';

/// A single turn-by-turn instruction step from an OSRM route.
class RouteStep {
  final String instruction;
  final double distance;
  final double duration;

  const RouteStep({
    required this.instruction,
    required this.distance,
    required this.duration,
  });

  /// Parse a step from an OSRM step JSON object.
  factory RouteStep.fromOsrmJson(Map<String, dynamic> json) {
    final maneuver = json['maneuver'] as Map<String, dynamic>? ?? {};
    final type = maneuver['type'] as String? ?? '';
    final modifier = maneuver['modifier'] as String? ?? '';
    final name = json['name'] as String? ?? '';

    String instruction;
    if (name.isNotEmpty) {
      instruction = modifier.isNotEmpty
          ? '${_capitalize(type)} $modifier onto $name'
          : '${_capitalize(type)} on $name';
    } else {
      instruction = modifier.isNotEmpty
          ? '${_capitalize(type)} $modifier'
          : _capitalize(type);
    }

    return RouteStep(
      instruction: instruction,
      distance: (json['distance'] as num?)?.toDouble() ?? 0.0,
      duration: (json['duration'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

/// The full result of an OSRM route request containing geometry,
/// distance, duration, and turn-by-turn steps.
class RouteResult {
  final List<LatLng> geometry;
  final double distanceMeters;
  final double durationSeconds;
  final List<RouteStep> steps;

  const RouteResult({
    required this.geometry,
    required this.distanceMeters,
    required this.durationSeconds,
    required this.steps,
  });

  /// Parse a [RouteResult] from the top-level OSRM JSON response.
  ///
  /// Expects the standard OSRM response with `code`, `routes[]`, etc.
  /// Returns `null` if the response is invalid or contains no routes.
  static RouteResult? fromOsrmJson(Map<String, dynamic> data) {
    if (data['code'] != 'Ok') return null;

    final routes = data['routes'] as List?;
    if (routes == null || routes.isEmpty) return null;

    final route = routes[0] as Map<String, dynamic>;

    // Parse geometry
    final geometry = route['geometry'] as Map<String, dynamic>?;
    if (geometry == null || geometry['type'] != 'LineString') return null;

    final coordinates = geometry['coordinates'] as List? ?? [];
    final points = coordinates.map<LatLng>((coord) {
      final lon = (coord[0] as num).toDouble();
      final lat = (coord[1] as num).toDouble();
      return LatLng(lat, lon);
    }).toList();

    if (points.isEmpty) return null;

    // Parse distance and duration
    final distanceMeters = (route['distance'] as num?)?.toDouble() ?? 0.0;
    final durationSeconds = (route['duration'] as num?)?.toDouble() ?? 0.0;

    // Parse steps from all legs
    final steps = <RouteStep>[];
    final legs = route['legs'] as List? ?? [];
    for (final leg in legs) {
      final legSteps = (leg as Map<String, dynamic>)['steps'] as List? ?? [];
      for (final step in legSteps) {
        steps.add(RouteStep.fromOsrmJson(step as Map<String, dynamic>));
      }
    }

    return RouteResult(
      geometry: points,
      distanceMeters: distanceMeters,
      durationSeconds: durationSeconds,
      steps: steps,
    );
  }
}

String _capitalize(String s) {
  if (s.isEmpty) return s;
  return s[0].toUpperCase() + s.substring(1);
}
