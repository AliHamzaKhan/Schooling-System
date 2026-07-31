import 'package:get/get.dart';

import '../controller/book_admin_controller.dart';
import '../controller/course_content_controller.dart';
import '../controller/courses_admin_controller.dart';
import '../models/admin_course_models.dart';

class CoursesAdminBinding extends Bindings {
  @override
  void dependencies() {
    Get.delete<CoursesAdminController>(force: true);
    Get.lazyPut<CoursesAdminController>(() => CoursesAdminController());
  }
}

class CourseContentBinding extends Bindings {
  @override
  void dependencies() {
    Get.delete<CourseContentController>(force: true);
    Get.lazyPut<CourseContentController>(
        () => CourseContentController.of(Get.arguments as AdminCourse));
  }
}

class BookAdminBinding extends Bindings {
  @override
  void dependencies() {
    Get.delete<BookAdminController>(force: true);
    Get.lazyPut<BookAdminController>(
        () => BookAdminController.of(Get.arguments as AdminBook));
  }
}
