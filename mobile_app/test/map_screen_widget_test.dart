import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile_app/features/map/map_screen.dart';
import 'package:mobile_app/features/map/map_service.dart';
import 'package:mobile_app/core/config.dart';
import 'package:mobile_app/core/auth_service.dart';
import 'package:mobile_app/core/api_client.dart';
import 'package:mobile_app/core/ws_service.dart';
import 'package:mobile_app/data/database.dart';
import 'package:mobile_app/data/repositories/incident_repository.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

Widget _buildTestApp() {
  FlutterSecureStorage.setMockInitialValues({});
  final db = AppDatabase.memory();
  final authService = AuthService();
  final apiClient = ApiClient(baseUrl: 'http://test', authService: authService);
  final incidentRepo = IncidentRepository(db, apiClient);
  final config = AppConfig();
  final wsService = WsService('http://test', authService, db);
  final mapService = MapService();

  return MultiProvider(
    providers: [
      Provider<AppConfig>.value(value: config),
      Provider<AuthService>.value(value: authService),
      Provider<ApiClient>.value(value: apiClient),
      Provider<AppDatabase>.value(value: db),
      Provider<IncidentRepository>.value(value: incidentRepo),
      Provider<WsService>.value(value: wsService),
      Provider<MapService>.value(value: mapService),
    ],
    child: const MaterialApp(
      home: MapScreen(),
    ),
  );
}

void main() {
  testWidgets('MapScreen constructs and renders without error', (WidgetTester tester) async {
    await tester.pumpWidget(_buildTestApp());
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('OpenRescue Map'), findsOneWidget);
    expect(find.byType(Scaffold), findsOneWidget);
    expect(find.byIcon(Icons.add_location_alt), findsOneWidget);
    expect(find.byIcon(Icons.message), findsOneWidget);
    expect(find.byIcon(Icons.my_location), findsOneWidget);
    expect(find.byIcon(Icons.bug_report), findsOneWidget);
  });

  testWidgets('MapScreen shows loading state initially', (WidgetTester tester) async {
    await tester.pumpWidget(_buildTestApp());

    // Initially should show loading indicator
    expect(find.byType(Scaffold), findsOneWidget);
    expect(find.text('OpenRescue Map'), findsOneWidget);
    expect(find.text('Resolving tile source...'), findsOneWidget);
  });
}
