import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/geocode_result.dart';

/// Geocoding Service interacting with the public Nominatim API.
class GeocodingService {
  final http.Client _client;
  
  // In-memory cache for reverse geocode results.
  // Keys are strictly formatted "lat,lon" strings.
  final Map<String, GeocodeResult> _cache = {};

  GeocodingService({http.Client? client}) : _client = client ?? http.Client();

  static DateTime? _lastRequestTime;

  /// Perform a Reverse Geocode to translate a LatLng into a physical address.
  /// Converts lat/lon locally to avoid hitting the API repetitively for identical calls.
  Future<GeocodeResult?> reverse(double lat, double lon) async {
    final cacheKey = '${lat.toStringAsFixed(6)},${lon.toStringAsFixed(6)}';
    
    if (_cache.containsKey(cacheKey)) {
      debugPrint('GeocodingService: Cache HIT for $cacheKey');
      return _cache[cacheKey];
    }
    
    debugPrint('GeocodingService: Cache MISS for $cacheKey — fetching API');

    final now = DateTime.now();
    if (_lastRequestTime != null) {
      final diff = now.difference(_lastRequestTime!);
      if (diff.inMilliseconds < 1000) {
        await Future.delayed(Duration(milliseconds: 1000 - diff.inMilliseconds));
      }
    }
    _lastRequestTime = DateTime.now();

    try {
      final uriStr = 'https://nominatim.openstreetmap.org/reverse'
          '?lat=$lat&lon=$lon&format=json&addressdetails=1';
          
      final uri = Uri.parse(uriStr);
      final response = await _client.get(
        uri,
        headers: {
          'User-Agent': 'OpenRescue/1.0 (Emergency Response Applicaton)'
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        // Nominatim can return an error JSON object with code 200 if coordinate is widely invalid.
        if (data.containsKey('error')) {
           return null;
        }

        final result = GeocodeResult.fromNominatim(data);
        _cache[cacheKey] = result;
        return result;
      } else {
        debugPrint('GeocodingService: Failed to fetch address. Status: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('GeocodingService: Exception fetching address: $e');
    }

    return null;
  }
}
