import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

/// Lifecycle state of a school's account on the platform.
enum SchoolStatus { active, trial, expired, pending }

extension SchoolStatusX on SchoolStatus {
  String get label => switch (this) {
        SchoolStatus.active => 'Active',
        SchoolStatus.trial => 'Trial',
        SchoolStatus.expired => 'Expired',
        SchoolStatus.pending => 'Pending',
      };

  /// Accent rail + status-pill color for this state.
  Color get color => switch (this) {
        SchoolStatus.active => AppColors.primary,
        SchoolStatus.trial => const Color(0xFFE8A317),
        SchoolStatus.expired => AppColors.error,
        SchoolStatus.pending => AppColors.aiAccent,
      };
}

/// A school/institution row in the admin School Management list.
class School {
  final String id;
  final String name;
  final String location;
  final int students;
  final SchoolStatus status;

  /// Contextual line under the location — e.g. "Joined Aug 2022",
  /// "12 Days Left", "Expired Jan 15".
  final String tenureLabel;

  /// Optional logo URL; when null the card shows a lettered placeholder.
  final String? logoUrl;

  // ── Backend fields (SchoolOut) ──────────────────────────────
  /// Unique school code (backend `code`); empty for mock rows.
  final String code;
  final String? contactEmail;
  final String? contactPhone;

  /// Full street address from the backend (`address`); the UI's [location] is
  /// derived from this when present.
  final String? address;

  /// Active subscription plan code/name from `subscription_plan`, if any.
  final String? planCode;
  final String? planName;

  /// The backend `settings` JSON blob (branding + billing/payment-mode keys).
  /// Kept so edit-mode writes can merge into it without dropping keys owned by
  /// the headmaster (uniform_color, logo_url, fee_due_day…).
  final Map<String, dynamic> settings;

  const School({
    required this.id,
    required this.name,
    required this.location,
    required this.students,
    required this.status,
    required this.tenureLabel,
    this.logoUrl,
    this.code = '',
    this.contactEmail,
    this.contactPhone,
    this.address,
    this.planCode,
    this.planName,
    this.settings = const {},
  });

  String get initial => name.isEmpty ? '?' : name.characters.first.toUpperCase();

  /// Uniform accent color (hex, e.g. "#1565C0") set by the headmaster, if any.
  String? get uniformColor => settings['uniform_color'] as String?;

  /// How this school pays us for their subscription (payment-mode block), or an
  /// empty map when none has been recorded yet.
  Map<String, dynamic> get billing =>
      (settings['billing'] as Map?)?.cast<String, dynamic>() ?? const {};

  /// Maps the backend `SchoolStatus` (pending/active/suspended) onto the UI
  /// enum. The backend has no trial/expired states; `suspended` is surfaced as
  /// [SchoolStatus.expired] (closest existing visual treatment).
  static SchoolStatus _statusFromApi(String? s) => switch (s) {
        'active' => SchoolStatus.active,
        'pending' => SchoolStatus.pending,
        'suspended' => SchoolStatus.expired,
        _ => SchoolStatus.pending,
      };

  /// Parses the backend `SchoolOut` payload. The backend does not expose a
  /// student count or tenure, so [students] defaults to 0 and [tenureLabel] is
  /// derived from status until those fields exist.
  factory School.fromJson(Map<String, dynamic> j) {
    final status = _statusFromApi(j['status'] as String?);
    final plan = j['subscription_plan'];
    final address = j['address'] as String?;
    return School(
      id: j['id']?.toString() ?? '',
      name: j['name'] as String? ?? '',
      location: (address == null || address.isEmpty) ? '—' : address,
      students: (j['students'] as num?)?.toInt() ?? 0,
      status: status,
      tenureLabel: status.label,
      logoUrl: j['logoUrl'] as String?,
      code: j['code'] as String? ?? '',
      contactEmail: j['contact_email'] as String?,
      contactPhone: j['contact_phone'] as String?,
      address: address,
      planCode: plan is Map ? plan['code'] as String? : null,
      planName: plan is Map ? plan['name'] as String? : null,
      settings: (j['settings'] as Map?)?.cast<String, dynamic>() ?? const {},
    );
  }
}
