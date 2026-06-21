import 'package:get/get.dart';

import '../../../data/guardian_repository.dart';
import '../../../shared/controller/child_scoped_controller.dart';
import '../models/fee_data.dart';

class FeeController extends ChildScopedController<FeeData> {
  final GuardianRepository _repo;
  FeeController({GuardianRepository? repo})
      : _repo = repo ?? Get.find<GuardianRepository>();

  @override
  Future<FeeData?> fetch(String childId) async {
    final res = await _repo.loadFees(childId);
    return res.success ? res.data : null;
  }
}
