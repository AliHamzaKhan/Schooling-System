import 'dart:async';

import 'package:get/get.dart';

import '../../../services/auth_service.dart';
import '../data/messaging_service.dart';
import '../models/conversation.dart';

/// Drives the inbox: loads the flat message list, groups it into conversations,
/// and exposes search + the total unread count.
class InboxController extends GetxController {
  final MessagingService _service;
  InboxController({MessagingService? service})
      : _service = service ?? MessagingService();

  final loading = true.obs;
  final refreshing = false.obs;
  final error = RxnString();
  final conversations = <Conversation>[].obs;
  final query = ''.obs;

  Timer? _debounce;

  /// The signed-in user's id — used to tell "my" messages from the other
  /// party's when counting unread and grouping threads.
  String get meId => Get.find<AuthService>().userId ?? '';

  @override
  void onInit() {
    super.onInit();
    load();
  }

  int get totalUnread =>
      conversations.fold(0, (sum, c) => sum + c.unreadFor(meId));

  List<Conversation> get visible {
    final q = query.value.trim().toLowerCase();
    if (q.isEmpty) return conversations;
    return conversations
        .where((c) => c.counterpartName.toLowerCase().contains(q))
        .toList(growable: false);
  }

  /// Unread messages the counterpart sent in conversation [c].
  int unreadFor(Conversation c) => c.unreadFor(meId);

  void onSearch(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 200), () => query.value = v);
  }

  Future<void> load() async {
    if (conversations.isEmpty) {
      loading.value = true;
    } else {
      conversations.clear();
      refreshing.value = true;
    }
    error.value = null;
    final res = await _service.list();
    if (res.success && res.data != null) {
      conversations.assignAll(Conversation.group(res.data!, meId));
    } else {
      error.value = res.error ?? 'Could not load messages.';
    }
    loading.value = false;
    refreshing.value = false;
  }

  @override
  void onClose() {
    _debounce?.cancel();
    super.onClose();
  }
}
