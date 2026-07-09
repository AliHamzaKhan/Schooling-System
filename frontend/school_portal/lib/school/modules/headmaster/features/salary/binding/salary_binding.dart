import 'package:get/get.dart';

import '../../../data/headmaster_repository.dart';
import '../controller/salary_controller.dart';

class SalaryBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<HeadmasterRepository>()) {
      Get.put<HeadmasterRepository>(HeadmasterRepository(), permanent: true);
    }
    Get.lazyPut<SalaryController>(() => SalaryController());
  }
}
