import 'package:flutter/material.dart';
import 'package:get/get.dart';
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
import '../ui/admin_widgets/admin_bottom_nav.dart';
import 'admin_routes.dart';

/// Root authenticated shell — hosts the five admin tabs behind a persistent
/// dark bottom navigation bar. Tabs are kept alive via [IndexedStack] so each
/// keeps its scroll position when switching.
class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _index = 0;

  static const _items = [
    AdminNavItem(icon: Icons.home_rounded, label: 'Home'),
    AdminNavItem(icon: Icons.apartment_rounded, label: 'Schools'),
    AdminNavItem(icon: Icons.credit_card_rounded, label: 'Billing'),
    AdminNavItem(icon: Icons.query_stats_rounded, label: 'Metrics'),
    AdminNavItem(icon: Icons.settings_rounded, label: 'Settings'),
  ];

  void _goTo(int i) => setState(() => _index = i);

  @override
  void initState() {
    super.initState();
    // Register tab controllers up front since IndexedStack mounts all tabs.
    DashboardBinding().dependencies();
    SchoolsBinding().dependencies();
    PaymentsBinding().dependencies();
    AnalyticsBinding().dependencies();
  }

  @override
  Widget build(BuildContext context) {
    final tabs = <Widget>[
      DashboardView(
        onCreateSchool: () => _goTo(1),
        onManageHeadmasters: () => Get.toNamed(AdminRoutes.headmasters),
      ),
      const SchoolsView(),
      const PaymentsView(),
      const AnalyticsView(),
      const SettingsView(),
    ];

    return AppScaffold(
      body: IndexedStack(index: _index, children: tabs),
      bottomNavigationBar: AdminBottomNav(
        currentIndex: _index,
        onTap: _goTo,
        items: _items,
      ),
    );
  }
}
