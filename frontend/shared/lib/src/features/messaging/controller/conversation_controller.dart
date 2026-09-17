import 'package:get/get.dart';

import '../../../services/auth_service.dart';
import '../data/messaging_service.dart';
import '../models/direct_message.dart';

/// Drives one open conversation with a single counterpart: loads the thread,
/// marks incoming messages read, and sends replies.
class ConversationController extends GetxController {
  final MessagingService _service;

  /// The other party in this thread.
  final String counterpartId;
  final String counterpartName;

  /// Student the thread concerns, if any — carried into every reply so a
  /// teacher↔guardian thread stays tied to the same student.
  final String? studentId;

  ConversationController({
    required this.counterpartId,
    required this.counterpartName,
    this.studentId,
    MessagingService? service,
  }) : _service = service ?? MessagingService();

  final loading = true.obs;
  final sending = false.obs;
  final error = RxnString();
  final messages = <DirectMessage>[].obs;

  String get me => Get.find<AuthService>().userId ?? '';

  /// Explicit context wins. A latest general message must not silently inherit
  /// a different child's context from an older message in this conversation.
  String? get _threadStudentId {
    return studentId ?? (messages.isEmpty ? null : messages.last.studentId);
  }

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    error.value = null;
    final res = await _service.list(counterpartId: counterpartId);
    if (res.success && res.data != null) {
      final thread = res.data!
          .where((m) => (m.senderId == me && m.recipientId == counterpartId) ||
              (m.recipientId == me && m.senderId == counterpartId))
          .toList()
        ..sort((a, b) => (a.createdAt ?? DateTime(0))
            .compareTo(b.createdAt ?? DateTime(0)));
      messages.assignAll(thread);
      loading.value = false;
      await _markIncomingRead();
    } else {
      messages.clear();
      error.value = res.error ?? 'Could not load this conversation.';
      loading.value = false;
    }
  }

  Future<void> _markIncomingRead() async {
    final unread = messages.where((m) => m.isUnreadFor(me)).toList();
    for (final m in unread) {
      final response = await _service.markRead(m.id);
      if (response.success && response.data is Map<String, dynamic>) {
        final updated = DirectMessage.fromJson(response.data as Map<String, dynamic>);
        final index = messages.indexWhere((item) => item.id == updated.id);
        if (index >= 0 && updated.recipientId == me && updated.senderId == counterpartId) {
          messages[index] = updated;
        }
      } else {
        error.value = 'Some read receipts could not be saved. Refresh to retry.';
      }
    }
  }

  /// Sends [text] to the counterpart and appends the created message.
  Future<bool> send(String text) async {
    final body = text.trim();
    if (body.isEmpty || sending.value) return false;
    sending.value = true;
    error.value = null;
    final res = await _service.send(
      recipientId: counterpartId,
      body: body,
      studentId: _threadStudentId,
    );
    sending.value = false;
    if (res.success && res.data != null) {
      messages.add(res.data!);
      return true;
    }
    error.value = res.error ?? 'Message not sent.';
    return false;
  }
}
