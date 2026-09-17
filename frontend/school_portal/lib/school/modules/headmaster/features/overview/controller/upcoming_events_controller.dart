import 'package:get/get.dart';
import 'package:shared/shared.dart';

import '../../../data/headmaster_repository.dart';
import '../models/overview_data.dart';

typedef UpcomingEventsLoader = Future<ApiResponse<OverviewData>> Function();

/// Restores the upcoming-events route from canonical backend data so opening
/// the URL directly does not depend on a previous screen's in-memory state.
class UpcomingEventsController extends GetxController {
  final UpcomingEventsLoader _loader;

  UpcomingEventsController({
    HeadmasterRepository? repository,
    UpcomingEventsLoader? loader,
  }) : _loader =
           loader ??
           (repository ?? Get.find<HeadmasterRepository>()).loadOverview;

  final loading = true.obs;
  final error = RxnString();
  final events = <UpcomingEvent>[].obs;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    loading.value = true;
    error.value = null;
    events.clear();
    final result = await _loader();
    if (result.success && result.data != null) {
      events.assignAll(result.data!.events);
    } else {
      error.value = result.error ?? 'Could not load upcoming events.';
    }
    loading.value = false;
  }
}
