import 'package:get/get.dart';

import '../controller/revenue_controller.dart';

class RevenueBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => RevenueController());
  }
}
