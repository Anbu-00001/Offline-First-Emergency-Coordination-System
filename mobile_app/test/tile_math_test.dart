import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/core/map/tile_math.dart';

void main() {
  group('Tile math — lonToTileX / latToTileY', () {
    test('zoom 0: entire world is one tile', () {
      expect(lonToTileX(0, 0), 0);
      expect(latToTileY(0, 0), 0);
    });

    test('zoom 1: (0,0) maps to tile (1,1)', () {
      expect(lonToTileX(0, 1), 1);
      expect(latToTileY(0, 1), 1);
    });

    test('London (51.5074, -0.1278) at zoom 10', () {
      // Known values from OSM wiki:
      // lon=-0.1278 → X = 511
      // lat=51.5074 → Y = 340
      expect(lonToTileX(-0.1278, 10), 511);
      expect(latToTileY(51.5074, 10), 340);
    });

    test('New Delhi (28.6139, 77.2090) at zoom 10', () {
      final x = lonToTileX(77.2090, 10);
      final y = latToTileY(28.6139, 10);
      // X should be around 731, Y around 438
      expect(x, greaterThan(700));
      expect(x, lessThan(750));
      expect(y, greaterThan(420));
      expect(y, lessThan(460));
    });

    test('Mumbai (19.0760, 72.8777) at zoom 12', () {
      final x = lonToTileX(72.8777, 12);
      final y = latToTileY(19.0760, 12);
      // X ~ 2894, Y ~ 1801
      expect(x, greaterThan(2850));
      expect(x, lessThan(2950));
      expect(y, greaterThan(1750));
      expect(y, lessThan(1850));
    });

    test('negative longitude: New York (-74.006, 40.7128) zoom 8', () {
      final x = lonToTileX(-74.006, 8);
      final y = latToTileY(40.7128, 8);
      expect(x, greaterThan(70));
      expect(x, lessThan(80));
      expect(y, greaterThan(90));
      expect(y, lessThan(100));
    });
  });

  group('Tile math — metersPerTile', () {
    test('metersPerTile at zoom 0, equator is ~40 million', () {
      final mpt = metersPerTile(0, 0);
      // Approximately Earth circumference
      expect(mpt, closeTo(40075016.686, 1000));
    });

    test('metersPerTile decreases with zoom', () {
      final mpt10 = metersPerTile(10, 22.35);
      final mpt12 = metersPerTile(12, 22.35);
      expect(mpt12, lessThan(mpt10));
      expect(mpt12 * 4, closeTo(mpt10, mpt10 * 0.01));
    });

    test('metersPerTile at zoom 15, India center ~1200m', () {
      final mpt = metersPerTile(15, 22.35);
      // At zoom 15, tile ~ 1200m at ~22° latitude
      expect(mpt, greaterThan(1000));
      expect(mpt, lessThan(1500));
    });
  });

  group('Tile math — tilesRadius', () {
    test('5km radius at zoom 15 needs ~4 tiles in each direction', () {
      final r = tilesRadius(15, 22.35, 5000);
      expect(r, greaterThanOrEqualTo(3));
      expect(r, lessThanOrEqualTo(6));
    });

    test('5km radius at zoom 12 needs ~1 tile in each direction', () {
      final r = tilesRadius(12, 22.35, 5000);
      expect(r, greaterThanOrEqualTo(0));
      expect(r, lessThanOrEqualTo(2));
    });

    test('radius 0 gives 0 tiles', () {
      final r = tilesRadius(15, 22.35, 0);
      expect(r, 0);
    });
  });

  group('Tile math — tilesInRadius', () {
    test('produces tiles for a radius', () {
      final tiles = tilesInRadius(22.35, 78.67, 2000, 15);
      expect(tiles, isNotEmpty);
      // All tiles should have z=15
      for (final t in tiles) {
        expect(t.z, 15);
      }
    });

    test('center tile is always included', () {
      final cx = lonToTileX(78.67, 15);
      final cy = latToTileY(22.35, 15);
      final tiles = tilesInRadius(22.35, 78.67, 1000, 15);
      expect(tiles.any((t) => t.x == cx && t.y == cy), isTrue);
    });

    test('tile coordinates are within valid range', () {
      final tiles = tilesInRadius(22.35, 78.67, 5000, 14);
      final maxTile = (1 << 14) - 1;
      for (final t in tiles) {
        expect(t.x, greaterThanOrEqualTo(0));
        expect(t.x, lessThanOrEqualTo(maxTile));
        expect(t.y, greaterThanOrEqualTo(0));
        expect(t.y, lessThanOrEqualTo(maxTile));
      }
    });
  });

  group('Tile math — totalTilesForJob', () {
    test('total tiles increases with zoom range', () {
      final narrow = totalTilesForJob(
        lat: 22.35, lon: 78.67,
        radiusMeters: 5000, minZoom: 14, maxZoom: 14,
      );
      final wide = totalTilesForJob(
        lat: 22.35, lon: 78.67,
        radiusMeters: 5000, minZoom: 14, maxZoom: 16,
      );
      expect(wide.total, greaterThan(narrow.total));
    });

    test('per-zoom breakdown sums to total', () {
      final result = totalTilesForJob(
        lat: 22.35, lon: 78.67,
        radiusMeters: 5000, minZoom: 12, maxZoom: 16,
      );
      final sum = result.perZoom.values.fold(0, (a, b) => a + b);
      expect(sum, result.total);
    });

    test('5km radius, zooms 12–16 stays under default limit', () {
      final result = totalTilesForJob(
        lat: 22.35, lon: 78.67,
        radiusMeters: 5000, minZoom: 12, maxZoom: 16,
      );
      expect(result.total, lessThanOrEqualTo(kMaxTilesPerJob));
    });
  });

  group('Tile math — reverse conversion', () {
    test('tileXToLon and tileYToLat roundtrip', () {
      final x = lonToTileX(78.67, 15);
      final y = latToTileY(22.35, 15);
      final lon = tileXToLon(x, 15);
      final lat = tileYToLat(y, 15);
      // Round trip should be close to original (within one tile)
      expect(lon, closeTo(78.67, 0.1));
      expect(lat, closeTo(22.35, 0.1));
    });
  });
}
