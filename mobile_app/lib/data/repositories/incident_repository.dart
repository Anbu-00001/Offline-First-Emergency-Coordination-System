import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import '../../models/models.dart' as domain;
import '../database.dart' as db;
import '../../core/api_client.dart';
import '../mappers/incident_mapper.dart';
import '../../services/p2p_service.dart';
import '../../services/polygon_cache_service.dart';

class IncidentRepository {
  final db.AppDatabase _db;
  final ApiClient _apiClient;
  final P2PService _p2pService;
  final PolygonCacheService _polygonCache;

  IncidentRepository(this._db, this._apiClient, this._p2pService, this._polygonCache) {
    // Day-16: Listen for incoming incident_create messages
    _p2pService.incomingIncidents.listen((dto) {
      _handleIncomingP2PIncident(dto);
    });

    // Day-17: Listen for sync_request messages — respond with local incidents
    _p2pService.syncRequests.listen((envelope) {
      _handleSyncRequest(envelope);
    });

    // Day-17: Listen for sync_response messages — merge received incidents
    _p2pService.syncResponses.listen((envelope) {
      _handleSyncResponse(envelope);
    });
  }

  Stream<List<domain.Incident>> watchIncidents() {
    return (_db.select(_db.incidents)..where((t) => t.deletedFlag.equals(false)))
        .watch()
        .map((rows) => rows.map((r) => incidentFromDb(r)).toList());
  }

  Future<domain.Incident> getIncident(String id) async {
    final row = await (_db.select(_db.incidents)..where((t) => t.id.equals(id))).getSingle();
    return incidentFromDb(row);
  }

  /// Fetches all non-deleted incidents from the local database.
  Future<List<domain.Incident>> getAllIncidents() async {
    final rows = await (_db.select(_db.incidents)
          ..where((t) => t.deletedFlag.equals(false)))
        .get();
    return rows.map((r) => incidentFromDb(r)).toList();
  }

  Future<void> createIncident(domain.IncidentCreateDto dto) async {
    final localDocId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    
    // Broadcast immediately to peers
    final incidentToBroadcast = domain.Incident(
      id: localDocId,
      reporterId: 'local_user', // This might be pulled from auth/context
      type: dto.type,
      lat: dto.lat,
      lon: dto.lon,
      priority: dto.priority,
      status: dto.status,
      clientId: dto.clientId,
      sequenceNum: dto.sequenceNum,
      updatedAt: DateTime.now(),
    );
    _p2pService.broadcastIncident(incidentToBroadcast);

    // Day 27: Generate and cache polygon for newly created incident
    _polygonCache.updateFromIncident(incidentToBroadcast);

    await _db.transaction(() async {
      await _db.into(_db.incidents).insert(
        db.IncidentsCompanion.insert(
          id: localDocId,
          reporterId: 'local_user', // This might be pulled from auth/context
          type: dto.type,
          lat: dto.lat,
          lon: dto.lon,
          priority: dto.priority,
          statusEnum: dto.status,
          clientId: dto.clientId,
          sequenceNum: dto.sequenceNum,
          updatedAt: DateTime.now(),
        ),
      );

      await _db.into(_db.syncQueue).insert(
        db.SyncQueueCompanion.insert(
          entityType: 'Incident',
          entityId: localDocId,
          operation: 'CREATE',
          data: jsonEncode(dto.toJson()),
          sequenceNum: dto.sequenceNum,
          timestamp: DateTime.now(),
        ),
      );
    });
  }

  Future<void> pushLocalChanges() async {
    final pendingChanges = await (_db.select(_db.syncQueue)..where((t) => t.status.equals('queued'))).get();
    if (pendingChanges.isEmpty) return;

    final changes = pendingChanges.map((q) => domain.LocalChange(
      entityType: q.entityType,
      entityId: q.entityId,
      operation: q.operation,
      data: jsonDecode(q.data),
      sequenceNum: q.sequenceNum,
      timestamp: q.timestamp,
    )).toList();

    try {
      final syncResult = await _apiClient.syncIncidents(changes);
      
      await _db.transaction(() async {
        // Mark as sent
        for (var q in pendingChanges) {
          await (_db.update(_db.syncQueue)..where((t) => t.id.equals(q.id)))
              .write(const db.SyncQueueCompanion(status: Value('sent')));
        }
        
        // Update local DB with server definitive source of truth
        for (var i in syncResult.accepted) {
          await _upsertIncidentFromServer(i);
        }
        for (var i in syncResult.conflicts) {
          await _upsertIncidentFromServer(i); // Last-writer-wins dictates using server's version here
        }
      });
    } catch (e) {
      // Failed to push (e.g. offline), keeps 'queued'
      debugPrint('Sync failed, will retry later: $e');
    }
  }

