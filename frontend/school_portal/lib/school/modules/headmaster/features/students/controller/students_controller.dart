import 'dart:async';

import 'package:get/get.dart';

import '../../../../../config/headmaster_routes.dart';
import '../../../data/headmaster_repository.dart';
import '../models/student.dart';
// Imported only for the [StudentsRepository.pageSize] constant; data access goes
// through [HeadmasterRepository].
import '../models/students_repository.dart' show StudentsRepository;

/// Drives the Student Roster: search + grade/section filters + pagination.
class StudentsController extends GetxController {
  final HeadmasterRepository _repo;
  StudentsController({HeadmasterRepository? repo})
      : _repo = repo ?? Get.find<HeadmasterRepository>();

  static const grades = [
    'All Grades', '9th', '10th', '11th', '12th',
  ];
  static const sections = ['All Sections', 'Alpha', 'Beta', 'Gamma'];

  final loading = true.obs;
  final error = RxnString();
  final _all = <Student>[].obs;
  final query = ''.obs;
  final grade = 'All Grades'.obs;
  final section = 'All Sections'.obs;
  final page = 1.obs;

  Timer? _debounce;

  @override
  void onInit() {
    super.onInit();
    fetch();
  }

  int get totalPages =>
      (_all.length / StudentsRepository.pageSize).ceil().clamp(1, 999);

  List<Student> get pageItems {
    final start = (page.value - 1) * StudentsRepository.pageSize;
    return _all.skip(start).take(StudentsRepository.pageSize).toList();
  }

  void onSearch(String v) {
    query.value = v;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      page.value = 1;
      fetch();
    });
  }

  void selectGrade(String? v) {
    if (v == null || v == grade.value) return;
    grade.value = v;
    page.value = 1;
    fetch();
  }

  void selectSection(String? v) {
    if (v == null || v == section.value) return;
    section.value = v;
    page.value = 1;
    fetch();
  }

  void goToPage(int p) => page.value = p.clamp(1, totalPages);

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
