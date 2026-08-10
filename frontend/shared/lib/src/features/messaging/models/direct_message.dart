/// One direct (1-to-1) message between two members of the same school.
///
/// Mirrors the backend `DirectMessageOut` payload from
/// `GET/POST /schools/{id}/messages`. A message may be a plain `message` or a
/// `complaint`, and may concern a specific student ([studentId]).
class DirectMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String recipientId;
  final String recipientName;
  final String? studentId;
  final String kind; // 'message' | 'complaint'
  final String body;
  final DateTime? readAt;
  final DateTime? createdAt;

  const DirectMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.recipientId,
    required this.recipientName,
    required this.studentId,
    required this.kind,
    required this.body,
    required this.readAt,
    required this.createdAt,
  });

  bool get isComplaint => kind == 'complaint';

  /// True when [me] sent this message (drives bubble alignment).
  bool sentByMe(String me) => senderId == me;

  /// True when this is an unread message addressed to [me].
  bool isUnreadFor(String me) => recipientId == me && readAt == null;

  /// The other party relative to [me] — used to group a conversation.
  String otherPartyId(String me) => senderId == me ? recipientId : senderId;
  String otherPartyName(String me) => senderId == me ? recipientName : senderName;

  factory DirectMessage.fromJson(Map<String, dynamic> j) => DirectMessage(
        id: '${j['id']}',
        senderId: '${j['sender_id']}',
        senderName: j['sender_name'] as String? ?? '',
        recipientId: '${j['recipient_id']}',
        recipientName: j['recipient_name'] as String? ?? '',
        studentId: j['student_id'] == null ? null : '${j['student_id']}',
        kind: j['kind'] as String? ?? 'message',
        body: j['body'] as String? ?? '',
        readAt: DateTime.tryParse('${j['read_at']}')?.toLocal(),
        createdAt: DateTime.tryParse('${j['created_at']}')?.toLocal(),
      );
}
