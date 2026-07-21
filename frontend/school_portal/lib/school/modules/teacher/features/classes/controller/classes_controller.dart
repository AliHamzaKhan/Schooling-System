import 'package:get/get.dart';

import '../../../data/teacher_repository.dart';
import '../models/my_class.dart';

/// Drives "My Classes" off the teacher's real timetable, so the list is the
/// sections they actually teach rather than every class in the school.
class TeacherClassesController extends GetxController {
  final TeacherRepository _repo;
  TeacherClassesController({TeacherRepository? repo})
      : _repo = repo ?? Get.find<TeacherRepository>();

  final loading = true.obs;
  final error = RxnString();
  final classes = <MyClass>[].obs;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    loading.value = true;
    error.value = null;
    final res = await _repo.loadMyTimetable();
    if (res.success) {
      classes.assignAll(MyClass.fromSlots(res.data ?? const []));
    } else {
      error.value = res.error ?? 'Could not load your classes.';
    }
    loading.value = false;
  }
}
