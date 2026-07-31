import 'package:get/get.dart';

import '../controller/classes_controller.dart';

class ClassesBinding extends Bindings {
  @override
  void dependencies() {
    // Do NOT delete an existing instance: the tab-shell registers the same
    // controller and expects it to survive when the standalone `/classes`
    // route (opened from the dashboard) is popped.
    if (!Get.isRegistered<HeadmasterClassesController>()) {
      // `fenix` so the controller is rebuilt on demand: the embedded People tab
      // ([ClassesView]) outlives standalone routes (e.g. `/classes` opened from
      // the dashboard). When such a route pops, GetX's smart-management disposes
      // this lazy controller; without `fenix` the still-mounted tab would then
      // fail to `Get.find` it ("HeadmasterClassesController not found").
      Get.lazyPut<HeadmasterClassesController>(
        () => HeadmasterClassesController(),
        fenix: true,
      );
    }
  }
}
