import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared/shared.dart';

import '../../../../../widgets/action_form_sheet.dart';
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

  /// Admit a new student and enroll them into a section in one step.
  Future<void> enrollStudentFlow() async {
    final sectionsRes = await _repo.loadSectionOptions();
    final sections = sectionsRes.data ?? const [];
    if (sections.isEmpty) {
      Get.snackbar('No sections yet',
          'Create a class and section before enrolling students.',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }
    final name = TextEditingController();
    final email = TextEditingController();
    final password = TextEditingController();
    final selectedSection = Rxn<String>(sections.first.id);

    final ok = await showActionFormSheet(
      title: 'Enroll Student',
      submitLabel: 'Admit & Enroll',
      fields: [
        GlassInput(label: 'Full name', hint: 'Student name', controller: name),
        GlassInput(
          label: 'Email',
          hint: 'student@school.edu',
          controller: email,
          keyboardType: TextInputType.emailAddress,
        ),
        GlassInput(
          label: 'Temporary password',
          hint: 'At least 8 characters',
          controller: password,
          obscureText: true,
        ),
        Obx(() => ActionDropdownField<String>(
              label: 'Section',
              hint: 'Select a section',
              value: selectedSection.value,
              items: [
                for (final s in sections)
                  DropdownMenuItem(value: s.id, child: Text(s.label)),
              ],
              onChanged: (v) => selectedSection.value = v,
            )),
      ],
      onSubmit: () async {
        if (name.text.trim().isEmpty) return 'Full name is required';
        if (!email.text.contains('@')) return 'A valid email is required';
        if (password.text.trim().length < 8) {
          return 'Password must be at least 8 characters';
        }
        final sectionId = selectedSection.value;
        if (sectionId == null) return 'Select a section';
        final created = await _repo.createUser(
            email: email.text.trim(),
            password: password.text.trim(),
            fullName: name.text.trim(),
            role: 'student');
        if (!created.success) {
          return created.error ?? 'Could not create the student';
        }
        final studentId = '${(created.data as Map)['id']}';
        final enrolled = await _repo.enrollStudent(
            sectionId: sectionId, studentId: studentId);
        return enrolled.success
            ? null
            : (enrolled.error ?? 'Student created, but enrollment failed');
      },
    );
    if (ok == true) {
      Get.snackbar('Student enrolled', 'The student was admitted and enrolled.',
          snackPosition: SnackPosition.BOTTOM);
      await fetch();
    }
  }

  @override
  void onClose() {
    _debounce?.cancel();
    super.onClose();
  }
}
