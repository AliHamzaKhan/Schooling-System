import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

enum LeaveStatus { pending, approved, rejected }

extension LeaveStatusX on LeaveStatus {
  String get label => switch (this) {
        LeaveStatus.pending => 'Pending',
        LeaveStatus.approved => 'Approved',
        LeaveStatus.rejected => 'Rejected',
      };

  Color get color => switch (this) {
        LeaveStatus.pending => const Color(0xFFE8A317),
        LeaveStatus.approved => AppColors.tertiary,
        LeaveStatus.rejected => AppColors.error,
      };

  IconData get icon => switch (this) {
        LeaveStatus.pending => AppIcons.hourglassTopRounded,
        LeaveStatus.approved => AppIcons.checkCircleOutlineRounded,
        LeaveStatus.rejected => AppIcons.cancelOutlined,
      };
}

/// A leave application the student has submitted, mirroring the backend
/// `LeaveOut`. Reviewer identity is intentionally not surfaced to the student.
class LeaveRequest {
  final String id;
  final String? leaveType;
  final String startDate;
  final String endDate;
  final String? reason;
  final LeaveStatus status;
  final String? reviewNote;

  const LeaveRequest({
    required this.id,
    required this.startDate,
    required this.endDate,
    required this.status,
    this.leaveType,
    this.reason,
    this.reviewNote,
  });

  factory LeaveRequest.fromJson(Map<String, dynamic> j) => LeaveRequest(
        id: '${j['id']}',
        leaveType: j['leave_type'] as String?,
        startDate: j['start_date'] as String? ?? '',
        endDate: j['end_date'] as String? ?? '',
        reason: j['reason'] as String?,
        status: switch ((j['status'] as String? ?? '').toLowerCase()) {
          'approved' => LeaveStatus.approved,
          'rejected' => LeaveStatus.rejected,
          _ => LeaveStatus.pending,
        },
        reviewNote: j['review_note'] as String?,
      );
}
