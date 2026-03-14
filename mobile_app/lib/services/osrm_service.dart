import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../core/config.dart';
import '../models/route_result.dart';

/// Service for talking to the OSRM Routing API
class OSRMService {
  final http.Client _client;

  OSRMService({http.Client? client}) : _client = client ?? http.Client();

  /// Fetches a route between two coordinate points.
  /// Returns a [RouteResult] with geometry, distance, duration, and steps,
  /// or `null` if the request fails.
  Future<RouteResult?> fetchRoute({
    required LatLng start,
    required LatLng end,
  }) async {
    try {
      final baseUrl = AppConfig.osrmBaseUrl;
      final uriStr = '$baseUrl/route/v1/driving/'
          '${start.longitude},${start.latitude};'
          '${end.longitude},${end.latitude}'
          '?overview=full&geometries=geojson&steps=true';

      final uri = Uri.parse(uriStr);
      final response = await _client.get(uri);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return RouteResult.fromOsrmJson(data);
      } else {
        debugPrint(
            'OSRMService: Failed to fetch route. Status: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('OSRMService: Exception fetching route: $e');
    }

    return null;
  }
}
