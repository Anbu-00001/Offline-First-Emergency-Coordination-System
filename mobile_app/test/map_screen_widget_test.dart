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
import 'package:mobile_app/services/location_service.dart';
import 'package:mobile_app/services/geocoding_service.dart';
import 'package:mobile_app/services/osrm_service.dart';
import 'package:mobile_app/services/route_cache_service.dart';
import 'package:mobile_app/services/responder_registry.dart';
import 'package:mobile_app/services/responder_state_service.dart';
import 'package:mobile_app/services/routing_service.dart';
import 'package:mobile_app/controllers/route_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile_app/controllers/responder_controller.dart';
import 'package:mobile_app/features/prefetch/prefetch_controller.dart';
import 'package:mobile_app/data/db/prefetch_database.dart';
import 'package:mobile_app/data/tiles_repository.dart';
import 'package:mobile_app/services/tile_prefetch_service.dart';

Future<Widget> _buildTestApp() async {
  FlutterSecureStorage.setMockInitialValues({});
  final db = AppDatabase.memory();
  final authService = AuthService();
  final apiClient = ApiClient(baseUrl: 'http://test', authService: authService);
  final incidentRepo = IncidentRepository(db, apiClient);
  final config = AppConfig();
  final wsService = WsService('http://test', authService, db);
  final mapService = MapService();
  final locationService = LocationService();
  final routingConfig = RoutingConfig();
  final geocodingService = GeocodingService();
  final osrmService = OSRMService();
  final routingService = OsrmRoutingService(osrmService: osrmService, config: routingConfig);
  final routeCacheService = RouteCacheService();
  final routeController = RouteController(routingService, routeCacheService);
  final responderRegistry = MockResponderRegistry();
  
  // Create dummy preferences and state service
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final responderStateService = ResponderStateService(prefs);
  
  final prefetchDb = PrefetchDatabase();
  final tilesRepo = TilesRepository(prefetchDb);
  final prefetchService = TilePrefetchService(
    repo: tilesRepo,
    mapService: mapService,
  );
  
  final responderController = ResponderController(
    stateService: responderStateService,
    locationService: locationService,
    prefetchService: prefetchService,
  );

  return MultiProvider(
    providers: [
      Provider<AppConfig>.value(value: config),
      Provider<AuthService>.value(value: authService),
      Provider<ApiClient>.value(value: apiClient),
      Provider<AppDatabase>.value(value: db),
      Provider<IncidentRepository>.value(value: incidentRepo),
      Provider<WsService>.value(value: wsService),
      Provider<MapService>.value(value: mapService),
      Provider<LocationService>.value(value: locationService),
      Provider<RoutingConfig>.value(value: routingConfig),
      Provider<GeocodingService>.value(value: geocodingService),
      Provider<OSRMService>.value(value: osrmService),
      Provider<RoutingService>.value(value: routingService),
      Provider<ResponderRegistry>.value(value: responderRegistry),
      Provider<RouteCacheService>.value(value: routeCacheService),
      Provider<RouteController>.value(value: routeController),
      Provider<ResponderStateService>.value(value: responderStateService),
      Provider<ResponderController>.value(value: responderController),
    ],
    child: const MaterialApp(
      home: MapScreen(),
    ),
  );
}

void main() {
  testWidgets('MapScreen constructs and renders without error', (WidgetTester tester) async {
    await tester.pumpWidget(await _buildTestApp());
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('OpenRescue Map'), findsOneWidget);
    expect(find.byType(Scaffold), findsOneWidget);
    expect(find.byIcon(Icons.add_location_alt), findsOneWidget);
    expect(find.byIcon(Icons.message), findsOneWidget);
    expect(find.byIcon(Icons.my_location), findsOneWidget);
    expect(find.byIcon(Icons.bug_report), findsOneWidget);
  });

  testWidgets('MapScreen shows loading state initially', (WidgetTester tester) async {
    await tester.pumpWidget(await _buildTestApp());

    // Initially should show loading indicator
    expect(find.byType(Scaffold), findsOneWidget);
    expect(find.text('OpenRescue Map'), findsOneWidget);
    expect(find.text('Resolving tile source...'), findsOneWidget);
  });
}
