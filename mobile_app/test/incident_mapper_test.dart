// GENERATED: test/incident_mapper_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/data/mappers/incident_mapper.dart';
import 'package:mobile_app/models/models.dart' as domain;
import 'package:mobile_app/data/database.dart' as db;

void main() {
  test('incidentFromDb maps correctly', () {
    final now = DateTime.now();
    final row = db.Incident(
      id: '123',
      reporter_id: 'user1',
      type: 'medical',
      lat: 10.0,
      lon: 20.0,
      priority: 'high',
      status_enum: 'open',
      client_id: 'client1',
      sequence_num: 1,
      deleted_flag: false,
      updated_at: now,
    );

    final domainInc = incidentFromDb(row);

    expect(domainInc.id, '123');
    expect(domainInc.reporter_id, 'user1');
    expect(domainInc.type, 'medical');
    expect(domainInc.lat, 10.0);
    expect(domainInc.lon, 20.0);
    expect(domainInc.assigned_responder_id, isNull);
    expect(domainInc.priority, 'high');
    expect(domainInc.status, 'open');
    expect(domainInc.client_id, 'client1');
    expect(domainInc.sequence_num, 1);
    expect(domainInc.deleted, false);
    expect(domainInc.updated_at, now);
  });

  test('incidentToDbCompanion maps correctly', () {
    final now = DateTime.now();
    final domainInc = domain.Incident(
      id: '456',
      reporter_id: 'user2',
      type: 'fire',
      lat: 30.0,
      lon: 40.0,
      priority: 'critical',
      status: 'resolved',
      client_id: 'client2',
      sequence_num: 2,
      deleted: true,
      updated_at: now,
    );

    final companion = incidentToDbCompanion(domainInc);

    expect(companion.id.value, '456');
    expect(companion.reporter_id.value, 'user2');
    expect(companion.type.value, 'fire');
    expect(companion.lat.value, 30.0);
    expect(companion.lon.value, 40.0);
    expect(companion.assigned_responder_id.value, isNull);
    expect(companion.priority.value, 'critical');
    expect(companion.status_enum.value, 'resolved');
    expect(companion.client_id.value, 'client2');
    expect(companion.sequence_num.value, 2);
    expect(companion.deleted_flag.value, true);
    expect(companion.updated_at.value, now);
  });
}
