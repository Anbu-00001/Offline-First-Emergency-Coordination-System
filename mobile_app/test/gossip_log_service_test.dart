import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/models/network_envelope.dart';
import 'package:mobile_app/services/gossip_log_service.dart';

/// Helper to create a test NetworkEnvelope with causal metadata.
NetworkEnvelope _makeEnvelope({
  required String msgId,
  String msgType = 'incident_create',
  int clock = 1,
  List<String> prevMsgIds = const [],
}) {
  return NetworkEnvelope(
    msgId: msgId,
    msgType: msgType,
    originPeer: 'test_peer',
    timestamp: 1000,
    clock: clock,
    prevMsgIds: prevMsgIds,
    payload: {'test': true},
  );
}

void main() {
  group('GossipLogService — causal ordering', () {
    late GossipLogService service;
    late List<NetworkEnvelope> received;
    late StreamSubscription<NetworkEnvelope> sub;

    setUp(() {
      service = GossipLogService();
      received = [];
      sub = service.validMessages.listen(received.add);
    });

    tearDown(() async {
      await sub.cancel();
      service.dispose();
    });

    test('message with no deps is applied immediately', () async {
      final msg = _makeEnvelope(msgId: 'msg_1', clock: 1);
      service.receive(msg);

      await pumpEventQueue();
      expect(received.length, 1);
      expect(received.first.msgId, 'msg_1');
      expect(service.logSize, 1);
      expect(service.pendingSize, 0);
    });

    test('message with missing dep is held pending', () async {
      // resolve depends on create — but create has not arrived yet
      final resolve = _makeEnvelope(
        msgId: 'msg_resolve',
        clock: 2,
        prevMsgIds: ['msg_create'],
      );
      service.receive(resolve);

      await pumpEventQueue();
      expect(received, isEmpty, reason: 'resolve should be pending until create arrives');
      expect(service.pendingSize, 1);
      expect(service.logSize, 0);
    });

    test('pending message is applied once its dep arrives', () async {
      // Step 1: resolve comes BEFORE create
      final resolve = _makeEnvelope(
        msgId: 'msg_resolve',
        clock: 2,
        prevMsgIds: ['msg_create'],
      );
      service.receive(resolve);
      await pumpEventQueue();
      expect(received, isEmpty);

      // Step 2: create arrives — resolve should unblock
      final create = _makeEnvelope(msgId: 'msg_create', clock: 1);
      service.receive(create);
      await pumpEventQueue();

      expect(received.length, 2);
      expect(received[0].msgId, 'msg_create',
          reason: 'create must be applied first');
      expect(received[1].msgId, 'msg_resolve',
          reason: 'resolve applied after dep satisfied');
      expect(service.pendingSize, 0);
    });

    test('chain: A → B → C resolved in correct causal order', () async {
      // Arrive out-of-order: C, then B, then A
      final msgC = _makeEnvelope(msgId: 'msg_c', clock: 3, prevMsgIds: ['msg_b']);
      final msgB = _makeEnvelope(msgId: 'msg_b', clock: 2, prevMsgIds: ['msg_a']);
      final msgA = _makeEnvelope(msgId: 'msg_a', clock: 1);

      service.receive(msgC);
      service.receive(msgB);
      await pumpEventQueue();
      expect(received, isEmpty, reason: 'C and B pending without A');

      service.receive(msgA);
      await pumpEventQueue();

      expect(received.length, 3);
      expect(received.map((e) => e.msgId).toList(), ['msg_a', 'msg_b', 'msg_c']);
    });

    test('HEADS is updated correctly', () async {
      final msgA = _makeEnvelope(msgId: 'msg_a', clock: 1);
      final msgB = _makeEnvelope(msgId: 'msg_b', clock: 2, prevMsgIds: ['msg_a']);

      service.receive(msgA);
      await pumpEventQueue();
      expect(service.heads, {'msg_a'}, reason: 'A is only head initially');

      service.receive(msgB);
      await pumpEventQueue();
      // A is now a parent of B, so it should be removed from heads
      expect(service.heads, {'msg_b'}, reason: 'B is the new head, A is no longer a head');
    });

    test('duplicate message is not applied twice', () async {
      final msg = _makeEnvelope(msgId: 'msg_dup', clock: 1);
      service.receive(msg);
      service.receive(msg); // second receive should be ignored

      await pumpEventQueue();
      expect(received.length, 1, reason: 'duplicate should be dropped');
      expect(service.logSize, 1);
    });

    test('recordSent records locally-sent message and unblocks pending', () async {
      // A pending message depends on a message we are about to send locally
      final incoming = _makeEnvelope(
        msgId: 'msg_from_peer',
        clock: 2,
        prevMsgIds: ['msg_local_sent'],
      );
      service.receive(incoming);
      await pumpEventQueue();
      expect(received, isEmpty);

      // Simulate local send
      final localMsg = _makeEnvelope(msgId: 'msg_local_sent', clock: 1);
      service.recordSent(localMsg);
      await pumpEventQueue();

      // recordSent should not emit via validMessages, but should unblock pending
      expect(received.length, 1);
      expect(received.first.msgId, 'msg_from_peer');
    });

    test('Lamport clock advances on receive', () async {
      expect(service.clock, 0);

      service.receive(_makeEnvelope(msgId: 'msg_1', clock: 5));
      // clock = max(0, 5) + 1 = 6
      expect(service.clock, 6);

      service.receive(_makeEnvelope(msgId: 'msg_2', clock: 3));
      // clock = max(6, 3) + 1 = 7
      expect(service.clock, 7);
    });
  });
}
