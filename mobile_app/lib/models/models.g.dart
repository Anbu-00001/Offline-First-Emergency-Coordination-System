// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Health _$HealthFromJson(Map<String, dynamic> json) => Health(
  status: json['status'] as String,
  service: json['service'] as String,
);

Map<String, dynamic> _$HealthToJson(Health instance) => <String, dynamic>{
  'status': instance.status,
  'service': instance.service,
};

AuthResponse _$AuthResponseFromJson(Map<String, dynamic> json) => AuthResponse(
  accessToken: json['access_token'] as String,
  tokenType: json['token_type'] as String,
);

Map<String, dynamic> _$AuthResponseToJson(AuthResponse instance) =>
    <String, dynamic>{
      'access_token': instance.accessToken,
      'token_type': instance.tokenType,
    };

Incident _$IncidentFromJson(Map<String, dynamic> json) => Incident(
  id: json['id'] as String,
  reporterId: json['reporter_id'] as String,
  type: json['type'] as String,
  lat: (json['lat'] as num).toDouble(),
  lon: (json['lon'] as num).toDouble(),
  assignedResponderId: json['assigned_responder_id'] as String?,
  priority: json['priority'] as String,
  status: json['status'] as String,
  clientId: json['client_id'] as String,
  sequenceNum: (json['sequence_num'] as num).toInt(),
  deleted: json['deleted'] as bool? ?? false,
  updatedAt: DateTime.parse(json['updated_at'] as String),
  data: json['data'] as Map<String, dynamic>?,
);

Map<String, dynamic> _$IncidentToJson(Incident instance) => <String, dynamic>{
  'id': instance.id,
  'reporter_id': instance.reporterId,
  'type': instance.type,
  'lat': instance.lat,
  'lon': instance.lon,
  'assigned_responder_id': instance.assignedResponderId,
  'priority': instance.priority,
  'status': instance.status,
  'client_id': instance.clientId,
  'sequence_num': instance.sequenceNum,
  'deleted': instance.deleted,
  'updated_at': instance.updatedAt.toIso8601String(),
  'data': instance.data,
};

IncidentCreateDto _$IncidentCreateDtoFromJson(Map<String, dynamic> json) =>
    IncidentCreateDto(
      type: json['type'] as String,
      lat: (json['lat'] as num).toDouble(),
      lon: (json['lon'] as num).toDouble(),
      priority: json['priority'] as String,
      status: json['status'] as String,
      clientId: json['client_id'] as String,
      sequenceNum: (json['sequence_num'] as num).toInt(),
      data: json['data'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$IncidentCreateDtoToJson(IncidentCreateDto instance) =>
    <String, dynamic>{
      'type': instance.type,
      'lat': instance.lat,
      'lon': instance.lon,
      'priority': instance.priority,
      'status': instance.status,
      'client_id': instance.clientId,
      'sequence_num': instance.sequenceNum,
      'data': instance.data,
    };

LocalChange _$LocalChangeFromJson(Map<String, dynamic> json) => LocalChange(
  entityType: json['entity_type'] as String,
  entityId: json['entity_id'] as String,
  operation: json['operation'] as String,
  data: json['data'] as Map<String, dynamic>,
  sequenceNum: (json['sequence_num'] as num).toInt(),
  timestamp: DateTime.parse(json['timestamp'] as String),
);

Map<String, dynamic> _$LocalChangeToJson(LocalChange instance) =>
    <String, dynamic>{
      'entity_type': instance.entityType,
      'entity_id': instance.entityId,
      'operation': instance.operation,
      'data': instance.data,
      'sequence_num': instance.sequenceNum,
      'timestamp': instance.timestamp.toIso8601String(),
    };

SyncResult _$SyncResultFromJson(Map<String, dynamic> json) => SyncResult(
  accepted: (json['accepted'] as List<dynamic>)
      .map((e) => Incident.fromJson(e as Map<String, dynamic>))
      .toList(),
  conflicts: (json['conflicts'] as List<dynamic>)
      .map((e) => Incident.fromJson(e as Map<String, dynamic>))
      .toList(),
  errors: (json['errors'] as List<dynamic>)
      .map((e) => e as Map<String, dynamic>)
      .toList(),
  currentServerSequence: (json['current_server_sequence'] as num).toInt(),
);

Map<String, dynamic> _$SyncResultToJson(SyncResult instance) =>
    <String, dynamic>{
      'accepted': instance.accepted.map((e) => e.toJson()).toList(),
      'conflicts': instance.conflicts.map((e) => e.toJson()).toList(),
      'errors': instance.errors,
      'current_server_sequence': instance.currentServerSequence,
    };
