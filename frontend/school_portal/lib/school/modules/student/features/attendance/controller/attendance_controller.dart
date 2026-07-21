import 'package:get/get.dart';

import '../../../data/student_repository.dart';
import '../models/attendance_data.dart';

class StudentAttendanceController extends GetxController {
  final StudentRepository _repo;
  StudentAttendanceController({StudentRepository? repo})
      : _repo = repo ?? Get.find<StudentRepository>();

  final loading = true.obs;
  final data = Rxn<AttendanceData>();

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    loading.value = true;
    final res = await _repo.loadAttendance();
    if (res.success) data.value = res.data;
    loading.value = false;
  }
}
