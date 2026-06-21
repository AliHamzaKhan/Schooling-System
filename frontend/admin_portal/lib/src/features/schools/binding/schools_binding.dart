import 'package:get/get.dart';

import '../controller/schools_controller.dart';

class SchoolsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SchoolsController>(() => SchoolsController());
  }
}
