import 'package:flutter/material.dart';

/// A headline payments KPI card.
class PaymentStat {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  /// Optional supporting line under the value (e.g. "+12% from last month").
  /// Rendered in [captionColor] when both are set.
  final String? caption;
  final Color? captionColor;

  const PaymentStat({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.caption,
    this.captionColor,
  });
}
