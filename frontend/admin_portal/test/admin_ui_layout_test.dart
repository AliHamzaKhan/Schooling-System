import 'package:admin_portal/src/data/models/admin_metrics.dart';
import 'package:admin_portal/src/data/models/dashboard_stats.dart';
import 'package:admin_portal/src/features/dashboard/components/alert_tile.dart';
import 'package:admin_portal/src/features/dashboard/components/quick_action_card.dart';
import 'package:admin_portal/src/features/payments/components/payment_stat_card.dart';
import 'package:admin_portal/src/features/payments/models/payments_data.dart';
import 'package:admin_portal/src/features/schools/components/school_card.dart';
import 'package:admin_portal/src/features/schools/models/school.dart';
import 'package:admin_portal/src/ui/admin_theme.dart';
import 'package:admin_portal/src/ui/admin_widgets/admin_search_field.dart';
import 'package:admin_portal/src/ui/admin_widgets/admin_surface.dart';
import 'package:admin_portal/src/ui/admin_widgets/filter_chips.dart';
import 'package:admin_portal/src/ui/admin_widgets/revenue_trend_card.dart';
import 'package:admin_portal/src/ui/admin_widgets/stat_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_portal/school/modules/headmaster/features/dashboard/components/module_directory.dart';

/// Renders the redesigned admin surfaces at phone width and fails on any
/// layout overflow — the hand-tuned cards (KPI grid, trend chart, school row)
/// are the pieces most likely to break when copy or data grows.
void main() {
  Future<void> pumpPage(WidgetTester tester, List<Widget> children) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: adminTheme(),
        home: Scaffold(
          body: AdminScreen(
            child: ListView(
              padding: const EdgeInsets.all(kAdminGutter),
              children: children,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  const metric = StatMetric(
    label: 'Total Schools',
    value: '128',
    trendPercent: 12,
    spark: [3, 5, 4, 8, 6, 9],
  );

  final months = [
    for (var m = 1; m <= 6; m++)
      RevenueMonth(month: '2026-0$m', total: m * 420.0, count: m),
  ];

  const school = School(
    id: '1',
    name: 'Riverside High School of Science',
    location: '124 Valley Road, Seattle, WA',
    students: 1240,
    status: SchoolStatus.active,
    tenureLabel: 'Joined Aug 2022',
    code: 'RV-4921',
    planName: 'Premium Plan',
    planCode: 'premium',
  );

  testWidgets('dashboard surfaces lay out at phone width', (tester) async {
    await pumpPage(tester, [
      const AdminPageHeader(
        title: 'Welcome Back, Admin',
        subtitle: "Here is an overview of your platform's performance today.",
      ),
      const StatCard(
        metric: metric,
        icon: Icons.apartment_rounded,
        emphasized: true,
      ),
      const SizedBox(height: 14),
      const StatCard(
        metric: metric,
        icon: Icons.bar_chart_rounded,
        showTrend: false,
      ),
      const SizedBox(height: 14),
      QuickActionCard(
        label: 'Create New School',
        description:
            'Add a new institution to the platform and invite administrators.',
        leadingIcon: Icons.add_rounded,
        watermarkIcon: Icons.add_business_rounded,
        onTap: () {},
      ),
      const SizedBox(height: 14),
      const AdminNavTile(
        icon: Icons.manage_accounts_rounded,
        title: 'Manage Headmasters',
        subtitle: 'Review and manage user roles.',
      ),
      const SizedBox(height: 14),
      const AlertTile(
        alert: AdminAlert(
          title: 'Subscription expiring',
          body: 'Greenwood Prep renews in 3 days.',
          timeAgo: '2h ago',
          severity: AlertSeverity.warning,
        ),
      ),
    ]);

    expect(find.text('Welcome Back, Admin'), findsOneWidget);
    expect(find.byType(StatCard), findsNWidgets(2));
  });

  testWidgets('schools directory surfaces lay out at phone width', (
    tester,
  ) async {
    await pumpPage(tester, [
      const AdminPageHeader(
        title: 'Schools Directory',
        subtitle: 'Manage and monitor affiliated institutions.',
      ),
      const AdminSearchField(hint: 'Search schools by name or ID...'),
      const SizedBox(height: 16),
      FilterChips(
        options: const ['All', 'Active', 'Pending'],
        selectedIndex: 0,
        onSelected: (_) {},
      ),
      const SizedBox(height: 16),
      const SchoolCard(school: school),
    ]);

    expect(find.text('ID: RV-4921'), findsOneWidget);
    expect(find.text('1,240 Students'), findsOneWidget);
    expect(find.text('Active'), findsWidgets);
  });

  testWidgets('billing surfaces lay out at phone width', (tester) async {
    await pumpPage(tester, [
      const AdminPageHeader(
        title: 'Financial Overview',
        subtitle: 'Review your recent billing metrics and revenue trends.',
      ),
      GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.42,
        children: const [
          PaymentStatCard(
            stat: PaymentStat(
              label: 'Total Revenue',
              value: '\$1,798,400',
              icon: Icons.account_balance_outlined,
              color: AdminPalette.ink,
            ),
          ),
          PaymentStatCard(
            stat: PaymentStat(
              label: 'This Month',
              value: '\$1,798',
              icon: Icons.calendar_month_outlined,
              color: AdminPalette.ink,
              caption: '+12% from last',
              captionColor: AdminPalette.positive,
            ),
          ),
        ],
      ),
      const SizedBox(height: 20),
      RevenueTrendCard(title: 'Revenue Trend', months: months),
    ]);

    expect(find.text('Last 6 Months'), findsOneWidget);
    expect(find.text('+12% from last'), findsOneWidget);
  });

  testWidgets('headmaster module directory lays out at phone width', (
    tester,
  ) async {
    await pumpPage(tester, const [HeadmasterModuleDirectory()]);

    expect(find.text('Manage your school'), findsOneWidget);
    expect(find.text('Students'), findsOneWidget);
    expect(find.text('School profile'), findsOneWidget);
    expect(find.text('Reports'), findsOneWidget);
  });

  testWidgets(
    'headmaster module directory filters and recovers from no results',
    (tester) async {
      await pumpPage(tester, const [HeadmasterModuleDirectory()]);

      await tester.enterText(find.byType(TextFormField), 'payroll');
      await tester.pump();
      expect(find.text('Payroll'), findsOneWidget);
      expect(find.text('Students'), findsNothing);

      await tester.enterText(find.byType(TextFormField), 'not a module');
      await tester.pump();
      expect(find.text('No modules found'), findsOneWidget);
      await tester.tap(find.text('Clear search'));
      await tester.pump();
      expect(find.text('Students'), findsOneWidget);
    },
  );

  testWidgets('headmaster module directory hides unavailable capabilities', (
    tester,
  ) async {
    await pumpPage(tester, const [
      HeadmasterModuleDirectory(
        enabledModules: {'student_management', 'timetable'},
      ),
    ]);

    expect(find.text('Students'), findsOneWidget);
    expect(find.text('Classes & sections'), findsOneWidget);
    expect(find.text('Timetable'), findsOneWidget);
    expect(find.text('Payroll'), findsNothing);
    expect(find.text('Transport'), findsNothing);
    expect(find.text('Settings'), findsOneWidget);
  });
}
