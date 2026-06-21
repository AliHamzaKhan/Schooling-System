import 'package:get/get.dart';

import '../../../data/teacher_repository.dart';
import '../models/dashboard_data.dart';

class DashboardController extends GetxController {
  final TeacherRepository _repo;
  DashboardController({TeacherRepository? repo})
      : _repo = repo ?? Get.find<TeacherRepository>();

  final loading = true.obs;
  final error = RxnString();
  final data = Rxn<DashboardData>();
  final completed = <String>{}.obs;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  bool isDone(TodoItem t) => t.done || completed.contains(t.id);

  void toggle(TodoItem t) {
    if (completed.contains(t.id)) {
      completed.remove(t.id);
    } else {
      completed.add(t.id);
    }
  }

  Future<void> load() async {
    loading.value = true;
    final res = await _repo.loadDashboard();
    if (res.success && res.data != null) {
      data.value = res.data;
      completed.assignAll(res.data!.todos.where((t) => t.done).map((t) => t.id));
    } else {
      error.value = res.error;
    }
    loading.value = false;
  }
}
