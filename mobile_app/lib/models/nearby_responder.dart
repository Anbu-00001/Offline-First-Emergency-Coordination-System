/// A structured model representing a discovered nearby responder
/// and their relative distance from a queried coordinate.
class NearbyResponder {
  final String id;
  final double distanceKm;

  NearbyResponder({
    required this.id,
    required this.distanceKm,
  });
}
