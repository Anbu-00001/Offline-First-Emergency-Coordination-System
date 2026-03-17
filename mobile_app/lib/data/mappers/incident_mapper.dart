import '../../models/models.dart' as domain;
import '../database.dart' as db;
import 'package:drift/drift.dart' as drift;

/// Convert DB incident row to domain model
domain.Incident incidentFromDb(db.Incident row) {
  return domain.Incident(
    id: row.id,
    reporterId: row.reporterId,
    type: row.type,
    lat: row.lat,
    lon: row.lon,
    assignedResponderId: row.assignedResponderId,
    priority: row.priority,
    status: row.statusEnum,
    clientId: row.clientId,
    sequenceNum: row.sequenceNum,
    deleted: row.deletedFlag,
    updatedAt: row.updatedAt,
  );
}

/// Convert domain model to DB companion
db.IncidentsCompanion incidentToDbCompanion(domain.Incident i) {
  return db.IncidentsCompanion(
    id: drift.Value(i.id),
    reporterId: drift.Value(i.reporterId),
    type: drift.Value(i.type),
    lat: drift.Value(i.lat),
    lon: drift.Value(i.lon),
    assignedResponderId: drift.Value(i.assignedResponderId),
    priority: drift.Value(i.priority),
    statusEnum: drift.Value(i.status),
    clientId: drift.Value(i.clientId),
    sequenceNum: drift.Value(i.sequenceNum),
    deletedFlag: drift.Value(i.deleted),
    updatedAt: drift.Value(i.updatedAt),
  );
}
