import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

/// Student row in the "Overdue Payments" list.
class OverduePayment {
  final String id;
  final String studentName;
  final String grade;
  final int overdueDays;
  final double amount;
  final String? avatarUrl;
  final Color accent;

  const OverduePayment({
    required this.id,
    required this.studentName,
    required this.grade,
    required this.overdueDays,
    required this.amount,
    required this.accent,
    this.avatarUrl,
  });

  String get amountLabel => '\$${amount.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
        (m) => '${m[1]},',
      )}';

  factory OverduePayment.fromJson(Map<String, dynamic> json) => OverduePayment(
        id: '${json['id']}',
        studentName: json['student_name'] as String? ?? '',
        grade: '${json['grade'] ?? ''}',
        overdueDays: (json['overdue_days'] as num?)?.toInt() ?? 0,
        amount: (json['amount'] as num?)?.toDouble() ?? 0,
        avatarUrl: json['avatar_url'] as String?,
        accent: AppColors.primary,
      );
}

/// Aggregate Fee Management payload.
class FeesData {
  final String term;
  final String totalCollected;
  final double trendPercent;
  final double progressPercent;
  final String targetLabel;
  final String outstandingAmount;
  final int outstandingCount;
  final List<OverduePayment> overdue;

  const FeesData({
    required this.term,
    required this.totalCollected,
    required this.trendPercent,
    required this.progressPercent,
    required this.targetLabel,
    required this.outstandingAmount,
    required this.outstandingCount,
    required this.overdue,
  });

  factory FeesData.fromJson(Map<String, dynamic> json) => FeesData(
        term: json['term'] as String? ?? '',
        totalCollected: '${json['total_collected'] ?? ''}',
        trendPercent: (json['trend_percent'] as num?)?.toDouble() ?? 0,
        progressPercent: (json['progress_percent'] as num?)?.toDouble() ?? 0,
        targetLabel: json['target_label'] as String? ?? '',
        outstandingAmount: '${json['outstanding_amount'] ?? ''}',
        outstandingCount: (json['outstanding_count'] as num?)?.toInt() ?? 0,
        overdue: ((json['overdue'] as List?) ?? [])
            .map((e) => OverduePayment.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
