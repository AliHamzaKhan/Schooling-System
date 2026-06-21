import 'package:get/get.dart';

import '../../../data/headmaster_repository.dart';
import '../models/announcement.dart';

/// Drives the Announcements Hub: filter + list state, with a "compose" hook.
class AnnouncementsController extends GetxController {
  final HeadmasterRepository _repo;
  AnnouncementsController({HeadmasterRepository? repo})
      : _repo = repo ?? Get.find<HeadmasterRepository>();

  static const filters = ['All Updates', 'School-Wide', 'Teachers Only', 'Events'];

  final loading = true.obs;
  final error = RxnString();
  final items = <Announcement>[].obs;
  final filter = 'All Updates'.obs;

  @override
  void onInit() {
    super.onInit();
    fetch();
  }

  void selectFilter(String value) {
    if (filter.value == value) return;
    filter.value = value;
    fetch();
  }

  Future<void> fetch() async {
    loading.value = true;
    error.value = null;
    final res = await _repo.loadAnnouncements(filter: filter.value);
    if (res.success && res.data != null) {
      items.assignAll(res.data!);
    } else {
      error.value = res.error ?? 'Could not load announcements.';
    }
    loading.value = false;
  }
}
