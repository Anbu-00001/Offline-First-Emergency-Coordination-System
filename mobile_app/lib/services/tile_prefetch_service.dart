import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import '../core/map/tile_math.dart';
import '../data/tiles_repository.dart';
import '../data/db/prefetch_database.dart';
import '../features/map/map_service.dart';

/// Progress snapshot for a prefetch job.
class PrefetchProgress {
  final String jobId;
  final String status;
  final int totalTiles;
  final int tilesDone;
  final int tilesFailed;
  final int tilesQueued;
  final double? estimatedSecondsRemaining;

  PrefetchProgress({
    required this.jobId,
    required this.status,
    required this.totalTiles,
    required this.tilesDone,
    this.tilesFailed = 0,
    this.tilesQueued = 0,
    this.estimatedSecondsRemaining,
  });

  double get progressFraction =>
      totalTiles > 0 ? tilesDone / totalTiles : 0.0;

  bool get isComplete =>
      status == 'completed' || status == 'cancelled';
}

/// Asynchronous tile download engine with persistent queue, concurrency
/// control, exponential backoff, and pause/resume/cancel support.
class TilePrefetchService {
  final TilesRepository _repo;
  final MapService _mapService;
  final int concurrency;

  /// Active job controllers.
  final Map<String, _JobRunner> _activeJobs = {};

  /// Random for jitter.
  final _random = Random();

  TilePrefetchService({
    required TilesRepository repo,
    required MapService mapService,
    this.concurrency = kDefaultConcurrency,
  })  : _repo = repo,
        _mapService = mapService;

  /// Start a new tile prefetch job.
  ///
  /// Returns the job ID. Throws if tile count exceeds [kMaxTilesPerJob]
  /// and [allowLargeJob] is false.
  Future<String> startJob({
    required double lat,
    required double lon,
    double radiusMeters = kDefaultPrefetchRadiusM,
    int minZoom = kDefaultPrefetchMinZoom,
    int maxZoom = kDefaultPrefetchMaxZoom,
    bool allowLargeJob = false,
  }) async {
    // 1. Compute tile set
    final estimate = totalTilesForJob(
      lat: lat,
      lon: lon,
      radiusMeters: radiusMeters,
      minZoom: minZoom,
      maxZoom: maxZoom,
    );

    debugPrint('PrefetchService: Estimated ${estimate.total} tiles '
        'for ${radiusMeters}m radius, zooms $minZoom..$maxZoom');

    // 2. Safety guardrail
    if (estimate.total > kMaxTilesPerJob && !allowLargeJob) {
      throw PrefetchLimitExceeded(
        estimated: estimate.total,
        limit: kMaxTilesPerJob,
      );
    }

    // 3. Generate job ID
    final jobId = _generateJobId();

    // 4. Create job record
    await _repo.createJob(
      jobId: jobId,
      lat: lat,
      lon: lon,
      radiusM: radiusMeters.round(),
      minZoom: minZoom,
      maxZoom: maxZoom,
      totalTiles: estimate.total,
    );

    // 5. Enqueue tiles (lower zooms first for zoom-first strategy)
    for (int z = minZoom; z <= maxZoom; z++) {
      final tiles = tilesInRadius(lat, lon, radiusMeters, z);
      final records = tiles.map((t) => (z: t.z, x: t.x, y: t.y)).toList();
      await _repo.enqueueTiles(jobId, records);
    }

    debugPrint('PrefetchService: Job $jobId created with ${estimate.total} tiles');

    // 6. Start processing
    _startProcessing(jobId);

    return jobId;
  }

  /// Pause a running job.
  Future<void> pauseJob(String jobId) async {
    _activeJobs[jobId]?.pause();
    await _repo.updateJobStatus(jobId, 'paused');
    debugPrint('PrefetchService: Job $jobId paused');
  }

  /// Resume a paused job.
  Future<void> resumeJob(String jobId) async {
    await _repo.updateJobStatus(jobId, 'running');
    await _repo.resetInProgressTiles(jobId);
    _startProcessing(jobId);
    debugPrint('PrefetchService: Job $jobId resumed');
  }

  /// Cancel a job.
  Future<void> cancelJob(String jobId) async {
    _activeJobs[jobId]?.cancel();
    _activeJobs.remove(jobId);
    await _repo.updateJobStatus(jobId, 'cancelled');
    debugPrint('PrefetchService: Job $jobId cancelled');
  }

  /// Get a stream of progress updates for a job.
  Stream<PrefetchProgress> getJobProgress(String jobId) {
    return _repo.watchJobProgress(jobId).asyncMap((job) async {
      if (job == null) {
        return PrefetchProgress(
          jobId: jobId,
          status: 'unknown',
          totalTiles: 0,
          tilesDone: 0,
        );
      }

      final counts = await _repo.getTileStatusCounts(jobId);

      return PrefetchProgress(
        jobId: jobId,
        status: job.status,
        totalTiles: job.totalTiles,
        tilesDone: job.tilesDone,
        tilesFailed: counts['failed'] ?? 0,
        tilesQueued: counts['queued'] ?? 0,
      );
    });
  }

  /// Resume any pending jobs (for background fetch handler).
  Future<void> resumePendingJobs() async {
    final jobs = await _repo.getResumableJobs();
    for (final job in jobs) {
      await _repo.resetInProgressTiles(job.jobId);
      await _repo.updateJobStatus(job.jobId, 'running');
      _startProcessing(job.jobId);
    }
    debugPrint('PrefetchService: Resumed ${jobs.length} pending jobs');
  }

