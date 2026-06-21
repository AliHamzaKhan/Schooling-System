import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

import 'performance_data.dart';

class PerformanceRepository {
  Future<ApiResponse<StudentDetail>> load(String? studentId) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    return ApiResponse.ok(_mock);
  }

  static const _mock = StudentDetail(
    id: '884920',
    name: 'Leo Carter',
    grade: 'Grade 8',
    subject: 'Advanced Math',
    currentGpa: '3.8',
    attendancePercent: '96%',
    trendLabels: ['Sep', 'Oct', 'Nov', 'Dec', 'Jan', 'Feb'],
    trendScores: [82, 84, 88, 86, 92, 94],
    week: [
      WeekDay('Mon', DayMark.present),
      WeekDay('Tue', DayMark.present),
      WeekDay('Wed', DayMark.absent),
      WeekDay('Thu', DayMark.present),
      WeekDay('Fri', DayMark.present),
    ],
    recent: [
      GradeFeedback(
        id: 'G-1',
        title: 'Midterm Algebra Exam',
        dateLine: 'Oct 24',
        quote: '"Great improvement on quadratic equations."',
        grade: 'A-',
        icon: Icons.menu_book_outlined,
        iconColor: AppColors.primary,
      ),
      GradeFeedback(
        id: 'G-2',
        title: 'Pop Quiz: Geometry',
        dateLine: 'Oct 18',
        quote: '"Review triangle postulates."',
        grade: 'C+',
        icon: Icons.quiz_outlined,
        iconColor: AppColors.error,
      ),
      GradeFeedback(
        id: 'G-3',
        title: 'Group Project: Statistics',
        dateLine: 'Oct 10',
        quote: '"Excellent leadership and data presentation."',
        grade: 'A',
        icon: Icons.groups_outlined,
        iconColor: AppColors.tertiary,
      ),
    ],
  );
}