  Future<void> _upsertIncidentFromServer(domain.Incident serverIncident) async {
    await _db.into(_db.incidents).insertOnConflictUpdate(
      incidentToDbCompanion(serverIncident),
    );
  }

  int _getIncidentStatePriority(String state) {
    switch (state.toUpperCase()) {
      case 'RESOLVED':
        return 3;
      case 'ASSIGNED':
        return 2;
      case 'PENDING':
        return 1;
      default:
        return 0; // e.g. 'new' or unknown
    }
  }

  /// Handles an incoming P2P incident from the network.
  ///
  /// Uses the incident_id from the envelope payload as the DB primary key
  /// to enable DB-level deduplication. If an incident with the same ID already
  /// exists, the CRDT merge logic is applied.
  Future<void> _handleIncomingP2PIncident(domain.IncidentCreateDto dto) async {
    // Extract incident_id from envelope metadata (passed through dto.data)
    final String incidentId = dto.data?['incident_id'] as String? ??
        'p2p_${DateTime.now().millisecondsSinceEpoch}';

    // DB-level dedup: check if this incident already exists
    final existing = await (_db.select(_db.incidents)
          ..where((t) => t.id.equals(incidentId)))
        .get();

    if (existing.isNotEmpty) {
      final current = incidentFromDb(existing.first);
      final currentPriority = _getIncidentStatePriority(current.status);
      final incomingPriority = _getIncidentStatePriority(dto.status);

      debugPrint('[IncidentRepo] PEER_UPDATE: received incident $incidentId with state ${dto.status} clock ${dto.sequenceNum}');
      debugPrint('[IncidentRepo] CURRENT_STATE: ${current.status}');
      debugPrint('[IncidentRepo] CURRENT_CLOCK: ${current.sequenceNum}');

      bool shouldUpdate = false;
      String mergeDecision = '';
      
      if (incomingPriority > currentPriority) {
        shouldUpdate = true;
        mergeDecision = 'Incoming priority (${dto.status}) > Current priority (${current.status})';
      } else if (incomingPriority == currentPriority) {
        if (dto.sequenceNum > current.sequenceNum) {
          shouldUpdate = true;
          mergeDecision = 'Same priority, Incoming clock (${dto.sequenceNum}) > Current clock (${current.sequenceNum})';
        } else {
          mergeDecision = 'Same priority, Incoming clock (${dto.sequenceNum}) <= Current clock (${current.sequenceNum})';
        }
      } else {
        mergeDecision = 'Incoming priority (${dto.status}) < Current priority (${current.status})';
      }

      debugPrint('[IncidentRepo] MERGE_DECISION: $mergeDecision -> ${shouldUpdate ? 'incoming wins' : 'local wins'}');

      if (shouldUpdate) {
        debugPrint(
            '[IncidentRepo] CRDT_MERGE_APPLIED: Updating $incidentId state to ${dto.status}');
        debugPrint(
            '[IncidentRepo] STATE_UPDATED: $incidentId from ${current.status} to ${dto.status}');
        debugPrint('[IncidentRepo] CONFLICT_RESOLVED: incoming wins');

        await (_db.update(_db.incidents)..where((t) => t.id.equals(incidentId)))
            .write(
          db.IncidentsCompanion(
            statusEnum: Value(dto.status),
            sequenceNum: Value(dto.sequenceNum),
            updatedAt: Value(DateTime.now()),
            lat: Value(dto.lat),
            lon: Value(dto.lon),
            priority: Value(dto.priority),
            type: Value(dto.type),
            clientId: Value(dto.clientId),
          ),
        );

        // Day 27: Refresh polygon cache after CRDT merge update
        debugPrint('[IncidentRepo] CRDT_MERGE_COMPLETED: $incidentId');
        final updatedIncident = await getIncident(incidentId);
        _polygonCache.updateFromIncident(updatedIncident);
      } else {
        debugPrint(
            '[IncidentRepo] CRDT_MERGE_APPLIED: Local state kept for $incidentId');
        debugPrint('[IncidentRepo] CONFLICT_RESOLVED: local wins');
      }
      debugPrint('[IncidentRepo] P2P_INCIDENT_RECEIVED: $incidentId');
      return;
    }

    // Insert the new incident
    await _db.into(_db.incidents).insert(
      db.IncidentsCompanion.insert(
        id: incidentId,
        reporterId: dto.clientId,
        type: dto.type,
        lat: dto.lat,
        lon: dto.lon,
        priority: dto.priority,
        statusEnum: dto.status,
        clientId: dto.clientId,
        sequenceNum: dto.sequenceNum,
        updatedAt: DateTime.now(),
      ),
    );

    debugPrint(
        '[IncidentRepo] P2P incident inserted: $incidentId');
    debugPrint('[IncidentRepo] P2P_INCIDENT_RECEIVED: $incidentId');

    // Day 27: Generate and cache polygon after P2P insert
    final insertedIncident = await getIncident(incidentId);
    _polygonCache.updateFromIncident(insertedIncident);
  }

