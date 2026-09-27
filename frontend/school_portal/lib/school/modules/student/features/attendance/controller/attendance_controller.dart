import 'package:get/get.dart';

import '../../../data/student_repository.dart';
import '../models/attendance_data.dart';

class StudentAttendanceController extends GetxController {
  final StudentRepository _repo;
  StudentAttendanceController({StudentRepository? repo})
    : _repo = repo ?? Get.find<StudentRepository>();

  final loading = true.obs;
  final data = Rxn<AttendanceData>();
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
    final res = await _repo.loadAttendance();
    if (res.success && res.data != null) {
      data.value = res.data;
    } else {
      error.value = res.error ?? 'Could not load attendance.';
    }
    loading.value = false;
  }
}
