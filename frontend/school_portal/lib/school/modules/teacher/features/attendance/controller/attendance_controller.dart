import 'package:get/get.dart';
import 'package:shared/shared.dart';

import '../../../data/teacher_repository.dart';
import '../models/attendance_models.dart';

/// Drives the class-list (entry-point) view.
class TeacherAttendanceController extends GetxController {
  final TeacherRepository _repo;
  TeacherAttendanceController({TeacherRepository? repo})
      : _repo = repo ?? Get.find<TeacherRepository>();

  final loading = true.obs;
  final classes = <AttendanceClass>[].obs;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    loading.value = true;
    final res = await _repo.loadAttendanceClasses();
    if (res.success && res.data != null) classes.assignAll(res.data!);
    loading.value = false;
  }
}

/// Drives the per-class marking screen. Created fresh per-route so state
/// resets when the teacher backs out and re-enters.
class AttendanceMarkController extends GetxController {
  final TeacherRepository _repo;
  AttendanceMarkController({TeacherRepository? repo})
      : _repo = repo ?? Get.find<TeacherRepository>();

  late final AttendanceClass classInfo;
  final loading = true.obs;
  final students = <AttendanceStudent>[].obs;
  final marks = <String, AttendanceMark>{}.obs;
  final query = ''.obs;

  @override
  void onInit() {
    super.onInit();
    final arg = Get.arguments;
    classInfo = arg is AttendanceClass ? arg : _fallback;
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
        .where((s) =>
            s.name.toLowerCase().contains(q) ||
            s.id.toLowerCase().contains(q))
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

  Future<void> submit() async {
    await _repo.saveAttendanceMarks(
      classInfo.id,
      {for (final e in marks.entries) e.key: e.value.name},
    );
    Get.back<bool>(result: true);
    Get.snackbar('Submitted',
        'Attendance recorded for ${classInfo.subject} — ${classInfo.grade}.',
        snackPosition: SnackPosition.BOTTOM);
  }

  Future<void> load() async {
    loading.value = true;
    final res = await _repo.loadAttendanceStudents(classInfo.id);
    if (res.success && res.data != null) students.assignAll(res.data!);
    loading.value = false;
  }

  static const _fallback = AttendanceClass(
    id: 'MATH-G8',
    subject: 'Mathematics',
    grade: 'Grade 8',
    students: 28,
    icon: AppIcons.functionsRounded,
    color: AppColors.primary,
  );
}
