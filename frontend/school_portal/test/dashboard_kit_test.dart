import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:persistent_bottom_nav_bar/persistent_bottom_nav_bar.dart';
import 'package:school_portal/school/widgets/dashboard_kit.dart';
import 'package:school_portal/school/widgets/portal_nav_bar.dart';
import 'package:school_portal/school/widgets/portal_tab_scaffold.dart';

/// The shared dashboard shape and the module nav bar.
///
/// These two widgets are now on every screen of all four modules, so a
/// regression in either is a regression everywhere. The nav bar in particular
/// dropped its text labels, which makes the [Semantics] labels the only thing
/// naming the tabs — worth a test, because nothing on screen would look wrong
/// if they disappeared.
void main() {
  Widget wrap(Widget child) => MaterialApp(
        home: Scaffold(body: SingleChildScrollView(child: child)),
      );

  group('PortalNavBar', () {
    const tabs = [
      PortalTab(Icons.dashboard_rounded, 'Home'),
      PortalTab(Icons.insights_rounded, 'Academics'),
      PortalTab(Icons.notifications_outlined, 'Alerts'),
    ];

    testWidgets('names every tab for a screen reader', (tester) async {
      final controller = PersistentTabController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        wrap(PortalNavBar(tabs: tabs, controller: controller)),
      );

      for (final tab in tabs) {
        expect(
          find.bySemanticsLabel(tab.label),
          findsOneWidget,
          reason: 'the bar shows no text, so this label is the only name '
              '"${tab.label}" has',
        );
      }
    });

    testWidgets('marks exactly one tab selected, and follows the controller',
        (tester) async {
      final controller = PersistentTabController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        wrap(PortalNavBar(tabs: tabs, controller: controller)),
      );

      final handle = tester.ensureSemantics();
      expect(_selectedLabels(tester), ['Home']);

      // Programmatic switch: the bar reads the controller rather than keeping
      // its own copy of the index, so this has to move the highlight.
      controller.jumpToTab(2);
      await tester.pumpAndSettle();
      expect(_selectedLabels(tester), ['Alerts']);

      // And a tap moves it back.
      await tester.tap(find.bySemanticsLabel('Academics'));
      await tester.pumpAndSettle();
      expect(controller.index, 1);
      expect(_selectedLabels(tester), ['Academics']);
      handle.dispose();
    });
  });

  group('dashboard kit', () {
    testWidgets('the identity card takes initials from the name',
        (tester) async {
      expect(DashboardIdentityCard.initialsOf('Test High Student'), 'TH');
      expect(DashboardIdentityCard.initialsOf('  madonna '), 'M');
      expect(DashboardIdentityCard.initialsOf(''), '?');

      await tester.pumpWidget(wrap(const DashboardIdentityCard(
        title: 'Test High Student',
        subtitle: 'Grade 5 — Section A',
      )));
      expect(find.text('TH'), findsOneWidget);
      expect(find.text('Grade 5 — Section A'), findsOneWidget);
    });

    testWidgets('the stat grid shows every value with its own label',
        (tester) async {
      await tester.pumpWidget(wrap(const DashboardStatGrid(stats: [
        DashboardStat(
            icon: Icons.event_available_rounded,
            accent: Colors.green,
            value: '92%',
            label: 'Attendance',
            sub: 'This month'),
        DashboardStat(
            icon: Icons.grading_rounded,
            accent: Colors.blue,
            value: '3.4',
            label: 'GPA'),
        DashboardStat(
            icon: Icons.assignment_outlined,
            accent: Colors.orange,
            value: '0',
            label: 'Pending homework',
            sub: 'All clear'),
        // Not every "value" is a number, which is why the field is a String.
        DashboardStat(
            icon: Icons.payments_outlined,
            accent: Colors.green,
            value: 'Paid',
            label: 'Fees'),
      ])));

      expect(find.text('92%'), findsOneWidget);
      expect(find.text('Paid'), findsOneWidget);
      expect(find.text('Pending homework'), findsOneWidget);
      expect(find.text('All clear'), findsOneWidget);
    });

    testWidgets('a part-full last row of links keeps the tile width',
        (tester) async {
      // Four links: three across, then one alone — which must be a third of
      // the width, not the whole row.
      await tester.pumpWidget(wrap(DashboardQuickLinks(links: [
        for (final label in ['Report Card', 'Timetable', 'Exams', 'Fees'])
          DashboardLink(icon: Icons.circle, label: label, onTap: () {}),
      ])));

      final first = tester.getSize(find.ancestor(
        of: find.text('Report Card'),
        matching: find.byType(Container),
      ).first);
      final last = tester.getSize(find.ancestor(
        of: find.text('Fees'),
        matching: find.byType(Container),
      ).first);
      expect(last.width, closeTo(first.width, 0.5));
    });

    testWidgets('a stat with no tap target is still rendered', (tester) async {
      // The guardian fees card is tappable and the attendance card is not;
      // both have to draw.
      await tester.pumpWidget(wrap(const DashboardStatCard(
        stat: DashboardStat(
          icon: Icons.event_available_rounded,
          accent: Colors.green,
          value: '0%',
          label: 'Attendance',
          sub: 'This month',
        ),
      )));
      expect(find.text('0%'), findsOneWidget);
    });
  });
}

/// Labels of the tabs currently marked selected in the semantics tree.
List<String> _selectedLabels(WidgetTester tester) {
  final labels = <String>[];
  void visit(SemanticsNode node) {
    if (node.hasFlag(SemanticsFlag.isSelected) && node.label.isNotEmpty) {
      labels.add(node.label);
    }
    node.visitChildren((child) {
      visit(child);
      return true;
    });
  }

  visit(tester.binding.pipelineOwner.semanticsOwner!.rootSemanticsNode!);
  return labels;
}
