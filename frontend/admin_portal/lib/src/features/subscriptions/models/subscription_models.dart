import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

/// Billing duration of a plan/subscription term. Mirrors the backend
/// `BillingPeriod` enum (monthly / six_month / annual).
enum BillingPeriod { monthly, sixMonth, annual }

extension BillingPeriodX on BillingPeriod {
  /// Backend wire value.
  String get code => switch (this) {
        BillingPeriod.monthly => 'monthly',
        BillingPeriod.sixMonth => 'six_month',
        BillingPeriod.annual => 'annual',
      };

  String get label => switch (this) {
        BillingPeriod.monthly => 'Monthly',
        BillingPeriod.sixMonth => '6-Month',
        BillingPeriod.annual => 'Annual',
      };

  /// Suffix shown next to a price, e.g. "$299 / mo".
  String get priceSuffix => switch (this) {
        BillingPeriod.monthly => '/ mo',
        BillingPeriod.sixMonth => '/ 6 mo',
        BillingPeriod.annual => '/ yr',
      };

  static BillingPeriod fromCode(String? c) => switch (c) {
        'six_month' => BillingPeriod.sixMonth,
        'annual' => BillingPeriod.annual,
        _ => BillingPeriod.monthly,
      };
}

/// How a discount is applied when assigning a subscription.
enum DiscountType { none, percent, fixed }

extension DiscountTypeX on DiscountType {
  String get code => switch (this) {
        DiscountType.none => 'none',
        DiscountType.percent => 'percent',
        DiscountType.fixed => 'fixed',
      };
}

/// Lifecycle of a per-school subscription. Mirrors backend `SubscriptionStatus`.
enum SubscriptionStatus { pending, active, expired, cancelled }

extension SubscriptionStatusX on SubscriptionStatus {
  String get label => switch (this) {
        SubscriptionStatus.pending => 'Pending',
        SubscriptionStatus.active => 'Active',
        SubscriptionStatus.expired => 'Expired',
        SubscriptionStatus.cancelled => 'Cancelled',
      };

  Color get color => switch (this) {
        SubscriptionStatus.active => AppColors.primary,
        SubscriptionStatus.pending => AppColors.aiAccent,
        SubscriptionStatus.expired => AppColors.error,
        SubscriptionStatus.cancelled => AppColors.onSurfaceVariant,
      };

  static SubscriptionStatus fromCode(String? c) => switch (c) {
        'active' => SubscriptionStatus.active,
        'pending' => SubscriptionStatus.pending,
        'expired' => SubscriptionStatus.expired,
        'cancelled' => SubscriptionStatus.cancelled,
        _ => SubscriptionStatus.pending,
      };
}

/// An admin-editable subscription plan (product) from `/subscription-plans`.
class SubscriptionPlanModel {
  final String id;
  final String code;
  final String name;
  final String? description;
  final double price;
  final BillingPeriod billingPeriod;
  final List<String> modules;
  final bool isActive;

  const SubscriptionPlanModel({
    required this.id,
    required this.code,
    required this.name,
    required this.price,
    required this.billingPeriod,
    this.description,
    this.modules = const [],
    this.isActive = true,
  });

  factory SubscriptionPlanModel.fromJson(Map<String, dynamic> j) =>
      SubscriptionPlanModel(
        id: j['id']?.toString() ?? '',
        code: j['code'] as String? ?? '',
        name: j['name'] as String? ?? '',
        description: j['description'] as String?,
        price: (j['price'] as num?)?.toDouble() ?? 0,
        billingPeriod: BillingPeriodX.fromCode(j['billing_period'] as String?),
        modules: (j['modules'] as List? ?? const [])
            .map((e) => e.toString())
            .toList(),
        isActive: j['is_active'] as bool? ?? true,
      );
}

/// A per-school subscription instance from `/subscriptions`.
class SchoolSubscriptionModel {
  final String id;
  final String schoolId;
  final String? schoolName;
  final String planId;
  final String? planName;
  final SubscriptionStatus status;
  final DateTime startDate;
  final DateTime endDate;
  final BillingPeriod billingPeriod;
  final double basePrice;
  final double netAmount;

  const SchoolSubscriptionModel({
    required this.id,
    required this.schoolId,
    required this.planId,
    required this.status,
    required this.startDate,
    required this.endDate,
    required this.billingPeriod,
    required this.basePrice,
    required this.netAmount,
    this.schoolName,
    this.planName,
  });

  factory SchoolSubscriptionModel.fromJson(Map<String, dynamic> j) =>
      SchoolSubscriptionModel(
        id: j['id']?.toString() ?? '',
        schoolId: j['school_id']?.toString() ?? '',
        schoolName: j['school_name'] as String?,
        planId: j['plan_id']?.toString() ?? '',
        planName: j['plan_name'] as String?,
        status: SubscriptionStatusX.fromCode(j['status'] as String?),
        startDate: DateTime.tryParse(j['start_date'] as String? ?? '') ??
            DateTime.now(),
        endDate:
            DateTime.tryParse(j['end_date'] as String? ?? '') ?? DateTime.now(),
        billingPeriod: BillingPeriodX.fromCode(j['billing_period'] as String?),
        basePrice: (j['base_price'] as num?)?.toDouble() ?? 0,
        netAmount: (j['net_amount'] as num?)?.toDouble() ?? 0,
      );
}
