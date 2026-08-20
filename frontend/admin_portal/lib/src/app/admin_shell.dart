import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:persistent_bottom_nav_bar/persistent_bottom_nav_bar.dart';

import '../features/analytics/binding/analytics_binding.dart';
import '../features/analytics/view/analytics_view.dart';
import '../features/dashboard/binding/dashboard_binding.dart';
import '../features/dashboard/view/dashboard_view.dart';
import '../features/payments/binding/payments_binding.dart';
import '../features/payments/view/payments_view.dart';
import '../features/schools/binding/schools_binding.dart';
import '../features/schools/view/schools_view.dart';
import '../features/settings/view/settings_view.dart';
import '../ui/admin_theme.dart';
import 'admin_routes.dart';
import 'package:shared/shared.dart';

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
          onViewSchools: () => _tabController.jumpToTab(1),
          onViewSubscriptions: () =>
              Get.toNamed(AdminRoutes.subscriptionManagement),
          onViewRevenue: () => Get.toNamed(AdminRoutes.revenue),
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
        activeColorPrimary: AdminPalette.ink,
        activeColorSecondary: Colors.white,
        inactiveColorPrimary: AdminPalette.faint,
        textStyle: AdminType.meta.copyWith(fontSize: 11),
      );

  List<PersistentBottomNavBarItem> _items() => [
        _item(
          AnimatedIcon(icon: AnimatedIcons.home_menu, progress: _homeAnimValue),
          'Home',
          animController: _homeAnim,
        ),
        _item(const Icon(AppIcons.apartmentRounded), 'Schools'),
        _item(const Icon(AppIcons.creditCardRounded), 'Billing'),
        _item(const Icon(AppIcons.queryStatsRounded), 'Metrics'),
        _item(const Icon(AppIcons.settingsRounded), 'Settings'),
      ];

  /// Android back handling for the admin root. We take it over from the nav bar
  /// (`handleAndroidBackButtonPress: false`) so that back on a non-Home tab
  /// returns to Home, and back on the Home tab is blocked — the admin is never
  /// popped off the shell back to the login screen. They leave via logout or
  /// the OS home button.
  void _onBack(bool didPop, Object? result) {
    if (didPop) return;
    if (_tabController.index != 0) _tabController.jumpToTab(0);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: _onBack,
      child: PersistentTabView(
        context,
        controller: _tabController,
        screens: _screens(),
        items: _items(),
        navBarStyle: NavBarStyle.style7,
        backgroundColor: AdminPalette.card,
        decoration: NavBarDecoration(
          border: const Border(
            top: BorderSide(color: AdminPalette.border),
          ),
          boxShadow: AdminPalette.cardShadow,
        ),
        confineToSafeArea: true,
        handleAndroidBackButtonPress: false,
        resizeToAvoidBottomInset: true,
        stateManagement: true,
      ),
    );
  }
}
