import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared/shared.dart';

import '../../../../../widgets/action_form_sheet.dart';
import '../../../data/headmaster_repository.dart';
import '../models/admin_course_models.dart';

/// Manages one course's content: its books and notes (add + list).
class CourseContentController extends GetxController {
  final HeadmasterRepository _repo;
  CourseContentController({HeadmasterRepository? repo})
    : _repo = repo ?? Get.find<HeadmasterRepository>();

  final loading = true.obs;
  final error = RxnString();
  final course = Rxn<AdminCourse>();
  final books = <AdminBook>[].obs;
  final notes = <AdminNote>[].obs;
  late final String courseId;

  @override
  void onInit() {
    super.onInit();
    courseId = courseIdFromRoute(
      parameters: Get.parameters,
      arguments: Get.arguments,
    );
    if (courseId.isEmpty) {
      error.value = 'A valid course is required.';
      loading.value = false;
      return;
    }
    load();
  }

  static String courseIdFromRoute({
    required Map<String, String?> parameters,
    Object? arguments,
  }) {
    final fromUrl = parameters['course_id']?.trim() ?? '';
    if (fromUrl.isNotEmpty) return fromUrl;
    return arguments is AdminCourse ? arguments.id : '';
  }

  Future<void> load() async {
    loading.value = true;
    error.value = null;
    course.value = null;
    books.clear();
    notes.clear();
    final courses = await _repo.loadCourses();
    final canonical = courses.data?.firstWhereOrNull(
      (item) => item.id == courseId,
    );
    if (!courses.success || canonical == null) {
      error.value = courses.success
          ? 'Course not found.'
          : (courses.error ?? 'Could not load the course.');
      loading.value = false;
      return;
    }
    course.value = canonical;
    final b = await _repo.loadBooks(courseId);
    final n = await _repo.loadNotes(courseId);
    if (b.success && b.data != null) books.assignAll(b.data!);
    if (n.success && n.data != null) notes.assignAll(n.data!);
    if (!b.success && !n.success) {
      error.value = b.error ?? 'Could not load course content.';
    }
    loading.value = false;
  }

  Future<void> addBookFlow() async {
    final title = TextEditingController();
    final description = TextEditingController();
    final ok = await showActionFormSheet(
      title: 'New Book',
      // The sheet owns these fields and disposes them when it closes.
      ownedControllers: [title, description],
      fields: [
        GlassInput(
          label: 'Title',
          hint: 'e.g. Life Science',
          controller: title,
        ),
        GlassInput(
          label: 'Description (optional)',
          hint: 'Short description',
          controller: description,
        ),
      ],
      onSubmit: () async {
        if (title.text.trim().isEmpty) return 'A title is required';
        final res = await _repo.createBook(
          courseId: courseId,
          title: title.text.trim(),
          description: description.text.trim().isEmpty
              ? null
              : description.text.trim(),
        );
        return res.success ? null : (res.error ?? 'Could not create the book');
      },
    );
    if (ok == true) await load();
  }

  Future<void> addNoteFlow() async {
    final title = TextEditingController();
    final content = TextEditingController();
    final ok = await showActionFormSheet(
      title: 'New Note',
      ownedControllers: [title, content],
      fields: [
        GlassInput(label: 'Title', hint: 'e.g. Key Terms', controller: title),
        GlassInput(
          label: 'Content',
          hint: 'Write the note text…',
          controller: content,
          keyboardType: TextInputType.multiline,
        ),
      ],
      onSubmit: () async {
        if (title.text.trim().isEmpty) return 'A title is required';
        if (content.text.trim().isEmpty) return 'Content is required';
        final res = await _repo.createNote(
          courseId: courseId,
          title: title.text.trim(),
          content: content.text.trim(),
        );
        return res.success ? null : (res.error ?? 'Could not create the note');
      },
    );
    if (ok == true) await load();
  }
}
