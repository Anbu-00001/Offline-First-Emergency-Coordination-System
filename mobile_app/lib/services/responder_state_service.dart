import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ResponderState {
  inactive,
  active,
}

/// Manages responder mode state (inactive / active), persists to SharedPreferences,
/// and broadcasts changes via an observable Stream.
class ResponderStateService {
  static const String _kStateKey = 'responder_state';

  final SharedPreferences _prefs;
  final _stateController = StreamController<ResponderState>.broadcast();

  ResponderState _currentState = ResponderState.inactive;

  ResponderStateService(this._prefs) {
    _loadInitialState();
  }

  /// The current, synchronously available state.
  ResponderState get currentState => _currentState;

  /// Subscribe to state changes.
  Stream<ResponderState> get stateStream => _stateController.stream;

  void _loadInitialState() {
    final active = _prefs.getBool(_kStateKey) ?? false;
    _currentState = active ? ResponderState.active : ResponderState.inactive;
    _stateController.add(_currentState);
  }

  /// Toggle the current responder state.
  Future<void> toggleState() async {
    final newState = _currentState == ResponderState.active
        ? ResponderState.inactive
        : ResponderState.active;

    await setState(newState);
  }

  /// Explicitly set the responder state.
  Future<void> setState(ResponderState newState) async {
    if (_currentState == newState) return;

    _currentState = newState;
    await _prefs.setBool(_kStateKey, newState == ResponderState.active);

    if (newState == ResponderState.active) {
      debugPrint('Responder mode activated');
    }

    _stateController.add(newState);
  }

  /// Dispose the stream controller.
  void dispose() {
    _stateController.close();
  }
}
