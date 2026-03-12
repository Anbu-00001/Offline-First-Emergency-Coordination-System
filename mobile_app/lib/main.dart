import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/config.dart';
import 'core/auth_service.dart';
import 'core/api_client.dart';
import 'core/ws_service.dart';
import 'data/database.dart';
import 'data/db/prefetch_database.dart';
import 'data/repositories/incident_repository.dart';
import 'data/tiles_repository.dart';
import 'features/map/map_screen.dart';
import 'features/map/map_service.dart';
import 'features/prefetch/prefetch_controller.dart';
import 'services/tile_prefetch_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/responder_state_service.dart';
import 'services/location_service.dart';
import 'controllers/responder_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 1. Core Config
  final config = AppConfig();
  final baseUrl = await config.resolveBackendBaseUrl();
  
  // 2. Services
  final authService = AuthService();
  final apiClient = ApiClient(baseUrl: baseUrl, authService: authService);
  final db = AppDatabase();
  final incidentRepo = IncidentRepository(db, apiClient);
  final wsService = WsService(baseUrl, authService, db);
  final mapService = MapService();

  // 3. Prefetch system
  final prefetchDb = PrefetchDatabase();
  final tilesRepo = TilesRepository(prefetchDb);
  final prefetchService = TilePrefetchService(
    repo: tilesRepo,
    mapService: mapService,
  );
  final prefetchController = PrefetchController(prefetchService);

  // 4. Responder System
  final prefs = await SharedPreferences.getInstance();
  final responderStateService = ResponderStateService(prefs);
  final locationService = LocationService();
  final responderController = ResponderController(
    stateService: responderStateService,
    locationService: locationService,
    prefetchService: prefetchService,
  );

  runApp(
    MultiProvider(
      providers: [
        Provider<AppConfig>.value(value: config),
        Provider<AuthService>.value(value: authService),
        Provider<ApiClient>.value(value: apiClient),
        Provider<AppDatabase>.value(value: db),
        Provider<IncidentRepository>.value(value: incidentRepo),
        Provider<WsService>.value(value: wsService),
        Provider<MapService>.value(value: mapService),
        Provider<PrefetchDatabase>.value(value: prefetchDb),
        Provider<TilesRepository>.value(value: tilesRepo),
        Provider<TilePrefetchService>.value(value: prefetchService),
        ChangeNotifierProvider<PrefetchController>.value(
            value: prefetchController),
        Provider<ResponderStateService>.value(value: responderStateService),
        Provider<LocationService>.value(value: locationService),
        Provider<ResponderController>.value(value: responderController),
      ],
      child: const OpenRescueApp(),
    ),
  );
}

class OpenRescueApp extends StatelessWidget {
  const OpenRescueApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OpenRescue',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.red),
        useMaterial3: true,
      ),
      home: const MapScreen(),
    );
  }
}
