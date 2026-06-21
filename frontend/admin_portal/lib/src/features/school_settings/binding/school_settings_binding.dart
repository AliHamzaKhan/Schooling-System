import 'package:get/get.dart';

import '../controller/school_settings_controller.dart';

class SchoolSettingsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SchoolSettingsController>(() => SchoolSettingsController());
  }
}
