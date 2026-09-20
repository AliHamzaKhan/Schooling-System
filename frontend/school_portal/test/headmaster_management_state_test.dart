import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared/shared.dart';

import 'package:school_portal/school/modules/headmaster/data/headmaster_api_service.dart';
import 'package:school_portal/school/modules/headmaster/data/headmaster_repository.dart';
import 'package:school_portal/school/modules/headmaster/features/classes/controller/classes_controller.dart';
import 'package:school_portal/school/modules/headmaster/features/classes/models/classes_data.dart';
import 'package:school_portal/school/modules/headmaster/features/settings/controller/settings_controller.dart';
import 'package:school_portal/school/modules/headmaster/features/settings/models/school_profile.dart';
import 'package:school_portal/school/modules/headmaster/features/students/controller/students_controller.dart';
import 'package:school_portal/school/modules/headmaster/features/students/models/student.dart';
import 'package:school_portal/school/modules/headmaster/features/teachers/controller/teachers_controller.dart';
import 'package:school_portal/school/modules/headmaster/features/teachers/models/teacher.dart';
import 'package:school_portal/school/modules/headmaster/features/timetable/controller/timetable_controller.dart';
import 'package:school_portal/school/modules/headmaster/features/timetable/models/timetable_data.dart';

class _Store extends DataStoreService {}

void main() {
  setUp(() {
    Get.testMode = true;
    EnvConfig.bootstrap(Environment.debug);
    final api = ApiService(store: _Store());
    Get.put<HeadmasterRepository>(
      HeadmasterRepository(api: HeadmasterApiService(api: api)),
    );
  });
  tearDown(Get.reset);

  test('core management refreshes clear stale records on failure', () async {
    var fail = false;
    final classes = HeadmasterClassesController(
      loader: () async => fail
          ? ApiResponse.fail('Classes unavailable.')
          : ApiResponse.ok(
              const ClassDirectoryData(
                stats: [],
                grades: [
                  GradeGroup(
                    classId: 'class-1',
                    className: 'Grade 8',
                    grade: 8,
                    level: GradeLevel.middle,
                    sections: [],
                  ),
                ],
              ),
            ),
    );
    final students = StudentsController(
      loader: ({query = '', grade, section}) async => fail
          ? ApiResponse.fail('Students unavailable.')
          : ApiResponse.ok(const [
              Student(
                id: 'student-1',
                roll: '8-A-1',
                name: 'Test Learner',
                grade: '8',
                section: 'A',
                status: StudentStatus.active,
              ),
            ]),
    );
    final teachers = TeachersController(
      loader: ({query = ''}) async => fail
          ? ApiResponse.fail('Teachers unavailable.')
          : ApiResponse.ok(const [
              Teacher(
                id: 'teacher-1',
                name: 'Test Teacher',
                department: 'Mathematics',
                status: TeacherStatus.active,
                accent: AppColors.primary,
              ),
            ]),
    );
    final timetable = HeadmasterTimetableController(
      loader: () async => fail
          ? ApiResponse.fail('Timetable unavailable.')
          : ApiResponse.ok(const TimetableData(days: ['Monday'], slots: [])),
    );
    final settings = SettingsController(
      loader: () async => fail
          ? ApiResponse.fail('Settings unavailable.')
          : ApiResponse.ok(
              const SchoolProfile(
                id: 'school-1',
                name: 'Meri Taleem School',
                code: 'MTS',
                feeDueDay: 10,
              ),
            ),
    );

    await Future.wait([
      classes.load(),
      students.fetch(),
      teachers.fetch(),
      timetable.load(),
      settings.load(),
    ]);
    expect(classes.data.value?.grades.single.className, 'Grade 8');
    expect(students.pageItems.single.name, 'Test Learner');
    expect(teachers.results.single.name, 'Test Teacher');
    expect(timetable.data.value?.days, ['Monday']);
    expect(settings.name.value, 'Meri Taleem School');

    fail = true;
    await Future.wait([
      classes.load(),
      students.fetch(),
      teachers.fetch(),
      timetable.load(),
      settings.load(),
    ]);
    expect(classes.data.value, isNull);
    expect(students.pageItems, isEmpty);
    expect(teachers.results, isEmpty);
    expect(timetable.data.value, isNull);
    expect(settings.name.value, isEmpty);
    expect(classes.error.value, 'Classes unavailable.');
    expect(students.error.value, 'Students unavailable.');
    expect(teachers.error.value, 'Teachers unavailable.');
    expect(timetable.error.value, 'Timetable unavailable.');
    expect(settings.error.value, 'Settings unavailable.');
  });
}
