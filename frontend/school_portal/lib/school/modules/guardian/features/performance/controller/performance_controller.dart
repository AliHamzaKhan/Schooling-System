import 'package:get/get.dart';

import '../../../data/guardian_repository.dart';
import '../../../shared/controller/child_scoped_controller.dart';
import '../models/performance_data.dart';

class GuardianPerformanceController extends ChildScopedController<PerformanceData> {
  final GuardianRepository _repo;
  GuardianPerformanceController({GuardianRepository? repo})
      : _repo = repo ?? Get.find<GuardianRepository>();

  @override
  Future<PerformanceData?> fetch(String childId) async {
    final res = await _repo.loadPerformance(childId);
    return res.success ? res.data : null;
  }
}
