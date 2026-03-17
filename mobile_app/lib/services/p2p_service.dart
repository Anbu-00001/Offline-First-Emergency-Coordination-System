import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/models.dart';
import '../models/network_envelope.dart';
import 'message_cache.dart';

/// Maximum number of incidents per sync_response batch to avoid network flooding.
const int syncBatchSize = 50;

/// Service responsible for communicating with the local Go P2P Daemon.
///
/// Features:
/// - Envelope-based messaging (NetworkEnvelope)
/// - Deduplication via MessageCache
/// - Outgoing message queue for offline resilience
/// - Automatic reconnection with queued message flush
/// - State synchronization via sync_request / sync_response protocol (Day-17)
class P2PService {
  final String hostUrl;
  WebSocketChannel? _channel;
  bool _isConnected = false;
  final StreamController<NetworkEnvelope> _envelopeStreamController =
      StreamController<NetworkEnvelope>.broadcast();

  /// Legacy stream for backward compatibility with IncidentRepository
  final StreamController<IncidentCreateDto> _incidentStreamController =
      StreamController<IncidentCreateDto>.broadcast();

  /// Stream for sync_request envelopes so the repository can respond
  final StreamController<NetworkEnvelope> _syncRequestStreamController =
      StreamController<NetworkEnvelope>.broadcast();

  /// Stream for sync_response envelopes so the repository can merge incidents
  final StreamController<NetworkEnvelope> _syncResponseStreamController =
      StreamController<NetworkEnvelope>.broadcast();

  /// Message deduplication cache (LRU, 1000 entries)
  final MessageCache _messageCache = MessageCache(maxSize: 1000);

  /// Outgoing message queue for when the connection is unavailable
  final List<NetworkEnvelope> _outgoingQueue = [];

  /// Peer sync state map to prevent infinite sync loops (Day-17)
  /// peer_id → sync_completed (boolean)
  final Map<String, bool> _peerSyncState = {};

  P2PService({required this.hostUrl});

  /// The stream of incidents received from the P2P network
  Stream<IncidentCreateDto> get incomingIncidents =>
      _incidentStreamController.stream;

  /// The stream of raw envelopes received from the P2P network
  Stream<NetworkEnvelope> get incomingEnvelopes =>
      _envelopeStreamController.stream;

  /// The stream of sync_request envelopes
  Stream<NetworkEnvelope> get syncRequests =>
      _syncRequestStreamController.stream;

  /// The stream of sync_response envelopes
  Stream<NetworkEnvelope> get syncResponses =>
      _syncResponseStreamController.stream;

  /// Whether the WebSocket connection is currently active
  bool get isConnected => _isConnected;

  /// Number of messages waiting in the outgoing queue
  int get outgoingQueueLength => _outgoingQueue.length;

  /// Connects to the local daemon's WebSocket endpoint for receiving messages
  void connect() {
    final wsBase = hostUrl.replaceFirst('http', 'ws');
    final wsUrl = Uri.parse('$wsBase:7000/events');

    try {
      _channel = WebSocketChannel.connect(wsUrl);
      _isConnected = true;
      debugPrint('[P2P] Connected to WebSocket at $wsUrl');

      // Flush any queued outgoing messages
      _flushOutgoingQueue();

      _channel!.stream.listen(
        (message) {
          _handleIncomingMessage(message);
        },
        onError: (error) {
          debugPrint('[P2P] WebSocket error: $error');
          _isConnected = false;
          _reconnect();
        },
        onDone: () {
          debugPrint('[P2P] WebSocket closed');
          _isConnected = false;
          _reconnect();
        },
      );
    } catch (e) {
      debugPrint('[P2P] Connection failed: $e');
      _isConnected = false;
      _reconnect();
    }
  }

