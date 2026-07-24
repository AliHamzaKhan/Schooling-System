import 'dart:async';

import 'package:get/get.dart';

import '../../../../../config/headmaster_routes.dart';
import '../../../../../widgets/filter_sheet.dart';
import '../../../data/headmaster_repository.dart';
import '../models/student.dart';

/// Drives the Student Roster: search + grade/section filters + pagination.
class StudentsController extends GetxController {
  final HeadmasterRepository _repo;
  StudentsController({HeadmasterRepository? repo})
      : _repo = repo ?? Get.find<HeadmasterRepository>();

  /// Student cards shown per page.
  static const pageSize = 4;

  static const anyGrade = 'All Grades';
  static const anySection = 'All Sections';

  static const grades = [
    anyGrade, '9th', '10th', '11th', '12th',
  ];
  static const sections = [anySection, 'Alpha', 'Beta', 'Gamma'];

  final loading = true.obs;
  final error = RxnString();
  final _all = <Student>[].obs;
  final query = ''.obs;
  final grade = anyGrade.obs;
  final section = anySection.obs;
  final page = 1.obs;

  Timer? _debounce;

  @override
  void onInit() {
    super.onInit();
    fetch();
  }

  int get totalPages =>
      (_all.length / pageSize).ceil().clamp(1, 999);

  List<Student> get pageItems {
    final start = (page.value - 1) * pageSize;
    return _all.skip(start).take(pageSize).toList();
  }

  void onSearch(String v) {
    query.value = v;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      page.value = 1;
      fetch();
    });
  }

  void goToPage(int p) => page.value = p.clamp(1, totalPages);

  /// Number of filters narrowing the roster — drives the filter button badge.
  int get activeFilterCount =>
      (grade.value == anyGrade ? 0 : 1) + (section.value == anySection ? 0 : 1);

  /// Opens the grade/section filter sheet. Both sections are single-select;
  /// an empty selection means "no filter" and maps back to the sentinel value.
  Future<void> openFilter() async {
    final result = await showFilterSheet(
      title: 'Filter Students',
      sections: [
        FilterSection(
          key: 'grade',
          title: 'Grade',
          options: grades.skip(1).toList(),
          multiSelect: false,
          initial: grade.value == anyGrade ? const {} : {grade.value},
        ),
        FilterSection(
          key: 'section',
          title: 'Section',
          options: sections.skip(1).toList(),
          multiSelect: false,
          initial: section.value == anySection ? const {} : {section.value},
        ),
      ],
    );
    if (result == null) return;
    final pickedGrade = result['grade'] ?? const <String>{};
    final pickedSection = result['section'] ?? const <String>{};
    final nextGrade = pickedGrade.isEmpty ? anyGrade : pickedGrade.first;
    final nextSection = pickedSection.isEmpty ? anySection : pickedSection.first;
    if (nextGrade == grade.value && nextSection == section.value) return;
    grade.value = nextGrade;
    section.value = nextSection;
    page.value = 1;
    await fetch();
  }

  Future<void> fetch() async {
    loading.value = true;
    error.value = null;
    final res = await _repo.loadStudents(
        query: query.value, grade: grade.value, section: section.value);
    if (res.success && res.data != null) {
      _all.assignAll(res.data!);
    } else {
      error.value = res.error ?? 'Could not load students.';
    }
    loading.value = false;
  }

  /// Open the full-page student registration flow and refresh the roster if
  /// the admission succeeded.
  Future<void> enrollStudentFlow() async {
    final ok = await Get.toNamed(HeadmasterRoutes.studentRegistration);
    if (ok == true) await fetch();
  }

  @override
  void onClose() {
    _debounce?.cancel();
    super.onClose();
  }
}
