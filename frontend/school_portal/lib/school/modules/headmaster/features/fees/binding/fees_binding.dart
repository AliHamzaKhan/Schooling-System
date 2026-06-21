import 'package:get/get.dart';

import '../controller/fees_controller.dart';

class FeesBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<FeesController>(() => FeesController());
  }
}
