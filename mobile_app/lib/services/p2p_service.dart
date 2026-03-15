import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/models.dart';

/// Service responsible for communicating with the local Go P2P Daemon.
class P2PService {
  final String hostUrl;
  WebSocketChannel? _channel;
  final StreamController<IncidentCreateDto> _incidentStreamController = StreamController<IncidentCreateDto>.broadcast();

  P2PService({required this.hostUrl}); // Default is usually localhost or LAN IP

  /// The stream of incidents received from the P2P network
  Stream<IncidentCreateDto> get incomingIncidents => _incidentStreamController.stream;

  /// Connects to the local daemon's WebSocket endpoint for receiving messages
  void connect() {
    // Determine the WS base URL safely
    final wsBase = hostUrl.replaceFirst('http', 'ws');
    final wsUrl = Uri.parse('$wsBase:7000/events');

    try {
      _channel = WebSocketChannel.connect(wsUrl);
      debugPrint('P2PService: Connected to WebSocket at $wsUrl');

      _channel!.stream.listen(
        (message) {
          try {
            final data = jsonDecode(message) as Map<String, dynamic>;
            if (data['type'] == 'incident_create') {
              // Parse incoming gossip message back into our DTO
              final dto = IncidentCreateDto(
                type: data['type'],
                lat: data['lat'] as double,
                lon: data['lon'] as double,
                priority: data['priority'],
                status: 'new',
                client_id: data['device_id'],
                sequence_num: 1, // Assume 1 for day-15
              );
              // Send out to stream
              _incidentStreamController.add(dto);
              debugPrint('P2PService: Received incident ${data['incident_id']} from peer ${data['device_id']}');
            }
          } catch (e) {
            debugPrint('P2PService: Failed to parse incoming message: $e');
          }
        },
        onError: (error) {
          debugPrint('P2PService: WebSocket error: $error');
          _reconnect();
        },
        onDone: () {
          debugPrint('P2PService: WebSocket closed');
          _reconnect();
        },
      );
    } catch (e) {
      debugPrint('P2PService: Connection failed: $e');
      _reconnect();
    }
  }

  void _reconnect() {
    Future.delayed(const Duration(seconds: 5), () {
      if (_channel != null && _channel!.closeCode == null) return; // Prevent multiple reconnect loops
      debugPrint('P2PService: Attempting to reconnect...');
      connect();
    });
  }

  /// Broadcasts an incident to the P2P network using the local daemon
  Future<void> broadcastIncident(Incident incident) async {
    final uri = Uri.parse('$hostUrl:7000/broadcast');
    
    // Formatting match for Go daemon schema
    final payload = {
      'type': 'incident_create',
      'incident_id': incident.id,
      'lat': incident.lat,
      'lon': incident.lon,
      'priority': incident.priority,
      'timestamp': incident.updated_at.millisecondsSinceEpoch ~/ 1000,
      'device_id': incident.reporter_id,
    };

    try {
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      if (response.statusCode == 202) {
        debugPrint('P2PService: Broadcasted incident ${incident.id} to P2P network');
      } else {
        debugPrint('P2PService: Broadcast failed with status ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('P2PService: Failed to broadcast incident: $e');
    }
  }

  void dispose() {
    _channel?.sink.close();
    _incidentStreamController.close();
  }
}
