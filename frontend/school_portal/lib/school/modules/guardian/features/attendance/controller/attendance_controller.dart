import 'package:get/get.dart';

import '../../../data/guardian_repository.dart';
import '../../../shared/controller/child_scoped_controller.dart';
import '../models/attendance_data.dart';

class GuardianAttendanceController
    extends ChildScopedController<GuardianAttendanceData> {
  final GuardianRepository _repo;
  GuardianAttendanceController({GuardianRepository? repo})
      : _repo = repo ?? Get.find<GuardianRepository>();

  @override
  Future<GuardianAttendanceData?> fetch(String childId) async {
    final res = await _repo.loadAttendance(childId);
    return res.success ? res.data : null;
  }
}
