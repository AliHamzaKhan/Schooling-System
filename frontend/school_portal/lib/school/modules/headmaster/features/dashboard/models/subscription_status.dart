/// The school's subscription status, used to drive the Headmaster expiry alert.
class SubscriptionStatus {
  final bool hasSubscription;
  final String? status;
  final String? planName;
  final DateTime? endDate;
  final int? daysRemaining;
  final bool isExpiringSoon;

  const SubscriptionStatus({
    required this.hasSubscription,
    this.status,
    this.planName,
    this.endDate,
    this.daysRemaining,
    this.isExpiringSoon = false,
  });

  /// True once the subscription has already lapsed.
  bool get isExpired =>
      status == 'expired' || (daysRemaining != null && daysRemaining! < 0);

  factory SubscriptionStatus.fromJson(Map<String, dynamic> j) =>
      SubscriptionStatus(
        hasSubscription: j['has_subscription'] as bool? ?? false,
        status: j['status'] as String?,
        planName: j['plan_name'] as String?,
        endDate: DateTime.tryParse(j['end_date'] as String? ?? ''),
        daysRemaining: (j['days_remaining'] as num?)?.toInt(),
        isExpiringSoon: j['is_expiring_soon'] as bool? ?? false,
      );
}
