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
import '../ui/admin_widgets/admin_surface.dart';
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
  static const _desktopBreakpoint = 1024.0;
  final _tabController = PersistentTabController(initialIndex: 0);
  late final List<Widget> _tabScreens;

  // Animated "Home" icon (home ⇄ menu), per the persistent_bottom_nav_bar API.
  late final AnimationController _homeAnim = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 400),
  );
  late final Animation<double> _homeAnimValue = Tween<double>(
    begin: 0,
    end: 1,
  ).animate(_homeAnim);

  @override
  void initState() {
    super.initState();
    // Register tab controllers up front since the tabs are kept alive.
    DashboardBinding().dependencies();
    SchoolsBinding().dependencies();
    PaymentsBinding().dependencies();
    AnalyticsBinding().dependencies();
    _homeAnim.forward();
    _tabScreens = _screens();
  }

  @override
  void dispose() {
    _homeAnim.dispose();
    _tabController.dispose();
    super.dispose();
  }

  List<Widget> _screens() => [
    DashboardView(
      onCreateSchool: () => _selectTab(1),
      onManageHeadmasters: () => Get.toNamed(AdminRoutes.headmasters),
      onViewSchools: () => _selectTab(1),
      onViewSubscriptions: () =>
          Get.toNamed(AdminRoutes.subscriptionManagement),
      onViewRevenue: () => Get.toNamed(AdminRoutes.revenue),
    ),
    const SchoolsView(),
    const PaymentsView(),
    const AnalyticsView(),
    const SettingsView(),
  ];

  PersistentBottomNavBarItem _item(
    Widget icon,
    String title, {
    AnimationController? animController,
  }) => PersistentBottomNavBarItem(
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

  void _selectTab(int index) {
    _tabController.jumpToTab(index);
    if (mounted) setState(() {});
  }

  /// Android back handling for the admin root. We take it over from the nav bar
  /// (`handleAndroidBackButtonPress: false`) so that back on a non-Home tab
  /// returns to Home, and back on the Home tab is blocked — the admin is never
  /// popped off the shell back to the login screen. They leave via logout or
  /// the OS home button.
  void _onBack(bool didPop, Object? result) {
    if (didPop) return;
    if (_tabController.index != 0) _selectTab(0);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: _onBack,
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth >= _desktopBreakpoint) {
            return Scaffold(
              body: Row(
                children: [
                  _AdminSidebar(
                    selectedIndex: _tabController.index,
                    onSelected: _selectTab,
                  ),
                  const VerticalDivider(width: 1, color: AdminPalette.border),
                  Expanded(
                    child: IndexedStack(
                      index: _tabController.index,
                      children: _tabScreens,
                    ),
                  ),
                ],
              ),
            );
          }

          return PersistentTabView(
            context,
            controller: _tabController,
            screens: _tabScreens,
            items: _items(),
            navBarStyle: NavBarStyle.style7,
            backgroundColor: AdminPalette.card,
            decoration: NavBarDecoration(
              border: const Border(top: BorderSide(color: AdminPalette.border)),
              boxShadow: AdminPalette.cardShadow,
            ),
            confineToSafeArea: true,
            handleAndroidBackButtonPress: false,
            resizeToAvoidBottomInset: true,
            stateManagement: true,
          );
        },
      ),
    );
  }
}

class _AdminSidebar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const _AdminSidebar({required this.selectedIndex, required this.onSelected});

  static const _destinations = [
    (AppIcons.dashboardRounded, 'Overview'),
    (AppIcons.apartmentRounded, 'Schools'),
    (AppIcons.creditCardRounded, 'Billing'),
    (AppIcons.queryStatsRounded, 'Analytics'),
    (AppIcons.settingsRounded, 'Settings'),
  ];

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthService>();
    return SafeArea(
      child: Container(
        width: 252,
        color: AdminPalette.card,
        padding: const EdgeInsets.fromLTRB(16, 22, 16, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                children: [
                  const AdminIconTile(
                    icon: AppIcons.shieldMoonOutlined,
                    size: 42,
                    background: AdminPalette.ink,
                    foreground: Colors.white,
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Meri Taleem', style: AdminType.rowTitle),
                      Text('Platform Console', style: AdminType.meta),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 34),
            for (var i = 0; i < _destinations.length; i++) ...[
              _SidebarDestination(
                icon: _destinations[i].$1,
                label: _destinations[i].$2,
                selected: selectedIndex == i,
                onTap: () => onSelected(i),
              ),
              const SizedBox(height: 6),
            ],
            const Spacer(),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: AdminPalette.tint,
                borderRadius: AdminRadius.brTile,
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: AdminPalette.ink,
                    child: Text(
                      (auth.fullName?.trim().isNotEmpty ?? false)
                          ? auth.fullName!.trim()[0].toUpperCase()
                          : 'A',
                      style: AdminType.label.copyWith(color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          auth.fullName ?? 'Administrator',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AdminType.label,
                        ),
                        Text('Super admin', style: AdminType.meta),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SidebarDestination extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SidebarDestination({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AdminPalette.ink : Colors.transparent,
      borderRadius: AdminRadius.brTile,
      child: InkWell(
        onTap: onTap,
        borderRadius: AdminRadius.brTile,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          child: Row(
            children: [
              Icon(
                icon,
                size: 19,
                color: selected ? Colors.white : AdminPalette.muted,
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: AdminType.label.copyWith(
                  color: selected ? Colors.white : AdminPalette.muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
