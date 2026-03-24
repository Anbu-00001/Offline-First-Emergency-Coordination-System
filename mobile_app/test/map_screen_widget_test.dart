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
import 'package:mobile_app/services/route_avoidance_service.dart';
import 'package:mobile_app/services/polygon_generator.dart';
import 'package:mobile_app/services/polygon_avoidance_service.dart';
import 'package:mobile_app/services/polygon_cache_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile_app/controllers/responder_controller.dart';
import 'package:mobile_app/data/db/prefetch_database.dart';
import 'package:mobile_app/data/tiles_repository.dart';
import 'package:mobile_app/services/tile_prefetch_service.dart';
import 'package:mobile_app/services/p2p_service.dart';

void main() {
  late AppDatabase db;
  late P2PService p2pService;
  late RouteController routeController;

  Future<Widget> buildTestApp() async {
    FlutterSecureStorage.setMockInitialValues({});
    db = AppDatabase.memory();
    final authService = AuthService();
    final apiClient = ApiClient(baseUrl: 'http://test', authService: authService);
    p2pService = P2PService(hostUrl: 'http://test');
    final polygonGenerator = PolygonGenerator();
    final polygonCacheService = PolygonCacheService(polygonGenerator);
    final incidentRepo = IncidentRepository(db, apiClient, p2pService, polygonCacheService);
    final config = AppConfig();
    final wsService = WsService('http://test', authService, db);
    final mapService = MapService();
    final locationService = LocationService();
    final routingConfig = RoutingConfig();
    final geocodingService = GeocodingService();
    final osrmService = OSRMService();
    final routingService = OsrmRoutingService(osrmService: osrmService, config: routingConfig);
    final routeCacheService = RouteCacheService();
    final routeAvoidanceService = RouteAvoidanceService();
    final polygonAvoidanceService = PolygonAvoidanceService(polygonCacheService);
    routeController = RouteController(routingService, routeCacheService, routeAvoidanceService, polygonAvoidanceService, incidentRepo);
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

    // Clean up handled manually in each test to avoid testWidgets timer invariants
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
        Provider<RouteAvoidanceService>.value(value: routeAvoidanceService),
        Provider<PolygonAvoidanceService>.value(value: polygonAvoidanceService),
        Provider<RouteController>.value(value: routeController),
        Provider<ResponderStateService>.value(value: responderStateService),
        Provider<ResponderController>.value(value: responderController),
        Provider<P2PService>.value(value: p2pService),
      ],
      child: const MaterialApp(
        home: MapScreen(),
      ),
    );
  }

  testWidgets('MapScreen constructs and renders without error', (WidgetTester tester) async {
    await tester.pumpWidget(await buildTestApp());
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('OpenRescue Map'), findsOneWidget);
    expect(find.byType(Scaffold), findsOneWidget);
    expect(find.byIcon(Icons.add_location_alt), findsOneWidget);
    expect(find.byIcon(Icons.message), findsOneWidget);
    expect(find.byIcon(Icons.my_location), findsOneWidget);
    expect(find.byIcon(Icons.bug_report), findsOneWidget);

    // Force widgets to dispose and clean up timers
    await tester.pumpWidget(const SizedBox());
    p2pService.dispose();
    routeController.dispose();
    await db.close();
  });

  testWidgets('MapScreen shows loading state initially', (WidgetTester tester) async {
    await tester.pumpWidget(await buildTestApp());

    // Initially should show loading indicator
    expect(find.byType(Scaffold), findsOneWidget);
    expect(find.text('OpenRescue Map'), findsOneWidget);
    expect(find.text('Resolving tile source...'), findsOneWidget);

    // Force widgets to dispose and clean up timers
    await tester.pumpWidget(const SizedBox());
    p2pService.dispose();
    routeController.dispose();
    await db.close();
  });
}
