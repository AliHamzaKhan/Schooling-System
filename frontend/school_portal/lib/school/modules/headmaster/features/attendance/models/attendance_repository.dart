import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

import 'attendance_data.dart';

/// Loads the daily attendance dashboard payload.
class AttendanceRepository {
  Future<ApiResponse<AttendanceData>> load(AttendanceRange range) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    return ApiResponse.ok(range == AttendanceRange.week ? _week : _month);
  }

  static const _month = AttendanceData(
    metrics: [
      AttendanceMetric(
        label: 'STUDENTS PRESENT',
        value: '1,248',
        trendPercent: 2.4,
        icon: Icons.school_rounded,
        color: AppColors.primary,
      ),
      AttendanceMetric(
        label: 'TEACHERS PRESENT',
        value: '112',
        trendPercent: 0.5,
        icon: Icons.workspace_premium_outlined,
        color: Color(0xFFE8A317),
      ),
      AttendanceMetric(
        label: 'TOTAL ABSENCES',
        value: '45',
        trendPercent: -1.2,
        icon: Icons.do_not_disturb_alt_rounded,
        color: AppColors.error,
      ),
      AttendanceMetric(
        label: 'LATE ARRIVALS',
        value: '18',
        trendPercent: 0,
        icon: Icons.access_time_rounded,
        color: AppColors.aiAccent,
      ),
    ],
    studentRatePercent: 94,
    teacherRatePercent: 98,
    trendLabels: ['Oct 1', 'Oct 8', 'Oct 15', 'Oct 22', 'Oct 29'],
    studentTrend: [88, 91, 86, 95, 93],
    teacherTrend: [60, 70, 55, 80, 75],
    grades: [
      GradeAttendance(grade: 1, name: 'Grade 1 - Explorers', percent: 96, color: AppColors.primary),
      GradeAttendance(grade: 2, name: 'Grade 2 - Navigators', percent: 92, color: AppColors.aiAccent),
      GradeAttendance(grade: 3, name: 'Grade 3 - Voyagers', percent: 95, color: AppColors.tertiary),
    ],
  );

  static const _week = AttendanceData(
    metrics: [
      AttendanceMetric(
        label: 'STUDENTS PRESENT',
        value: '1,231',
        trendPercent: 1.1,
        icon: Icons.school_rounded,
        color: AppColors.primary,
      ),
      AttendanceMetric(
        label: 'TEACHERS PRESENT',
        value: '110',
        trendPercent: 0.0,
        icon: Icons.workspace_premium_outlined,
        color: Color(0xFFE8A317),
      ),
      AttendanceMetric(
        label: 'TOTAL ABSENCES',
        value: '52',
        trendPercent: 1.4,
        icon: Icons.do_not_disturb_alt_rounded,
        color: AppColors.error,
      ),
      AttendanceMetric(
        label: 'LATE ARRIVALS',
        value: '22',
        trendPercent: 3.0,
        icon: Icons.access_time_rounded,
        color: AppColors.aiAccent,
      ),
    ],
    studentRatePercent: 91,
    teacherRatePercent: 96,
    trendLabels: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'],
    studentTrend: [82, 88, 90, 85, 91],
    teacherTrend: [55, 62, 70, 68, 75],
    grades: [
      GradeAttendance(grade: 1, name: 'Grade 1 - Explorers', percent: 93, color: AppColors.primary),
      GradeAttendance(grade: 2, name: 'Grade 2 - Navigators', percent: 90, color: AppColors.aiAccent),
      GradeAttendance(grade: 3, name: 'Grade 3 - Voyagers', percent: 92, color: AppColors.tertiary),
    ],
  );
}
