import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

/// Student row in the "Overdue Payments" list.
class OverduePayment {
  final String id;
  final String? studentId;
  final String studentName;
  final String grade;
  final int overdueDays;
  final double amount;
  final String? avatarUrl;
  final Color accent;

  const OverduePayment({
    required this.id,
    this.studentId,
    required this.studentName,
    required this.grade,
    required this.overdueDays,
    required this.amount,
    required this.accent,
    this.avatarUrl,
  });

  String get amountLabel =>
      '\$${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';

  factory OverduePayment.fromJson(Map<String, dynamic> json) => OverduePayment(
    id: '${json['id']}',
    studentId: json['student_id']?.toString(),
    studentName: json['student_name'] as String? ?? '',
    grade: '${json['grade'] ?? ''}',
    overdueDays: (json['overdue_days'] as num?)?.toInt() ?? 0,
    amount: (json['amount'] as num?)?.toDouble() ?? 0,
    avatarUrl: json['avatar_url'] as String?,
    accent: AppColors.primary,
  );
}

/// One read-only outstanding-balance age range from `/fees/aging`.
class FeeAgingBucket {
  final String label;
  final int invoiceCount;
  final double outstandingTotal;

  const FeeAgingBucket({
    required this.label,
    required this.invoiceCount,
    required this.outstandingTotal,
  });

  factory FeeAgingBucket.fromJson(Map<String, dynamic> json) => FeeAgingBucket(
    label: json['label'] as String? ?? '',
    invoiceCount: (json['invoice_count'] as num?)?.toInt() ?? 0,
    outstandingTotal: (json['outstanding_total'] as num?)?.toDouble() ?? 0,
  );
}

/// Aggregate Fee Management payload.
class FeesData {
  final String term;
  final String totalCollected;
  /// Change against the previous term; null when no history is available.
  final double? trendPercent;
  final double progressPercent;
  final String targetLabel;
  final String outstandingAmount;
  final int outstandingCount;
  final List<OverduePayment> overdue;
  final List<FeeAgingBucket> aging;

  /// Server-confirmed report date, used to label the read-only aging summary.
  final DateTime? agingAsOfDate;
  final int? reconciliationIssues;

  const FeesData({
    required this.term,
    required this.totalCollected,
    this.trendPercent,
    required this.progressPercent,
    required this.targetLabel,
    required this.outstandingAmount,
    required this.outstandingCount,
    required this.overdue,
    required this.aging,
    this.agingAsOfDate,
    this.reconciliationIssues,
  });

  factory FeesData.fromJson(Map<String, dynamic> json) => FeesData(
    term: json['term'] as String? ?? '',
    totalCollected: '${json['total_collected'] ?? ''}',
    trendPercent: (json['trend_percent'] as num?)?.toDouble(),
    progressPercent: (json['progress_percent'] as num?)?.toDouble() ?? 0,
    targetLabel: json['target_label'] as String? ?? '',
    outstandingAmount: '${json['outstanding_amount'] ?? ''}',
    outstandingCount: (json['outstanding_count'] as num?)?.toInt() ?? 0,
    overdue: ((json['overdue'] as List?) ?? [])
        .map((e) => OverduePayment.fromJson(e as Map<String, dynamic>))
        .toList(),
    aging: ((json['aging'] as List?) ?? [])
        .map((e) => FeeAgingBucket.fromJson(e as Map<String, dynamic>))
        .toList(),
    agingAsOfDate: DateTime.tryParse(json['aging_as_of_date'] as String? ?? ''),
    reconciliationIssues: (json['reconciliation_issues'] as num?)?.toInt(),
  );
}
