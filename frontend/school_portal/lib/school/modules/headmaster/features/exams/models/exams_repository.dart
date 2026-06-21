import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

import 'exams_data.dart';

class ExamsRepository {
  Future<ApiResponse<ExamsData>> load() async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    return ApiResponse.ok(_mock);
  }

  static const _mock = ExamsData(
    activeExams: 3,
    upcomingExams: 12,
    pendingResults: 4,
    schedule: [
      ExamScheduleItem(
        id: 'E-001',
        subject: 'Midterm Mathematics',
        grade: 'Grade 10',
        schedule: 'In Progress (45m remaining)',
        location: '',
        icon: Icons.adjust_rounded,
        iconColor: AppColors.error,
        status: ExamStatus.live,
      ),
      ExamScheduleItem(
        id: 'E-002',
        subject: 'Physics Practical',
        grade: 'Grade 11',
        schedule: 'Tomorrow, 10:00 AM',
        location: 'Lab B',
        icon: Icons.science_outlined,
        iconColor: AppColors.primary,
        status: ExamStatus.upcoming,
      ),
      ExamScheduleItem(
        id: 'E-003',
        subject: 'Literature Essay',
        grade: 'Grade 12',
        schedule: 'Oct 24, 09:00 AM',
        location: 'Hall A',
        icon: Icons.menu_book_outlined,
        iconColor: AppColors.tertiary,
        status: ExamStatus.upcoming,
      ),
    ],
    recent: [
      RecentStudent(id: '98234', name: 'Emma Thompson', accent: AppColors.tertiary),
      RecentStudent(id: '98235', name: 'Lucas Chen', accent: Color(0xFFE8A317)),
    ],
    gradeDistribution: {'A': 38, 'B': 52, 'C': 28, 'D': 12, 'F': 4},
  );
}
