import 'package:get/get.dart';

import '../controller/promotion_controller.dart';

class PromotionBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PromotionController>(() => PromotionController());
  }
}
