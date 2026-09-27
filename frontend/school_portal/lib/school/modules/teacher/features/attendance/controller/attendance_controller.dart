import 'package:get/get.dart';

import '../../../data/teacher_repository.dart';
import '../models/attendance_models.dart';

/// Drives the class-list (entry-point) view.
class TeacherAttendanceController extends GetxController {
  final TeacherRepository _repo;
  TeacherAttendanceController({TeacherRepository? repo})
    : _repo = repo ?? Get.find<TeacherRepository>();

  final loading = true.obs;
  final classes = <AttendanceClass>[].obs;
  final error = RxnString();

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    loading.value = true;
    error.value = null;
    classes.clear();
    final res = await _repo.loadAttendanceClasses();
    if (res.success && res.data != null) {
      classes.assignAll(res.data!);
    } else {
      error.value = res.error ?? 'Could not load attendance classes.';
    }
    loading.value = false;
  }
}

/// Drives the per-class marking screen. Created fresh per-route so state
/// resets when the teacher backs out and re-enters.
class AttendanceMarkController extends GetxController {
  final TeacherRepository _repo;
  final AttendanceClass? _initialClassInfo;
  AttendanceMarkController({
    TeacherRepository? repo,
    AttendanceClass? initialClassInfo,
  }) : _repo = repo ?? Get.find<TeacherRepository>(),
       _initialClassInfo = initialClassInfo;

  AttendanceClass? classInfo;
  final loading = true.obs;
  final submitting = false.obs;
  final students = <AttendanceStudent>[].obs;
  final marks = <String, AttendanceMark>{}.obs;
  final query = ''.obs;
  final error = RxnString();
  final submitError = RxnString();

  @override
  void onInit() {
    super.onInit();
    final arg = Get.arguments;
    classInfo = _initialClassInfo ?? (arg is AttendanceClass ? arg : null);
    if (classInfo == null) {
      error.value =
          'Choose a class from the attendance list before marking attendance.';
      loading.value = false;
      return;
    }
    load();
  }

  int get total => students.length;
  int get present =>
      marks.values.where((m) => m == AttendanceMark.present).length;
  int get absent =>
      marks.values.where((m) => m == AttendanceMark.absent).length;

  List<AttendanceStudent> get filtered {
    if (query.value.isEmpty) return students;
    final q = query.value.toLowerCase();
    return students
        .where(
          (s) =>
              s.name.toLowerCase().contains(q) ||
              s.id.toLowerCase().contains(q),
        )
        .toList();
  }

  AttendanceMark markFor(String id) => marks[id] ?? AttendanceMark.unmarked;

  void setMark(String id, AttendanceMark mark) {
    final current = marks[id];
    marks[id] = current == mark ? AttendanceMark.unmarked : mark;
  }

  void markAllPresent() {
    for (final s in students) {
      marks[s.id] = AttendanceMark.present;
    }
  }

  void onSearch(String v) => query.value = v;

  Future<bool> submit() async {
    if (submitting.value) return false;
    final selectedClass = classInfo;
    if (selectedClass == null) {
      submitError.value = 'Choose a class before submitting attendance.';
      return false;
    }
    submitting.value = true;
    submitError.value = null;
    final res = await _repo.saveAttendanceMarks(selectedClass.id, {
      for (final e in marks.entries) e.key: e.value.name,
    });
    submitting.value = false;
    if (!res.success) {
      submitError.value = res.error ?? 'Could not save attendance. Try again.';
      return false;
    }
    Get.back<bool>(result: true);
    Get.snackbar(
      'Submitted',
      'Attendance recorded for ${selectedClass.subject} — ${selectedClass.grade}.',
      snackPosition: SnackPosition.BOTTOM,
    );
    return true;
  }

  Future<void> load() async {
    loading.value = true;
    error.value = null;
    students.clear();
    marks.clear();
    final selectedClass = classInfo;
    if (selectedClass == null) {
      error.value =
          'Choose a class from the attendance list before marking attendance.';
      loading.value = false;
      return;
    }
    final res = await _repo.loadAttendanceStudents(selectedClass.id);
    if (res.success && res.data != null) {
      students.assignAll(res.data!);
    } else {
      error.value = res.error ?? 'Could not load class attendance.';
    }
    loading.value = false;
  }
}
