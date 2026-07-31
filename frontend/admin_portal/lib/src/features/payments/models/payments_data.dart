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
