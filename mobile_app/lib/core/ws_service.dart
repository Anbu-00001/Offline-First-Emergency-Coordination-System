import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'package:drift/drift.dart';

import 'auth_service.dart';
import '../data/database.dart';

class WsService {
  final String _baseUrl;
  final AuthService _authService;
  final AppDatabase _db;
  
  WebSocketChannel? _channel;
  final StreamController<Map<String, dynamic>> _messageController = StreamController.broadcast();
  
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  bool _isConnecting = false;
  
  WsService(this._baseUrl, this._authService, this._db);

  Stream<Map<String, dynamic>> get messages => _messageController.stream;

  Future<void> connect() async {
    if (_isConnecting || _channel != null) return;
    _isConnecting = true;
    
    final token = await _authService.getToken();
    if (token == null) {
      debugPrint('WS: No auth token');
      _isConnecting = false;
      return;
    }

    // Convert http:// to ws:// 
    final wsBaseUrl = _baseUrl.replaceFirst('http', 'ws');
    final wsUrl = Uri.parse('$wsBaseUrl/ws/peer?token=$token');

    try {
      _channel = WebSocketChannel.connect(wsUrl);
      
      _channel!.stream.listen(
        (message) {
          _reconnectAttempts = 0; // reset on successful message
          try {
            final data = jsonDecode(message);
            _messageController.add(data);
          } catch (e) {
            debugPrint('WS Parse error: $e');
          }
        },
        onDone: () {
          debugPrint('WS Closed');
          _channel = null;
          _isConnecting = false;
          _scheduleReconnect();
        },
        onError: (error) {
          debugPrint('WS Error: $error');
          _channel = null;
          _isConnecting = false;
          _scheduleReconnect();
        },
      );
      
      _isConnecting = false;
      _reconnectAttempts = 0;
      debugPrint('WS Connected');
      
      // Attempt to send queued messages
      _flushQueue();
      
    } catch (e) {
      debugPrint('WS Connect Exception: $e');
      _channel = null;
      _isConnecting = false;
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    if (_reconnectAttempts < 5) { // Cap backoff
      final delay = pow(2, _reconnectAttempts) * 1000;
      _reconnectAttempts++;
      debugPrint('WS: Reconnecting in ${delay}ms (attempt $_reconnectAttempts)');
      _reconnectTimer = Timer(Duration(milliseconds: delay.toInt()), () {
        connect();
      });
    } else {
      debugPrint('WS: Retry limit reached. Waiting for manual reconnect.');
    }
  }

  Future<void> sendMessage(Map<String, dynamic> msg, {String? entityId}) async {
    // 1. Persist to sync queue
    final queueId = await _db.into(_db.syncQueue).insert(
      SyncQueueCompanion.insert(
        entityType: 'Message',
        entityId: entityId ?? 'msg_${DateTime.now().millisecondsSinceEpoch}',
        operation: 'SEND',
        data: jsonEncode(msg),
        sequenceNum: 0,
        timestamp: DateTime.now(),
        status: const Value('queued'),
      ),
    );

    // 2. Transmit immediately if channel is open
    _trySendMessage(queueId, msg);
  }

  void _trySendMessage(int queueId, Map<String, dynamic> msg) {
    if (_channel != null) {
      try {
        _channel!.sink.add(jsonEncode(msg));
        // Mark as sent
        (_db.update(_db.syncQueue)..where((t) => t.id.equals(queueId)))
            .write(const SyncQueueCompanion(status: Value('sent')));
      } catch (e) {
        debugPrint('WS Send failed: \$e');
      }
    }
  }

  Future<void> _flushQueue() async {
    final pendingItems = await (_db.select(_db.syncQueue)..where((t) => t.status.equals('queued') & t.entityType.equals('Message'))).get();
    for (var item in pendingItems) {
      _trySendMessage(item.id, jsonDecode(item.data));
    }
  }

  void disconnect() {
    _reconnectTimer?.cancel();
    _channel?.sink.close(status.normalClosure);
    _channel = null;
  }
}
