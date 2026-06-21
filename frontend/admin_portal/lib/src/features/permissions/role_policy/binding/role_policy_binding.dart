import 'package:get/get.dart';

import '../controller/role_policy_controller.dart';

class RolePolicyBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<RolePolicyController>(() => RolePolicyController());
  }
}
