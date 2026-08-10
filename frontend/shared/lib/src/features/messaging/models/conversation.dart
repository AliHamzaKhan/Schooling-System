import 'direct_message.dart';

/// A back-and-forth thread with one counterpart, built client-side by grouping
/// the flat `/messages` list (the backend has no thread concept).
class Conversation {
  final String counterpartId;
  final String counterpartName;

  /// All messages exchanged with the counterpart, oldest first.
  final List<DirectMessage> messages;

  const Conversation({
    required this.counterpartId,
    required this.counterpartName,
    required this.messages,
  });

  DirectMessage get last => messages.last;

  /// Number of unread messages the counterpart sent to [me].
  int unreadFor(String me) =>
      messages.where((m) => m.isUnreadFor(me)).length;

  bool hasUnreadFor(String me) => messages.any((m) => m.isUnreadFor(me));

  /// The student this thread concerns, if any (carried into replies so the
  /// teacher↔guardian thread stays tied to the same student).
  String? get studentId {
    for (final m in messages.reversed) {
      if (m.studentId != null) return m.studentId;
    }
    return null;
  }

  /// Groups a flat message list into conversations keyed by the other party,
  /// newest-active thread first. [me] is the signed-in user's id.
  static List<Conversation> group(List<DirectMessage> all, String me) {
    final byParty = <String, List<DirectMessage>>{};
    final names = <String, String>{};
    for (final m in all) {
      final other = m.otherPartyId(me);
      byParty.putIfAbsent(other, () => []).add(m);
      names[other] = m.otherPartyName(me);
    }
    final convos = byParty.entries.map((e) {
      final msgs = [...e.value]..sort((a, b) =>
          (a.createdAt ?? DateTime(0)).compareTo(b.createdAt ?? DateTime(0)));
      return Conversation(
        counterpartId: e.key,
        counterpartName: names[e.key] ?? '',
        messages: msgs,
      );
    }).toList();
    convos.sort((a, b) => (b.last.createdAt ?? DateTime(0))
        .compareTo(a.last.createdAt ?? DateTime(0)));
    return convos;
  }
}
