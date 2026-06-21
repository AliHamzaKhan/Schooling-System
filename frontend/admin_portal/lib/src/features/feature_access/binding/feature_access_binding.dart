import 'package:get/get.dart';

import '../controller/feature_access_controller.dart';

class FeatureAccessBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<FeatureAccessController>(() => FeatureAccessController());
  }
}
