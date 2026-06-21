import 'package:flutter/material.dart';

/// A child (student) linked to the signed-in guardian. The Guardian module is
/// multi-child: every feature reads the currently selected [Child] from the
/// [GuardianSessionController].
class Child {
  final String id;
  final String name;
  final String grade; // e.g. "Grade 5 — Section B"
  final String? photoUrl;

  /// At-a-glance figures used by dashboard summary cards.
  final int attendancePercent; // 0..100
  final double gpa; // 0..4
  final int pendingHomework;
  final bool feesDue;

  const Child({
    required this.id,
    required this.name,
    required this.grade,
    this.photoUrl,
    required this.attendancePercent,
    required this.gpa,
    required this.pendingHomework,
    required this.feesDue,
  });

  /// Parse a child from the backend JSON shape.
  factory Child.fromJson(Map<String, dynamic> json) => Child(
        id: '${json['id']}',
        name: json['name'] as String? ?? '',
        grade: json['grade'] as String? ?? '',
        photoUrl: json['photo_url'] as String?,
        attendancePercent: (json['attendance_percent'] as num?)?.toInt() ?? 0,
        gpa: (json['gpa'] as num?)?.toDouble() ?? 0,
        pendingHomework: (json['pending_homework'] as num?)?.toInt() ?? 0,
        feesDue: json['fees_due'] as bool? ?? false,
      );

  /// Initials for the avatar fallback ("Aanya Khan" -> "AK").
  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.characters.first.toUpperCase();
    return (parts.first.characters.first + parts.last.characters.first)
        .toUpperCase();
  }
}
