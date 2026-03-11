import 'dart:math';

/// Pure tile math functions for Web Mercator / SlippyMap tile calculations.
///
/// All functions are deterministic and have zero side effects.
/// Reference: https://wiki.openstreetmap.org/wiki/Slippy_map_tilenames

/// Convert longitude to tile X coordinate at given zoom.
int lonToTileX(double lon, int zoom) {
  return ((lon + 180.0) / 360.0 * (1 << zoom)).floor();
}

/// Convert latitude to tile Y coordinate at given zoom.
int latToTileY(double lat, int zoom) {
  final latRad = lat * pi / 180.0;
  return ((1.0 - log(tan(latRad) + 1.0 / cos(latRad)) / pi) /
          2.0 *
          (1 << zoom))
      .floor();
}

/// Convert tile X back to longitude (west edge of tile).
double tileXToLon(int x, int zoom) {
  return x / (1 << zoom) * 360.0 - 180.0;
}

/// Convert tile Y back to latitude (north edge of tile).
double tileYToLat(int y, int zoom) {
  final n = pi - 2.0 * pi * y / (1 << zoom);
  return 180.0 / pi * atan(0.5 * (exp(n) - exp(-n)));
}

/// Ground resolution: meters per tile at a given zoom and latitude.
///
/// Formula: C * cos(lat) / 2^zoom where C = 2π × 6378137 (earth circumference).
/// Since a tile is 256px, metersPerTile = metersPerPixel × 256.
/// Simplified: metersPerTile = 156543.03392804097 * cos(lat*π/180) * 256 / 2^zoom
/// Wait — the standard formula for meters/pixel is:
///   metersPerPixel = 156543.03392804097 * cos(lat * π/180) / 2^zoom
/// So metersPerTile (256px) = metersPerPixel * 256
double metersPerTile(int zoom, double lat) {
  const double metersPerPixelAtZoom0 = 156543.03392804097;
  final metersPerPixel =
      metersPerPixelAtZoom0 * cos(lat * pi / 180.0) / (1 << zoom);
  return metersPerPixel * 256.0;
}

/// Compute the number of tiles needed in each direction (radius) to cover
/// [radiusMeters] at a given [zoom] and [lat].
int tilesRadius(int zoom, double lat, double radiusMeters) {
  final mpt = metersPerTile(zoom, lat);
  if (mpt <= 0) return 0;
  return (radiusMeters / mpt).ceil();
}

/// A tile coordinate (z, x, y).
class TileCoord {
  final int z;
  final int x;
  final int y;

  const TileCoord(this.z, this.x, this.y);

  @override
  bool operator ==(Object other) =>
      other is TileCoord && other.z == z && other.x == x && other.y == y;

  @override
  int get hashCode => Object.hash(z, x, y);

  @override
  String toString() => 'TileCoord($z/$x/$y)';
}

/// Compute all tile coordinates needed to cover a circle of [radiusMeters]
/// around ([lat], [lon]) at a single [zoom] level.
///
/// Clamps tile coordinates to valid range [0, 2^zoom - 1].
List<TileCoord> tilesInRadius(
    double lat, double lon, double radiusMeters, int zoom) {
  final cx = lonToTileX(lon, zoom);
  final cy = latToTileY(lat, zoom);
  final r = tilesRadius(zoom, lat, radiusMeters);
  final maxTile = (1 << zoom) - 1;

  final tiles = <TileCoord>[];
  for (int x = (cx - r).clamp(0, maxTile);
      x <= (cx + r).clamp(0, maxTile);
      x++) {
    for (int y = (cy - r).clamp(0, maxTile);
        y <= (cy + r).clamp(0, maxTile);
        y++) {
      tiles.add(TileCoord(zoom, x, y));
    }
  }
  return tiles;
}

/// Compute total tile count for a prefetch job across a range of zoom levels.
///
/// Returns a map of zoom → tile count, plus the total.
({int total, Map<int, int> perZoom}) totalTilesForJob({
  required double lat,
  required double lon,
  required double radiusMeters,
  required int minZoom,
  required int maxZoom,
}) {
  final perZoom = <int, int>{};
  int total = 0;
  for (int z = minZoom; z <= maxZoom; z++) {
    final count = tilesInRadius(lat, lon, radiusMeters, z).length;
    perZoom[z] = count;
    total += count;
  }
  return (total: total, perZoom: perZoom);
}

/// Maximum tiles per job (safety guardrail).
const int kMaxTilesPerJob = 5000;

/// Maximum retry attempts per tile.
const int kMaxTileAttempts = 5;

/// Base retry delay in milliseconds.
const int kBaseRetryDelayMs = 2000;

/// Default download concurrency.
const int kDefaultConcurrency = 4;

/// Default prefetch radius in meters.
const double kDefaultPrefetchRadiusM = 5000.0;

/// Default min zoom for prefetch.
const int kDefaultPrefetchMinZoom = 12;

/// Default max zoom for prefetch.
const int kDefaultPrefetchMaxZoom = 16;
