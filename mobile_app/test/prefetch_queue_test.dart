import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/data/db/prefetch_database.dart';
import 'package:mobile_app/data/tiles_repository.dart';

void main() {
  late PrefetchDatabase db;
  late TilesRepository repo;

  setUp(() {
    db = PrefetchDatabase.memory();
    repo = TilesRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('Job lifecycle', () {
    test('createJob and getJob roundtrip', () async {
      await repo.createJob(
        jobId: 'test-job-1',
        lat: 22.35,
        lon: 78.67,
        radiusM: 5000,
        minZoom: 12,
        maxZoom: 16,
        totalTiles: 100,
      );

      final job = await repo.getJob('test-job-1');
      expect(job, isNotNull);
      expect(job!.jobId, 'test-job-1');
      expect(job.lat, 22.35);
      expect(job.lon, 78.67);
      expect(job.radiusM, 5000);
      expect(job.totalTiles, 100);
      expect(job.tilesDone, 0);
      expect(job.status, 'running');
    });

    test('updateJobStatus changes status', () async {
      await repo.createJob(
        jobId: 'test-job-2',
        lat: 22.35,
        lon: 78.67,
        radiusM: 5000,
        minZoom: 12,
        maxZoom: 16,
        totalTiles: 50,
      );

      await repo.updateJobStatus('test-job-2', 'paused');
      final job = await repo.getJob('test-job-2');
      expect(job!.status, 'paused');
    });

    test('completed job gets finishedAt timestamp', () async {
      await repo.createJob(
        jobId: 'test-job-3',
        lat: 22.35,
        lon: 78.67,
        radiusM: 5000,
        minZoom: 12,
        maxZoom: 16,
        totalTiles: 10,
      );

      await repo.updateJobStatus('test-job-3', 'completed');
      final job = await repo.getJob('test-job-3');
      expect(job!.status, 'completed');
      expect(job.finishedAt, isNotNull);
    });

    test('getResumableJobs returns running and paused', () async {
      await repo.createJob(
        jobId: 'run-1', lat: 22.35, lon: 78.67,
        radiusM: 5000, minZoom: 12, maxZoom: 16, totalTiles: 10,
      );
      await repo.createJob(
        jobId: 'paused-1', lat: 22.35, lon: 78.67,
        radiusM: 5000, minZoom: 12, maxZoom: 16, totalTiles: 10,
      );
      await repo.updateJobStatus('paused-1', 'paused');
      await repo.createJob(
        jobId: 'done-1', lat: 22.35, lon: 78.67,
        radiusM: 5000, minZoom: 12, maxZoom: 16, totalTiles: 10,
      );
      await repo.updateJobStatus('done-1', 'completed');

      final resumable = await repo.getResumableJobs();
      expect(resumable.length, 2);
      expect(resumable.map((j) => j.jobId).toSet(),
          containsAll(['run-1', 'paused-1']));
    });
  });

  group('Tile enqueue & dequeue', () {
    test('enqueueTiles inserts tiles with queued status', () async {
      await repo.createJob(
        jobId: 'tile-job-1', lat: 22.35, lon: 78.67,
        radiusM: 5000, minZoom: 14, maxZoom: 14, totalTiles: 3,
      );

      await repo.enqueueTiles('tile-job-1', [
        (z: 14, x: 100, y: 200),
        (z: 14, x: 101, y: 200),
        (z: 14, x: 100, y: 201),
      ]);

      final batch = await repo.nextBatchOfTiles('tile-job-1', limit: 10);
      expect(batch.length, 3);
      expect(batch.every((t) => t.status == 'queued'), isTrue);
    });

    test('nextBatchOfTiles respects limit', () async {
      await repo.createJob(
        jobId: 'tile-job-2', lat: 22.35, lon: 78.67,
        radiusM: 5000, minZoom: 14, maxZoom: 14, totalTiles: 5,
      );

      await repo.enqueueTiles('tile-job-2', [
        (z: 14, x: 100, y: 200),
        (z: 14, x: 101, y: 200),
        (z: 14, x: 102, y: 200),
        (z: 14, x: 103, y: 200),
        (z: 14, x: 104, y: 200),
      ]);

      final batch = await repo.nextBatchOfTiles('tile-job-2', limit: 2);
      expect(batch.length, 2);
    });

    test('markTileDownloaded updates status and filePath', () async {
      await repo.createJob(
        jobId: 'tile-job-3', lat: 22.35, lon: 78.67,
        radiusM: 5000, minZoom: 14, maxZoom: 14, totalTiles: 1,
      );

      await repo.enqueueTiles('tile-job-3', [(z: 14, x: 100, y: 200)]);
      final tiles = await repo.nextBatchOfTiles('tile-job-3');
      await repo.markTileDownloaded(tiles.first.id, '/path/to/14/100/200.png');

      // Should not appear in next queued batch
      final remaining = await repo.nextBatchOfTiles('tile-job-3');
      expect(remaining, isEmpty);
    });

    test('markTileFailed updates status and lastError', () async {
      await repo.createJob(
        jobId: 'tile-job-4', lat: 22.35, lon: 78.67,
        radiusM: 5000, minZoom: 14, maxZoom: 14, totalTiles: 1,
      );

      await repo.enqueueTiles('tile-job-4', [(z: 14, x: 100, y: 200)]);
      final tiles = await repo.nextBatchOfTiles('tile-job-4');
      await repo.markTileFailed(tiles.first.id, 'HTTP 500');

      // Should not appear in queued batch
      final remaining = await repo.nextBatchOfTiles('tile-job-4');
      expect(remaining, isEmpty);
    });

    test('requeueFailedTiles requeues tiles under max attempts', () async {
      await repo.createJob(
        jobId: 'tile-job-5', lat: 22.35, lon: 78.67,
        radiusM: 5000, minZoom: 14, maxZoom: 14, totalTiles: 1,
      );

      await repo.enqueueTiles('tile-job-5', [(z: 14, x: 100, y: 200)]);
      final tiles = await repo.nextBatchOfTiles('tile-job-5');
      await repo.markTileInProgress(tiles.first.id);
      await repo.markTileFailed(tiles.first.id, 'timeout');

      final requeued = await repo.requeueFailedTiles('tile-job-5',
          maxAttempts: 5);
      expect(requeued, 1);

      final batch = await repo.nextBatchOfTiles('tile-job-5');
      expect(batch.length, 1);
    });
  });

  group('Progress tracking', () {
    test('incrementJobProgress increases tilesDone', () async {
      await repo.createJob(
        jobId: 'prog-1', lat: 22.35, lon: 78.67,
        radiusM: 5000, minZoom: 14, maxZoom: 14, totalTiles: 10,
      );

      await repo.incrementJobProgress('prog-1');
      await repo.incrementJobProgress('prog-1');

      final job = await repo.getJob('prog-1');
      expect(job!.tilesDone, 2);
    });

    test('getTileStatusCounts returns correct breakdown', () async {
      await repo.createJob(
        jobId: 'stat-1', lat: 22.35, lon: 78.67,
        radiusM: 5000, minZoom: 14, maxZoom: 14, totalTiles: 3,
      );

      await repo.enqueueTiles('stat-1', [
        (z: 14, x: 100, y: 200),
        (z: 14, x: 101, y: 200),
        (z: 14, x: 102, y: 200),
      ]);

      final tiles = await repo.nextBatchOfTiles('stat-1');
      await repo.markTileDownloaded(tiles[0].id, '/path/a.png');
      await repo.markTileFailed(tiles[1].id, 'error');

      final counts = await repo.getTileStatusCounts('stat-1');
      expect(counts['downloaded'], 1);
      expect(counts['failed'], 1);
      expect(counts['queued'], 1);
    });
  });

  group('Cleanup', () {
    test('clearAll removes all data', () async {
      await repo.createJob(
        jobId: 'clean-1', lat: 22.35, lon: 78.67,
        radiusM: 5000, minZoom: 14, maxZoom: 14, totalTiles: 2,
      );
      await repo.enqueueTiles('clean-1', [
        (z: 14, x: 100, y: 200),
        (z: 14, x: 101, y: 200),
      ]);

      await repo.clearAll();

      final job = await repo.getJob('clean-1');
      expect(job, isNull);

      final tiles = await repo.nextBatchOfTiles('clean-1');
      expect(tiles, isEmpty);
    });
  });
}
