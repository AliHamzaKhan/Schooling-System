import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:persistent_bottom_nav_bar/persistent_bottom_nav_bar.dart';
import 'package:shared/shared.dart';

import '../features/analytics/binding/analytics_binding.dart';
import '../features/analytics/view/analytics_view.dart';
import '../features/dashboard/binding/dashboard_binding.dart';
import '../features/dashboard/view/dashboard_view.dart';
import '../features/payments/binding/payments_binding.dart';
import '../features/payments/view/payments_view.dart';
import '../features/schools/binding/schools_binding.dart';
import '../features/schools/view/schools_view.dart';
import '../features/settings/view/settings_view.dart';
import 'admin_routes.dart';

/// Root authenticated shell — hosts the five admin tabs behind a persistent
/// style-7 bottom navigation bar (persistent_bottom_nav_bar).
class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> with TickerProviderStateMixin {
  final _tabController = PersistentTabController(initialIndex: 0);

  // Animated "Home" icon (home ⇄ menu), per the persistent_bottom_nav_bar API.
  late final AnimationController _homeAnim =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
  late final Animation<double> _homeAnimValue =
      Tween<double>(begin: 0, end: 1).animate(_homeAnim);

  @override
  void initState() {
    super.initState();
    // Register tab controllers up front since the tabs are kept alive.
    DashboardBinding().dependencies();
    SchoolsBinding().dependencies();
    PaymentsBinding().dependencies();
    AnalyticsBinding().dependencies();
    _homeAnim.forward();
  }

  @override
  void dispose() {
    _homeAnim.dispose();
    _tabController.dispose();
    super.dispose();
  }

  List<Widget> _screens() => [
        DashboardView(
          onCreateSchool: () => _tabController.jumpToTab(1),
          onManageHeadmasters: () => Get.toNamed(AdminRoutes.headmasters),
        ),
        const SchoolsView(),
        const PaymentsView(),
        const AnalyticsView(),
        const SettingsView(),
      ];

  PersistentBottomNavBarItem _item(Widget icon, String title,
          {AnimationController? animController}) =>
      PersistentBottomNavBarItem(
        icon: icon,
        iconAnimationController: animController,
        title: title,
        activeColorPrimary: AppColors.primary,
        activeColorSecondary: Colors.white,
        inactiveColorPrimary: AppColors.onSurfaceVariant,
      );

  List<PersistentBottomNavBarItem> _items() => [
        _item(
          AnimatedIcon(icon: AnimatedIcons.home_menu, progress: _homeAnimValue),
          'Home',
          animController: _homeAnim,
        ),
        _item(const Icon(Icons.apartment_rounded), 'Schools'),
        _item(const Icon(Icons.credit_card_rounded), 'Billing'),
        _item(const Icon(Icons.query_stats_rounded), 'Metrics'),
        _item(const Icon(Icons.settings_rounded), 'Settings'),
      ];

  @override
  Widget build(BuildContext context) {
    return PersistentTabView(
      context,
      controller: _tabController,
      screens: _screens(),
      items: _items(),
      navBarStyle: NavBarStyle.style7,
      backgroundColor: AppColors.surface,
      confineToSafeArea: true,
      handleAndroidBackButtonPress: true,
      resizeToAvoidBottomInset: true,
      stateManagement: true,
    );
  }
}
