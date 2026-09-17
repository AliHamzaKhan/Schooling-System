import 'package:get/get.dart';

import '../controller/upcoming_events_controller.dart';

class UpcomingEventsBinding extends Bindings {
  @override
  void dependencies() {
    Get.delete<UpcomingEventsController>(force: true);
    Get.lazyPut<UpcomingEventsController>(() => UpcomingEventsController());
  }
}
