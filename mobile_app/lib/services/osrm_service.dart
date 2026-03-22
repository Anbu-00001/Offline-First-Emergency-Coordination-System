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
  /// Returns a list of [RouteResult]s with geometry, distance, duration, and steps,
  /// or an empty list if the request fails.
  ///
  /// Uses polyline6 encoding for ~80% smaller response payloads.
  Future<List<RouteResult>> fetchRoute({
    required LatLng start,
    required LatLng end,
    String? baseUrlOverride,
    bool alternatives = false,
  }) async {
    try {
      final baseUrl = baseUrlOverride ?? AppConfig.osrmBaseUrl;
      final uriStr = '$baseUrl/route/v1/driving/'
          '${start.longitude},${start.latitude};'
          '${end.longitude},${end.latitude}'
          '?overview=full&geometries=polyline6&steps=true'
          '&annotations=false&alternatives=$alternatives';

      final uri = Uri.parse(uriStr);
      final response = await _client.get(uri);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return RouteResult.fromOsrmJsonList(data);
      } else {
        debugPrint(
            'OSRMService: Failed to fetch route. Status: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('OSRMService: Exception fetching route: $e');
    }

    return [];
  }
}
