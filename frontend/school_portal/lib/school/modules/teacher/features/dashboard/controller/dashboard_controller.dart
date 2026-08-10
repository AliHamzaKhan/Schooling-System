import 'package:get/get.dart';
import 'package:shared/shared.dart';

import '../../../data/teacher_repository.dart';
import '../models/dashboard_data.dart';

class TeacherDashboardController extends GetxController {
  final TeacherRepository _repo;
  TeacherDashboardController({TeacherRepository? repo})
      : _repo = repo ?? Get.find<TeacherRepository>();

  final loading = true.obs;
  final error = RxnString();
  final data = Rxn<DashboardData>();

  /// The signed-in teacher's display name, for the identity card. The
  /// dashboard payload carries a greeting rather than a name, and a greeting
  /// is not a name — "Good morning" in a name slot is worse than a fallback.
  String get teacherName {
    final full = Get.find<AuthService>().fullName?.trim() ?? '';
    return full.isEmpty ? 'Teacher' : full;
  }

  @override
  void onInit() {
    super.onInit();
    load();
  }

  // No "tick off" here: a to-do is derived from real outstanding work, so it
  // clears when the work is done (submissions graded, exam passes) — never
  // because a local checkbox was toggled.

  Future<void> load() async {
    loading.value = true;
    final res = await _repo.loadDashboard();
    if (res.success && res.data != null) {
      data.value = res.data;
    } else {
      error.value = res.error;
    }
    loading.value = false;
  }
}
