import 'package:get/get.dart';

import '../../../data/student_repository.dart';
import '../models/exam.dart';

class StudentExamsController extends GetxController {
  final StudentRepository _repo;
  StudentExamsController({StudentRepository? repo})
    : _repo = repo ?? Get.find<StudentRepository>();

  final loading = true.obs;
  final data = Rxn<ExamsData>();
  final error = RxnString();

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    loading.value = true;
    error.value = null;
    data.value = null;
    final res = await _repo.loadExams();
    if (res.success && res.data != null) {
      data.value = res.data;
    } else {
      error.value = res.error ?? 'Could not load exam schedule.';
    }
    loading.value = false;
  }
}
