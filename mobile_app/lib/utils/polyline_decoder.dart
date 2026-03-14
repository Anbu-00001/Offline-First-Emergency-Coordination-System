import 'package:latlong2/latlong.dart';

/// Decodes a Google Encoded Polyline string into a list of [LatLng] points.
///
/// [precision] should be 5 for standard Google polyline encoding
/// or 6 for OSRM polyline6 encoding.
List<LatLng> decodePolyline(String encoded, {int precision = 6}) {
  final points = <LatLng>[];
  final factor = _pow10(precision);
  int index = 0;
  int lat = 0;
  int lng = 0;

  while (index < encoded.length) {
    // Decode latitude
    int shift = 0;
    int result = 0;
    int byte;
    do {
      byte = encoded.codeUnitAt(index++) - 63;
      result |= (byte & 0x1F) << shift;
      shift += 5;
    } while (byte >= 0x20);
    lat += (result & 1) != 0 ? ~(result >> 1) : (result >> 1);

    // Decode longitude
    shift = 0;
    result = 0;
    do {
      byte = encoded.codeUnitAt(index++) - 63;
      result |= (byte & 0x1F) << shift;
      shift += 5;
    } while (byte >= 0x20);
    lng += (result & 1) != 0 ? ~(result >> 1) : (result >> 1);

    points.add(LatLng(lat / factor, lng / factor));
  }

  return points;
}

double _pow10(int n) {
  double result = 1.0;
  for (int i = 0; i < n; i++) {
    result *= 10;
  }
  return result;
}
