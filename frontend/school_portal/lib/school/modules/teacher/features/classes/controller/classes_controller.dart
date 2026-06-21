import 'package:get/get.dart';

import '../../../data/teacher_repository.dart';
import '../models/teaching_class.dart';

class ClassesController extends GetxController {
  final TeacherRepository _repo;
  ClassesController({TeacherRepository? repo})
      : _repo = repo ?? Get.find<TeacherRepository>();

  final loading = true.obs;
  final classes = <TeachingClass>[].obs;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    loading.value = true;
    final res = await _repo.loadClasses();
    if (res.success && res.data != null) classes.assignAll(res.data!);
    loading.value = false;
  }
}
