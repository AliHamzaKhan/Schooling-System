import 'package:get/get.dart';

import '../controller/school_info_controller.dart';

class SchoolInfoBinding extends Bindings {
  @override
  void dependencies() {
    Get.delete<SchoolInfoController>(force: true);
    Get.lazyPut<SchoolInfoController>(() => SchoolInfoController());
  }
}
