import 'package:get/get.dart';

import '../data/headmaster_repository.dart';

/// Route-local module dependency needed before any feature binding runs.
///
/// Registering this on every headmaster page makes cold/direct URL loads
/// independent of whether the shell happened to be visited earlier.
class HeadmasterRouteBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<HeadmasterRepository>()) {
      Get.put<HeadmasterRepository>(HeadmasterRepository(), permanent: true);
    }
  }
}
