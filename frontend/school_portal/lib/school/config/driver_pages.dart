import 'package:get/get.dart';

import '../modules/driver/binding/driver_binding.dart';
import '../modules/driver/driver_shell.dart';
import 'driver_routes.dart';

/// `GetPage` declarations for the Driver module. Spread into the global router
/// by [AppPages].
class DriverPages {
  DriverPages._();

  static final pages = <GetPage>[
    GetPage(
      name: DriverRoutes.shell,
      page: () => const DriverShell(),
      binding: DriverBinding(),
    ),
  ];
}
