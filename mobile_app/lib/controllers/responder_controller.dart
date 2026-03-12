import 'dart:async';

import 'package:flutter/foundation.dart';
import '../services/responder_state_service.dart';
import '../services/location_service.dart';
import '../services/tile_prefetch_service.dart';

/// Acts as the glue: listens to [ResponderStateService]. When active, it uses
/// [LocationService] to get the location, and then triggers an offline tile
/// prefetch centered around the responder for 5km using [TilePrefetchService].
class ResponderController {
  final ResponderStateService _stateService;
  final LocationService _locationService;
  final TilePrefetchService _prefetchService;

  StreamSubscription<ResponderState>? _stateSub;
  bool _hasTriggeredForCurrentSession = false;

  ResponderController({
    required ResponderStateService stateService,
    required LocationService locationService,
    required TilePrefetchService prefetchService,
  })  : _stateService = stateService,
        _locationService = locationService,
        _prefetchService = prefetchService {
    _init();
  }

  void _init() {
    _stateSub = _stateService.stateStream.listen(_onStateChanged);
    
    // Check initial state
    _onStateChanged(_stateService.currentState);
  }

  Future<void> _onStateChanged(ResponderState state) async {
    if (state == ResponderState.inactive) {
      _hasTriggeredForCurrentSession = false;
      return;
    }

    if (state == ResponderState.active) {
      if (_hasTriggeredForCurrentSession) return;
      _hasTriggeredForCurrentSession = true;

      // 1. Get the current location
      final location = await _locationService.getCurrentLocation();
      
      if (location == null) {
        debugPrint('ResponderController: Failed to get location, skipping tile prefetch');
        return;
      }

      // 2. Trigger tile prefetch for 5km radius
      debugPrint('Starting tile prefetch for radius');
      
      try {
        await _prefetchService.startPrefetchForRadius(
          location,
          5000, // 5km radius
        );
      } catch (e) {
        debugPrint('ResponderController: Failed to start prefetch: $e');
      }
    }
  }

  void dispose() {
    _stateSub?.cancel();
  }
}
