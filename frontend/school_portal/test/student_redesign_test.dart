import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared/shared.dart';
import 'package:school_portal/school/modules/student/widgets/student_gradient_header.dart';
import 'package:school_portal/school/widgets/dashboard_kit.dart';

void main() {
  for (final width in [320.0, 390.0, 1200.0]) {
    testWidgets('student learning surfaces at $width with large text', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: MediaQuery(
            data: MediaQueryData(
              size: Size(width, 1000),
              textScaler: TextScaler.linear(1.3),
              disableAnimations: true,
            ),
            child: Scaffold(
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const StudentGradientHeader(
                      name: 'Ayesha',
                      subtitle: 'Student',
                    ),
                    const SizedBox(height: 24),
                    const DashboardStatGrid(
                      stats: [
                        DashboardStat(
                          icon: Icons.check_circle,
                          accent: AppColors.tertiary,
                          value: '94%',
                          label: 'Attendance',
                          sub: 'This month',
                        ),
                        DashboardStat(
                          icon: Icons.assignment,
                          accent: AppColors.secondary,
                          value: '3',
                          label: 'Pending homework',
                          sub: 'Due soon',
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    DashboardQuickLinks(
                      links: [
                        DashboardLink(
                          icon: Icons.book,
                          label: 'Courses',
                          onTap: () {},
                        ),
                        DashboardLink(
                          icon: Icons.quiz,
                          label: 'Quizzes',
                          onTap: () {},
                        ),
                        DashboardLink(
                          icon: Icons.calendar_month,
                          label: 'Timetable',
                          onTap: () {},
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Hey, Ayesha!'), findsOneWidget);
      expect(find.text('94%'), findsOneWidget);
    });
  }
}
