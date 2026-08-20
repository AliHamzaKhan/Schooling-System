import 'package:get/get.dart';

import '../controller/driver_trip_controller.dart';
import '../data/driver_repository.dart';

class DriverBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<DriverRepository>()) {
      Get.put<DriverRepository>(DriverRepository(), permanent: true);
    }
    Get.lazyPut<DriverTripController>(() => DriverTripController());
  }
}
