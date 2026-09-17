import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared/shared.dart';

import '../../../../../widgets/action_form_sheet.dart';
import '../../../data/headmaster_repository.dart';
import '../models/admin_course_models.dart';

/// Manages one book's chapters (add + list).
class BookAdminController extends GetxController {
  final HeadmasterRepository _repo;
  BookAdminController({HeadmasterRepository? repo})
    : _repo = repo ?? Get.find<HeadmasterRepository>();

  final loading = true.obs;
  final error = RxnString();
  final book = Rxn<AdminBook>();
  final chapters = <AdminChapter>[].obs;
  late final String courseId;
  late final String bookId;

  @override
  void onInit() {
    super.onInit();
    final route = routeIds(
      parameters: Get.parameters,
      arguments: Get.arguments,
    );
    courseId = route.courseId;
    bookId = route.bookId;
    if (bookId.isEmpty) {
      error.value = 'A valid book is required.';
      loading.value = false;
      return;
    }
    load();
  }

  static ({String courseId, String bookId}) routeIds({
    required Map<String, String?> parameters,
    Object? arguments,
  }) {
    final courseId = parameters['course_id']?.trim() ?? '';
    final bookId = parameters['book_id']?.trim() ?? '';
    if (bookId.isNotEmpty) return (courseId: courseId, bookId: bookId);
    return arguments is AdminBook
        ? (courseId: '', bookId: arguments.id)
        : (courseId: '', bookId: '');
  }

  Future<void> load() async {
    loading.value = true;
    error.value = null;
    book.value = null;
    chapters.clear();
    if (courseId.isNotEmpty) {
      final books = await _repo.loadBooks(courseId);
      final canonical = books.data?.firstWhereOrNull(
        (item) => item.id == bookId,
      );
      if (!books.success || canonical == null) {
        error.value = books.success
            ? 'Book not found.'
            : (books.error ?? 'Could not load the book.');
        loading.value = false;
        return;
      }
      book.value = canonical;
    } else if (Get.arguments is AdminBook) {
      // Compatibility fallback for an older in-memory navigation. New links
      // always carry both IDs and resolve the canonical book above.
      book.value = Get.arguments as AdminBook;
    } else {
      error.value = 'A course identifier is required to load this book.';
      loading.value = false;
      return;
    }
    final res = await _repo.loadChapters(bookId);
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
          label: 'Title',
          hint: 'e.g. Chapter 1: Living Things',
          controller: title,
        ),
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
          bookId: bookId,
          title: title.text.trim(),
          content: content.text.trim(),
        );
        return res.success
            ? null
            : (res.error ?? 'Could not create the chapter');
      },
    );
    if (ok == true) await load();
  }
}