  /// Handles an incoming WebSocket message, parsing it as a NetworkEnvelope
  void _handleIncomingMessage(dynamic message) {
    try {
      final data = jsonDecode(message) as Map<String, dynamic>;
      final envelope = NetworkEnvelope.fromJson(data);

      // Deduplication check
      if (_messageCache.isDuplicate(envelope.msgId)) {
        debugPrint(
            '[P2P] Duplicate ignored: msg_id=${envelope.msgId} from ${envelope.originPeer}');
        return;
      }

      debugPrint(
          '[P2P] Received: msg_id=${envelope.msgId} msg_type=${envelope.msgType} from ${envelope.originPeer}');

      // Forward the raw envelope
      _envelopeStreamController.add(envelope);

      // Route based on msg_type
      switch (envelope.msgType) {
        case 'incident_create':
          _handleIncidentCreate(envelope);
          break;
        case 'sync_request':
          _handleSyncRequest(envelope);
          break;
        case 'sync_response':
          _handleSyncResponse(envelope);
          break;
        default:
          debugPrint(
              '[P2P] Unknown msg_type: ${envelope.msgType}, forwarding envelope only');
      }
    } catch (e) {
      debugPrint('[P2P] Failed to parse incoming message: $e');
    }
  }

  /// Handles an incoming incident_create message (existing Day-16 logic)
  void _handleIncidentCreate(NetworkEnvelope envelope) {
    final payload = envelope.payload;
    final dto = IncidentCreateDto(
      type: payload['type'] as String? ?? 'incident_create',
      lat: (payload['lat'] as num?)?.toDouble() ?? 0.0,
      lon: (payload['lon'] as num?)?.toDouble() ?? 0.0,
      priority: payload['priority'] as String? ?? 'medium',
      status: 'new',
      clientId: payload['device_id'] as String? ?? envelope.originPeer,
      sequenceNum: 1,
      data: {
        'msg_id': envelope.msgId,
        'origin_peer': envelope.originPeer,
        'incident_id': payload['incident_id'] as String? ?? envelope.msgId,
      },
    );
    _incidentStreamController.add(dto);
  }

  /// Handles an incoming sync_request — emits to the syncRequests stream
  /// so that IncidentRepository can respond with local incidents.
  void _handleSyncRequest(NetworkEnvelope envelope) {
    final peerID = envelope.originPeer;

    // Prevent responding to the same peer's sync_request multiple times
    if (_peerSyncState[peerID] == true) {
      debugPrint(
          '[P2P] Sync already completed for peer $peerID, ignoring duplicate sync_request');
      return;
    }

    debugPrint(
        '[P2P] SYNC_REQUEST_RECEIVED: sync_request from peer $peerID');
    _syncRequestStreamController.add(envelope);
  }

  /// Handles an incoming sync_response — emits to the syncResponses stream
  /// so that IncidentRepository can merge the incidents.
  void _handleSyncResponse(NetworkEnvelope envelope) {
    debugPrint(
        '[P2P] SYNC_RESPONSE_RECEIVED: sync_response from peer ${envelope.originPeer}');
    _syncResponseStreamController.add(envelope);

    // Mark this peer as sync-completed so we don't request again
    _peerSyncState[envelope.originPeer] = true;
  }

