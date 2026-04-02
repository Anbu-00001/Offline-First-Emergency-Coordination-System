import 'dart:io';
import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';

class LocalFileTileProvider extends TileProvider {
  LocalFileTileProvider();

  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) {
    // Determine path from urlTemplate which was populated with dir path
    final url = getTileUrl(coordinates, options);
    final file = File(url);

    if (file.existsSync()) {
      return FileImage(file);
    } else {
      debugPrint("Tile not found: $url");
      // Return a transparent image or handle error
      throw Exception("Tile not found: $url");
    }
  }
}
