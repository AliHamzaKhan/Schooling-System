import 'package:get/get.dart';

import '../controller/school_info_edit_controller.dart';

class SchoolInfoEditBinding extends Bindings {
  @override
  void dependencies() {
    Get.delete<SchoolInfoEditController>(force: true);
    Get.lazyPut<SchoolInfoEditController>(() => SchoolInfoEditController());
  }
}
