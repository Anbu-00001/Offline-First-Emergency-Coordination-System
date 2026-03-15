import 'dart:async';
import '../models/nearby_responder.dart';

/// Service abstraction for discovering available responders near a specific location.
/// Designed to be implemented by Mesh networks, REST APIs, or Mock providers.
abstract class ResponderRegistry {
  /// Fetch a list of available responders near the given coordinates.
  Future<List<NearbyResponder>> getNearbyResponders(double lat, double lon);
}

/// A Mock implementation of [ResponderRegistry] intended for MVP/UI development.
/// Simulates network latency and randomly generates responder IDs and distances.
class MockResponderRegistry implements ResponderRegistry {
  @override
  Future<List<NearbyResponder>> getNearbyResponders(double lat, double lon) async {
    // Simulate mesh network discovery latency
    await Future.delayed(const Duration(milliseconds: 500));

    // Return the specific mock data requested
    return [
      NearbyResponder(id: "Responder_12", distanceKm: 1.2),
      NearbyResponder(id: "Responder_21", distanceKm: 2.4),
      NearbyResponder(id: "Responder_07", distanceKm: 3.1),
    ];
  }
}
