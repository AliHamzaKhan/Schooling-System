import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

import 'fees_data.dart';

class FeesRepository {
  Future<ApiResponse<FeesData>> load() async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    return ApiResponse.ok(_mock);
  }

  static const _mock = FeesData(
    term: 'Term 2',
    totalCollected: '\$452,800',
    trendPercent: 12,
    progressPercent: 0.85,
    targetLabel: '85% (\$530,000)',
    outstandingAmount: '\$77,200',
    outstandingCount: 42,
    overdue: [
      OverduePayment(
        id: 'P-1',
        studentName: 'Emma Thompson',
        grade: 'Grade 8',
        overdueDays: 14,
        amount: 1200,
        accent: AppColors.primary,
      ),
      OverduePayment(
        id: 'P-2',
        studentName: 'Lucas Chen',
        grade: 'Grade 10',
        overdueDays: 7,
        amount: 850,
        accent: Color(0xFFE8A317),
      ),
      OverduePayment(
        id: 'P-3',
        studentName: 'Sophia Martinez',
        grade: 'Grade 3',
        overdueDays: 21,
        amount: 2100,
        accent: AppColors.tertiary,
      ),
    ],
  );
}
