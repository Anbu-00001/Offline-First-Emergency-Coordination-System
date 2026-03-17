// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $IncidentsTable extends Incidents
    with TableInfo<$IncidentsTable, Incident> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $IncidentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _reporterIdMeta = const VerificationMeta(
    'reporterId',
  );
  @override
  late final GeneratedColumn<String> reporterId = GeneratedColumn<String>(
    'reporter_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _latMeta = const VerificationMeta('lat');
  @override
  late final GeneratedColumn<double> lat = GeneratedColumn<double>(
    'lat',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lonMeta = const VerificationMeta('lon');
  @override
  late final GeneratedColumn<double> lon = GeneratedColumn<double>(
    'lon',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _assignedResponderIdMeta =
      const VerificationMeta('assignedResponderId');
  @override
  late final GeneratedColumn<String> assignedResponderId =
      GeneratedColumn<String>(
        'assigned_responder_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _priorityMeta = const VerificationMeta(
    'priority',
  );
  @override
  late final GeneratedColumn<String> priority = GeneratedColumn<String>(
    'priority',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusEnumMeta = const VerificationMeta(
    'statusEnum',
  );
  @override
  late final GeneratedColumn<String> statusEnum = GeneratedColumn<String>(
    'status_enum',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _clientIdMeta = const VerificationMeta(
    'clientId',
  );
  @override
  late final GeneratedColumn<String> clientId = GeneratedColumn<String>(
    'client_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sequenceNumMeta = const VerificationMeta(
    'sequenceNum',
  );
  @override
  late final GeneratedColumn<int> sequenceNum = GeneratedColumn<int>(
    'sequence_num',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedFlagMeta = const VerificationMeta(
    'deletedFlag',
  );
  @override
  late final GeneratedColumn<bool> deletedFlag = GeneratedColumn<bool>(
    'deleted_flag',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("deleted_flag" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    reporterId,
    type,
    lat,
    lon,
    assignedResponderId,
    priority,
    statusEnum,
    clientId,
    sequenceNum,
    deletedFlag,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'incidents';
  @override
  VerificationContext validateIntegrity(
    Insertable<Incident> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('reporter_id')) {
      context.handle(
        _reporterIdMeta,
        reporterId.isAcceptableOrUnknown(data['reporter_id']!, _reporterIdMeta),
      );
    } else if (isInserting) {
      context.missing(_reporterIdMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('lat')) {
      context.handle(
        _latMeta,
        lat.isAcceptableOrUnknown(data['lat']!, _latMeta),
      );
    } else if (isInserting) {
      context.missing(_latMeta);
    }
    if (data.containsKey('lon')) {
      context.handle(
        _lonMeta,
        lon.isAcceptableOrUnknown(data['lon']!, _lonMeta),
      );
    } else if (isInserting) {
      context.missing(_lonMeta);
    }
    if (data.containsKey('assigned_responder_id')) {
      context.handle(
        _assignedResponderIdMeta,
        assignedResponderId.isAcceptableOrUnknown(
          data['assigned_responder_id']!,
          _assignedResponderIdMeta,
        ),
      );
    }
    if (data.containsKey('priority')) {
      context.handle(
        _priorityMeta,
        priority.isAcceptableOrUnknown(data['priority']!, _priorityMeta),
      );
    } else if (isInserting) {
      context.missing(_priorityMeta);
    }
    if (data.containsKey('status_enum')) {
      context.handle(
        _statusEnumMeta,
        statusEnum.isAcceptableOrUnknown(data['status_enum']!, _statusEnumMeta),
      );
    } else if (isInserting) {
      context.missing(_statusEnumMeta);
    }
    if (data.containsKey('client_id')) {
      context.handle(
        _clientIdMeta,
        clientId.isAcceptableOrUnknown(data['client_id']!, _clientIdMeta),
      );
    } else if (isInserting) {
      context.missing(_clientIdMeta);
    }
    if (data.containsKey('sequence_num')) {
      context.handle(
        _sequenceNumMeta,
        sequenceNum.isAcceptableOrUnknown(
          data['sequence_num']!,
          _sequenceNumMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_sequenceNumMeta);
    }
    if (data.containsKey('deleted_flag')) {
      context.handle(
        _deletedFlagMeta,
        deletedFlag.isAcceptableOrUnknown(
          data['deleted_flag']!,
          _deletedFlagMeta,
        ),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Incident map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Incident(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      reporterId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reporter_id'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      lat: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}lat'],
      )!,
      lon: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}lon'],
      )!,
      assignedResponderId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}assigned_responder_id'],
      ),
      priority: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}priority'],
      )!,
      statusEnum: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status_enum'],
      )!,
      clientId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}client_id'],
      )!,
      sequenceNum: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sequence_num'],
      )!,
      deletedFlag: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}deleted_flag'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $IncidentsTable createAlias(String alias) {
    return $IncidentsTable(attachedDatabase, alias);
  }
}