  // ─── Internal processing ────────────────────────────────────────────────

  void _startProcessing(String jobId) {
    if (_activeJobs.containsKey(jobId)) return;

    final runner = _JobRunner(
      jobId: jobId,
      repo: _repo,
      mapService: _mapService,
      concurrency: concurrency,
      random: _random,
      onComplete: () {
        _activeJobs.remove(jobId);
      },
    );

    _activeJobs[jobId] = runner;
    runner.start();
  }

  String _generateJobId() {
    final now = DateTime.now();
    final r = _random.nextInt(0xFFFF).toRadixString(16).padLeft(4, '0');
    return '${now.millisecondsSinceEpoch.toRadixString(16)}-$r';
  }
}

/// Manages the async download loop for a single job.
class _JobRunner {
  final String jobId;
  final TilesRepository repo;
  final MapService mapService;
  final int concurrency;
  final Random random;
  final VoidCallback onComplete;

  bool _paused = false;
  bool _cancelled = false;

  _JobRunner({
    required this.jobId,
    required this.repo,
    required this.mapService,
    required this.concurrency,
    required this.random,
    required this.onComplete,
  });

  void pause() => _paused = true;
  void cancel() => _cancelled = true;

  Future<void> start() async {
    final tileUrl = mapService.tileUrl;
    final tilesDir = await _getTilesDir();

    while (!_paused && !_cancelled) {
      // Fetch a batch of tiles to process
      final batch = await repo.nextBatchOfTiles(jobId, limit: concurrency * 2);

      if (batch.isEmpty) {
        // Check if there are failed tiles to requeue
        final requeued = await repo.requeueFailedTiles(jobId,
            maxAttempts: kMaxTileAttempts);
        if (requeued == 0) {
          // All done
          await repo.updateJobStatus(jobId, 'completed');
          debugPrint('PrefetchService: Job $jobId completed');
          onComplete();
          return;
        }
        continue;
      }

      // Process batch with concurrency limit (simple semaphore)
      final futures = <Future>[];
      int active = 0;

      for (final tile in batch) {
        if (_paused || _cancelled) break;

        // Wait if at concurrency limit
        while (active >= concurrency) {
          await Future.delayed(const Duration(milliseconds: 50));
          if (_paused || _cancelled) break;
        }
        if (_paused || _cancelled) break;

        active++;
        futures.add(_processTile(tile, tileUrl, tilesDir).whenComplete(() {
          active--;
        }));
      }

      // Wait for current batch to finish
      await Future.wait(futures);
    }

    if (_cancelled) {
      onComplete();
    }
  }

  Future<void> _processTile(
      PrefetchTile tile, String tileUrlTemplate, String tilesDir) async {
    final tilePath = p.join(tilesDir, '${tile.z}', '${tile.x}', '${tile.y}.png');

    // Check if tile already exists on disk
    if (File(tilePath).existsSync()) {
      await repo.markTileSkipped(tile.id, tilePath);
      await repo.incrementJobProgress(jobId);
      return;
    }

    // Mark in_progress
    await repo.markTileInProgress(tile.id);

    // Build URL
    final url = tileUrlTemplate
        .replaceFirst('{z}', tile.z.toString())
        .replaceFirst('{x}', tile.x.toString())
        .replaceFirst('{y}', tile.y.toString());

    try {
      // Download tile
      final response = await http.get(
        Uri.parse(url),
        headers: {'User-Agent': 'OpenRescue/1.0 (Tile Prefetch)'},
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
        // Atomic write: write to temp then rename
        final tileFile = File(tilePath);
        await tileFile.parent.create(recursive: true);
        final tempFile = File('$tilePath.tmp');
        await tempFile.writeAsBytes(response.bodyBytes, flush: true);
        await tempFile.rename(tilePath);

        await repo.markTileDownloaded(tile.id, tilePath);
        await repo.incrementJobProgress(jobId);
      } else {
        throw HttpException(
            'HTTP ${response.statusCode} for ${tile.z}/${tile.x}/${tile.y}');
      }
    } catch (e) {
      final errorMsg = e.toString();
      debugPrint(
          'PrefetchService: Tile ${tile.z}/${tile.x}/${tile.y} failed: $errorMsg');

      if (tile.attempts + 1 >= kMaxTileAttempts) {
        await repo.markTileFailed(tile.id, errorMsg);
      } else {
        // Requeue with backoff
        final delay = _retryDelay(tile.attempts + 1);
        await Future.delayed(Duration(milliseconds: delay));
        await repo.markTileFailed(tile.id, errorMsg);
      }
    }
  }

  /// Exponential backoff with jitter.
  int _retryDelay(int attempt) {
    final base = kBaseRetryDelayMs * (1 << (attempt - 1));
    final jitter = (base * 0.4 * random.nextDouble() - base * 0.2).round();
    return base + jitter;
  }

  Future<String> _getTilesDir() async {
    final appDir = await getApplicationDocumentsDirectory();
    return p.join(appDir.path, 'tiles');
  }
}

/// Exception thrown when a job exceeds the tile limit.
class PrefetchLimitExceeded implements Exception {
  final int estimated;
  final int limit;

  PrefetchLimitExceeded({required this.estimated, required this.limit});

  @override
  String toString() =>
      'PrefetchLimitExceeded: Job requires $estimated tiles '
      '(limit: $limit). Set allowLargeJob=true to override.';
}
