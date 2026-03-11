import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../services/tile_prefetch_service.dart';
import '../../core/map/tile_math.dart';

/// ChangeNotifier wrapping TilePrefetchService for UI binding.
class PrefetchController extends ChangeNotifier {
  final TilePrefetchService _service;

  String? _activeJobId;
  PrefetchProgress? _progress;
  StreamSubscription<PrefetchProgress>? _progressSub;
  String? _errorMessage;
  bool _isStarting = false;

  PrefetchController(this._service);

  // ─── Getters ──────────────────────────────────────────────────────────

  String? get activeJobId => _activeJobId;
  PrefetchProgress? get progress => _progress;
  String? get errorMessage => _errorMessage;
  bool get isStarting => _isStarting;
  bool get hasActiveJob => _activeJobId != null && _progress?.isComplete != true;

  // ─── Actions ──────────────────────────────────────────────────────────

  /// Start a new prefetch job.
  Future<void> startPrefetch({
    required double lat,
    required double lon,
    double radiusMeters = kDefaultPrefetchRadiusM,
    int minZoom = kDefaultPrefetchMinZoom,
    int maxZoom = kDefaultPrefetchMaxZoom,
    bool allowLargeJob = false,
  }) async {
    _isStarting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final jobId = await _service.startJob(
        lat: lat,
        lon: lon,
        radiusMeters: radiusMeters,
        minZoom: minZoom,
        maxZoom: maxZoom,
        allowLargeJob: allowLargeJob,
      );

      _activeJobId = jobId;
      _listenToProgress(jobId);
    } on PrefetchLimitExceeded catch (e) {
      _errorMessage = 'Too many tiles (${e.estimated}). '
          'Max is ${e.limit}. Reduce radius or zoom range.';
    } catch (e) {
      _errorMessage = 'Failed to start: $e';
    } finally {
      _isStarting = false;
      notifyListeners();
    }
  }

  /// Pause the active job.
  Future<void> pause() async {
    if (_activeJobId == null) return;
    await _service.pauseJob(_activeJobId!);
    notifyListeners();
  }

  /// Resume the active job.
  Future<void> resume() async {
    if (_activeJobId == null) return;
    await _service.resumeJob(_activeJobId!);
    _listenToProgress(_activeJobId!);
    notifyListeners();
  }

  /// Cancel the active job.
  Future<void> cancel() async {
    if (_activeJobId == null) return;
    await _service.cancelJob(_activeJobId!);
    _progressSub?.cancel();
    _activeJobId = null;
    _progress = null;
    notifyListeners();
  }

  /// Estimate tile count without starting a job.
  ({int total, Map<int, int> perZoom}) estimateTiles({
    required double lat,
    required double lon,
    required double radiusMeters,
    required int minZoom,
    required int maxZoom,
  }) {
    return totalTilesForJob(
      lat: lat,
      lon: lon,
      radiusMeters: radiusMeters,
      minZoom: minZoom,
      maxZoom: maxZoom,
    );
  }

  // ─── Internal ─────────────────────────────────────────────────────────

  void _listenToProgress(String jobId) {
    _progressSub?.cancel();
    _progressSub = _service.getJobProgress(jobId).listen(
      (progress) {
        _progress = progress;
        notifyListeners();
      },
      onError: (e) {
        _errorMessage = 'Progress error: $e';
        notifyListeners();
      },
    );
  }

  @override
  void dispose() {
    _progressSub?.cancel();
    super.dispose();
  }
}
