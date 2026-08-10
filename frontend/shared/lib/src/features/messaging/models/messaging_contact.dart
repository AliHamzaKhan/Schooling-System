/// A member of the school the signed-in user may start a conversation with.
///
/// Mirrors the backend `ContactOut` payload from
/// `GET /schools/{id}/messages/contacts`.
class MessagingContact {
  final String id;
  final String name;
  final String role; // headmaster / teacher / guardian / student / staff

  const MessagingContact({
    required this.id,
    required this.name,
    required this.role,
  });

  String get initial =>
      name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();

  /// Title-cased role for display (e.g. 'Teacher').
  String get roleLabel =>
      role.isEmpty ? 'Staff' : role[0].toUpperCase() + role.substring(1);

  factory MessagingContact.fromJson(Map<String, dynamic> j) => MessagingContact(
        id: '${j['id']}',
        name: j['name'] as String? ?? '',
        role: j['role'] as String? ?? 'staff',
      );
}
