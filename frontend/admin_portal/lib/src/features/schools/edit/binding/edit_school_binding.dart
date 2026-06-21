import 'package:get/get.dart';

import '../controller/edit_school_controller.dart';

class EditSchoolBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<EditSchoolController>(() => EditSchoolController());
  }
}
