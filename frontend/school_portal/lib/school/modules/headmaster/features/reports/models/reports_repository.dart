import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

import 'reports_data.dart';

class ReportsRepository {
  Future<ApiResponse<ReportsData>> load() async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    return ApiResponse.ok(_mock);
  }

  static const _mock = ReportsData(
    metrics: [
      ReportMetric(
        label: 'TOTAL ENROLLMENT',
        value: '1,432',
        trendPercent: 8.4,
        icon: Icons.groups_rounded,
        color: AppColors.primary,
        spark: [3, 3, 3.5, 3.5, 4, 6],
      ),
      ReportMetric(
        label: 'AVG ASSESSMENT SCORE',
        value: '86.4%',
        trendPercent: 2.1,
        icon: Icons.workspace_premium_outlined,
        color: Color(0xFFE8A317),
        spark: [3, 3, 3, 3, 3, 5],
      ),
      ReportMetric(
        label: 'REVENUE COLLECTED',
        value: '\$1.2M',
        trendPercent: -1.5,
        icon: Icons.ondemand_video_rounded,
        color: AppColors.tertiary,
        spark: [4, 4, 4, 4, 4, 5],
      ),
    ],
    currentYearScores: [45, 68, 82, 90],
    previousYearScores: [38, 50, 60, 68],
    performanceLabels: ['Q1', 'Q2', 'Q3', 'Q4'],
    enrollmentByYear: {'Y7': 280, 'Y8': 310, 'Y9': 290, 'Y10': 320, 'Y11': 232},
  );
}
