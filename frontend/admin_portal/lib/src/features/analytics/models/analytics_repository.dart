import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

import 'analytics_data.dart';

/// Loads the Analytics Overview payload (KPIs + chart series).
class AnalyticsRepository {
  Future<ApiResponse<AnalyticsData>> load() async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return ApiResponse.ok(_mock);
  }

  static const _mock = AnalyticsData(
    metrics: [
      AnalyticsMetric(
        label: 'Total Users',
        value: '124.5K',
        trendPercent: 12.5,
        icon: Icons.groups_rounded,
        iconColor: AppColors.primary,
      ),
      AnalyticsMetric(
        label: 'Active Schools',
        value: '1,204',
        trendPercent: 8.2,
        icon: Icons.apartment_rounded,
        iconColor: AppColors.aiAccent,
      ),
      AnalyticsMetric(
        label: 'Monthly Revenue',
        value: '\$452K',
        trendPercent: 24.1,
        icon: Icons.ondemand_video_rounded,
        iconColor: Color(0xFFE8A317),
      ),
      AnalyticsMetric(
        label: 'Churn Rate',
        value: '2.4%',
        trendPercent: -1.2,
        icon: Icons.sell_rounded,
        iconColor: AppColors.tertiary,
      ),
    ],
    months: ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'],
    students: [38, 42, 55, 60, 78, 104],
    educators: [20, 24, 28, 33, 40, 52],
    totalActive: '4.2k',
    subscriptionShares: [
      SubscriptionShare(label: 'Pro Tier', percent: 45, color: AppColors.primary),
      SubscriptionShare(label: 'Premium', percent: 30, color: AppColors.aiAccent),
      SubscriptionShare(label: 'Basic Plan', percent: 25, color: AppColors.tertiaryFixedDim),
    ],
    revenueByMonth: [30, 45, 38, 60, 52, 72],
  );
}
