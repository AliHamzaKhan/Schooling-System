import 'package:get/get.dart';

import '../controller/headmasters_controller.dart';

class HeadmastersBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<HeadmastersController>(() => HeadmastersController());
  }
}
