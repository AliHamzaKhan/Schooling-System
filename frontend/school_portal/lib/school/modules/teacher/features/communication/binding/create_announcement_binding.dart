import 'package:get/get.dart';

import '../controller/create_announcement_controller.dart';

class CreateAnnouncementBinding extends Bindings {
  @override
  void dependencies() {
    Get.delete<CreateAnnouncementController>(force: true);
    Get.lazyPut<CreateAnnouncementController>(
        () => CreateAnnouncementController());
  }
}
