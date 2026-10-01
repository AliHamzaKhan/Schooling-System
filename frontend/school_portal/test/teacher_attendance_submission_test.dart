import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:school_portal/school/modules/teacher/data/teacher_repository.dart';
import 'package:school_portal/school/modules/teacher/features/attendance/controller/attendance_controller.dart';
import 'package:school_portal/school/modules/teacher/features/attendance/models/attendance_models.dart';
import 'package:shared/shared.dart';

class _FailingTeacherRepository extends TeacherRepository {
  @override
  Future<ApiResponse<List<AttendanceStudent>>> loadAttendanceStudents(
    String classId,
  ) async => ApiResponse.fail('Roster is unavailable.');

  @override
  Future<ApiResponse<void>> saveAttendanceMarks(
    String sectionId,
    Map<String, String> marks,
  ) async => ApiResponse.fail('Attendance could not be saved.');
}

void main() {
  setUpAll(() {
    Get.testMode = true;
    Get.put<ApiService>(ApiService(store: DataStoreService()));
  });

  test(
    'attendance submit keeps the route open and exposes save failure',
    () async {
      final controller = AttendanceMarkController(
        repo: _FailingTeacherRepository(),
        initialClassInfo: const AttendanceClass(
          id: 'section-1',
          subject: 'Mathematics',
          grade: 'Grade 8',
          students: 1,
          icon: AppIcons.functionsRounded,
          color: AppColors.primary,
        ),
      );
      controller.onInit();
      controller.marks['student-1'] = AttendanceMark.present;

      final result = await controller.submit();

      expect(result, isFalse);
      expect(controller.submitting.value, isFalse);
      expect(controller.submitError.value, 'Attendance could not be saved.');
    },
  );

  test('attendance marking rejects a route without a selected class', () {
    final controller = AttendanceMarkController(
      repo: _FailingTeacherRepository(),
    );

    controller.onInit();

    expect(controller.classInfo, isNull);
    expect(controller.loading.value, isFalse);
    expect(controller.error.value, contains('Choose a class'));
  });

  test('an empty register is not sent to the server', () async {
    var saves = 0;
    final controller = AttendanceMarkController(
      repo: _CountingTeacherRepository(() => saves++),
      initialClassInfo: const AttendanceClass(
        id: 'section-1',
        subject: 'Daily register',
        grade: 'Grade 1 A',
        students: 1,
        icon: AppIcons.functionsRounded,
        color: AppColors.primary,
      ),
    );
    controller.onInit();
    controller.marks['student-1'] = AttendanceMark.unmarked;

    expect(await controller.submit(), isFalse);
    expect(saves, 0);
    expect(
      controller.submitError.value,
      'Mark at least one student before submitting.',
    );
  });
}

class _CountingTeacherRepository extends _FailingTeacherRepository {
  _CountingTeacherRepository(this.onSave);
  final void Function() onSave;

  @override
  Future<ApiResponse<void>> saveAttendanceMarks(
    String sectionId,
    Map<String, String> marks,
  ) async {
    onSave();
    return ApiResponse.fail('unexpected save');
  }
}
