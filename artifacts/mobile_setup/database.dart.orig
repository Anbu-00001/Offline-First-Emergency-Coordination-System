import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'database.g.dart';

class Incidents extends Table {
  TextColumn get id => text()();
  TextColumn get reporter_id => text()();
  TextColumn get type => text()();
  RealColumn get lat => real()();
  RealColumn get lon => real()();
  TextColumn get assigned_responder_id => text().nullable()();
  TextColumn get priority => text()();
  TextColumn get status_enum => text()();
  TextColumn get client_id => text()();
  IntColumn get sequence_num => integer()();
  BoolColumn get deleted_flag => boolean().withDefault(const Constant(false))();
  DateTimeColumn get updated_at => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class SyncQueue extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get entity_type => text()();
  TextColumn get entity_id => text()();
  TextColumn get operation => text()();
  TextColumn get data => text()(); // JSON string representation
  IntColumn get sequence_num => integer()();
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
