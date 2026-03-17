import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/network_envelope.dart';

/// GossipLogService implements causal message ordering for the OpenRescue P2P network.
///
/// Day-18: Messages are only forwarded downstream via [validMessages] once ALL
/// their declared dependencies ([NetworkEnvelope.prevMsgIds]) are present in the log.
///
/// Pipeline position:
/// ```
/// P2PService (dedup) → GossipLogService.receive()
///                              ↓ canApply? YES
///                       GossipLogService._apply()
///                              ↓ validMessages stream
///                       P2PService routing → IncidentRepository
/// ```
///
/// Causal rules (Lamport):
/// - On **send**: clock = clock + 1
/// - On **receive**: clock = max(local, received) + 1
class GossipLogService {
  /// Applied messages: msgId → envelope
  final Map<String, NetworkEnvelope> _log = {};

  /// Pending messages waiting for their dependencies: msgId → envelope
  final Map<String, NetworkEnvelope> _pending = {};

  /// HEADS: tip messages with no known children (for future sync optimization)
  final Set<String> _heads = {};

  /// Lamport logical clock
  int _clock = 0;

  /// Stream of causally-ready messages for downstream consumers
  final StreamController<NetworkEnvelope> _outController =
      StreamController<NetworkEnvelope>.broadcast();

  /// Stream that emits messages only when all their dependencies are satisfied.
  Stream<NetworkEnvelope> get validMessages => _outController.stream;

  /// Snapshot of current HEAD message IDs (unmodifiable copy).
  Set<String> get heads => Set.unmodifiable(_heads);

  /// Number of messages in the log (applied).
  int get logSize => _log.length;

  /// Number of messages in the pending queue.
  int get pendingSize => _pending.length;

  /// Current Lamport clock value.
  int get clock => _clock;

  /// Processes an incoming message from the network.
  ///
  /// Updates the Lamport clock using max(local, received)+1, then either
  /// applies the message immediately (if deps satisfied) or queues it pending.
  void receive(NetworkEnvelope env) {
    // Lamport clock update: max(local, received) + 1
    if (env.clock > _clock) {
      _clock = env.clock;
    }
    _clock++;

    debugPrint(
        '[GossipLog] MESSAGE_RECEIVED: msg_id=${env.msgId} msg_type=${env.msgType} '
        'clock=${env.clock} deps=${env.prevMsgIds}');

    // Skip if already known (extra safety beyond P2PService dedup)
    if (_log.containsKey(env.msgId) || _pending.containsKey(env.msgId)) {
      return;
    }

    if (_canApply(env)) {
      _apply(env);
      _tryApplyPending();
    } else {
      _pending[env.msgId] = env;
      debugPrint(
          '[GossipLog] MESSAGE_PENDING: msg_id=${env.msgId} waiting for deps=${env.prevMsgIds}');
    }
  }

  /// Records a locally-originated (sent) message into the log without emitting
  /// it downstream (it was already processed locally).
  ///
  /// This ensures that remote messages depending on our messages can be applied.
  /// Also updates the Lamport clock: clock = clock + 1.
  void recordSent(NetworkEnvelope env) {
    _clock++;
    if (_log.containsKey(env.msgId)) return;

    _log[env.msgId] = env;
    _updateHeads(env);

    debugPrint(
        '[GossipLog] SELF_RECORDED: msg_id=${env.msgId} clock=$_clock');

    // Unblock any pending messages that depended on this one
    _tryApplyPending();
  }

  /// Returns whether all declared dependencies of [env] are present in the log.
  bool _canApply(NetworkEnvelope env) {
    for (final depId in env.prevMsgIds) {
      if (depId.isNotEmpty && !_log.containsKey(depId)) {
        return false;
      }
    }
    return true;
  }

  /// Applies a message: moves it into the log, updates HEADS, and emits downstream.
  void _apply(NetworkEnvelope env) {
    _pending.remove(env.msgId);
    _log[env.msgId] = env;
    _updateHeads(env);

    debugPrint(
        '[GossipLog] MESSAGE_APPLIED: msg_id=${env.msgId} msg_type=${env.msgType} '
        'clock=${env.clock}');

    _outController.add(env);
  }

  /// Scans the pending queue and applies any messages whose deps are now satisfied.
  /// Repeats until no further progress is possible.
  void _tryApplyPending() {
    bool progress = true;
    while (progress) {
      progress = false;
      final toApply = _pending.values
          .where((env) => _canApply(env))
          .toList(growable: false);

      for (final env in toApply) {
        debugPrint(
            '[GossipLog] DEPENDENCY_RESOLVED: msg_id=${env.msgId} deps=${env.prevMsgIds} now satisfied');
        _apply(env);
        progress = true;
      }
    }
  }

  /// Updates the HEADS set when a message is applied.
  ///
  /// - Remove all of env's dependencies from HEADS (they now have a child).
  /// - Add env to HEADS (it currently has no children).
  void _updateHeads(NetworkEnvelope env) {
    for (final depId in env.prevMsgIds) {
      if (depId.isNotEmpty) {
        _heads.remove(depId);
      }
    }
    _heads.add(env.msgId);
  }

  /// Disposes the stream controller. Call when the service is no longer needed.
  void dispose() {
    _outController.close();
  }
}
