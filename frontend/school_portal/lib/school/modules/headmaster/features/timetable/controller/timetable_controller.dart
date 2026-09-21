import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared/shared.dart';

import '../../../../../widgets/action_form_sheet.dart';
import '../../../data/headmaster_repository.dart';
import '../models/timetable_data.dart';

typedef TimetableLoader = Future<ApiResponse<TimetableData>> Function();

class HeadmasterTimetableController extends GetxController {
  final HeadmasterRepository _repo;
  final TimetableLoader _loader;
  HeadmasterTimetableController({
    HeadmasterRepository? repo,
    TimetableLoader? loader,
  }) : _repo = repo ?? Get.find<HeadmasterRepository>(),
       _loader =
           loader ?? (repo ?? Get.find<HeadmasterRepository>()).loadTimetable;

  static const classOptions = [
    'All Classes',
    'Class 8A',
    'Class 8B',
    'Class 9A',
  ];
  static const teacherOptions = [
    'All Teachers',
    'Mr. Anderson',
    'Ms. Davis',
    'Dr. Smith',
    'Mr. Jones',
  ];

  final loading = true.obs;
  final error = RxnString();
  final data = Rxn<TimetableData>();
  final classFilter = 'All Classes'.obs;
  final teacherFilter = 'All Teachers'.obs;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  void selectClass(String? v) {
    if (v == null || v == classFilter.value) return;
    classFilter.value = v;
  }

  void selectTeacher(String? v) {
    if (v == null || v == teacherFilter.value) return;
    teacherFilter.value = v;
  }

  Future<void> load() async {
    loading.value = true;
    error.value = null;
    data.value = null;
    final res = await _loader();
    if (res.success && res.data != null) {
      data.value = res.data;
    } else {
      error.value = res.error ?? 'Could not load timetable.';
    }
    loading.value = false;
  }

  /// Validates and creates a class/grade, then refreshes the timetable on
  /// success. Returns `null` on success or a message for an empty name or a
  /// backend failure. UI-free so the authoring journey is harnessable.
  Future<String?> submitNewClass({required String name, String? level}) async {
    if (name.trim().isEmpty) return 'Class name is required';
    final res = await _repo.createClass(
      name: name.trim(),
      level: int.tryParse(level?.trim() ?? ''),
    );
    if (!res.success) return res.error ?? 'Could not create class';
    await load();
    return null;
  }

  /// Opens the "New Class" form (creates a class/grade); reloads on success.
  Future<void> createClassFlow() async {
    final name = TextEditingController();
    final level = TextEditingController();
    final ok = await showActionFormSheet(
      title: 'New Class',
      submitLabel: 'Create Class',
      // The sheet owns these fields and disposes them when it closes.
      ownedControllers: [name, level],
      fields: [
        GlassInput(label: 'Class name', hint: 'e.g. Grade 5', controller: name),
        GlassInput(
          label: 'Level (optional)',
          hint: 'e.g. 5',
          controller: level,
          keyboardType: TextInputType.number,
        ),
      ],
      onSubmit: () => submitNewClass(name: name.text, level: level.text),
    );
    if (ok == true) {
      Get.snackbar(
        'Class created',
        'The class was added.',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
}
