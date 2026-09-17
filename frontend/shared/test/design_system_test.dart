import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared/shared.dart';

Widget _app(
  Widget child, {
  double width = 800,
  double textScale = 1,
  bool disableAnimations = false,
}) {
  return MaterialApp(
    theme: AppTheme.light(),
    home: MediaQuery(
      data: MediaQueryData(
        size: Size(width, 1000),
        textScaler: TextScaler.linear(textScale),
        disableAnimations: disableAnimations,
      ),
      child: Scaffold(body: child),
    ),
  );
}

void main() {
  double contrast(Color foreground, Color background) {
    final light = foreground.computeLuminance();
    final dark = background.computeLuminance();
    final brighter = light > dark ? light : dark;
    final dimmer = light > dark ? dark : light;
    return (brighter + 0.05) / (dimmer + 0.05);
  }

  test('representative text color pairs meet WCAG AA contrast', () {
    final pairs = <(Color, Color)>[
      (AppColors.onSurface, AppColors.background),
      (AppColors.onSurfaceVariant, AppColors.card),
      (AppColors.onPrimary, AppColors.primary),
      (AppColors.onSecondary, AppColors.secondary),
      (AppColors.onTertiary, AppColors.tertiary),
      (AppColors.onError, AppColors.error),
      (AppColors.onPrimaryContainer, AppColors.primaryContainer),
    ];

    for (final pair in pairs) {
      expect(
        contrast(pair.$1, pair.$2),
        greaterThanOrEqualTo(4.5),
        reason: '${pair.$1} on ${pair.$2}',
      );
    }
  });

  testWidgets('state views expose one concise live-region announcement', (
    tester,
  ) async {
    var retries = 0;
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      _app(
        AppStateView.error(
          title: 'Could not load attendance',
          message: 'Check your connection and try again.',
          actionLabel: 'Try again',
          onAction: () => retries++,
        ),
      ),
    );

    expect(
      find.bySemanticsLabel(
        'Could not load attendance. Check your connection and try again.',
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('Try again'));
    expect(retries, 1);
    semantics.dispose();
  });

  testWidgets('interactive card exposes its supplied accessible name', (
    tester,
  ) async {
    var taps = 0;
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      _app(
        Center(
          child: AppCard(
            semanticLabel: 'Open Mathematics course',
            onTap: () => taps++,
            child: const Text('Mathematics'),
          ),
        ),
      ),
    );

    await tester.tap(find.bySemanticsLabel('Open Mathematics course'));
    expect(taps, 1);
    semantics.dispose();
  });

  testWidgets('catalogue primitives tolerate narrow layout at 200% text', (
    tester,
  ) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      _app(
        ListView(
          padding: const EdgeInsets.all(AppSpacing.stackMd),
          children: [
            AppTextField(
              controller: controller,
              label: 'Guardian email address',
              helperText: 'Used for account recovery and school notices.',
              required: true,
            ),
            const SizedBox(height: AppSpacing.stackMd),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Current term', style: AppTypography.titleLg),
                  const Text('September to December'),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.stackMd),
            const AppDataTable(
              semanticLabel: 'Student attendance summary',
              columns: [
                DataColumn(label: Text('Student name')),
                DataColumn(label: Text('Attendance status')),
                DataColumn(label: Text('Last updated')),
              ],
              rows: [
                DataRow(
                  cells: [
                    DataCell(Text('Ayesha Khan')),
                    DataCell(Text('Present')),
                    DataCell(Text('16 September 2026')),
                  ],
                ),
              ],
            ),
            const AppStateView.empty(
              title: 'No more results',
              message: 'Try changing the current filters.',
            ),
          ],
        ),
        width: 320,
        textScale: 2,
        disableAnimations: true,
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('Guardian email address (required)'), findsOneWidget);
    expect(find.text('Ayesha Khan'), findsOneWidget);
    expect(find.text('No more results'), findsOneWidget);
  });

  testWidgets('expanded actions reflow at 200% text', (tester) async {
    await tester.pumpWidget(
      _app(
        Center(
          child: SizedBox(
            width: 280,
            child: PrimaryButton(
              label: 'Save school settings',
              expanded: true,
              onPressed: () {},
            ),
          ),
        ),
        width: 320,
        textScale: 2,
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Save school settings'), findsOneWidget);
  });

  testWidgets('FadeSlideIn renders immediately when motion is reduced', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        const FadeSlideIn(child: Text('Ready without motion')),
        disableAnimations: true,
      ),
    );

    final opacity = tester.widgetList<Opacity>(find.byType(Opacity));
    expect(opacity, isEmpty);
    expect(find.text('Ready without motion'), findsOneWidget);
  });

  testWidgets(
    'dialogs omit scale and badge animations when motion is reduced',
    (tester) async {
      await tester.pumpWidget(
        GetMaterialApp(
          theme: AppTheme.light(),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: child!,
          ),
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () => showAppAlert(
                icon: Icons.info_outline,
                title: 'Important information',
                message: 'The dialog is available without decorative motion.',
              ),
              child: const Text('Open dialog'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open dialog'));
      await tester.pump();

      expect(find.text('Important information'), findsOneWidget);
      expect(find.byType(ScaleTransition), findsNothing);
      expect(find.byType(TweenAnimationBuilder<double>), findsNothing);
    },
  );
}
