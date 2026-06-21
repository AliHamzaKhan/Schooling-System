import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

import 'exam.dart';

class ExamsRepository {
  Future<ApiResponse<ExamsData>> load() async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    return ApiResponse.ok(_mock);
  }

  static const _mock = ExamsData(
    comingThisMonth: 3,
    next: ExamCountdown(
      days: 3,
      hours: 14,
      title: 'Midterm Mathematics',
      date: 'Oct 24',
      time: '09:00 AM',
      location: 'Hall A, Science Building',
    ),
    timeline: [
      UpcomingExam(
        id: 'E-1',
        title: 'Physics Fundamentals',
        date: 'Oct 26',
        time: '14:00 PM',
        location: 'Lab Room 3B',
        dateShort: 'OCT 26',
        accent: Color(0xFFE8A317),
      ),
      UpcomingExam(
        id: 'E-2',
        title: 'World History Eras',
        date: 'Nov 02',
        time: '10:30 AM',
        location: 'Main Auditorium',
        dateShort: 'NOV 02',
        accent: AppColors.primary,
      ),
    ],
  );
}
