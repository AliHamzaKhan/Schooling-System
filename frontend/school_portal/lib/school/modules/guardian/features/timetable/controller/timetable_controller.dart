import 'package:get/get.dart';

import '../../../data/guardian_repository.dart';
import '../../../shared/controller/child_scoped_controller.dart';
import '../models/timetable_data.dart';

/// Loads the active child's weekly timetable; reloads on child switch via
/// [ChildScopedController]. Tracks which day column is selected ([selectedDay]),
/// defaulting to "today" whenever new data arrives.
class TimetableController extends ChildScopedController<TimetableData> {
  final GuardianRepository _repo;
  TimetableController({GuardianRepository? repo})
      : _repo = repo ?? Get.find<GuardianRepository>();

  final selectedDay = 0.obs;

  @override
  Future<TimetableData?> fetch(String childId) async {
    final res = await _repo.loadTimetable(childId);
    final data = res.success ? res.data : null;
    if (data != null) {
      final todayIdx = data.days.indexWhere((d) => d.isToday);
      selectedDay.value = todayIdx >= 0 ? todayIdx : 0;
    }
    return data;
  }

  void selectDay(int index) => selectedDay.value = index;
}
