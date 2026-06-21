import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

import 'dashboard_data.dart';

class DashboardRepository {
  Future<ApiResponse<DashboardData>> load() async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    return ApiResponse.ok(_mock);
  }

  static const _mock = DashboardData(
    greeting: 'Good morning,\nHeadmaster',
    date: 'Oct 24, 2023',
    metrics: [
      DashboardMetric(
        label: 'Total Students',
        value: '1,248',
        trendPercent: 2,
        icon: Icons.school_rounded,
        color: AppColors.primary,
      ),
      DashboardMetric(
        label: 'Total Teachers',
        value: '84',
        trendPercent: 0,
        icon: Icons.record_voice_over_outlined,
        color: AppColors.aiAccent,
      ),
      DashboardMetric(
        label: "Today's Attendance",
        value: '94.2%',
        trendPercent: -1,
        icon: Icons.how_to_reg_outlined,
        color: Color(0xFFE8A317),
      ),
    ],
    approvals: [
      PendingApproval(
        id: 'AP-1',
        icon: Icons.event_note_outlined,
        title: 'Field Trip Request: Science Museum',
        requestedBy: 'Requested by Mr. Davis (Grade 8)',
      ),
      PendingApproval(
        id: 'AP-2',
        icon: Icons.receipt_long_outlined,
        title: 'Budget Approval: New Art Supplies',
        requestedBy: 'Requested by Ms. Lee (Art Dept)',
      ),
    ],
    announcements: [
      RecentAnnouncementSummary(
        id: 'AN-1',
        title: 'End of Term Examinations Schedule',
        preview: 'The final schedule for the upcoming end of term…',
        timeAgo: '2h ago',
        accent: AppColors.primary,
      ),
      RecentAnnouncementSummary(
        id: 'AN-2',
        title: 'Campus Maintenance Notice',
        preview: 'The West Wing library will be closed for routine maintenance…',
        timeAgo: 'Yesterday',
        accent: AppColors.tertiary,
      ),
    ],
  );
}
