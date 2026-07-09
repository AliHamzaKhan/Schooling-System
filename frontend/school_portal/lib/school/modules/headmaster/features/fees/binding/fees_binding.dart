import 'package:get/get.dart';

import '../controller/fees_controller.dart';

class FeesBinding extends Bindings {
  @override
  void dependencies() {
    Get.delete<FeesController>(force: true);
    Get.lazyPut<FeesController>(() => FeesController());
  }
}
