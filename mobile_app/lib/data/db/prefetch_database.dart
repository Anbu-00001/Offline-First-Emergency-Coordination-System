import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'prefetch_database.g.dart';

// ─── Prefetch Jobs ──────────────────────────────────────────────────────────

/// Persistent record of a tile prefetch job.
class PrefetchJobs extends Table {
  TextColumn get jobId => text()();
  RealColumn get lat => real()();
  RealColumn get lon => real()();
  IntColumn get radiusM => integer()();
  IntColumn get minZoom => integer()();
  IntColumn get maxZoom => integer()();
  IntColumn get totalTiles => integer()();
  IntColumn get tilesDone => integer().withDefault(const Constant(0))();
  /// running | paused | completed | cancelled
  TextColumn get status => text().withDefault(const Constant('running'))();
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get finishedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {jobId};
}

// ─── Prefetch Tiles ─────────────────────────────────────────────────────────

/// Individual tile download record within a prefetch job.
class PrefetchTiles extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get z => integer()();
  IntColumn get x => integer()();
  IntColumn get y => integer()();
  /// queued | in_progress | downloaded | failed | skipped
  TextColumn get status => text().withDefault(const Constant('queued'))();
  IntColumn get attempts => integer().withDefault(const Constant(0))();
  TextColumn get lastError => text().nullable()();
  TextColumn get filePath => text().nullable()();
  TextColumn get jobId => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
}

// ─── Database ───────────────────────────────────────────────────────────────

@DriftDatabase(tables: [PrefetchJobs, PrefetchTiles])
class PrefetchDatabase extends _$PrefetchDatabase {
  /// Production constructor — uses a file-backed database.
  PrefetchDatabase() : super(_openConnection());

  /// In-memory constructor for testing.
  PrefetchDatabase.memory() : super(NativeDatabase.memory());

  @override
  int get schemaVersion => 1;
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'openrescue_prefetch.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
