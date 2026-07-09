import 'package:get/get.dart';

import '../controller/notification_controller.dart';

class NotificationBinding extends Bindings {
  @override
  void dependencies() {
    Get.delete<NotificationController>(force: true);
    Get.lazyPut<NotificationController>(() => NotificationController());
  }
}
