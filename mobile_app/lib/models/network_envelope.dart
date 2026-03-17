/// Standardized network envelope for P2P message exchange.
///
/// Day-18: Extended with Lamport clock ([clock]) and causal dependency list
/// ([prevMsgIds]) for causal consistency enforcement via GossipLogService.
///
/// This format is shared between the Go daemon and Flutter P2PService.
/// Designed for forward compatibility — unknown fields in [payload] are preserved.
class NetworkEnvelope {
  final String msgId;
  final String msgType;
  final String originPeer;
  final int timestamp;
  /// Day-18: Lamport logical clock value at the time of send.
  final int clock;
  /// Day-18: IDs of messages this message causally depends on.
  final List<String> prevMsgIds;
  final Map<String, dynamic> payload;

  NetworkEnvelope({
    required this.msgId,
    required this.msgType,
    required this.originPeer,
    required this.timestamp,
    this.clock = 0,
    this.prevMsgIds = const [],
    required this.payload,
  });

  factory NetworkEnvelope.fromJson(Map<String, dynamic> json) {
    return NetworkEnvelope(
      msgId: json['msg_id'] as String? ?? '',
      msgType: json['msg_type'] as String? ?? 'unknown',
      originPeer: json['origin_peer'] as String? ?? '',
      timestamp: (json['timestamp'] as num?)?.toInt() ?? 0,
      clock: (json['clock'] as num?)?.toInt() ?? 0,
      prevMsgIds: (json['prev_msg_ids'] as List<dynamic>? ?? [])
          .map((e) => e as String)
          .toList(),
      payload: json['payload'] as Map<String, dynamic>? ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'msg_id': msgId,
      'msg_type': msgType,
      'origin_peer': originPeer,
      'timestamp': timestamp,
      'clock': clock,
      'prev_msg_ids': prevMsgIds,
      'payload': payload,
    };
  }

  @override
  String toString() =>
      'NetworkEnvelope(msgId: $msgId, msgType: $msgType, originPeer: $originPeer)';
}
