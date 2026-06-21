import 'package:get/get.dart';

import '../../../data/headmaster_repository.dart';
import '../models/exams_data.dart';

/// Drives Exams & Results: data load + search query state.
class ExamsController extends GetxController {
  final HeadmasterRepository _repo;
  ExamsController({HeadmasterRepository? repo})
      : _repo = repo ?? Get.find<HeadmasterRepository>();

  final loading = true.obs;
  final error = RxnString();
  final data = Rxn<ExamsData>();
  final searchQuery = ''.obs;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  void onSearch(String value) => searchQuery.value = value;

  Future<void> load() async {
    loading.value = true;
    error.value = null;
    final res = await _repo.loadExams();
    if (res.success && res.data != null) {
      data.value = res.data;
    } else {
      error.value = res.error ?? 'Could not load exams.';
    }
    loading.value = false;
  }
}
