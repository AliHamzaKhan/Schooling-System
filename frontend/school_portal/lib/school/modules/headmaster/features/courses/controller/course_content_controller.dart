import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared/shared.dart';

import '../../../../../widgets/action_form_sheet.dart';
import '../../../data/headmaster_repository.dart';
import '../models/admin_course_models.dart';

/// Manages one course's content: its books and notes (add + list).
class CourseContentController extends GetxController {
  final HeadmasterRepository _repo;
  final AdminCourse course;
  CourseContentController.of(this.course, {HeadmasterRepository? repo})
      : _repo = repo ?? Get.find<HeadmasterRepository>();

  final loading = true.obs;
  final error = RxnString();
  final books = <AdminBook>[].obs;
  final notes = <AdminNote>[].obs;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    loading.value = true;
    error.value = null;
    final b = await _repo.loadBooks(course.id);
    final n = await _repo.loadNotes(course.id);
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
      fields: [
        GlassInput(label: 'Title', hint: 'e.g. Life Science', controller: title),
        GlassInput(
          label: 'Description (optional)',
          hint: 'Short description',
          controller: description,
        ),
      ],
      onSubmit: () async {
        if (title.text.trim().isEmpty) return 'A title is required';
        final res = await _repo.createBook(
          courseId: course.id,
          title: title.text.trim(),
          description:
              description.text.trim().isEmpty ? null : description.text.trim(),
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
          courseId: course.id,
          title: title.text.trim(),
          content: content.text.trim(),
        );
        return res.success ? null : (res.error ?? 'Could not create the note');
      },
    );
    if (ok == true) await load();
  }
}
