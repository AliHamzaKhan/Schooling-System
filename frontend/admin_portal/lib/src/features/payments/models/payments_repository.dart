import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

import 'payments_data.dart';

/// Loads the Payments & Billing dashboard payload.
class PaymentsRepository {
  Future<ApiResponse<PaymentsData>> load() async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return ApiResponse.ok(_mock);
  }

  static const _mock = PaymentsData(
    stats: [
      PaymentStat(
        label: 'Total Revenue',
        value: '\$124,500.00',
        icon: Icons.account_balance_wallet_outlined,
        color: AppColors.primary,
      ),
      PaymentStat(
        label: 'Successful Payments',
        value: '1,245',
        icon: Icons.check_circle_outline_rounded,
        color: AppColors.tertiary,
      ),
      PaymentStat(
        label: 'Pending Settlements',
        value: '\$8,230.50',
        icon: Icons.pending_actions_outlined,
        color: Color(0xFFE8A317),
      ),
    ],
    revenue: [
      RevenueMonth(month: 'Jan', subscriptions: 28, addOns: 6),
      RevenueMonth(month: 'Feb', subscriptions: 24, addOns: 8),
      RevenueMonth(month: 'Mar', subscriptions: 40, addOns: 10),
      RevenueMonth(month: 'Apr', subscriptions: 52, addOns: 12),
      RevenueMonth(month: 'May', subscriptions: 48, addOns: 14),
      RevenueMonth(month: 'Jun', subscriptions: 60, addOns: 18),
    ],
  );
}
