import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared/shared.dart';

import '../../../../../widgets/action_form_sheet.dart';
import '../../../data/headmaster_api_service.dart' show PickerOption;
import '../../../data/headmaster_repository.dart';
import '../../timetable/models/timetable_slot.dart' show SubjectOption;
import '../models/admin_course_models.dart';

/// Lists the school's courses and creates new ones (headmaster authoring).
///
/// A course is a subject offered to one class+section, so the create flow makes
/// the headmaster pick a class+section and a subject from the school catalog.
class CoursesAdminController extends GetxController {
  final HeadmasterRepository _repo;
  CoursesAdminController({HeadmasterRepository? repo})
      : _repo = repo ?? Get.find<HeadmasterRepository>();

  final loading = true.obs;
  final error = RxnString();
  final courses = <AdminCourse>[].obs;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    loading.value = true;
    error.value = null;
    final res = await _repo.loadCourses();
    if (res.success && res.data != null) {
      courses.assignAll(res.data!);
    } else {
      error.value = res.error ?? 'Could not load courses.';
    }
    loading.value = false;
  }

  /// Courses grouped by their class+section label ("Grade 5 · A"), sorted with
  /// scoped courses first and any legacy school-wide courses under "Unassigned".
  Map<String, List<AdminCourse>> get grouped {
    final map = <String, List<AdminCourse>>{};
    for (final c in courses) {
      final key = c.classSectionLabel ?? 'Unassigned';
      (map[key] ??= <AdminCourse>[]).add(c);
    }
    final keys = map.keys.toList()
      ..sort((a, b) {
        if (a == 'Unassigned') return 1;
        if (b == 'Unassigned') return -1;
        return a.compareTo(b);
      });
    return {for (final k in keys) k: map[k]!};
  }

  /// Opens the "New Course" form (class+section + subject pickers); reloads on
  /// success.
  Future<void> createFlow() async {
    final results = await Future.wait([
      _repo.loadSectionOptions(),
      _repo.loadSubjectOptions(),
    ]);
    final secRes = results[0] as ApiResponse<List<PickerOption>>;
    final subjRes = results[1] as ApiResponse<List<SubjectOption>>;

    if (!secRes.success || secRes.data == null) {
      Get.snackbar('Could not load classes',
          secRes.error ?? 'Please try again.',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }
    final sections = secRes.data!;
    if (sections.isEmpty) {
      Get.snackbar('No sections yet',
          'Create a class and section before adding a course.',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }
    final subjects = (subjRes.success ? subjRes.data : null) ?? const <SubjectOption>[];

    final selectedSection = sections.first.id.obs;
    final selectedSubjectId = RxnString();
    final title = TextEditingController();
    final description = TextEditingController();

    final ok = await showActionFormSheet(
      title: 'New Course',
      submitLabel: 'Create Course',
      fields: [
        _dropdown<String>(
          label: 'Class & Section',
          valueListenable: selectedSection,
          items: [
            for (final s in sections)
              DropdownMenuItem(value: s.id, child: Text(s.label)),
          ],
          onChanged: (v) => selectedSection.value = v ?? selectedSection.value,
        ),
        const SizedBox(height: AppSpacing.stackMd),
        _dropdown<String?>(
          label: 'Subject',
          valueListenable: selectedSubjectId,
          hint: 'Pick a subject',
          items: [
            const DropdownMenuItem(value: null, child: Text('Pick a subject')),
            for (final s in subjects)
              DropdownMenuItem(value: s.id, child: Text(s.name)),
          ],
          onChanged: (v) => selectedSubjectId.value = v,
        ),
        const SizedBox(height: AppSpacing.stackMd),
        GlassInput(
          label: 'Title (optional)',
          hint: 'Defaults to the subject name',
          controller: title,
        ),
        GlassInput(
          label: 'Description (optional)',
          hint: 'What is this course about?',
          controller: description,
          keyboardType: TextInputType.multiline,
        ),
      ],
      onSubmit: () async {
        final subj =
            subjects.firstWhereOrNull((s) => s.id == selectedSubjectId.value);
        final courseTitle =
            title.text.trim().isNotEmpty ? title.text.trim() : (subj?.name ?? '');
        if (courseTitle.isEmpty) {
          return 'Pick a subject or enter a title';
        }
        final res = await _repo.createCourse(
          title: courseTitle,
          subject: subj?.name,
          subjectId: subj?.id,
          sectionId: selectedSection.value,
          description:
              description.text.trim().isEmpty ? null : description.text.trim(),
        );
        return res.success ? null : (res.error ?? 'Could not create the course');
      },
    );
    if (ok == true) await load();
  }
}

/// A labelled dropdown styled to sit alongside [GlassInput] fields in the
/// create sheet. Rebuilds via [Obx] when [valueListenable] changes.
Widget _dropdown<T>({
  required String label,
  required Rx<T> valueListenable,
  required List<DropdownMenuItem<T>> items,
  required ValueChanged<T?> onChanged,
  String? hint,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label.toUpperCase(),
          style: AppTypography.labelCaps
              .copyWith(color: AppColors.onSurfaceVariant)),
      const SizedBox(height: 4),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.stackMd),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.button),
          border: Border.all(color: AppColors.outlineVariant),
        ),
        child: Obx(
          () => DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              isExpanded: true,
              value: valueListenable.value,
              hint: hint == null ? null : Text(hint),
              items: items,
              onChanged: onChanged,
            ),
          ),
        ),
      ),
    ],
  );
}
