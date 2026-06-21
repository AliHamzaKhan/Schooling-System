import 'package:get/get.dart';

import '../controller/overview_controller.dart';

class OverviewBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<OverviewController>(() => OverviewController());
  }
}
