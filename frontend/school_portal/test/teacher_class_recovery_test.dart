import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:school_portal/school/modules/teacher/data/teacher_repository.dart';
import 'package:school_portal/school/modules/teacher/features/classes/controller/classes_controller.dart';
import 'package:school_portal/school/modules/teacher/features/classes/models/my_class.dart';
import 'package:school_portal/school/modules/teacher/features/calendar/models/timetable_slot.dart';
import 'package:school_portal/school/modules/teacher/features/performance/controller/class_performance_controller.dart';
import 'package:school_portal/school/modules/teacher/features/performance/models/section_performance.dart';
import 'package:shared/shared.dart';

class _FailingTimetableRepository extends TeacherRepository {
  @override
  Future<ApiResponse<List<TeacherSlot>>> loadMyTimetable({
    DateTime? onDate,
  }) async => ApiResponse.fail('Timetable is unavailable.');
}

const _class = MyClass(
  sectionId: 'section-a',
  className: 'Grade 8',
  sectionName: 'A',
  studentCount: 2,
  subjects: ['Mathematics'],
  periodsPerWeek: 3,
);

void main() {
  setUp(() {
    Get.testMode = true;
    Get.put<ApiService>(ApiService(store: DataStoreService()));
  });
  tearDown(Get.reset);

  test(
    'classes reload clears stale sections before reporting a failure',
    () async {
      final controller = TeacherClassesController(
        repo: _FailingTimetableRepository(),
      )..classes.add(_class);

      await controller.load();

      expect(controller.classes, isEmpty);
      expect(controller.error.value, 'Timetable is unavailable.');
    },
  );

  test(
    'performance reload clears stale selected section and roster on failure',
    () async {
      final controller =
          ClassPerformanceController(repo: _FailingTimetableRepository())
            ..sections.add(_class)
            ..selectedSectionId.value = _class.sectionId
            ..rosters[_class.sectionId] = const SectionPerformance(
              sectionId: 'section-a',
              className: 'Grade 8',
              sectionName: 'A',
              students: [],
            );

      await controller.loadSections();

      expect(controller.sections, isEmpty);
      expect(controller.selectedSectionId.value, isNull);
      expect(controller.rosters, isEmpty);
      expect(controller.sectionsError.value, 'Timetable is unavailable.');
    },
  );
}
