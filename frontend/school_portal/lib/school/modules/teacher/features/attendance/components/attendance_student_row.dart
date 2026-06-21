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
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(AppRadius.full),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ActionDot(
                  active: mark == AttendanceMark.present,
                  color: AttendanceMark.present.color,
                  icon: AttendanceMark.present.icon,
                  onTap: () => onChanged(AttendanceMark.present)),
              const SizedBox(width: 14),
              _ActionDot(
                  active: mark == AttendanceMark.late,
                  color: AttendanceMark.late.color,
                  icon: AttendanceMark.late.icon,
                  onTap: () => onChanged(AttendanceMark.late)),
              const SizedBox(width: 14),
              _ActionDot(
                  active: mark == AttendanceMark.absent,
                  color: AttendanceMark.absent.color,
                  icon: AttendanceMark.absent.icon,
                  onTap: () => onChanged(AttendanceMark.absent)),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.stackMd),
        const Divider(height: 1, color: AppColors.outlineVariant),
      ],
    );
  }
}

class _ActionDot extends StatelessWidget {
  final bool active;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;

  const _ActionDot({
    required this.active,
    required this.color,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: active ? color.withValues(alpha: 0.18) : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Icon(icon,
            size: 18,
            color: active ? color : AppColors.onSurfaceVariant),
      ),
    );
  }
}
