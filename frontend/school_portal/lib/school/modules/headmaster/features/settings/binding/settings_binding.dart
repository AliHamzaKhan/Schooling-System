import 'package:get/get.dart';

import '../../../data/headmaster_repository.dart';
import '../controller/settings_controller.dart';

class SettingsBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<HeadmasterRepository>()) {
      Get.put<HeadmasterRepository>(HeadmasterRepository(), permanent: true);
    }
    Get.lazyPut<SettingsController>(() => SettingsController());
  }
}
