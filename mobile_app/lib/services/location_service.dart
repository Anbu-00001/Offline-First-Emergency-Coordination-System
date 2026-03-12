import 'package:location/location.dart';
import 'package:latlong2/latlong.dart';

/// Service to handle retrieving device GPS location and managing permissions.
class LocationService {
  final Location _location = Location();

  /// Retrieves the current device location.
  /// Requests permissions and services if necessary.
  /// Returns [LatLng] if successful, or null if permissions denied or unavailable.
  Future<LatLng?> getCurrentLocation() async {
    bool serviceEnabled;
    PermissionStatus permissionGranted;

    // Check if location services are enabled
    serviceEnabled = await _location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _location.requestService();
      if (!serviceEnabled) {
        return null;
      }
    }

    // Check if permissions are granted
    permissionGranted = await _location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await _location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) {
        return null;
      }
    }

    // Get the actual location
    try {
      final locationData = await _location.getLocation();
      if (locationData.latitude != null && locationData.longitude != null) {
        return LatLng(locationData.latitude!, locationData.longitude!);
      }
    } catch (e) {
      // Ignored: fallback to null
    }

    return null;
  }
}
