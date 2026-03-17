import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:drift/drift.dart' as drift;
import 'dart:convert';

import '../../core/ws_service.dart';
import '../../data/database.dart';

class MessagingScreen extends StatefulWidget {
  const MessagingScreen({super.key});

  @override
  State<MessagingScreen> createState() => _MessagingScreenState();
}

class _MessagingScreenState extends State<MessagingScreen> {
  final _textController = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];

  @override
  void initState() {
    super.initState();
    final ws = context.read<WsService>();
    ws.connect();
    ws.messages.listen((msg) {
      if (mounted) {
        setState(() {
          _messages.add(msg);
        });
      }
    });
  }

  @override
  void dispose() {
    // We can keep WS connected or disconnect when leaving. Keep it simple.
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ws = context.read<WsService>();
    final db = context.watch<AppDatabase>();

    return Scaffold(
      appBar: AppBar(title: const Text('Peer Messaging')),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<SyncQueueData>>(
              // Watch outgoing messages for status
              stream: (db.select(db.syncQueue)
                    ..where((t) => t.entityType.equals('Message'))
                    ..orderBy([(t) => drift.OrderingTerm(expression: t.timestamp, mode: drift.OrderingMode.asc)]))
                  .watch(),
              builder: (context, snapshot) {
                final outgoing = snapshot.data ?? [];
                
                return ListView.builder(
                  itemCount: _messages.length + outgoing.length,
                  itemBuilder: (context, index) {
                    if (index < _messages.length) {
                      final msg = _messages[index];
                      return ListTile(
                        title: Text(msg['text'] ?? 'Unknown'),
                        subtitle: const Text('Received from peer'),
                        leading: const Icon(Icons.download),
                      );
                    } else {
                      final outMsg = outgoing[index - _messages.length];
                      final content = jsonDecode(outMsg.data)['text'] ?? 'Unknown';
                      return ListTile(
                        title: Text(content),
                        subtitle: Text('Status: ${outMsg.status}'),
                        leading: const Icon(Icons.upload),
                        trailing: outMsg.status == 'queued'
                            ? const CircularProgressIndicator()
                            : const Icon(Icons.check_circle, color: Colors.green),
                      );
                    }
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    decoration: const InputDecoration(hintText: 'Enter message...'),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () {
                    if (_textController.text.isNotEmpty) {
                      ws.sendMessage({
                        'text': _textController.text,
                        'type': 'chat',
                        'timestamp': DateTime.now().toIso8601String(),
                      });
                      _textController.clear();
                    }
                  },
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}
