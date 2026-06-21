import 'package:get/get.dart';

import '../controller/guardians_controller.dart';

class GuardiansBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<GuardiansController>(() => GuardiansController());
  }
}
