import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'database.g.dart';

class Incidents extends Table {
  TextColumn get id => text()();
  TextColumn get reporterId => text().named('reporter_id')();
  TextColumn get type => text()();
  RealColumn get lat => real()();
  RealColumn get lon => real()();
  TextColumn get assignedResponderId => text().named('assigned_responder_id').nullable()();
  TextColumn get priority => text()();
  TextColumn get statusEnum => text().named('status_enum')();
  TextColumn get clientId => text().named('client_id')();
  IntColumn get sequenceNum => integer().named('sequence_num')();
  BoolColumn get deletedFlag => boolean().named('deleted_flag').withDefault(const Constant(false))();
  DateTimeColumn get updatedAt => dateTime().named('updated_at')();

  @override
  Set<Column> get primaryKey => {id};
}

class SyncQueue extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get entityType => text().named('entity_type')();
  TextColumn get entityId => text().named('entity_id')();
  TextColumn get operation => text()();
  TextColumn get data => text()(); // JSON string representation
  IntColumn get sequenceNum => integer().named('sequence_num')();
  DateTimeColumn get timestamp => dateTime()();
  TextColumn get status => text().withDefault(const Constant('queued'))(); // queued, sent, failed
}

@DriftDatabase(tables: [Incidents, SyncQueue])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());
  AppDatabase.memory() : super(NativeDatabase.memory());

  @override
  int get schemaVersion => 1;
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'openrescue.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
