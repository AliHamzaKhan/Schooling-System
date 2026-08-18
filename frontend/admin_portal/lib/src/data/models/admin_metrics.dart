/// Platform metrics that back the admin Dashboard KPIs and the revenue report.
library;

/// Live KPI payload from `/admin/dashboard`.
class AdminDashboardData {
  final int totalSchools;
  final int activeSubscriptions;
  final double monthlyRevenue;

  const AdminDashboardData({
    required this.totalSchools,
    required this.activeSubscriptions,
    required this.monthlyRevenue,
  });

  factory AdminDashboardData.fromJson(Map<String, dynamic> j) =>
      AdminDashboardData(
        totalSchools: (j['total_schools'] as num?)?.toInt() ?? 0,
        activeSubscriptions: (j['active_subscriptions'] as num?)?.toInt() ?? 0,
        monthlyRevenue: (j['monthly_revenue'] as num?)?.toDouble() ?? 0,
      );
}

/// One month bucket in the revenue report (`/admin/revenue`).
class RevenueMonth {
  final String month; // "YYYY-MM"
  final double total;
  final int count;

  const RevenueMonth({
    required this.month,
    required this.total,
    required this.count,
  });

  factory RevenueMonth.fromJson(Map<String, dynamic> j) => RevenueMonth(
        month: j['month'] as String? ?? '',
        total: (j['total'] as num?)?.toDouble() ?? 0,
        count: (j['count'] as num?)?.toInt() ?? 0,
      );
}

/// Full revenue report: a window of monthly buckets plus their sum.
class RevenueReport {
  final double total;
  final List<RevenueMonth> months;

  const RevenueReport({required this.total, required this.months});

  factory RevenueReport.fromJson(Map<String, dynamic> j) => RevenueReport(
        total: (j['total'] as num?)?.toDouble() ?? 0,
        months: (j['months'] as List? ?? const [])
            .map((e) => RevenueMonth.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

/// One recorded payment in the billing ledger (`/admin/billing`).
class PaymentRow {
  final String id;
  final String? schoolName;
  final String? planName;
  final double amount;
  final DateTime paidAt;

  const PaymentRow({
    required this.id,
    required this.amount,
    required this.paidAt,
    this.schoolName,
    this.planName,
  });

  factory PaymentRow.fromJson(Map<String, dynamic> j) => PaymentRow(
        id: j['id']?.toString() ?? '',
        schoolName: j['school_name'] as String?,
        planName: j['plan_name'] as String?,
        amount: (j['amount'] as num?)?.toDouble() ?? 0,
        paidAt: DateTime.tryParse(j['paid_at'] as String? ?? '') ?? DateTime.now(),
      );
}

/// Billing overview payload (`/admin/billing`).
class BillingReport {
  final double totalRevenue;
  final double thisMonthRevenue;
  final int paymentCount;
  final double pendingAmount;
  final List<PaymentRow> recent;
  final List<RevenueMonth> months;

  const BillingReport({
    required this.totalRevenue,
    required this.thisMonthRevenue,
    required this.paymentCount,
    required this.pendingAmount,
    required this.recent,
    required this.months,
  });

  factory BillingReport.fromJson(Map<String, dynamic> j) => BillingReport(
        totalRevenue: (j['total_revenue'] as num?)?.toDouble() ?? 0,
        thisMonthRevenue: (j['this_month_revenue'] as num?)?.toDouble() ?? 0,
        paymentCount: (j['payment_count'] as num?)?.toInt() ?? 0,
        pendingAmount: (j['pending_amount'] as num?)?.toDouble() ?? 0,
        recent: (j['recent'] as List? ?? const [])
            .map((e) => PaymentRow.fromJson(e as Map<String, dynamic>))
            .toList(),
        months: (j['months'] as List? ?? const [])
            .map((e) => RevenueMonth.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

/// One point on the transactions progress chart (`/admin/transactions`).
class TransactionBucket {
  final String label; // "YYYY-MM-DD" (month range) or "YYYY-MM" (year / all)
  final double total;
  final int count;

  const TransactionBucket({
    required this.label,
    required this.total,
    required this.count,
  });

  factory TransactionBucket.fromJson(Map<String, dynamic> j) => TransactionBucket(
        label: j['label'] as String? ?? '',
        total: (j['total'] as num?)?.toDouble() ?? 0,
        count: (j['count'] as num?)?.toInt() ?? 0,
      );
}

/// Filtered ledger view backing the "View All" transactions screen.
class TransactionsReport {
  final String range; // "month" | "year" | "all"
  final double total;
  final int count;
  final List<TransactionBucket> buckets;
  final List<PaymentRow> transactions;

  const TransactionsReport({
    required this.range,
    required this.total,
    required this.count,
    required this.buckets,
    required this.transactions,
  });

  factory TransactionsReport.fromJson(Map<String, dynamic> j) => TransactionsReport(
        range: j['range'] as String? ?? 'all',
        total: (j['total'] as num?)?.toDouble() ?? 0,
        count: (j['count'] as num?)?.toInt() ?? 0,
        buckets: (j['buckets'] as List? ?? const [])
            .map((e) => TransactionBucket.fromJson(e as Map<String, dynamic>))
            .toList(),
        transactions: (j['transactions'] as List? ?? const [])
            .map((e) => PaymentRow.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

/// One slice of the active-subscription plan distribution.
class PlanShare {
  final String planName;
  final int count;
  final double percent;

  const PlanShare({
    required this.planName,
    required this.count,
    required this.percent,
  });

  factory PlanShare.fromJson(Map<String, dynamic> j) => PlanShare(
        planName: j['plan_name'] as String? ?? '',
        count: (j['count'] as num?)?.toInt() ?? 0,
        percent: (j['percent'] as num?)?.toDouble() ?? 0,
      );
}

/// Platform metrics payload (`/admin/metrics`).
class MetricsReport {
  final int totalSchools;
  final int activeSubscriptions;
  final int totalUsers;
  final double monthlyRevenue;
  final double churnRate;
  final List<PlanShare> planDistribution;
  final List<RevenueMonth> revenueByMonth;

  const MetricsReport({
    required this.totalSchools,
    required this.activeSubscriptions,
    required this.totalUsers,
    required this.monthlyRevenue,
    required this.churnRate,
    required this.planDistribution,
    required this.revenueByMonth,
  });

  factory MetricsReport.fromJson(Map<String, dynamic> j) => MetricsReport(
        totalSchools: (j['total_schools'] as num?)?.toInt() ?? 0,
        activeSubscriptions: (j['active_subscriptions'] as num?)?.toInt() ?? 0,
        totalUsers: (j['total_users'] as num?)?.toInt() ?? 0,
        monthlyRevenue: (j['monthly_revenue'] as num?)?.toDouble() ?? 0,
        churnRate: (j['churn_rate'] as num?)?.toDouble() ?? 0,
        planDistribution: (j['plan_distribution'] as List? ?? const [])
            .map((e) => PlanShare.fromJson(e as Map<String, dynamic>))
            .toList(),
        revenueByMonth: (j['revenue_by_month'] as List? ?? const [])
            .map((e) => RevenueMonth.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
