import 'package:get/get.dart';

import '../../../data/headmaster_repository.dart';
import '../models/attendance_data.dart';

/// Drives Attendance Overview: range toggle + data load.
class AttendanceController extends GetxController {
  final HeadmasterRepository _repo;
  AttendanceController({HeadmasterRepository? repo})
      : _repo = repo ?? Get.find<HeadmasterRepository>();

  final loading = true.obs;
  final error = RxnString();
  final data = Rxn<AttendanceData>();
  final range = AttendanceRange.month.obs;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  void selectRange(AttendanceRange r) {
    if (range.value == r) return;
    range.value = r;
    load();
  }

  Future<void> load() async {
    loading.value = true;
    error.value = null;
    final res = await _repo.loadAttendance(range.value);
    if (res.success && res.data != null) {
      data.value = res.data;
    } else {
      error.value = res.error ?? 'Could not load attendance.';
    }
    loading.value = false;
  }
}
