import 'package:get/get.dart';

import '../../../data/student_repository.dart';
import '../models/notification_item.dart';

class NotificationsController extends GetxController {
  final StudentRepository _repo;
  NotificationsController({StudentRepository? repo})
      : _repo = repo ?? Get.find<StudentRepository>();

  final loading = true.obs;
  final items = <NotificationItem>[].obs;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  int get newCount => items.where((n) => n.unread).length;

  Future<void> load() async {
    loading.value = true;
    final res = await _repo.loadNotifications();
    if (res.success && res.data != null) items.assignAll(res.data!);
    loading.value = false;
  }
}