  // ─── Day-17: State Synchronization Handlers ────────────────────────────

  /// Handles a sync_request: fetches all local incidents and sends them back
  /// as batched sync_response messages via P2PService.
  Future<void> _handleSyncRequest(dynamic envelope) async {
    debugPrint('[IncidentRepo] Processing sync_request — fetching local incidents');

    try {
      final incidents = await getAllIncidents();
      debugPrint(
          '[IncidentRepo] Found ${incidents.length} local incidents to sync');

      // Send the incidents back as a sync_response via P2PService
      await _p2pService.sendSyncResponse(incidents);

      debugPrint(
          '[IncidentRepo] SYNC_RESPONSE_SENT: ${incidents.length} incidents sent');
    } catch (e) {
      debugPrint('[IncidentRepo] Failed to handle sync_request: $e');
    }
  }

  /// Handles a sync_response: extracts incidents from the payload and inserts
  /// them using the existing deduplication logic.
  Future<void> _handleSyncResponse(dynamic envelope) async {
    try {
      final payload = (envelope as dynamic).payload as Map<String, dynamic>;
      final incidentsList = payload['incidents'] as List<dynamic>? ?? [];

      debugPrint(
          '[IncidentRepo] SYNC_RESPONSE_RECEIVED: ${incidentsList.length} incidents in batch');

      int mergedCount = 0;
      for (final incidentData in incidentsList) {
        final Map<String, dynamic> incMap =
            incidentData is Map<String, dynamic>
                ? incidentData
                : Map<String, dynamic>.from(incidentData as Map);

        final incidentId =
            incMap['incident_id'] as String? ??
            'sync_${DateTime.now().millisecondsSinceEpoch}_$mergedCount';

        // Use IncidentCreateDto and pass through existing dedup logic
        final dto = domain.IncidentCreateDto(
          type: incMap['type'] as String? ?? 'unknown',
          lat: (incMap['lat'] as num?)?.toDouble() ?? 0.0,
          lon: (incMap['lon'] as num?)?.toDouble() ?? 0.0,
          priority: incMap['priority'] as String? ?? 'medium',
          status: incMap['status'] as String? ?? incMap['state'] as String? ?? 'new',
          clientId: incMap['reporter_id'] as String? ?? 'synced_peer',
          sequenceNum: incMap['clock'] as int? ?? 1,
          data: {'incident_id': incidentId},
        );

        await _handleIncomingP2PIncident(dto);
        mergedCount++;
      }

      debugPrint(
          '[IncidentRepo] INCIDENT_MERGED: processed $mergedCount incidents from sync_response');
    } catch (e) {
      debugPrint('[IncidentRepo] Failed to handle sync_response: $e');
    }
  }
}
