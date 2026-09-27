import 'package:get/get.dart';

import '../../data/guardian_repository.dart';
import '../controller/guardian_session_controller.dart';

/// Registers the module-wide singletons permanently: the [GuardianRepository]
/// (single data gateway shared by every Guardian controller) and the
/// [GuardianSessionController] (selected child, persists across tabs/drill-ins).
class GuardianSessionBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<GuardianRepository>()) {
      Get.put<GuardianRepository>(GuardianRepository(), permanent: true);
    }
    if (!Get.isRegistered<GuardianSessionController>()) {
      Get.put<GuardianSessionController>(GuardianSessionController(), permanent: true);
    }
  }
}
