import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

import '../models/attendance_models.dart';

/// One student row: avatar, name + ID line, and a pill containing three
/// circular action buttons (Present / Late / Absent). The currently-selected
/// state tints with that mark's color.
class AttendanceStudentRow extends StatelessWidget {
  final AttendanceStudent student;
  final AttendanceMark mark;
  final ValueChanged<AttendanceMark> onChanged;

  const AttendanceStudentRow({
    super.key,
    required this.student,
    required this.mark,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: student.accent.withValues(alpha: 0.18),
              child: Text(student.initial,
                  style: AppTypography.titleMd.copyWith(color: student.accent)),
            ),
            const SizedBox(width: AppSpacing.stackSm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(student.name,
                      style: AppTypography.titleMd
                          .copyWith(fontWeight: FontWeight.w700)),
                  Text('ID: ${student.id}', style: AppTypography.bodySm),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _ActionButton(
                  active: mark == AttendanceMark.present,
                  mark: AttendanceMark.present,
                  onTap: () => onChanged(AttendanceMark.present)),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _ActionButton(
                  active: mark == AttendanceMark.late,
                  mark: AttendanceMark.late,
                  onTap: () => onChanged(AttendanceMark.late)),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _ActionButton(
                  active: mark == AttendanceMark.absent,
                  mark: AttendanceMark.absent,
                  onTap: () => onChanged(AttendanceMark.absent)),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.stackMd),
        const Divider(height: 1, color: AppColors.outlineVariant),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final bool active;
  final AttendanceMark mark;
  final VoidCallback onTap;

  const _ActionButton({
    required this.active,
    required this.mark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = mark.color;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        decoration: BoxDecoration(
          color: active
              ? color.withValues(alpha: 0.18)
              : AppColors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(AppRadius.full),
          border: Border.all(
              color: active ? color : AppColors.outlineVariant, width: 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(mark.icon,
                size: 16,
                color: active ? color : AppColors.onSurfaceVariant),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                mark.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.labelMd.copyWith(
                    color: active ? color : AppColors.onSurfaceVariant,
                    fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
