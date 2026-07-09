import 'package:get/get.dart';

import '../controller/results_controller.dart';

class ResultsBinding extends Bindings {
  @override
  void dependencies() {
    Get.delete<ResultsController>(force: true);
    Get.lazyPut<ResultsController>(() => ResultsController());
  }
}
