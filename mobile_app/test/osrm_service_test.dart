import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mobile_app/services/osrm_service.dart';

class MockHttpClient extends Mock implements http.Client {}

class FakeUri extends Fake implements Uri {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeUri());
  });

  group('OSRMService', () {
    late MockHttpClient mockHttpClient;
    late OSRMService osrmService;

    setUp(() {
      mockHttpClient = MockHttpClient();
      osrmService = OSRMService(client: mockHttpClient);
    });

    test('fetchRoute returns RouteResult with geometry, distance, duration', () async {
      final jsonResponse = '''
      {
        "code": "Ok",
        "routes": [
          {
            "distance": 3400.5,
            "duration": 480.0,
            "geometry": {
              "type": "LineString",
              "coordinates": [
                [80.2057, 13.0215],
                [80.2100, 13.0250]
              ]
            },
            "legs": [
              {
                "steps": [
                  {
                    "maneuver": {"type": "depart", "modifier": ""},
                    "name": "Main Road",
                    "distance": 3400.5,
                    "duration": 480.0
                  }
                ]
              }
            ]
          }
        ]
      }
      ''';

      when(() => mockHttpClient.get(any())).thenAnswer(
        (_) async => http.Response(jsonResponse, 200),
      );

      final start = const LatLng(13.0215, 80.2057);
      final end = const LatLng(13.0250, 80.2100);

      final result = await osrmService.fetchRoute(start: start, end: end);

      expect(result, isNotNull);
      expect(result!.geometry.length, 2);
      expect(result.geometry[0].latitude, 13.0215);
      expect(result.geometry[0].longitude, 80.2057);
      expect(result.geometry[1].latitude, 13.0250);
      expect(result.geometry[1].longitude, 80.2100);
      expect(result.distanceMeters, 3400.5);
      expect(result.durationSeconds, 480.0);
      expect(result.steps.length, 1);
      expect(result.steps[0].instruction, contains('Main Road'));

      verify(() => mockHttpClient.get(any())).called(1);
    });

    test('fetchRoute returns null when no route is found', () async {
      final jsonResponse = '''
      {
        "code": "Ok",
        "routes": []
      }
      ''';

      when(() => mockHttpClient.get(any())).thenAnswer(
        (_) async => http.Response(jsonResponse, 200),
      );

      final start = const LatLng(13.0215, 80.2057);
      final end = const LatLng(13.0250, 80.2100);

      final result = await osrmService.fetchRoute(start: start, end: end);

      expect(result, isNull);
      verify(() => mockHttpClient.get(any())).called(1);
    });

    test('fetchRoute handles invalid json', () async {
      final jsonResponse = 'invalid json';

      when(() => mockHttpClient.get(any())).thenAnswer(
        (_) async => http.Response(jsonResponse, 200),
      );

      final start = const LatLng(13.0215, 80.2057);
      final end = const LatLng(13.0250, 80.2100);

      final result = await osrmService.fetchRoute(start: start, end: end);

      expect(result, isNull);
      verify(() => mockHttpClient.get(any())).called(1);
    });

    test('fetchRoute returns null on non-200 status', () async {
      when(() => mockHttpClient.get(any())).thenAnswer(
        (_) async => http.Response('Server Error', 500),
      );

      final start = const LatLng(13.0215, 80.2057);
      final end = const LatLng(13.0250, 80.2100);

      final result = await osrmService.fetchRoute(start: start, end: end);

      expect(result, isNull);
      verify(() => mockHttpClient.get(any())).called(1);
    });
  });
}
