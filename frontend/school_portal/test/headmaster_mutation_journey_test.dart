import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared/shared.dart';

import 'package:school_portal/school/modules/headmaster/data/headmaster_api_service.dart';
import 'package:school_portal/school/modules/headmaster/data/headmaster_repository.dart';
import 'package:school_portal/school/modules/headmaster/features/classes/controller/classes_controller.dart';
import 'package:school_portal/school/modules/headmaster/features/classes/models/classes_data.dart';
import 'package:school_portal/school/modules/headmaster/features/settings/controller/settings_controller.dart';
import 'package:school_portal/school/modules/headmaster/features/settings/models/school_profile.dart';
import 'package:school_portal/school/modules/headmaster/features/timetable/controller/timetable_controller.dart';
import 'package:school_portal/school/modules/headmaster/features/timetable/models/timetable_data.dart';

/// Fake gateway that records mutation/reload calls and can be flipped to fail,
/// so the create/author/save journeys are exercised without a backend.
class _MutationRepo extends HeadmasterRepository {
  _MutationRepo()
    : super(
        api: HeadmasterApiService(api: ApiService(store: DataStoreService())),
      );

  bool failMutation = false;
  int classLoads = 0;
  int timetableLoads = 0;
  int profileLoads = 0;
  int classCreates = 0;
  int sectionCreates = 0;
  int profileSaves = 0;

  @override
  Future<ApiResponse<ClassDirectoryData>> loadClasses() async {
    classLoads++;
    return ApiResponse.ok(
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
    );
  }

  @override
  Future<ApiResponse<dynamic>> createClass({
    required String name,
    int? level,
    String? roomNo,
  }) async {
    classCreates++;
    return failMutation
        ? ApiResponse.fail('Backend rejected class.')
        : ApiResponse<dynamic>.ok(true);
  }

  @override
  Future<ApiResponse<dynamic>> createSection({
    required String classId,
    required String name,
    String? roomNo,
  }) async {
    sectionCreates++;
    return failMutation
        ? ApiResponse.fail('Backend rejected section.')
        : ApiResponse<dynamic>.ok(true);
  }

  @override
  Future<ApiResponse<TimetableData>> loadTimetable() async {
    timetableLoads++;
    return ApiResponse.ok(const TimetableData(days: ['Monday'], slots: []));
  }

  @override
  Future<ApiResponse<SchoolProfile>> loadSchoolProfile() async {
    profileLoads++;
    return ApiResponse.ok(
      const SchoolProfile(
        id: 'school-1',
        name: 'Meri Taleem School',
        code: 'MTS',
        feeDueDay: 10,
      ),
    );
  }

  @override
  Future<ApiResponse<SchoolProfile>> saveSchoolProfile({
    required String name,
    String? logoUrl,
    String? uniformColor,
    int? feeDueDay,
    int? salaryDay,
  }) async {
    profileSaves++;
    return failMutation
        ? ApiResponse.fail('Backend rejected settings.')
        : ApiResponse.ok(
            SchoolProfile(
              id: 'school-1',
              name: name,
              code: 'MTS',
              logoUrl: logoUrl,
              uniformColor: uniformColor,
              feeDueDay: feeDueDay,
              salaryDay: salaryDay,
            ),
          );
  }
}

void main() {
  late _MutationRepo repo;

  setUp(() {
    Get.testMode = true;
    EnvConfig.bootstrap(Environment.debug);
    repo = _MutationRepo();
    Get.put<HeadmasterRepository>(repo);
  });
  tearDown(Get.reset);

  test('class creation validates, blocks duplicates and refreshes', () async {
    final classes = HeadmasterClassesController(repo: repo);
    await classes.load();
    expect(repo.classLoads, 1);

    // Empty name is caught before any backend call, and nothing reloads.
    expect(await classes.submitNewClass(name: '   '), 'Class name is required');
    expect(repo.classCreates, 0);
    expect(repo.classLoads, 1);

    // Duplicate (case-insensitive) is rejected without a backend call.
    expect(
      await classes.submitNewClass(name: 'grade 8'),
      'A class named "grade 8" already exists',
    );
    expect(repo.classCreates, 0);

    // A valid create returns null and refreshes the directory.
    expect(
      await classes.submitNewClass(name: 'Grade 9', level: '9', roomNo: 'B-12'),
      isNull,
    );
    expect(repo.classCreates, 1);
    expect(repo.classLoads, 2);

    // A backend rejection surfaces its message and does not reload.
    repo.failMutation = true;
    expect(
      await classes.submitNewClass(name: 'Grade 10'),
      'Backend rejected class.',
    );
    expect(repo.classLoads, 2);
  });

  test('section creation validates and refreshes on success', () async {
    final classes = HeadmasterClassesController(repo: repo);
    await classes.load();

    expect(
      await classes.submitNewSection(classId: 'class-1', name: '  '),
      'Section name is required',
    );
    expect(repo.sectionCreates, 0);

    expect(
      await classes.submitNewSection(classId: 'class-1', name: 'A'),
      isNull,
    );
    expect(repo.sectionCreates, 1);
    expect(repo.classLoads, 2);

    repo.failMutation = true;
    expect(
      await classes.submitNewSection(classId: 'class-1', name: 'B'),
      'Backend rejected section.',
    );
    expect(repo.classLoads, 2);
  });

  test('timetable class authoring validates and refreshes', () async {
    final timetable = HeadmasterTimetableController(repo: repo);
    await timetable.load();
    expect(repo.timetableLoads, 1);

    expect(await timetable.submitNewClass(name: ''), 'Class name is required');
    expect(repo.classCreates, 0);

    expect(await timetable.submitNewClass(name: 'Grade 9', level: '9'), isNull);
    expect(repo.classCreates, 1);
    expect(repo.timetableLoads, 2);

    repo.failMutation = true;
    expect(
      await timetable.submitNewClass(name: 'Grade 10'),
      'Backend rejected class.',
    );
    expect(repo.timetableLoads, 2);
  });

  test('settings save validates fee/salary days and persists', () async {
    final settings = SettingsController(repo: repo);
    await settings.load();
    expect(settings.name.value, 'Meri Taleem School');

    // Empty name blocks the save before any backend call.
    settings.name.value = '   ';
    expect(await settings.submitSave(), 'School name cannot be empty.');
    expect(repo.profileSaves, 0);

    // Out-of-range fee/salary days are rejected with clear messages.
    settings.name.value = 'Meri Taleem School';
    settings.feeDueDay.value = '40';
    expect(await settings.submitSave(), 'Enter a fee day between 1 and 31.');
    settings.feeDueDay.value = '10';
    settings.salaryDay.value = '0';
    expect(await settings.submitSave(), 'Enter a salary day between 1 and 31.');
    expect(repo.profileSaves, 0);

    // A valid save returns null, clears the saving flag and refills the form
    // from the persisted record.
    settings.salaryDay.value = '1';
    settings.name.value = 'Renamed Academy';
    expect(await settings.submitSave(), isNull);
    expect(repo.profileSaves, 1);
    expect(settings.saving.value, isFalse);
    expect(settings.name.value, 'Renamed Academy');

    // A backend rejection surfaces its message.
    repo.failMutation = true;
    expect(await settings.submitSave(), 'Backend rejected settings.');
    expect(settings.saving.value, isFalse);
  });
}
