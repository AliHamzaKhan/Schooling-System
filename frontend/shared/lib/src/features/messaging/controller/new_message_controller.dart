import 'dart:async';

import 'package:get/get.dart';

import '../data/messaging_service.dart';
import '../models/messaging_contact.dart';

/// Drives the "new conversation" picker: loads messageable school members and
/// filters them by name/role.
class NewMessageController extends GetxController {
  final MessagingService _service;
  NewMessageController({MessagingService? service})
      : _service = service ?? MessagingService();

  final loading = true.obs;
  final error = RxnString();
  final contacts = <MessagingContact>[].obs;
  final query = ''.obs;

  Timer? _debounce;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  List<MessagingContact> get visible {
    final q = query.value.trim().toLowerCase();
    if (q.isEmpty) return contacts;
    return contacts
        .where((c) =>
            c.name.toLowerCase().contains(q) ||
            c.role.toLowerCase().contains(q))
        .toList(growable: false);
  }

  void onSearch(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 200), () => query.value = v);
  }

  Future<void> load() async {
    loading.value = true;
    error.value = null;
    final res = await _service.contacts();
    if (res.success && res.data != null) {
      contacts.assignAll(res.data!);
    } else {
      error.value = res.error ?? 'Could not load contacts.';
    }
    loading.value = false;
  }

  @override
  void onClose() {
    _debounce?.cancel();
    super.onClose();
  }
}
