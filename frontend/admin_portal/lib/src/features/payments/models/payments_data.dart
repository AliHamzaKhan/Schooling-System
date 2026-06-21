import 'package:flutter/material.dart';

/// A headline payments KPI card.
class PaymentStat {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const PaymentStat({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });
}

/// Monthly revenue split into subscription vs add-on components.
class RevenueMonth {
  final String month;
  final double subscriptions;
  final double addOns;
  const RevenueMonth({required this.month, required this.subscriptions, required this.addOns});

  double get total => subscriptions + addOns;
}

/// Payload for the Payments & Billing screen.
class PaymentsData {
  final List<PaymentStat> stats;
  final List<RevenueMonth> revenue;
  const PaymentsData({required this.stats, required this.revenue});
}
