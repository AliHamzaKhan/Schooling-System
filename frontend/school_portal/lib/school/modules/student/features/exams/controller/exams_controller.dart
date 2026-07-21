import 'package:get/get.dart';

import '../../../data/student_repository.dart';
import '../models/exam.dart';

class StudentExamsController extends GetxController {
  final StudentRepository _repo;
  StudentExamsController({StudentRepository? repo})
      : _repo = repo ?? Get.find<StudentRepository>();

  final loading = true.obs;
  final data = Rxn<ExamsData>();

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    loading.value = true;
    final res = await _repo.loadExams();
    if (res.success) data.value = res.data;
    loading.value = false;
  }
}
