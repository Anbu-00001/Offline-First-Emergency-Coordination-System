/// Structured lookup result from a Reverse Geocoding operation.
class GeocodeResult {
  final String address;
  final String? landmark;

  GeocodeResult({
    required this.address,
    this.landmark,
  });

  /// Factory constructors from Nominatim reverse-geocode JSON.
  factory GeocodeResult.fromNominatim(Map<String, dynamic> json) {
    final addressMap = json['address'] as Map<String, dynamic>? ?? {};
    
    // Attempt to extract a landmark or notable building
    final landmark = addressMap['amenity'] ??
        addressMap['building'] ??
        addressMap['shop'] ??
        addressMap['tourism'] ??
        addressMap['leisure'] ??
        addressMap['historic'] ??
        addressMap['office'] ??
        addressMap['village'] ??
        addressMap['neighbourhood'];
        
    final displayName = json['display_name'] as String? ?? 'Unknown Location';

    return GeocodeResult(
      address: displayName,
      landmark: landmark?.toString(),
    );
  }
}
