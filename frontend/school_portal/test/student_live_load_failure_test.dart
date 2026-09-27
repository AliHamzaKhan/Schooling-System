import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:school_portal/school/modules/student/data/student_repository.dart';
import 'package:school_portal/school/modules/student/features/assignments/controller/assignments_controller.dart';
import 'package:school_portal/school/modules/student/features/assignments/models/assignment.dart';
import 'package:school_portal/school/modules/student/features/attendance/controller/attendance_controller.dart';
import 'package:school_portal/school/modules/student/features/attendance/models/attendance_data.dart';
import 'package:school_portal/school/modules/student/features/exams/controller/exams_controller.dart';
import 'package:school_portal/school/modules/student/features/exams/models/exam.dart';
import 'package:shared/shared.dart';

class _FailingStudentRepository extends StudentRepository {
  @override
  Future<ApiResponse<AttendanceData>> loadAttendance() async =>
      ApiResponse.fail('Attendance service is unavailable.');

  @override
  Future<ApiResponse<AssignmentsData>> loadAssignments() async =>
      ApiResponse.fail('Assignments service is unavailable.');

  @override
  Future<ApiResponse<ExamsData>> loadExams() async =>
      ApiResponse.fail('Exams service is unavailable.');
}

void main() {
  setUpAll(() {
    Get.testMode = true;
    Get.put<ApiService>(ApiService(store: DataStoreService()));
  });

  test(
    'attendance failure clears old data and exposes a retryable error',
    () async {
      final controller = StudentAttendanceController(
        repo: _FailingStudentRepository(),
      );
      controller.data.value = const AttendanceData(
        monthlyAverage: 95,
        deltaPercent: 1,
        week: [],
        recentAbsences: [],
        lateMarks: [],
      );

      await controller.load();

      expect(controller.loading.value, isFalse);
      expect(controller.data.value, isNull);
      expect(controller.error.value, 'Attendance service is unavailable.');
    },
  );

  test(
    'assignment failure clears old data and exposes a retryable error',
    () async {
      final controller = StudentAssignmentsController(
        repo: _FailingStudentRepository(),
      );
      controller.data.value = const AssignmentsData(
        summary: AssignmentsSummary(
          completed: 1,
          total: 1,
          inProgress: 0,
          toDo: 0,
        ),
        assignments: [],
      );

      await controller.load();

      expect(controller.loading.value, isFalse);
      expect(controller.data.value, isNull);
      expect(controller.error.value, 'Assignments service is unavailable.');
    },
  );

  test('exam failure clears old data and exposes a retryable error', () async {
    final controller = StudentExamsController(
      repo: _FailingStudentRepository(),
    );
    controller.data.value = const ExamsData(
      comingThisMonth: 1,
      next: ExamCountdown(
        days: 1,
        hours: 0,
        title: 'Mathematics',
        date: '2026-10-01',
        time: '09:00',
        location: 'Hall A',
      ),
      timeline: [],
    );

    await controller.load();

    expect(controller.loading.value, isFalse);
    expect(controller.data.value, isNull);
    expect(controller.error.value, 'Exams service is unavailable.');
  });
}
