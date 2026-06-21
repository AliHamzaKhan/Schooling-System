import 'package:get/get.dart';

import '../../../data/guardian_repository.dart';
import '../../../shared/controller/child_scoped_controller.dart';
import '../models/homework_data.dart';

class HomeworkController extends ChildScopedController<HomeworkData> {
  final GuardianRepository _repo;
  HomeworkController({GuardianRepository? repo})
      : _repo = repo ?? Get.find<GuardianRepository>();

  @override
  Future<HomeworkData?> fetch(String childId) async {
    final res = await _repo.loadHomework(childId);
    return res.success ? res.data : null;
  }
}
