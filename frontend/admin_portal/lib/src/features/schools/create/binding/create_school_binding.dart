import 'package:get/get.dart';

import '../controller/create_school_controller.dart';

class CreateSchoolBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<CreateSchoolController>(() => CreateSchoolController());
  }
}
