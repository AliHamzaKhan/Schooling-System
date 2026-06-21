import 'package:get/get.dart';

import '../../../data/student_repository.dart';
import '../models/assignment.dart';

class AssignmentsController extends GetxController {
  final StudentRepository _repo;
  AssignmentsController({StudentRepository? repo})
      : _repo = repo ?? Get.find<StudentRepository>();

  final loading = true.obs;
  final data = Rxn<AssignmentsData>();

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    loading.value = true;
    final res = await _repo.loadAssignments();
    if (res.success) data.value = res.data;
    loading.value = false;
  }
}
