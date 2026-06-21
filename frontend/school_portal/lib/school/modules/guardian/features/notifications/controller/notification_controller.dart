import 'package:get/get.dart';

import '../../../data/guardian_repository.dart';
import '../models/notification_item.dart';

/// Notifications Center controller — module-wide alert feed (not scoped to a
/// single child). Supports an All/Unread filter and mark-as-read.
class NotificationController extends GetxController {
  final GuardianRepository _repo;
  NotificationController({GuardianRepository? repo})
      : _repo = repo ?? Get.find<GuardianRepository>();

  final loading = true.obs;
  final _all = <NotificationItem>[].obs;

  /// 0 = All, 1 = Unread.
  final filterIndex = 0.obs;

  int get unreadCount => _all.where((n) => !n.read).length;

  List<NotificationItem> get visible {
    if (filterIndex.value == 1) {
      return _all.where((n) => !n.read).toList();
    }
    return _all.toList();
  }

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    loading.value = true;
    final res = await _repo.loadNotifications();
    if (res.success && res.data != null) _all.assignAll(res.data!);
    loading.value = false;
  }

  void setFilter(int i) => filterIndex.value = i;

  void markRead(String id) {
    final idx = _all.indexWhere((n) => n.id == id);
    if (idx != -1 && !_all[idx].read) {
      _all[idx] = _all[idx].copyWith(read: true);
    }
  }

  void markAllRead() {
    for (var i = 0; i < _all.length; i++) {
      if (!_all[i].read) _all[i] = _all[i].copyWith(read: true);
    }
  }
}
