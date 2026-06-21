import 'package:get/get.dart';

import '../../../data/guardian_repository.dart';
import '../../../shared/controller/guardian_session_controller.dart';
import '../models/activity_item.dart';

/// Drives the Guardian Dashboard: surfaces the active child's summary (read
/// from the session) and reloads the timeline activity feed whenever the
/// selected child changes.
class GuardianDashboardController extends GetxController {
  final GuardianRepository _repo;
  final GuardianSessionController session;

  GuardianDashboardController({
    GuardianRepository? repo,
    GuardianSessionController? session,
  })  : _repo = repo ?? Get.find<GuardianRepository>(),
        session = session ?? Get.find<GuardianSessionController>();

  final loadingFeed = true.obs;
  final feed = <ActivityItem>[].obs;

  @override
  void onInit() {
    super.onInit();
    // React to child switches and to the initial child load resolving.
    ever<String?>(session.selectedId, (id) {
      if (id != null) _loadFeed(id);
    });
    final current = session.selectedId.value;
    if (current != null) _loadFeed(current);
  }

  Future<void> _loadFeed(String childId) async {
    loadingFeed.value = true;
    final res = await _repo.loadDashboardFeed(childId);
    if (res.success && res.data != null) feed.assignAll(res.data!);
    loadingFeed.value = false;
  }
}
