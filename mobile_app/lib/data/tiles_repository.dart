import 'dart:async';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'db/prefetch_database.dart';

/// Repository wrapping the PrefetchDatabase for tile/job CRUD operations.
class TilesRepository {
  final PrefetchDatabase _db;

  TilesRepository(this._db);

  // ─── Job operations ─────────────────────────────────────────────────────

  /// Create a new prefetch job record.
  Future<void> createJob({
    required String jobId,
    required double lat,
    required double lon,
    required int radiusM,
    required int minZoom,
    required int maxZoom,
    required int totalTiles,
  }) async {
    await _db.into(_db.prefetchJobs).insert(PrefetchJobsCompanion.insert(
          jobId: jobId,
          lat: lat,
          lon: lon,
          radiusM: radiusM,
          minZoom: minZoom,
          maxZoom: maxZoom,
          totalTiles: totalTiles,
          startedAt: DateTime.now(),
        ));
  }

  /// Get a job by ID.
  Future<PrefetchJob?> getJob(String jobId) async {
    return (_db.select(_db.prefetchJobs)
          ..where((j) => j.jobId.equals(jobId)))
        .getSingleOrNull();
  }

  /// Update job status.
  Future<void> updateJobStatus(String jobId, String status) async {
    await (_db.update(_db.prefetchJobs)
          ..where((j) => j.jobId.equals(jobId)))
        .write(PrefetchJobsCompanion(
      status: Value(status),
      finishedAt: (status == 'completed' || status == 'cancelled')
          ? Value(DateTime.now())
          : const Value.absent(),
    ));
  }

  /// Increment tilesDone counter for a job.
  Future<void> incrementJobProgress(String jobId) async {
    await _db.customStatement(
      'UPDATE prefetch_jobs SET tiles_done = tiles_done + 1 WHERE job_id = ?',
      [jobId],
    );
  }

  /// Watch job progress as a stream.
  Stream<PrefetchJob?> watchJobProgress(String jobId) {
    return (_db.select(_db.prefetchJobs)
          ..where((j) => j.jobId.equals(jobId)))
        .watchSingleOrNull();
  }

  /// Get all jobs with a given status.
  Future<List<PrefetchJob>> getJobsByStatus(String status) async {
    return (_db.select(_db.prefetchJobs)
          ..where((j) => j.status.equals(status)))
        .get();
  }

  /// Get all jobs that can be resumed (running or paused).
  Future<List<PrefetchJob>> getResumableJobs() async {
    return (_db.select(_db.prefetchJobs)
          ..where(
              (j) => j.status.isIn(const ['running', 'paused'])))
        .get();
  }

  // ─── Tile operations ────────────────────────────────────────────────────

  /// Enqueue a batch of tiles for a job.
  Future<void> enqueueTiles(
      String jobId, List<({int z, int x, int y})> tiles) async {
    final now = DateTime.now();
    await _db.batch((batch) {
      batch.insertAll(
        _db.prefetchTiles,
        tiles
            .map((t) => PrefetchTilesCompanion.insert(
                  z: t.z,
                  x: t.x,
                  y: t.y,
                  jobId: jobId,
                  createdAt: now,
                  updatedAt: now,
                ))
            .toList(),
      );
    });
  }

  /// Get next batch of tiles to download for a job.
  /// Returns tiles with status 'queued', limited to [limit].
  Future<List<PrefetchTile>> nextBatchOfTiles(String jobId,
      {int limit = 20}) async {
    return (_db.select(_db.prefetchTiles)
          ..where(
              (t) => t.jobId.equals(jobId) & t.status.equals('queued'))
          ..limit(limit))
        .get();
  }

  /// Mark a tile as in_progress and increment attempts.
  Future<void> markTileInProgress(int tileId) async {
    await (_db.update(_db.prefetchTiles)
          ..where((t) => t.id.equals(tileId)))
        .write(PrefetchTilesCompanion(
      status: const Value('in_progress'),
      updatedAt: Value(DateTime.now()),
    ));
    await _db.customStatement(
      'UPDATE prefetch_tiles SET attempts = attempts + 1 WHERE id = ?',
      [tileId],
    );
  }

  /// Mark a tile as downloaded.
  Future<void> markTileDownloaded(int tileId, String filePath) async {
    await (_db.update(_db.prefetchTiles)
          ..where((t) => t.id.equals(tileId)))
        .write(PrefetchTilesCompanion(
      status: const Value('downloaded'),
      filePath: Value(filePath),
      updatedAt: Value(DateTime.now()),
    ));
  }

  /// Mark a tile as failed.
  Future<void> markTileFailed(int tileId, String error) async {
    await (_db.update(_db.prefetchTiles)
          ..where((t) => t.id.equals(tileId)))
        .write(PrefetchTilesCompanion(
      status: const Value('failed'),
      lastError: Value(error),
      updatedAt: Value(DateTime.now()),
    ));
  }

  /// Mark a tile as skipped (already exists on disk).
  Future<void> markTileSkipped(int tileId, String filePath) async {
    await (_db.update(_db.prefetchTiles)
          ..where((t) => t.id.equals(tileId)))
        .write(PrefetchTilesCompanion(
      status: const Value('skipped'),
      filePath: Value(filePath),
      updatedAt: Value(DateTime.now()),
    ));
  }

  /// Requeue failed tiles with fewer than [maxAttempts] attempts.
  Future<int> requeueFailedTiles(String jobId,
      {int maxAttempts = 5}) async {
    final failed = await (_db.select(_db.prefetchTiles)
          ..where((t) =>
              t.jobId.equals(jobId) &
              t.status.equals('failed') &
              t.attempts.isSmallerThanValue(maxAttempts)))
        .get();

    for (final tile in failed) {
      await (_db.update(_db.prefetchTiles)
            ..where((t) => t.id.equals(tile.id)))
          .write(PrefetchTilesCompanion(
        status: const Value('queued'),
        updatedAt: Value(DateTime.now()),
      ));
    }
    return failed.length;
  }

  /// Reset in_progress tiles back to queued (for restart recovery).
  Future<void> resetInProgressTiles(String jobId) async {
    await (_db.update(_db.prefetchTiles)
          ..where((t) =>
              t.jobId.equals(jobId) & t.status.equals('in_progress')))
        .write(PrefetchTilesCompanion(
      status: const Value('queued'),
      updatedAt: Value(DateTime.now()),
    ));
  }

  /// Get tile counts by status for a job.
  Future<Map<String, int>> getTileStatusCounts(String jobId) async {
    final tiles = await (_db.select(_db.prefetchTiles)
          ..where((t) => t.jobId.equals(jobId)))
        .get();

    final counts = <String, int>{};
    for (final tile in tiles) {
      counts[tile.status] = (counts[tile.status] ?? 0) + 1;
    }
    return counts;
  }

  /// Check if a tile with given coordinates already has a file on disk.
  Future<String?> getTileFilePath(int z, int x, int y) async {
    final tile = await (_db.select(_db.prefetchTiles)
          ..where((t) =>
              t.z.equals(z) &
              t.x.equals(x) &
              t.y.equals(y) &
              t.status.isIn(const ['downloaded', 'skipped']))
          ..limit(1))
        .getSingleOrNull();
    return tile?.filePath;
  }

  /// Delete all tiles and jobs (cleanup).
  Future<void> clearAll() async {
    await _db.delete(_db.prefetchTiles).go();
    await _db.delete(_db.prefetchJobs).go();
  }
}
