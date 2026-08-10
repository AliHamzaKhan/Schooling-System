import 'package:get/get.dart';
import 'package:shared/shared.dart';

import '../../../data/student_repository.dart';
import '../../assignments/models/assignment.dart';
import '../../attendance/models/attendance_data.dart';
import '../../exams/models/exam.dart';

/// Aggregates the student's live assignments, exams and attendance into a single
/// at-a-glance dashboard. Reuses the per-feature repository reads, so no new
/// backend endpoint is required.
class StudentDashboardController extends GetxController {
  final StudentRepository _repo;
  StudentDashboardController({StudentRepository? repo})
      : _repo = repo ?? Get.find<StudentRepository>();

  final loading = true.obs;
  final error = RxnString();
  final assignments = Rxn<AssignmentsData>();
  final exams = Rxn<ExamsData>();
  final attendance = Rxn<AttendanceData>();

  @override
  void onInit() {
    super.onInit();
    load();
  }

  /// The signed-in student's first name, for the greeting.
  String get firstName {
    final full = fullName;
    return full.isEmpty ? 'there' : full.split(RegExp(r'\s+')).first;
  }

  /// The student's display name, for the identity card.
  String get fullName =>
      (Get.find<AuthService>().currentUser.value?['full_name'] as String? ?? '')
          .trim();

  /// The line under the name. `/auth/me` carries no class or section for a
  /// student, so this says what is actually known rather than inventing a
  /// grade — when the profile payload gains those fields, this getter is the
  /// only place that changes.
  String get roleLine => 'Student';

  /// Days until the next exam, or null when none is scheduled.
  int? get daysToNextExam => nextExam?.days;

  Future<void> load() async {
    loading.value = true;
    error.value = null;
    final a = await _repo.loadAssignments();
    final e = await _repo.loadExams();
    final at = await _repo.loadAttendance();
    if (a.success) assignments.value = a.data;
    if (e.success) exams.value = e.data;
    if (at.success) attendance.value = at.data;
    // Only surface a hard error if every section failed.
    if (!a.success && !e.success && !at.success) {
      error.value = a.error ?? 'Could not load your dashboard.';
    }
    loading.value = false;
  }

  /// Up to three not-yet-submitted assignments (soonest first, as returned).
  List<StudentAssignment> get dueSoon =>
      (assignments.value?.assignments ?? const <StudentAssignment>[])
          .where((x) => x.status != StudentAssignmentStatus.submitted)
          .take(3)
          .toList();

  int get attendancePercent => attendance.value?.monthlyAverage ?? 0;
  int get toDoCount => assignments.value?.summary.toDo ?? 0;
  int get examsThisMonth => exams.value?.comingThisMonth ?? 0;

  /// The next scheduled exam countdown, when one exists.
  ExamCountdown? get nextExam {
    final n = exams.value?.next;
    if (n == null || n.title.isEmpty) return null;
    return n;
  }

  /// The timeline entry behind [nextExam], for navigating to its detail.
  UpcomingExam? get nextExamEntry => exams.value?.nextEntry;
}
