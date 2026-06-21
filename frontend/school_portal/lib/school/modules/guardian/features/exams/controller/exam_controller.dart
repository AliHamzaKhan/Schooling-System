import 'package:get/get.dart';

import '../../../data/guardian_repository.dart';
import '../../../shared/controller/child_scoped_controller.dart';
import '../models/exam_data.dart';

class ExamController extends ChildScopedController<ExamData> {
  final GuardianRepository _repo;
  ExamController({GuardianRepository? repo})
      : _repo = repo ?? Get.find<GuardianRepository>();

  @override
  Future<ExamData?> fetch(String childId) async {
    final res = await _repo.loadExams(childId);
    return res.success ? res.data : null;
  }
}
