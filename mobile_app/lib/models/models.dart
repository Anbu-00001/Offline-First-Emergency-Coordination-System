import 'package:json_annotation/json_annotation.dart';

part 'models.g.dart';

@JsonSerializable(explicitToJson: true)
class Health {
  final String status;
  final String service;

  Health({required this.status, required this.service});

  factory Health.fromJson(Map<String, dynamic> json) => _$HealthFromJson(json);
  Map<String, dynamic> toJson() => _$HealthToJson(this);
}

@JsonSerializable(explicitToJson: true)
class AuthResponse {
  @JsonKey(name: 'access_token')
  final String accessToken;
  @JsonKey(name: 'token_type')
  final String tokenType;

  AuthResponse({required this.accessToken, required this.tokenType});

  factory AuthResponse.fromJson(Map<String, dynamic> json) => _$AuthResponseFromJson(json);
  Map<String, dynamic> toJson() => _$AuthResponseToJson(this);
}

@JsonSerializable(explicitToJson: true)
class Incident {
  final String id;
  @JsonKey(name: 'reporter_id')
  final String reporterId;
  final String type;
  final double lat;
  final double lon;
  @JsonKey(name: 'assigned_responder_id')
  final String? assignedResponderId;
  final String priority;
  final String status;
  @JsonKey(name: 'client_id')
  final String clientId;
  @JsonKey(name: 'sequence_num')
  final int sequenceNum;
  final bool deleted;
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;
  
  // Optional additional fields present in API that we might need to store
  final Map<String, dynamic>? data;

  Incident({
    required this.id,
    required this.reporterId,
    required this.type,
    required this.lat,
    required this.lon,
    this.assignedResponderId,
    required this.priority,
    required this.status,
    required this.clientId,
    required this.sequenceNum,
    this.deleted = false,
    required this.updatedAt,
    this.data,
  });

  factory Incident.fromJson(Map<String, dynamic> json) => _$IncidentFromJson(json);
  Map<String, dynamic> toJson() => _$IncidentToJson(this);
}

@JsonSerializable(explicitToJson: true)
class IncidentCreateDto {
  final String type;
  final double lat;
  final double lon;
  final String priority;
  final String status;
  @JsonKey(name: 'client_id')
  final String clientId;
  @JsonKey(name: 'sequence_num')
  final int sequenceNum;
  final Map<String, dynamic>? data;

  IncidentCreateDto({
    required this.type,
    required this.lat,
    required this.lon,
    required this.priority,
    required this.status,
    required this.clientId,
    required this.sequenceNum,
    this.data,
  });

  factory IncidentCreateDto.fromJson(Map<String, dynamic> json) => _$IncidentCreateDtoFromJson(json);
  Map<String, dynamic> toJson() => _$IncidentCreateDtoToJson(this);
}

@JsonSerializable(explicitToJson: true)
class LocalChange {
  @JsonKey(name: 'entity_type')
  final String entityType;
  @JsonKey(name: 'entity_id')
  final String entityId;
  final String operation; // 'CREATE', 'UPDATE', 'DELETE'
  final Map<String, dynamic> data;
  @JsonKey(name: 'sequence_num')
  final int sequenceNum;
  final DateTime timestamp;

  LocalChange({
    required this.entityType,
    required this.entityId,
    required this.operation,
    required this.data,
    required this.sequenceNum,
    required this.timestamp,
  });

  factory LocalChange.fromJson(Map<String, dynamic> json) => _$LocalChangeFromJson(json);
  Map<String, dynamic> toJson() => _$LocalChangeToJson(this);
}

@JsonSerializable(explicitToJson: true)
class SyncResult {
  final List<Incident> accepted;
  final List<Incident> conflicts;
  final List<Map<String, dynamic>> errors;
  @JsonKey(name: 'current_server_sequence')
  final int currentServerSequence;

  SyncResult({
    required this.accepted,
    required this.conflicts,
    required this.errors,
    required this.currentServerSequence,
  });

  factory SyncResult.fromJson(Map<String, dynamic> json) => _$SyncResultFromJson(json);
  Map<String, dynamic> toJson() => _$SyncResultToJson(this);
}
