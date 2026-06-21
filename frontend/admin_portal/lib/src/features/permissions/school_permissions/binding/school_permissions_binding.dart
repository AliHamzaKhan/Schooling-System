import 'package:get/get.dart';

import '../controller/school_permissions_controller.dart';

class SchoolPermissionsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SchoolPermissionsController>(() => SchoolPermissionsController());
  }
}
