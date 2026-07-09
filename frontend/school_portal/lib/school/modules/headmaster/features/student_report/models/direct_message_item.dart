/// A staff member's sent direct message / complaint (their side of the thread).
class DirectMessageItem {
  final String id;
  final String recipientName;
  final String kind; // message / complaint
  final String body;
  final String? studentId;
  final DateTime? createdAt;
  final bool read; // whether the recipient has read it

  const DirectMessageItem({
    required this.id,
    required this.recipientName,
    required this.kind,
    required this.body,
    required this.studentId,
    required this.createdAt,
    required this.read,
  });

  bool get isComplaint => kind == 'complaint';

  factory DirectMessageItem.fromJson(Map<String, dynamic> j) => DirectMessageItem(
        id: '${j['id']}',
        recipientName: j['recipient_name'] as String? ?? '',
        kind: j['kind'] as String? ?? 'message',
        body: j['body'] as String? ?? '',
        studentId: j['student_id'] == null ? null : '${j['student_id']}',
        createdAt: DateTime.tryParse('${j['created_at']}')?.toLocal(),
        read: j['read_at'] != null,
      );
}
