import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:latlong2/latlong.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'dart:io';

import 'package:mobile_app/services/responder_state_service.dart';
import 'package:mobile_app/services/location_service.dart';
import 'package:mobile_app/services/tile_prefetch_service.dart';
import 'package:mobile_app/controllers/responder_controller.dart';
import 'package:mobile_app/data/tiles_repository.dart';
import 'package:mobile_app/data/db/prefetch_database.dart';
import 'package:mobile_app/features/map/map_service.dart';

class MockLocationService extends Mock implements LocationService {}
class MockMapService extends Mock implements MapService {}

class FakePathProviderPlatform extends Fake
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  @override
  Future<String?> getApplicationDocumentsPath() async {
    return '/tmp';
  }
}

class MockHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  late PrefetchDatabase db;
  late TilesRepository tilesRepo;
  late MockMapService mockMapService;
  late TilePrefetchService prefetchService;
  
  late MockLocationService mockLocationService;
  late ResponderStateService stateService;
  late ResponderController controller;

  setUp(() async {
    PathProviderPlatform.instance = FakePathProviderPlatform();
    HttpOverrides.global = MockHttpOverrides();

    // 1. Setup real Drift prefetch DB in memory
    db = PrefetchDatabase.memory();
    tilesRepo = TilesRepository(db);
    mockMapService = MockMapService();
    when(() => mockMapService.tileUrl).thenReturn('http://mock/{z}/{x}/{y}.png');
    prefetchService = TilePrefetchService(repo: tilesRepo, mapService: mockMapService);

    // 2. Setup mock location
    mockLocationService = MockLocationService();
    when(() => mockLocationService.getCurrentLocation())
        .thenAnswer((_) async => const LatLng(22.35, 78.67));

    // 3. Setup SharedPreferences for state
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    stateService = ResponderStateService(prefs);

    // 4. Create the Controller
    controller = ResponderController(
      stateService: stateService,
      locationService: mockLocationService,
      prefetchService: prefetchService,
    );
  });

  tearDown(() async {
    controller.dispose();
    stateService.dispose();
    await db.close();
    HttpOverrides.global = null;
  });

  test('Activation triggers prefetch and location retrieval', () async {
    // Initially inactive
    expect(stateService.currentState, ResponderState.inactive);

    // Toggle to active
    await stateService.toggleState();
    
    // Allow microtasks to complete (Stream listener processing)
    await Future.delayed(Duration.zero);

    // Verify location was requested
    verify(() => mockLocationService.getCurrentLocation()).called(1);

    // Verify tiles queued
    // A 5km radius at zoom 14-16 should result in over 100 tiles.
    final queuedTiles = await db.select(db.prefetchTiles).get();
    
    // We expect the queue to receive tiles
    expect(queuedTiles, isNotEmpty);
    
    // Verify jobs created
    final jobs = await db.select(db.prefetchJobs).get();
    expect(jobs.length, 1);
    expect(jobs.first.radiusM, 5000);
    expect(jobs.first.minZoom, 14);
    expect(jobs.first.maxZoom, 16);
  });

  test('Prefetch only triggered once per session', () async {
    await stateService.setState(ResponderState.active);
    await Future.delayed(Duration.zero);

    // Should be called 1 time
    verify(() => mockLocationService.getCurrentLocation()).called(1);

    // Firing active again should not trigger a second location/prefetch call
    await stateService.setState(ResponderState.active);
    await Future.delayed(Duration.zero);
    
    verifyNever(() => mockLocationService.getCurrentLocation());

    // Toggle off then on should trigger again
    await stateService.setState(ResponderState.inactive);
    await Future.delayed(Duration.zero);
    
    await stateService.setState(ResponderState.active);
    await Future.delayed(Duration.zero);

    verify(() => mockLocationService.getCurrentLocation()).called(1); // 2 times total
  });
}
