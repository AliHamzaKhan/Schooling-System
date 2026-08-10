import 'package:get/get.dart';

import '../../../schools/models/school.dart';
import '../controller/school_modules_controller.dart';

class SchoolModulesBinding extends Bindings {
  @override
  void dependencies() {
    // The school being configured is passed as the route argument.
    final school = Get.arguments as School;
    Get.lazyPut<SchoolModulesController>(
        () => SchoolModulesController(school: school));
  }
}
