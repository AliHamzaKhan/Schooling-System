import 'package:get/get.dart';

import '../controller/communication_controller.dart';

class CommunicationBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<CommunicationController>(() => CommunicationController());
  }
}
