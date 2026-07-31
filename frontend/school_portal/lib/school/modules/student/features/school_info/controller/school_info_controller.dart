import 'package:get/get.dart';

import '../../../data/student_repository.dart';
import '../models/school_info_models.dart';

/// Loads the public school profile for the "My School" screen.
class SchoolInfoController extends GetxController {
  final StudentRepository _repo;
  SchoolInfoController({StudentRepository? repo})
      : _repo = repo ?? Get.find<StudentRepository>();

  final loading = true.obs;
  final error = RxnString();
  final info = Rxn<SchoolInfo>();

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    loading.value = true;
    error.value = null;
    final res = await _repo.loadSchoolInfo();
    if (res.success && res.data != null) {
      info.value = res.data;
    } else {
      error.value = res.error ?? 'Could not load school information.';
    }
    loading.value = false;
  }
}
