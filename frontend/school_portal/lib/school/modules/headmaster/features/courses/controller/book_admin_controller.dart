import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared/shared.dart';

import '../../../../../widgets/action_form_sheet.dart';
import '../../../data/headmaster_repository.dart';
import '../models/admin_course_models.dart';

/// Manages one book's chapters (add + list).
class BookAdminController extends GetxController {
  final HeadmasterRepository _repo;
  final AdminBook book;
  BookAdminController.of(this.book, {HeadmasterRepository? repo})
      : _repo = repo ?? Get.find<HeadmasterRepository>();

  final loading = true.obs;
  final error = RxnString();
  final chapters = <AdminChapter>[].obs;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    loading.value = true;
    error.value = null;
    final res = await _repo.loadChapters(book.id);
    if (res.success && res.data != null) {
      chapters.assignAll(res.data!);
    } else {
      error.value = res.error ?? 'Could not load chapters.';
    }
    loading.value = false;
  }

  Future<void> addChapterFlow() async {
    final title = TextEditingController();
    final content = TextEditingController();
    final ok = await showActionFormSheet(
      title: 'New Chapter',
      // The sheet owns these fields and disposes them when it closes.
      ownedControllers: [title, content],
      fields: [
        GlassInput(
            label: 'Title', hint: 'e.g. Chapter 1: Living Things', controller: title),
        GlassInput(
          label: 'Content',
          hint: 'Write the chapter text…',
          controller: content,
          keyboardType: TextInputType.multiline,
        ),
      ],
      onSubmit: () async {
        if (title.text.trim().isEmpty) return 'A title is required';
        if (content.text.trim().isEmpty) return 'Content is required';
        final res = await _repo.createChapter(
          bookId: book.id,
          title: title.text.trim(),
          content: content.text.trim(),
        );
        return res.success ? null : (res.error ?? 'Could not create the chapter');
      },
    );
    if (ok == true) await load();
  }
}
