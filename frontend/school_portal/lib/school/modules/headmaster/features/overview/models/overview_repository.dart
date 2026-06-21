import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

import 'overview_data.dart';

class OverviewRepository {
  Future<ApiResponse<OverviewData>> load() async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    return ApiResponse.ok(_mock);
  }

  static const _mock = OverviewData(
    school: SchoolIdentity(
      name: 'Oakridge Academy',
      address: '123 Learning Lane, Eduville',
      principal: 'Dr. Sarah Jenkins',
    ),
    pulse: [
      PulseMetric(
        label: 'Average Grade',
        value: 'B+',
        icon: Icons.star_rounded,
        accent: AppColors.primary,
        trendLabel: '+2.4%',
        trendColor: AppColors.tertiary,
        trendIcon: Icons.trending_up_rounded,
      ),
      PulseMetric(
        label: 'Daily Attendance',
        value: '94.2%',
        icon: Icons.fact_check_outlined,
        accent: AppColors.tertiary,
        trendLabel: '98%',
        trendColor: AppColors.tertiary,
        trendIcon: Icons.trending_up_rounded,
      ),
      PulseMetric(
        label: 'Teacher Retention',
        value: '92%',
        icon: Icons.psychology_alt_outlined,
        accent: AppColors.aiAccent,
        trendLabel: 'Stable',
        trendColor: AppColors.onSurfaceVariant,
      ),
      PulseMetric(
        label: 'Active Projects',
        value: '24',
        icon: Icons.engineering_outlined,
        accent: Color(0xFFE8A317),
      ),
    ],
    events: [
      UpcomingEvent(
        id: 'EV-1',
        title: 'Annual Science Fair',
        time: '09:00 AM - 03:00 PM',
        location: 'Main Hall',
        month: 'OCT',
        day: '12',
        tint: AppColors.primary,
        icon: Icons.science_outlined,
      ),
      UpcomingEvent(
        id: 'EV-2',
        title: 'Autumn Concert',
        time: '04:00 PM',
        location: 'Auditorium',
        month: 'OCT',
        day: '18',
        tint: Color(0xFFE8A317),
        icon: Icons.music_note_outlined,
      ),
    ],
  );
}
