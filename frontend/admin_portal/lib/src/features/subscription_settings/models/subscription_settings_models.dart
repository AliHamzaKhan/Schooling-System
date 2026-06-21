import 'package:shared/shared.dart';

/// A metered resource on the current plan (e.g. students, storage).
class UsageMetric {
  final String label;
  final int used;
  final int limit;
  final String unit; // "", "GB"
  const UsageMetric({
    required this.label,
    required this.used,
    required this.limit,
    this.unit = '',
  });

  double get ratio => limit == 0 ? 0 : (used / limit).clamp(0, 1).toDouble();
  bool get nearLimit => ratio >= 0.85;
}

/// The organization's current subscription configuration.
class SubscriptionSettings {
  final String planName;
  final String priceLabel; // "$499 / mo"
  final String renewalDate; // "Jan 15, 2026"
  final String billingCycle; // "Monthly" | "Annual"
  final bool autoRenew;
  final List<UsageMetric> usage;

  const SubscriptionSettings({
    required this.planName,
    required this.priceLabel,
    required this.renewalDate,
    required this.billingCycle,
    required this.autoRenew,
    required this.usage,
  });

  SubscriptionSettings copyWith({String? billingCycle, bool? autoRenew}) =>
      SubscriptionSettings(
        planName: planName,
        priceLabel: priceLabel,
        renewalDate: renewalDate,
        billingCycle: billingCycle ?? this.billingCycle,
        autoRenew: autoRenew ?? this.autoRenew,
        usage: usage,
      );
}

class SubscriptionSettingsRepository {
  Future<ApiResponse<SubscriptionSettings>> load() async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    return ApiResponse.ok(_mock);
  }

  static const _mock = SubscriptionSettings(
    planName: 'Full Suite',
    priceLabel: r'$499 / mo',
    renewalDate: 'Jan 15, 2026',
    billingCycle: 'Monthly',
    autoRenew: true,
    usage: [
      UsageMetric(label: 'Students', used: 2304, limit: 3000),
      UsageMetric(label: 'Staff accounts', used: 454, limit: 500),
      UsageMetric(label: 'Storage', used: 78, limit: 100, unit: 'GB'),
    ],
  );
}
