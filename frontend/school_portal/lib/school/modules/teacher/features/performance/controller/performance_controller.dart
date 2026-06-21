import 'package:get/get.dart';

import '../../../data/teacher_repository.dart';
import '../models/performance_data.dart';

class PerformanceController extends GetxController {
  final TeacherRepository _repo;
  PerformanceController({TeacherRepository? repo})
      : _repo = repo ?? Get.find<TeacherRepository>();

  final loading = true.obs;
  final student = Rxn<StudentDetail>();

  @override
  void onInit() {
    super.onInit();
    final arg = Get.arguments;
    load(arg is String ? arg : null);
  }

  Future<void> load(String? studentId) async {
    loading.value = true;
    final res = await _repo.loadStudentPerformance(studentId);
    if (res.success) student.value = res.data;
    loading.value = false;
  }
}
