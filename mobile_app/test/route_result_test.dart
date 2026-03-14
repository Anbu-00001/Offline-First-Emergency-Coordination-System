import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/models/route_result.dart';

void main() {
  group('RouteResult', () {
    test('parses geometry from OSRM JSON', () {
      final json = {
        'code': 'Ok',
        'routes': [
          {
            'distance': 3400.5,
            'duration': 480.0,
            'geometry': {
              'type': 'LineString',
              'coordinates': [
                [80.2057, 13.0215],
                [80.2080, 13.0230],
                [80.2100, 13.0250],
              ],
            },
            'legs': [],
          }
        ],
      };

      final result = RouteResult.fromOsrmJson(json);

      expect(result, isNotNull);
      expect(result!.geometry.length, 3);
      expect(result.geometry[0].latitude, 13.0215);
      expect(result.geometry[0].longitude, 80.2057);
      expect(result.geometry[2].latitude, 13.0250);
      expect(result.geometry[2].longitude, 80.2100);
    });

    test('parses distance correctly', () {
      final json = {
        'code': 'Ok',
        'routes': [
          {
            'distance': 5678.9,
            'duration': 300.0,
            'geometry': {
              'type': 'LineString',
              'coordinates': [
                [80.2057, 13.0215],
                [80.2100, 13.0250],
              ],
            },
            'legs': [],
          }
        ],
      };

      final result = RouteResult.fromOsrmJson(json);

      expect(result, isNotNull);
      expect(result!.distanceMeters, 5678.9);
    });

    test('parses duration correctly', () {
      final json = {
        'code': 'Ok',
        'routes': [
          {
            'distance': 1000.0,
            'duration': 720.5,
            'geometry': {
              'type': 'LineString',
              'coordinates': [
                [80.2057, 13.0215],
                [80.2100, 13.0250],
              ],
            },
            'legs': [],
          }
        ],
      };

      final result = RouteResult.fromOsrmJson(json);

      expect(result, isNotNull);
      expect(result!.durationSeconds, 720.5);
    });

    test('extracts steps from legs', () {
      final json = {
        'code': 'Ok',
        'routes': [
          {
            'distance': 3400.0,
            'duration': 480.0,
            'geometry': {
              'type': 'LineString',
              'coordinates': [
                [80.2057, 13.0215],
                [80.2100, 13.0250],
              ],
            },
            'legs': [
              {
                'steps': [
                  {
                    'maneuver': {'type': 'depart', 'modifier': ''},
                    'name': 'Main Road',
                    'distance': 500.0,
                    'duration': 60.0,
                  },
                  {
                    'maneuver': {'type': 'turn', 'modifier': 'right'},
                    'name': 'Highway',
                    'distance': 1200.0,
                    'duration': 120.0,
                  },
                  {
                    'maneuver': {'type': 'arrive', 'modifier': ''},
                    'name': '',
                    'distance': 0.0,
                    'duration': 0.0,
                  },
                ],
              }
            ],
          }
        ],
      };

      final result = RouteResult.fromOsrmJson(json);

      expect(result, isNotNull);
      expect(result!.steps.length, 3);
      expect(result.steps[0].instruction, contains('Main Road'));
      expect(result.steps[0].distance, 500.0);
      expect(result.steps[0].duration, 60.0);
      expect(result.steps[1].instruction, contains('right'));
      expect(result.steps[1].instruction, contains('Highway'));
      expect(result.steps[1].distance, 1200.0);
      expect(result.steps[2].instruction, contains('Arrive'));
    });

    test('returns null for non-Ok code', () {
      final json = {
        'code': 'InvalidQuery',
        'routes': [],
      };

      final result = RouteResult.fromOsrmJson(json);
      expect(result, isNull);
    });

    test('returns null for empty routes', () {
      final json = {
        'code': 'Ok',
        'routes': <dynamic>[],
      };

      final result = RouteResult.fromOsrmJson(json);
      expect(result, isNull);
    });

    test('returns null for invalid geometry type', () {
      final json = {
        'code': 'Ok',
        'routes': [
          {
            'distance': 100.0,
            'duration': 10.0,
            'geometry': {
              'type': 'Point',
              'coordinates': [80.2057, 13.0215],
            },
            'legs': [],
          }
        ],
      };

      final result = RouteResult.fromOsrmJson(json);
      expect(result, isNull);
    });
  });

  group('RouteStep', () {
    test('parses step with name and modifier', () {
      final json = {
        'maneuver': {'type': 'turn', 'modifier': 'left'},
        'name': 'Park Avenue',
        'distance': 800.0,
        'duration': 90.0,
      };

      final step = RouteStep.fromOsrmJson(json);

      expect(step.instruction, 'Turn left onto Park Avenue');
      expect(step.distance, 800.0);
      expect(step.duration, 90.0);
    });

    test('parses step without modifier', () {
      final json = {
        'maneuver': {'type': 'depart'},
        'name': 'Start Street',
        'distance': 100.0,
        'duration': 15.0,
      };

      final step = RouteStep.fromOsrmJson(json);

      expect(step.instruction, 'Depart on Start Street');
      expect(step.distance, 100.0);
    });

    test('parses step without name', () {
      final json = {
        'maneuver': {'type': 'arrive', 'modifier': ''},
        'name': '',
        'distance': 0.0,
        'duration': 0.0,
      };

      final step = RouteStep.fromOsrmJson(json);

      expect(step.instruction, 'Arrive');
      expect(step.distance, 0.0);
    });
  });
}
