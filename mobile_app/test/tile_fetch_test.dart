import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/core/map/tile_fetch_diagnostic.dart';

void main() {
  group('TileFetchDiagnostic', () {
    late HttpServer server;
    late String serverUrl;

    setUp(() async {
      // Start a local HTTP server for testing
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      serverUrl = 'http://${server.address.address}:${server.port}';

      server.listen((HttpRequest request) {
        if (request.uri.path == '/tiles/3/4/3.png') {
          // Serve a mock tile image (just 1 empty byte for testing)
          request.response
            ..statusCode = HttpStatus.ok
            ..headers.contentType = ContentType('image', 'png')
            ..add([0x00])
            ..close();
        } else if (request.uri.path == '/timeout') {
          // Deliberately hold the connection
        } else {
          request.response
            ..statusCode = HttpStatus.notFound
            ..close();
        }
      });
    });

    tearDown(() async {
      await server.close(force: true);
    });

    test('fetchSampleTile formats URL correctly and fetches bytes', () async {
      // The template contains {z}, {x}, {y} placeholders. 
      // TileFetchDiagnostic replaces them with 3, 4, 3 respectively.
      final urlTemplate = '$serverUrl/tiles/{z}/{x}/{y}.png';
      
      final result = await TileFetchDiagnostic.fetchSampleTile(urlTemplate);
      
      expect(result.statusCode, 200);
      expect(result.bytes, isNotNull);
      expect(result.bytes!.length, 1);
      expect(result.isSuccess, isTrue);
    });

    test('fetchSampleTile returns 404 for missing tile', () async {
      final urlTemplate = '$serverUrl/missing/{z}/{x}/{y}.png';
      
      final result = await TileFetchDiagnostic.fetchSampleTile(urlTemplate);
      
      expect(result.statusCode, 404);
      expect(result.isSuccess, isFalse);
    });

    test('fetchSampleTile handles invalid URL gracefully', () async {
      final result = await TileFetchDiagnostic.fetchSampleTile('http://invalid-url-that-does-not-exist.local');
      
      expect(result.statusCode, -1);
      expect(result.isSuccess, isFalse);
      expect(result.error, isNotNull);
    });
  });
}
