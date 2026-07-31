import 'package:get/get.dart';

import '../controller/book_chapters_controller.dart';
import '../controller/courses_controller.dart';
import '../controller/notes_controller.dart';
import '../controller/reader_controller.dart';
import '../models/course_models.dart';

class CoursesBinding extends Bindings {
  @override
  void dependencies() {
    Get.delete<CoursesController>(force: true);
    Get.lazyPut<CoursesController>(() => CoursesController());
  }
}

class BookChaptersBinding extends Bindings {
  @override
  void dependencies() {
    Get.delete<BookChaptersController>(force: true);
    Get.lazyPut<BookChaptersController>(
        () => BookChaptersController.of(Get.arguments as Course));
  }
}

class NotesBinding extends Bindings {
  @override
  void dependencies() {
    Get.delete<NotesController>(force: true);
    Get.lazyPut<NotesController>(
        () => NotesController.of(Get.arguments as Course));
  }
}

class ReaderBinding extends Bindings {
  @override
  void dependencies() {
    Get.delete<ReaderController>(force: true);
    Get.lazyPut<ReaderController>(
        () => ReaderController(Get.arguments as ReaderArgs));
  }
}
