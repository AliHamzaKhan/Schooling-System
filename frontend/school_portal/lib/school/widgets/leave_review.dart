import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

/// One leave request in a reviewer's queue (headmaster or class teacher).
/// Mirrors the backend `LeaveOut` with composed names.
class LeaveReviewItem {
  final String id;
  final String? studentId;
  final String? studentName;
  final String? requesterName;
  final String? studentClass;
  final String? studentSection;
  final String? leaveType;
  final String startDate;
  final String endDate;
  final String? reason;
  final String status; // pending | approved | rejected
  final String? reviewNote;

  const LeaveReviewItem({
    required this.id,
    required this.startDate,
    required this.endDate,
    required this.status,
    this.studentId,
    this.studentName,
    this.requesterName,
    this.studentClass,
    this.studentSection,
    this.leaveType,
    this.reason,
    this.reviewNote,
  });

  bool get isPending => status == 'pending';

  /// "Grade 5 · A" when the student's class+section is known, else null.
  String? get classSectionLabel {
    if (studentClass == null) return null;
    final sec = studentSection == null ? '' : ' · $studentSection';
    return '$studentClass$sec';
  }

  factory LeaveReviewItem.fromJson(Map<String, dynamic> j) => LeaveReviewItem(
        id: '${j['id']}',
        studentId: j['student_id'] as String?,
        studentName: j['student_name'] as String?,
        requesterName: j['requester_name'] as String?,
        studentClass: j['student_class'] as String?,
        studentSection: j['student_section'] as String?,
        leaveType: j['leave_type'] as String?,
        startDate: j['start_date'] as String? ?? '',
        endDate: j['end_date'] as String? ?? '',
        reason: j['reason'] as String?,
        status: (j['status'] as String? ?? 'pending').toLowerCase(),
        reviewNote: j['review_note'] as String?,
      );
}

Color _statusColor(String status) => switch (status) {
      'approved' => AppColors.tertiary,
      'rejected' => AppColors.error,
      _ => const Color(0xFFE8A317),
    };

/// A review card showing who/when/why, with Approve/Reject actions while pending.
class LeaveReviewCard extends StatelessWidget {
  final LeaveReviewItem item;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;
  /// Optional: show this student's past leaves. When provided a "History"
  /// action appears on the card.
  final VoidCallback? onHistory;
  const LeaveReviewCard({
    super.key,
    required this.item,
    this.onApprove,
    this.onReject,
    this.onHistory,
  });

  @override
  Widget build(BuildContext context) {
    final range = item.startDate == item.endDate
        ? item.startDate
        : '${item.startDate}  →  ${item.endDate}';
    final who = item.studentName ?? item.requesterName ?? 'Student';
    final byGuardian = item.requesterName != null &&
        item.studentName != null &&
        item.requesterName != item.studentName;
    return GlassSurface(
      padding: const EdgeInsets.all(AppSpacing.stackLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(who,
                    style: AppTypography.titleMd
                        .copyWith(fontWeight: FontWeight.w700)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _statusColor(item.status).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Text(
                  item.status[0].toUpperCase() + item.status.substring(1),
                  style: AppTypography.labelMd.copyWith(
                      color: _statusColor(item.status),
                      fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          if (item.classSectionLabel != null)
            Row(
              children: [
                const Icon(Icons.class_outlined,
                    size: 14, color: AppColors.onSurfaceVariant),
                const SizedBox(width: 4),
                Text(item.classSectionLabel!,
                    style: AppTypography.bodySm
                        .copyWith(color: AppColors.onSurfaceVariant)),
              ],
            ),
          if (byGuardian)
            Text('Requested by ${item.requesterName}',
                style: AppTypography.bodySm
                    .copyWith(color: AppColors.onSurfaceVariant)),
          const SizedBox(height: AppSpacing.stackSm),
          Row(
            children: [
              const Icon(Icons.event_rounded,
                  size: 16, color: AppColors.onSurfaceVariant),
              const SizedBox(width: 6),
              Text(range, style: AppTypography.bodyMd),
              if ((item.leaveType ?? '').isNotEmpty) ...[
                const SizedBox(width: 10),
                Text('· ${item.leaveType}',
                    style: AppTypography.bodySm
                        .copyWith(color: AppColors.onSurfaceVariant)),
              ],
            ],
          ),
          if ((item.reason ?? '').isNotEmpty) ...[
            const SizedBox(height: AppSpacing.stackSm),
            Text(item.reason!, style: AppTypography.bodyMd),
          ],
          if (item.isPending && (onApprove != null || onReject != null)) ...[
            const SizedBox(height: AppSpacing.stackMd),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onReject,
                    icon: const Icon(Icons.close_rounded, size: 18),
                    label: const Text('Reject'),
                    style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error),
                  ),
                ),
                const SizedBox(width: AppSpacing.stackMd),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: onApprove,
                    icon: const Icon(Icons.check_rounded, size: 18),
                    label: const Text('Approve'),
                  ),
                ),
              ],
            ),
          ],
          if (!item.isPending && (item.reviewNote ?? '').isNotEmpty) ...[
            const SizedBox(height: AppSpacing.stackSm),
            Text('Note: ${item.reviewNote!}',
                style: AppTypography.bodySm
                    .copyWith(color: AppColors.onSurfaceVariant)),
          ],
          if (onHistory != null && item.studentId != null) ...[
            const SizedBox(height: AppSpacing.stackSm),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: onHistory,
                icon: const Icon(Icons.history_rounded, size: 16),
                label: const Text('Leave history'),
                style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 32),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// A read-only history sheet listing every leave a single student has taken.
class LeaveHistorySheet extends StatelessWidget {
  final String studentName;
  final List<LeaveReviewItem> history;
  const LeaveHistorySheet({
    super.key,
    required this.studentName,
    required this.history,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.stackLg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$studentName · Leave history',
                style: AppTypography.titleMd
                    .copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: AppSpacing.stackMd),
            if (history.isEmpty)
              Text('No leave records for this student.',
                  style: AppTypography.bodyMd)
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: history.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AppSpacing.stackSm),
                  itemBuilder: (_, i) {
                    final h = history[i];
                    final range = h.startDate == h.endDate
                        ? h.startDate
                        : '${h.startDate}  →  ${h.endDate}';
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.circle,
                            size: 8, color: _statusColor(h.status)),
                        const SizedBox(width: AppSpacing.stackSm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(range, style: AppTypography.bodyMd),
                              Text(
                                '${h.status[0].toUpperCase()}${h.status.substring(1)}'
                                '${(h.leaveType ?? '').isNotEmpty ? ' · ${h.leaveType}' : ''}'
                                '${(h.reason ?? '').isNotEmpty ? ' · ${h.reason}' : ''}',
                                style: AppTypography.bodySm.copyWith(
                                    color: AppColors.onSurfaceVariant),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
