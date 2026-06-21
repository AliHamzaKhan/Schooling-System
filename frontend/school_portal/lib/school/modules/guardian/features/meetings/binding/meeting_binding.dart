import 'package:get/get.dart';

import '../controller/meeting_controller.dart';

class MeetingBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<MeetingController>(() => MeetingController());
  }
}
