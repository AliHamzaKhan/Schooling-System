/// Active-user counts for a school (backend `SchoolStatsOut`).
class SchoolStats {
  final int students;
  final int teachers;
  final int guardians;
  final int totalUsers;

  const SchoolStats({
    required this.students,
    required this.teachers,
    required this.guardians,
    required this.totalUsers,
  });

  factory SchoolStats.fromJson(Map<String, dynamic> j) => SchoolStats(
        students: (j['students'] as num?)?.toInt() ?? 0,
        teachers: (j['teachers'] as num?)?.toInt() ?? 0,
        guardians: (j['guardians'] as num?)?.toInt() ?? 0,
        totalUsers: (j['total_users'] as num?)?.toInt() ?? 0,
      );
}

/// One recorded payment in a school's billing ledger (backend `PaymentOut`).
class SchoolPayment {
  final String id;
  final double amount;
  final DateTime paidAt;
  final DateTime periodStart;
  final DateTime periodEnd;
  final String status;
  final String? planName;

  const SchoolPayment({
    required this.id,
    required this.amount,
    required this.paidAt,
    required this.periodStart,
    required this.periodEnd,
    required this.status,
    this.planName,
  });

  factory SchoolPayment.fromJson(Map<String, dynamic> j) => SchoolPayment(
        id: j['id']?.toString() ?? '',
        amount: (j['amount'] as num?)?.toDouble() ?? 0,
        paidAt: DateTime.tryParse(j['paid_at'] as String? ?? '') ?? DateTime.now(),
        periodStart:
            DateTime.tryParse(j['period_start'] as String? ?? '') ?? DateTime.now(),
        periodEnd:
            DateTime.tryParse(j['period_end'] as String? ?? '') ?? DateTime.now(),
        status: j['status'] as String? ?? 'paid',
        planName: j['plan_name'] as String?,
      );
}
