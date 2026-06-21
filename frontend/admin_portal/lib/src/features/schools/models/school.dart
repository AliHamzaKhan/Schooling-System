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

  const School({
    required this.id,
    required this.name,
    required this.location,
    required this.students,
    required this.status,
    required this.tenureLabel,
    this.logoUrl,
  });

  String get initial => name.isEmpty ? '?' : name.characters.first.toUpperCase();

  factory School.fromJson(Map<String, dynamic> j) => School(
        id: j['id'] as String,
        name: j['name'] as String,
        location: j['location'] as String,
        students: (j['students'] as num).toInt(),
        status: SchoolStatus.values.byName(j['status'] as String? ?? 'active'),
        tenureLabel: j['tenureLabel'] as String? ?? '',
        logoUrl: j['logoUrl'] as String?,
      );
}
