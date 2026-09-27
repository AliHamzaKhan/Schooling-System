import 'package:get/get.dart';

import '../../../data/student_repository.dart';
import '../models/timetable_data.dart';

/// Loads the student's own weekly timetable and tracks the selected day.
class StudentTimetableController extends GetxController {
  final StudentRepository _repo;
  StudentTimetableController({StudentRepository? repo})
    : _repo = repo ?? Get.find<StudentRepository>();

  final loading = true.obs;
  final error = RxnString();
  final days = <TimetableDay>[].obs;
  final selectedIndex = 0.obs;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    loading.value = true;
    error.value = null;
    days.clear();
    selectedIndex.value = 0;
    final res = await _repo.loadTimetable();
    if (res.success) {
      days.assignAll(res.data ?? const []);
      // Default to today's column when present.
      final todayIdx = days.indexWhere((d) => d.isToday);
      selectedIndex.value = todayIdx >= 0 ? todayIdx : 0;
    } else {
      error.value = res.error ?? 'Could not load your timetable.';
    }
    loading.value = false;
  }

  void selectDay(int i) => selectedIndex.value = i;

  TimetableDay? get selectedDay =>
      (days.isEmpty || selectedIndex.value >= days.length)
      ? null
      : days[selectedIndex.value];
}
