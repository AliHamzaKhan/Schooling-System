import 'package:get/get.dart';

import '../../../data/headmaster_repository.dart';
import '../models/reports_data.dart';

class ReportsController extends GetxController {
  final HeadmasterRepository _repo;
  ReportsController({HeadmasterRepository? repo})
      : _repo = repo ?? Get.find<HeadmasterRepository>();

  final loading = true.obs;
  final error = RxnString();
  final data = Rxn<ReportsData>();
  final range = PerformanceRange.year.obs;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  void selectRange(PerformanceRange r) => range.value = r;

  Future<void> load() async {
    loading.value = true;
    error.value = null;
    final res = await _repo.loadReports();
    if (res.success && res.data != null) {
      data.value = res.data;
    } else {
      error.value = res.error ?? 'Could not load reports.';
    }
    loading.value = false;
  }
}
