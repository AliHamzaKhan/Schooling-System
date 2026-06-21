import 'package:get/get.dart';

import '../controller/gradebook_controller.dart';

class GradebookBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<GradebookController>(() => GradebookController());
  }
}
