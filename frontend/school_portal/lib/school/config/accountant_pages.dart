import 'package:get/get.dart';
import 'package:shared/shared.dart';

import '../modules/accountant/accountant_shell.dart';
import 'accountant_routes.dart';

/// `GetPage` declarations for the Accountant module. Spread into the global
/// router by [AppPages].
class AccountantPages {
  AccountantPages._();

  static final _pages = <GetPage>[
    GetPage(name: AccountantRoutes.shell, page: () => const AccountantShell()),
  ];
  static List<GetPage> get pages => _pages
      .map(
        (page) => page.copy(
          middlewares: [
            ...?page.middlewares,
            RoleRouteGuard({'accountant'}),
          ],
        ),
      )
      .toList();
}
