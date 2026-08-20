import 'package:get/get.dart';

import '../../../data/headmaster_repository.dart';
import '../controller/transport_controller.dart';

class TransportBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<HeadmasterRepository>()) {
      Get.put<HeadmasterRepository>(HeadmasterRepository(), permanent: true);
    }
    Get.lazyPut<TransportController>(() => TransportController());
  }
}
