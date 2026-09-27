import 'package:get/get.dart';
import '../modules/teacher/data/teacher_repository.dart';
import '../modules/student/data/student_repository.dart';

class TeacherRouteBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<TeacherRepository>()) {
      Get.put<TeacherRepository>(TeacherRepository(), permanent: true);
    }
  }
}
class StudentRouteBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<StudentRepository>()) {
      Get.put<StudentRepository>(StudentRepository(), permanent: true);
    }
  }
}
