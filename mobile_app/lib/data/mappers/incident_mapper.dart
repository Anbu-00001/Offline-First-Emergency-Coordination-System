import '../../models/models.dart' as domain;
import '../database.dart' as db;
import 'package:drift/drift.dart' as drift;

/// Convert DB incident row to domain model
domain.Incident incidentFromDb(db.Incident row) {
  return domain.Incident(
    id: row.id,
    reporter_id: row.reporter_id,
    type: row.type,
    lat: row.lat,
    lon: row.lon,
    assigned_responder_id: row.assigned_responder_id,
    priority: row.priority,
    status: row.status_enum,
    client_id: row.client_id,
    sequence_num: row.sequence_num,
    deleted: row.deleted_flag,
    updated_at: row.updated_at,
  );
}

/// Convert domain model to DB companion
db.IncidentsCompanion incidentToDbCompanion(domain.Incident i) {
  return db.IncidentsCompanion(
    id: drift.Value(i.id),
    reporter_id: drift.Value(i.reporter_id),
    type: drift.Value(i.type),
    lat: drift.Value(i.lat),
    lon: drift.Value(i.lon),
    assigned_responder_id: drift.Value(i.assigned_responder_id),
    priority: drift.Value(i.priority),
    status_enum: drift.Value(i.status),
    client_id: drift.Value(i.client_id),
    sequence_num: drift.Value(i.sequence_num),
    deleted_flag: drift.Value(i.deleted),
    updated_at: drift.Value(i.updated_at),
  );
}
