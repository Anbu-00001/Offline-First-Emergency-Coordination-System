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
      reporterId: 'user1',
      type: 'medical',
      lat: 10.0,
      lon: 20.0,
      priority: 'high',
      statusEnum: 'open',
      clientId: 'client1',
      sequenceNum: 1,
      deletedFlag: false,
      updatedAt: now,
    );

    final domainInc = incidentFromDb(row);

    expect(domainInc.id, '123');
    expect(domainInc.reporterId, 'user1');
    expect(domainInc.type, 'medical');
    expect(domainInc.lat, 10.0);
    expect(domainInc.lon, 20.0);
    expect(domainInc.assignedResponderId, isNull);
    expect(domainInc.priority, 'high');
    expect(domainInc.status, 'open');
    expect(domainInc.clientId, 'client1');
    expect(domainInc.sequenceNum, 1);
    expect(domainInc.deleted, false);
    expect(domainInc.updatedAt, now);
  });

  test('incidentToDbCompanion maps correctly', () {
    final now = DateTime.now();
    final domainInc = domain.Incident(
      id: '456',
      reporterId: 'user2',
      type: 'fire',
      lat: 30.0,
      lon: 40.0,
      priority: 'critical',
      status: 'resolved',
      clientId: 'client2',
      sequenceNum: 2,
      deleted: true,
      updatedAt: now,
    );

    final companion = incidentToDbCompanion(domainInc);

    expect(companion.id.value, '456');
    expect(companion.reporterId.value, 'user2');
    expect(companion.type.value, 'fire');
    expect(companion.lat.value, 30.0);
    expect(companion.lon.value, 40.0);
    expect(companion.assignedResponderId.value, isNull);
    expect(companion.priority.value, 'critical');
    expect(companion.statusEnum.value, 'resolved');
    expect(companion.clientId.value, 'client2');
    expect(companion.sequenceNum.value, 2);
    expect(companion.deletedFlag.value, true);
    expect(companion.updatedAt.value, now);
  });
}
