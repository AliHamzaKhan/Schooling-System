import 'package:get/get.dart';

import '../../../data/student_repository.dart';
import '../controller/transport_controller.dart';

class StudentTransportBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<StudentRepository>()) {
      Get.put<StudentRepository>(StudentRepository(), permanent: true);
    }
    Get.lazyPut<StudentTransportController>(() => StudentTransportController());
  }
}
