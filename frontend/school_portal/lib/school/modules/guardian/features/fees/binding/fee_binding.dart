import 'package:get/get.dart';

import '../controller/fee_controller.dart';

class FeeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<FeeController>(() => FeeController());
  }
}
