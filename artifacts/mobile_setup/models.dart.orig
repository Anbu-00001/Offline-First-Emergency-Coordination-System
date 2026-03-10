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
  final String access_token;
  final String token_type;

  AuthResponse({required this.access_token, required this.token_type});

  factory AuthResponse.fromJson(Map<String, dynamic> json) => _$AuthResponseFromJson(json);
  Map<String, dynamic> toJson() => _$AuthResponseToJson(this);
}

@JsonSerializable(explicitToJson: true)
class Incident {
  final String id;
  final String reporter_id;
  final String type;
  final double lat;
  final double lon;
  final String? assigned_responder_id;
  final String priority;
  final String status;
  final String client_id;
  final int sequence_num;
  final bool deleted;
  final DateTime updated_at;
  
  // Optional additional fields present in API that we might need to store
  final Map<String, dynamic>? data;

  Incident({
    required this.id,
    required this.reporter_id,
    required this.type,
    required this.lat,
    required this.lon,
    this.assigned_responder_id,
    required this.priority,
    required this.status,
    required this.client_id,
    required this.sequence_num,
    this.deleted = false,
    required this.updated_at,
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
  final String client_id;
  final int sequence_num;
  final Map<String, dynamic>? data;

  IncidentCreateDto({
    required this.type,
    required this.lat,
    required this.lon,
    required this.priority,
    required this.status,
    required this.client_id,
    required this.sequence_num,
    this.data,
  });

  factory IncidentCreateDto.fromJson(Map<String, dynamic> json) => _$IncidentCreateDtoFromJson(json);
  Map<String, dynamic> toJson() => _$IncidentCreateDtoToJson(this);
}

@JsonSerializable(explicitToJson: true)
class LocalChange {
  final String entity_type;
  final String entity_id;
  final String operation; // 'CREATE', 'UPDATE', 'DELETE'
  final Map<String, dynamic> data;
  final int sequence_num;
  final DateTime timestamp;

  LocalChange({
    required this.entity_type,
    required this.entity_id,
    required this.operation,
    required this.data,
    required this.sequence_num,
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
  final int current_server_sequence;

  SyncResult({
    required this.accepted,
    required this.conflicts,
    required this.errors,
    required this.current_server_sequence,
  });

  factory SyncResult.fromJson(Map<String, dynamic> json) => _$SyncResultFromJson(json);
  Map<String, dynamic> toJson() => _$SyncResultToJson(this);
}