class Incident extends DataClass implements Insertable<Incident> {
  final String id;
  final String reporterId;
  final String type;
  final double lat;
  final double lon;
  final String? assignedResponderId;
  final String priority;
  final String statusEnum;
  final String clientId;
  final int sequenceNum;
  final bool deletedFlag;
  final DateTime updatedAt;
  const Incident({
    required this.id,
    required this.reporterId,
    required this.type,
    required this.lat,
    required this.lon,
    this.assignedResponderId,
    required this.priority,
    required this.statusEnum,
    required this.clientId,
    required this.sequenceNum,
    required this.deletedFlag,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['reporter_id'] = Variable<String>(reporterId);
    map['type'] = Variable<String>(type);
    map['lat'] = Variable<double>(lat);
    map['lon'] = Variable<double>(lon);
    if (!nullToAbsent || assignedResponderId != null) {
      map['assigned_responder_id'] = Variable<String>(assignedResponderId);
    }
    map['priority'] = Variable<String>(priority);
    map['status_enum'] = Variable<String>(statusEnum);
    map['client_id'] = Variable<String>(clientId);
    map['sequence_num'] = Variable<int>(sequenceNum);
    map['deleted_flag'] = Variable<bool>(deletedFlag);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  IncidentsCompanion toCompanion(bool nullToAbsent) {
    return IncidentsCompanion(
      id: Value(id),
      reporterId: Value(reporterId),
      type: Value(type),
      lat: Value(lat),
      lon: Value(lon),
      assignedResponderId: assignedResponderId == null && nullToAbsent
          ? const Value.absent()
          : Value(assignedResponderId),
      priority: Value(priority),
      statusEnum: Value(statusEnum),
      clientId: Value(clientId),
      sequenceNum: Value(sequenceNum),
      deletedFlag: Value(deletedFlag),
      updatedAt: Value(updatedAt),
    );
  }

  factory Incident.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Incident(
      id: serializer.fromJson<String>(json['id']),
      reporterId: serializer.fromJson<String>(json['reporterId']),
      type: serializer.fromJson<String>(json['type']),
      lat: serializer.fromJson<double>(json['lat']),
      lon: serializer.fromJson<double>(json['lon']),
      assignedResponderId: serializer.fromJson<String?>(
        json['assignedResponderId'],
      ),
      priority: serializer.fromJson<String>(json['priority']),
      statusEnum: serializer.fromJson<String>(json['statusEnum']),
      clientId: serializer.fromJson<String>(json['clientId']),
      sequenceNum: serializer.fromJson<int>(json['sequenceNum']),
      deletedFlag: serializer.fromJson<bool>(json['deletedFlag']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'reporterId': serializer.toJson<String>(reporterId),
      'type': serializer.toJson<String>(type),
      'lat': serializer.toJson<double>(lat),
      'lon': serializer.toJson<double>(lon),
      'assignedResponderId': serializer.toJson<String?>(assignedResponderId),
      'priority': serializer.toJson<String>(priority),
      'statusEnum': serializer.toJson<String>(statusEnum),
      'clientId': serializer.toJson<String>(clientId),
      'sequenceNum': serializer.toJson<int>(sequenceNum),
      'deletedFlag': serializer.toJson<bool>(deletedFlag),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Incident copyWith({
    String? id,
    String? reporterId,
    String? type,
    double? lat,
    double? lon,
    Value<String?> assignedResponderId = const Value.absent(),
    String? priority,
    String? statusEnum,
    String? clientId,
    int? sequenceNum,
    bool? deletedFlag,
    DateTime? updatedAt,
  }) => Incident(
    id: id ?? this.id,
    reporterId: reporterId ?? this.reporterId,
    type: type ?? this.type,
    lat: lat ?? this.lat,
    lon: lon ?? this.lon,
    assignedResponderId: assignedResponderId.present
        ? assignedResponderId.value
        : this.assignedResponderId,
    priority: priority ?? this.priority,
    statusEnum: statusEnum ?? this.statusEnum,
    clientId: clientId ?? this.clientId,
    sequenceNum: sequenceNum ?? this.sequenceNum,
    deletedFlag: deletedFlag ?? this.deletedFlag,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Incident copyWithCompanion(IncidentsCompanion data) {
    return Incident(
      id: data.id.present ? data.id.value : this.id,
      reporterId: data.reporterId.present
          ? data.reporterId.value
          : this.reporterId,
      type: data.type.present ? data.type.value : this.type,
      lat: data.lat.present ? data.lat.value : this.lat,
      lon: data.lon.present ? data.lon.value : this.lon,
      assignedResponderId: data.assignedResponderId.present
          ? data.assignedResponderId.value
          : this.assignedResponderId,
      priority: data.priority.present ? data.priority.value : this.priority,
      statusEnum: data.statusEnum.present
          ? data.statusEnum.value
          : this.statusEnum,
      clientId: data.clientId.present ? data.clientId.value : this.clientId,
      sequenceNum: data.sequenceNum.present
          ? data.sequenceNum.value
          : this.sequenceNum,
      deletedFlag: data.deletedFlag.present
          ? data.deletedFlag.value
          : this.deletedFlag,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Incident(')
          ..write('id: $id, ')
          ..write('reporterId: $reporterId, ')
          ..write('type: $type, ')
          ..write('lat: $lat, ')
          ..write('lon: $lon, ')
          ..write('assignedResponderId: $assignedResponderId, ')
          ..write('priority: $priority, ')
          ..write('statusEnum: $statusEnum, ')
          ..write('clientId: $clientId, ')
          ..write('sequenceNum: $sequenceNum, ')
          ..write('deletedFlag: $deletedFlag, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    reporterId,
    type,
    lat,
    lon,
    assignedResponderId,
    priority,
    statusEnum,
    clientId,
    sequenceNum,
    deletedFlag,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Incident &&
          other.id == this.id &&
          other.reporterId == this.reporterId &&
          other.type == this.type &&
          other.lat == this.lat &&
          other.lon == this.lon &&
          other.assignedResponderId == this.assignedResponderId &&
          other.priority == this.priority &&
          other.statusEnum == this.statusEnum &&
          other.clientId == this.clientId &&
          other.sequenceNum == this.sequenceNum &&
          other.deletedFlag == this.deletedFlag &&
          other.updatedAt == this.updatedAt);
}

class IncidentsCompanion extends UpdateCompanion<Incident> {
  final Value<String> id;
  final Value<String> reporterId;
  final Value<String> type;
  final Value<double> lat;
  final Value<double> lon;
  final Value<String?> assignedResponderId;
  final Value<String> priority;
  final Value<String> statusEnum;
  final Value<String> clientId;
  final Value<int> sequenceNum;
  final Value<bool> deletedFlag;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const IncidentsCompanion({
    this.id = const Value.absent(),
    this.reporterId = const Value.absent(),
    this.type = const Value.absent(),
    this.lat = const Value.absent(),
    this.lon = const Value.absent(),
    this.assignedResponderId = const Value.absent(),
    this.priority = const Value.absent(),
    this.statusEnum = const Value.absent(),
    this.clientId = const Value.absent(),
    this.sequenceNum = const Value.absent(),
    this.deletedFlag = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  IncidentsCompanion.insert({
    required String id,
    required String reporterId,
    required String type,
    required double lat,
    required double lon,
    this.assignedResponderId = const Value.absent(),
    required String priority,
    required String statusEnum,
    required String clientId,
    required int sequenceNum,
    this.deletedFlag = const Value.absent(),
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       reporterId = Value(reporterId),
       type = Value(type),
       lat = Value(lat),
       lon = Value(lon),
       priority = Value(priority),
       statusEnum = Value(statusEnum),
       clientId = Value(clientId),
       sequenceNum = Value(sequenceNum),
       updatedAt = Value(updatedAt);
  static Insertable<Incident> custom({
    Expression<String>? id,
    Expression<String>? reporterId,
    Expression<String>? type,
    Expression<double>? lat,
    Expression<double>? lon,
    Expression<String>? assignedResponderId,
    Expression<String>? priority,
    Expression<String>? statusEnum,
    Expression<String>? clientId,
    Expression<int>? sequenceNum,
    Expression<bool>? deletedFlag,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (reporterId != null) 'reporter_id': reporterId,
      if (type != null) 'type': type,
      if (lat != null) 'lat': lat,
      if (lon != null) 'lon': lon,
      if (assignedResponderId != null)
        'assigned_responder_id': assignedResponderId,
      if (priority != null) 'priority': priority,
      if (statusEnum != null) 'status_enum': statusEnum,
      if (clientId != null) 'client_id': clientId,
      if (sequenceNum != null) 'sequence_num': sequenceNum,
      if (deletedFlag != null) 'deleted_flag': deletedFlag,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  IncidentsCompanion copyWith({
    Value<String>? id,
    Value<String>? reporterId,
    Value<String>? type,
    Value<double>? lat,
    Value<double>? lon,
    Value<String?>? assignedResponderId,
    Value<String>? priority,
    Value<String>? statusEnum,
    Value<String>? clientId,
    Value<int>? sequenceNum,
    Value<bool>? deletedFlag,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return IncidentsCompanion(
      id: id ?? this.id,
      reporterId: reporterId ?? this.reporterId,
      type: type ?? this.type,
      lat: lat ?? this.lat,
      lon: lon ?? this.lon,
      assignedResponderId: assignedResponderId ?? this.assignedResponderId,
      priority: priority ?? this.priority,
      statusEnum: statusEnum ?? this.statusEnum,
      clientId: clientId ?? this.clientId,
      sequenceNum: sequenceNum ?? this.sequenceNum,
      deletedFlag: deletedFlag ?? this.deletedFlag,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (reporterId.present) {
      map['reporter_id'] = Variable<String>(reporterId.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (lat.present) {
      map['lat'] = Variable<double>(lat.value);
    }
    if (lon.present) {
      map['lon'] = Variable<double>(lon.value);
    }
    if (assignedResponderId.present) {
      map['assigned_responder_id'] = Variable<String>(
        assignedResponderId.value,
      );
    }
    if (priority.present) {
      map['priority'] = Variable<String>(priority.value);
    }
    if (statusEnum.present) {
      map['status_enum'] = Variable<String>(statusEnum.value);
    }
    if (clientId.present) {
      map['client_id'] = Variable<String>(clientId.value);
    }
    if (sequenceNum.present) {
      map['sequence_num'] = Variable<int>(sequenceNum.value);
    }
    if (deletedFlag.present) {
      map['deleted_flag'] = Variable<bool>(deletedFlag.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('IncidentsCompanion(')
          ..write('id: $id, ')
          ..write('reporterId: $reporterId, ')
          ..write('type: $type, ')
          ..write('lat: $lat, ')
          ..write('lon: $lon, ')
          ..write('assignedResponderId: $assignedResponderId, ')
          ..write('priority: $priority, ')
          ..write('statusEnum: $statusEnum, ')
          ..write('clientId: $clientId, ')
          ..write('sequenceNum: $sequenceNum, ')
          ..write('deletedFlag: $deletedFlag, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncQueueTable extends SyncQueue
    with TableInfo<$SyncQueueTable, SyncQueueData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncQueueTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _entityTypeMeta = const VerificationMeta(
    'entityType',
  );
  @override
  late final GeneratedColumn<String> entityType = GeneratedColumn<String>(
    'entity_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entityIdMeta = const VerificationMeta(
    'entityId',
  );
  @override
  late final GeneratedColumn<String> entityId = GeneratedColumn<String>(
    'entity_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _operationMeta = const VerificationMeta(
    'operation',
  );
  @override
  late final GeneratedColumn<String> operation = GeneratedColumn<String>(
    'operation',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dataMeta = const VerificationMeta('data');
  @override
  late final GeneratedColumn<String> data = GeneratedColumn<String>(
    'data',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sequenceNumMeta = const VerificationMeta(
    'sequenceNum',
  );
  @override
  late final GeneratedColumn<int> sequenceNum = GeneratedColumn<int>(
    'sequence_num',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _timestampMeta = const VerificationMeta(
    'timestamp',
  );
  @override
  late final GeneratedColumn<DateTime> timestamp = GeneratedColumn<DateTime>(
    'timestamp',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('queued'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    entityType,
    entityId,
    operation,
    data,
    sequenceNum,
    timestamp,
    status,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_queue';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncQueueData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('entity_type')) {
      context.handle(
        _entityTypeMeta,
        entityType.isAcceptableOrUnknown(data['entity_type']!, _entityTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_entityTypeMeta);
    }
    if (data.containsKey('entity_id')) {
      context.handle(
        _entityIdMeta,
        entityId.isAcceptableOrUnknown(data['entity_id']!, _entityIdMeta),
      );
    } else if (isInserting) {
      context.missing(_entityIdMeta);
    }
    if (data.containsKey('operation')) {
      context.handle(
        _operationMeta,
        operation.isAcceptableOrUnknown(data['operation']!, _operationMeta),
      );
    } else if (isInserting) {
      context.missing(_operationMeta);
    }
    if (data.containsKey('data')) {
      context.handle(
        _dataMeta,
        this.data.isAcceptableOrUnknown(data['data']!, _dataMeta),
      );
    } else if (isInserting) {
      context.missing(_dataMeta);
    }
    if (data.containsKey('sequence_num')) {
      context.handle(
        _sequenceNumMeta,
        sequenceNum.isAcceptableOrUnknown(
          data['sequence_num']!,
          _sequenceNumMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_sequenceNumMeta);
    }
    if (data.containsKey('timestamp')) {
      context.handle(
        _timestampMeta,
        timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta),
      );
    } else if (isInserting) {
      context.missing(_timestampMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SyncQueueData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncQueueData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      entityType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_type'],
      )!,
      entityId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_id'],
      )!,
      operation: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}operation'],
      )!,
      data: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}data'],
      )!,
      sequenceNum: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sequence_num'],
      )!,
      timestamp: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}timestamp'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
    );
  }

  @override
  $SyncQueueTable createAlias(String alias) {
    return $SyncQueueTable(attachedDatabase, alias);
  }
}

class SyncQueueData extends DataClass implements Insertable<SyncQueueData> {
  final int id;
  final String entityType;
  final String entityId;
  final String operation;
  final String data;
  final int sequenceNum;
  final DateTime timestamp;
  final String status;
  const SyncQueueData({
    required this.id,
    required this.entityType,
    required this.entityId,
    required this.operation,
    required this.data,
    required this.sequenceNum,
    required this.timestamp,
    required this.status,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['entity_type'] = Variable<String>(entityType);
    map['entity_id'] = Variable<String>(entityId);
    map['operation'] = Variable<String>(operation);
    map['data'] = Variable<String>(data);
    map['sequence_num'] = Variable<int>(sequenceNum);
    map['timestamp'] = Variable<DateTime>(timestamp);
    map['status'] = Variable<String>(status);
    return map;
  }

  SyncQueueCompanion toCompanion(bool nullToAbsent) {
    return SyncQueueCompanion(
      id: Value(id),
      entityType: Value(entityType),
      entityId: Value(entityId),
      operation: Value(operation),
      data: Value(data),
      sequenceNum: Value(sequenceNum),
      timestamp: Value(timestamp),
      status: Value(status),
    );
  }

  factory SyncQueueData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncQueueData(
      id: serializer.fromJson<int>(json['id']),
      entityType: serializer.fromJson<String>(json['entityType']),
      entityId: serializer.fromJson<String>(json['entityId']),
      operation: serializer.fromJson<String>(json['operation']),
      data: serializer.fromJson<String>(json['data']),
      sequenceNum: serializer.fromJson<int>(json['sequenceNum']),
      timestamp: serializer.fromJson<DateTime>(json['timestamp']),
      status: serializer.fromJson<String>(json['status']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'entityType': serializer.toJson<String>(entityType),
      'entityId': serializer.toJson<String>(entityId),
      'operation': serializer.toJson<String>(operation),
      'data': serializer.toJson<String>(data),
      'sequenceNum': serializer.toJson<int>(sequenceNum),
      'timestamp': serializer.toJson<DateTime>(timestamp),
      'status': serializer.toJson<String>(status),
    };
  }

  SyncQueueData copyWith({
    int? id,
    String? entityType,
    String? entityId,
    String? operation,
    String? data,
    int? sequenceNum,
    DateTime? timestamp,
    String? status,
  }) => SyncQueueData(
    id: id ?? this.id,
    entityType: entityType ?? this.entityType,
    entityId: entityId ?? this.entityId,
    operation: operation ?? this.operation,
    data: data ?? this.data,
    sequenceNum: sequenceNum ?? this.sequenceNum,
    timestamp: timestamp ?? this.timestamp,
    status: status ?? this.status,
  );
  SyncQueueData copyWithCompanion(SyncQueueCompanion data) {
    return SyncQueueData(
      id: data.id.present ? data.id.value : this.id,
      entityType: data.entityType.present
          ? data.entityType.value
          : this.entityType,
      entityId: data.entityId.present ? data.entityId.value : this.entityId,
      operation: data.operation.present ? data.operation.value : this.operation,
      data: data.data.present ? data.data.value : this.data,
      sequenceNum: data.sequenceNum.present
          ? data.sequenceNum.value
          : this.sequenceNum,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
      status: data.status.present ? data.status.value : this.status,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncQueueData(')
          ..write('id: $id, ')
          ..write('entityType: $entityType, ')
          ..write('entityId: $entityId, ')
          ..write('operation: $operation, ')
          ..write('data: $data, ')
          ..write('sequenceNum: $sequenceNum, ')
          ..write('timestamp: $timestamp, ')
          ..write('status: $status')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    entityType,
    entityId,
    operation,
    data,
    sequenceNum,
    timestamp,
    status,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncQueueData &&
          other.id == this.id &&
          other.entityType == this.entityType &&
          other.entityId == this.entityId &&
          other.operation == this.operation &&
          other.data == this.data &&
          other.sequenceNum == this.sequenceNum &&
          other.timestamp == this.timestamp &&
          other.status == this.status);
}

class SyncQueueCompanion extends UpdateCompanion<SyncQueueData> {
  final Value<int> id;
  final Value<String> entityType;
  final Value<String> entityId;
  final Value<String> operation;
  final Value<String> data;
  final Value<int> sequenceNum;
  final Value<DateTime> timestamp;
  final Value<String> status;
  const SyncQueueCompanion({
    this.id = const Value.absent(),
    this.entityType = const Value.absent(),
    this.entityId = const Value.absent(),
    this.operation = const Value.absent(),
    this.data = const Value.absent(),
    this.sequenceNum = const Value.absent(),
    this.timestamp = const Value.absent(),
    this.status = const Value.absent(),
  });
  SyncQueueCompanion.insert({
    this.id = const Value.absent(),
    required String entityType,
    required String entityId,
    required String operation,
    required String data,
    required int sequenceNum,
    required DateTime timestamp,
    this.status = const Value.absent(),
  }) : entityType = Value(entityType),
       entityId = Value(entityId),
       operation = Value(operation),
       data = Value(data),
       sequenceNum = Value(sequenceNum),
       timestamp = Value(timestamp);
  static Insertable<SyncQueueData> custom({
    Expression<int>? id,
    Expression<String>? entityType,
    Expression<String>? entityId,
    Expression<String>? operation,
    Expression<String>? data,
    Expression<int>? sequenceNum,
    Expression<DateTime>? timestamp,
    Expression<String>? status,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (entityType != null) 'entity_type': entityType,
      if (entityId != null) 'entity_id': entityId,
      if (operation != null) 'operation': operation,
      if (data != null) 'data': data,
      if (sequenceNum != null) 'sequence_num': sequenceNum,
      if (timestamp != null) 'timestamp': timestamp,
      if (status != null) 'status': status,
    });
  }

  SyncQueueCompanion copyWith({
    Value<int>? id,
    Value<String>? entityType,
    Value<String>? entityId,
    Value<String>? operation,
    Value<String>? data,
    Value<int>? sequenceNum,
    Value<DateTime>? timestamp,
    Value<String>? status,
  }) {
    return SyncQueueCompanion(
      id: id ?? this.id,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      operation: operation ?? this.operation,
      data: data ?? this.data,
      sequenceNum: sequenceNum ?? this.sequenceNum,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (entityType.present) {
      map['entity_type'] = Variable<String>(entityType.value);
    }
    if (entityId.present) {
      map['entity_id'] = Variable<String>(entityId.value);
    }
    if (operation.present) {
      map['operation'] = Variable<String>(operation.value);
    }
    if (data.present) {
      map['data'] = Variable<String>(data.value);
    }
    if (sequenceNum.present) {
      map['sequence_num'] = Variable<int>(sequenceNum.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<DateTime>(timestamp.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncQueueCompanion(')
          ..write('id: $id, ')
          ..write('entityType: $entityType, ')
          ..write('entityId: $entityId, ')
          ..write('operation: $operation, ')
          ..write('data: $data, ')
          ..write('sequenceNum: $sequenceNum, ')
          ..write('timestamp: $timestamp, ')
          ..write('status: $status')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $IncidentsTable incidents = $IncidentsTable(this);
  late final $SyncQueueTable syncQueue = $SyncQueueTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [incidents, syncQueue];
}

typedef $$IncidentsTableCreateCompanionBuilder =
    IncidentsCompanion Function({
      required String id,
      required String reporterId,
      required String type,
      required double lat,
      required double lon,
      Value<String?> assignedResponderId,
      required String priority,
      required String statusEnum,
      required String clientId,
      required int sequenceNum,
      Value<bool> deletedFlag,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$IncidentsTableUpdateCompanionBuilder =
    IncidentsCompanion Function({
      Value<String> id,
      Value<String> reporterId,
      Value<String> type,
      Value<double> lat,
      Value<double> lon,
      Value<String?> assignedResponderId,
      Value<String> priority,
      Value<String> statusEnum,
      Value<String> clientId,
      Value<int> sequenceNum,
      Value<bool> deletedFlag,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$IncidentsTableFilterComposer
    extends Composer<_$AppDatabase, $IncidentsTable> {
  $$IncidentsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reporterId => $composableBuilder(
    column: $table.reporterId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get lat => $composableBuilder(
    column: $table.lat,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get lon => $composableBuilder(
    column: $table.lon,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get assignedResponderId => $composableBuilder(
    column: $table.assignedResponderId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get priority => $composableBuilder(
    column: $table.priority,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get statusEnum => $composableBuilder(
    column: $table.statusEnum,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get clientId => $composableBuilder(
    column: $table.clientId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sequenceNum => $composableBuilder(
    column: $table.sequenceNum,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get deletedFlag => $composableBuilder(
    column: $table.deletedFlag,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$IncidentsTableOrderingComposer
    extends Composer<_$AppDatabase, $IncidentsTable> {
  $$IncidentsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reporterId => $composableBuilder(
    column: $table.reporterId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get lat => $composableBuilder(
    column: $table.lat,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get lon => $composableBuilder(
    column: $table.lon,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get assignedResponderId => $composableBuilder(
    column: $table.assignedResponderId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get priority => $composableBuilder(
    column: $table.priority,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get statusEnum => $composableBuilder(
    column: $table.statusEnum,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get clientId => $composableBuilder(
    column: $table.clientId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sequenceNum => $composableBuilder(
    column: $table.sequenceNum,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get deletedFlag => $composableBuilder(
    column: $table.deletedFlag,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$IncidentsTableAnnotationComposer
    extends Composer<_$AppDatabase, $IncidentsTable> {
  $$IncidentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get reporterId => $composableBuilder(
    column: $table.reporterId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<double> get lat =>
      $composableBuilder(column: $table.lat, builder: (column) => column);

  GeneratedColumn<double> get lon =>
      $composableBuilder(column: $table.lon, builder: (column) => column);

  GeneratedColumn<String> get assignedResponderId => $composableBuilder(
    column: $table.assignedResponderId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get priority =>
      $composableBuilder(column: $table.priority, builder: (column) => column);

  GeneratedColumn<String> get statusEnum => $composableBuilder(
    column: $table.statusEnum,
    builder: (column) => column,
  );

  GeneratedColumn<String> get clientId =>
      $composableBuilder(column: $table.clientId, builder: (column) => column);

  GeneratedColumn<int> get sequenceNum => $composableBuilder(
    column: $table.sequenceNum,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get deletedFlag => $composableBuilder(
    column: $table.deletedFlag,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$IncidentsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $IncidentsTable,
          Incident,
          $$IncidentsTableFilterComposer,
          $$IncidentsTableOrderingComposer,
          $$IncidentsTableAnnotationComposer,
          $$IncidentsTableCreateCompanionBuilder,
          $$IncidentsTableUpdateCompanionBuilder,
          (Incident, BaseReferences<_$AppDatabase, $IncidentsTable, Incident>),
          Incident,
          PrefetchHooks Function()
        > {
  $$IncidentsTableTableManager(_$AppDatabase db, $IncidentsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$IncidentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$IncidentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$IncidentsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> reporterId = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<double> lat = const Value.absent(),
                Value<double> lon = const Value.absent(),
                Value<String?> assignedResponderId = const Value.absent(),
                Value<String> priority = const Value.absent(),
                Value<String> statusEnum = const Value.absent(),
                Value<String> clientId = const Value.absent(),
                Value<int> sequenceNum = const Value.absent(),
                Value<bool> deletedFlag = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => IncidentsCompanion(
                id: id,
                reporterId: reporterId,
                type: type,
                lat: lat,
                lon: lon,
                assignedResponderId: assignedResponderId,
                priority: priority,
                statusEnum: statusEnum,
                clientId: clientId,
                sequenceNum: sequenceNum,
                deletedFlag: deletedFlag,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String reporterId,
                required String type,
                required double lat,
                required double lon,
                Value<String?> assignedResponderId = const Value.absent(),
                required String priority,
                required String statusEnum,
                required String clientId,
                required int sequenceNum,
                Value<bool> deletedFlag = const Value.absent(),
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => IncidentsCompanion.insert(
                id: id,
                reporterId: reporterId,
                type: type,
                lat: lat,
                lon: lon,
                assignedResponderId: assignedResponderId,
                priority: priority,
                statusEnum: statusEnum,
                clientId: clientId,
                sequenceNum: sequenceNum,
                deletedFlag: deletedFlag,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$IncidentsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $IncidentsTable,
      Incident,
      $$IncidentsTableFilterComposer,
      $$IncidentsTableOrderingComposer,
      $$IncidentsTableAnnotationComposer,
      $$IncidentsTableCreateCompanionBuilder,
      $$IncidentsTableUpdateCompanionBuilder,
      (Incident, BaseReferences<_$AppDatabase, $IncidentsTable, Incident>),
      Incident,
      PrefetchHooks Function()
    >;
typedef $$SyncQueueTableCreateCompanionBuilder =
    SyncQueueCompanion Function({
      Value<int> id,
      required String entityType,
      required String entityId,
      required String operation,
      required String data,
      required int sequenceNum,
      required DateTime timestamp,
      Value<String> status,
    });
typedef $$SyncQueueTableUpdateCompanionBuilder =
    SyncQueueCompanion Function({
      Value<int> id,
      Value<String> entityType,
      Value<String> entityId,
      Value<String> operation,
      Value<String> data,
      Value<int> sequenceNum,
      Value<DateTime> timestamp,
      Value<String> status,
    });

class $$SyncQueueTableFilterComposer
    extends Composer<_$AppDatabase, $SyncQueueTable> {
  $$SyncQueueTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get operation => $composableBuilder(
    column: $table.operation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get data => $composableBuilder(
    column: $table.data,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sequenceNum => $composableBuilder(
    column: $table.sequenceNum,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncQueueTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncQueueTable> {
  $$SyncQueueTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get operation => $composableBuilder(
    column: $table.operation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get data => $composableBuilder(
    column: $table.data,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sequenceNum => $composableBuilder(
    column: $table.sequenceNum,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncQueueTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncQueueTable> {
  $$SyncQueueTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get entityId =>
      $composableBuilder(column: $table.entityId, builder: (column) => column);

  GeneratedColumn<String> get operation =>
      $composableBuilder(column: $table.operation, builder: (column) => column);

  GeneratedColumn<String> get data =>
      $composableBuilder(column: $table.data, builder: (column) => column);

  GeneratedColumn<int> get sequenceNum => $composableBuilder(
    column: $table.sequenceNum,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get timestamp =>
      $composableBuilder(column: $table.timestamp, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);
}

class $$SyncQueueTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SyncQueueTable,
          SyncQueueData,
          $$SyncQueueTableFilterComposer,
          $$SyncQueueTableOrderingComposer,
          $$SyncQueueTableAnnotationComposer,
          $$SyncQueueTableCreateCompanionBuilder,
          $$SyncQueueTableUpdateCompanionBuilder,
          (
            SyncQueueData,
            BaseReferences<_$AppDatabase, $SyncQueueTable, SyncQueueData>,
          ),
          SyncQueueData,
          PrefetchHooks Function()
        > {
  $$SyncQueueTableTableManager(_$AppDatabase db, $SyncQueueTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncQueueTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncQueueTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncQueueTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> entityType = const Value.absent(),
                Value<String> entityId = const Value.absent(),
                Value<String> operation = const Value.absent(),
                Value<String> data = const Value.absent(),
                Value<int> sequenceNum = const Value.absent(),
                Value<DateTime> timestamp = const Value.absent(),
                Value<String> status = const Value.absent(),
              }) => SyncQueueCompanion(
                id: id,
                entityType: entityType,
                entityId: entityId,
                operation: operation,
                data: data,
                sequenceNum: sequenceNum,
                timestamp: timestamp,
                status: status,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String entityType,
                required String entityId,
                required String operation,
                required String data,
                required int sequenceNum,
                required DateTime timestamp,
                Value<String> status = const Value.absent(),
              }) => SyncQueueCompanion.insert(
                id: id,
                entityType: entityType,
                entityId: entityId,
                operation: operation,
                data: data,
                sequenceNum: sequenceNum,
                timestamp: timestamp,
                status: status,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncQueueTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SyncQueueTable,
      SyncQueueData,
      $$SyncQueueTableFilterComposer,
      $$SyncQueueTableOrderingComposer,
      $$SyncQueueTableAnnotationComposer,
      $$SyncQueueTableCreateCompanionBuilder,
      $$SyncQueueTableUpdateCompanionBuilder,
      (
        SyncQueueData,
        BaseReferences<_$AppDatabase, $SyncQueueTable, SyncQueueData>,
      ),
      SyncQueueData,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$IncidentsTableTableManager get incidents =>
      $$IncidentsTableTableManager(_db, _db.incidents);
  $$SyncQueueTableTableManager get syncQueue =>
      $$SyncQueueTableTableManager(_db, _db.syncQueue);
}
