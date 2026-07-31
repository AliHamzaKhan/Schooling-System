import 'package:get/get.dart';

import '../../../data/student_repository.dart';
import '../models/course_models.dart';

/// Drives the Book track: loads the course's books, and the chapter table of
/// contents for the selected book, plus the saved "continue reading" position.
class BookChaptersController extends GetxController {
  final StudentRepository _repo;
  final Course course;
  BookChaptersController.of(this.course, {StudentRepository? repo})
      : _repo = repo ?? Get.find<StudentRepository>();

  final loading = true.obs;
  final error = RxnString();
  final books = <CourseBook>[].obs;
  final selectedBook = Rxn<CourseBook>();
  final chapters = <ChapterBrief>[].obs;

  /// Saved position for the selected book, so we can offer "Continue".
  final resumeChapterId = RxnString();

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    loading.value = true;
    error.value = null;
    final res = await _repo.loadCourseBooks(course.id);
    if (!res.success || res.data == null) {
      error.value = res.error ?? 'Could not load books.';
      loading.value = false;
      return;
    }
    books.assignAll(res.data!);
    if (books.isNotEmpty) {
      await selectBook(books.first);
    }
    loading.value = false;
  }

  Future<void> selectBook(CourseBook book) async {
    selectedBook.value = book;
    chapters.clear();
    resumeChapterId.value = null;
    final res = await _repo.loadBookChapters(book.id);
    if (res.success && res.data != null) {
      chapters.assignAll(res.data!);
    } else {
      error.value = res.error ?? 'Could not load chapters.';
    }
    final prog = await _repo.loadReadingProgress(
        resourceType: 'book', resourceId: book.id);
    if (prog.success && prog.data != null && prog.data!.chapterId != null) {
      resumeChapterId.value = prog.data!.chapterId;
    }
  }

  /// The chapter to resume, if the saved one still exists.
  ChapterBrief? get resumeChapter {
    final id = resumeChapterId.value;
    if (id == null) return null;
    for (final c in chapters) {
      if (c.id == id) return c;
    }
    return null;
  }
}