  /// Sends a sync_response containing a batch of incidents to the P2P network.
  ///
  /// Incidents are chunked into batches of [syncBatchSize] to avoid flooding.
  Future<void> sendSyncResponse(List<Incident> incidents) async {
    if (incidents.isEmpty) {
      debugPrint('[P2P] No incidents to sync, skipping sync_response');
      return;
    }

    // Chunk incidents into batches
    for (var i = 0; i < incidents.length; i += syncBatchSize) {
      final batchEnd = (i + syncBatchSize < incidents.length)
          ? i + syncBatchSize
          : incidents.length;
      final batch = incidents.sublist(i, batchEnd);

      final payloadList = batch.map((incident) => {
        'incident_id': incident.id,
        'type': incident.type,
        'lat': incident.lat,
        'lon': incident.lon,
        'priority': incident.priority,
        'status': incident.status,
        'reporter_id': incident.reporterId,
        'timestamp': incident.updatedAt.millisecondsSinceEpoch ~/ 1000,
      }).toList();

      final envelope = NetworkEnvelope(
        msgId:
            'sync_resp_${DateTime.now().millisecondsSinceEpoch}_batch_${i ~/ syncBatchSize}',
        msgType: 'sync_response',
        originPeer: '', // Will be stamped by the Go daemon
        timestamp: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        payload: {
          'incidents': payloadList,
          'batch_index': i ~/ syncBatchSize,
          'total_incidents': incidents.length,
        },
      );

      // Add to our own dedup cache to prevent self-echo
      _messageCache.isDuplicate(envelope.msgId);

      final success = await _sendEnvelopeHttp(envelope);
      if (success) {
        debugPrint(
            '[P2P] SYNC_RESPONSE_SENT: batch ${i ~/ syncBatchSize} with ${batch.length} incidents');
      } else {
        debugPrint(
            '[P2P] Failed to send sync_response batch ${i ~/ syncBatchSize}');
        _outgoingQueue.add(envelope);
      }
    }
  }

  void _reconnect() {
    Future.delayed(const Duration(seconds: 5), () {
      if (_channel != null && _channel!.closeCode == null) return;
      debugPrint('[P2P] Attempting to reconnect...');
      connect();
    });
  }

  /// Flushes queued outgoing messages in order
  Future<void> _flushOutgoingQueue() async {
    if (_outgoingQueue.isEmpty) return;

    debugPrint('[P2P] Flushing ${_outgoingQueue.length} queued messages');
    final toFlush = List<NetworkEnvelope>.from(_outgoingQueue);
    _outgoingQueue.clear();

    for (final envelope in toFlush) {
      await _sendEnvelopeHttp(envelope);
    }
  }

  /// Sends a NetworkEnvelope via HTTP POST to the daemon
  Future<bool> _sendEnvelopeHttp(NetworkEnvelope envelope) async {
    final uri = Uri.parse('$hostUrl:7000/broadcast');

    try {
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(envelope.toJson()),
      );

      if (response.statusCode == 202) {
        debugPrint(
            '[P2P] Broadcasted: msg_id=${envelope.msgId} msg_type=${envelope.msgType}');
        return true;
      } else {
        debugPrint(
            '[P2P] Broadcast failed with status ${response.statusCode}');
        return false;
      }
    } catch (e) {
      debugPrint('[P2P] Failed to broadcast: $e');
      return false;
    }
  }

  /// Broadcasts an incident to the P2P network using the local daemon.
  ///
  /// Wraps the incident in a NetworkEnvelope. If the connection is unavailable,
  /// the message is queued and will be sent when reconnected.
  Future<void> broadcastIncident(Incident incident) async {
    final envelope = NetworkEnvelope(
      msgId: 'msg_${DateTime.now().millisecondsSinceEpoch}_${incident.id.hashCode.abs()}',
      msgType: 'incident_create',
      originPeer: '', // Will be stamped by the Go daemon
      timestamp: incident.updatedAt.millisecondsSinceEpoch ~/ 1000,
      payload: {
        'type': incident.type,
        'incident_id': incident.id,
        'lat': incident.lat,
        'lon': incident.lon,
        'priority': incident.priority,
        'timestamp': incident.updatedAt.millisecondsSinceEpoch ~/ 1000,
        'device_id': incident.reporterId,
      },
    );

    // Add to our own dedup cache to prevent self-echo
    _messageCache.isDuplicate(envelope.msgId);

    final success = await _sendEnvelopeHttp(envelope);
    if (!success) {
      debugPrint('[P2P] Queuing message for later delivery: msg_id=${envelope.msgId}');
      _outgoingQueue.add(envelope);
    }
  }

  void dispose() {
    _channel?.sink.close();
    _envelopeStreamController.close();
    _incidentStreamController.close();
    _syncRequestStreamController.close();
    _syncResponseStreamController.close();
  }
}
