import 'package:get/get.dart';

import '../controller/transport_controller.dart';

class GuardianTransportBinding extends Bindings {
  @override
  void dependencies() {
    Get.delete<GuardianTransportController>(force: true);
    Get.lazyPut<GuardianTransportController>(() => GuardianTransportController());
  }
}
