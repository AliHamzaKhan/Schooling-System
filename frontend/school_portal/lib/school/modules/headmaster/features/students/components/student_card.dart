import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

import '../models/student.dart';

/// Centered student card: overflow menu in the corner, large avatar, name +
/// roll number, then two side-by-side info pills for Grade and Section.
/// Status-colored left rail.
class StudentCard extends StatelessWidget {
  final Student student;
  final VoidCallback? onTap;
  final VoidCallback? onMenu;

  const StudentCard({super.key, required this.student, this.onTap, this.onMenu});

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      padding: EdgeInsets.zero,
      onTap: onTap,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 5,
              decoration: BoxDecoration(
                color: student.status.color,
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(AppRadius.card),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.stackMd),
                child: Column(
                  children: [
                    Align(
                      alignment: Alignment.centerRight,
                      child: InkWell(
                        onTap: onMenu,
                        borderRadius: BorderRadius.circular(AppRadius.full),
                        child: const Padding(
                          padding: EdgeInsets.all(4),
                          child: Icon(Icons.more_vert_rounded,
                              size: 20, color: AppColors.onSurfaceVariant),
                        ),
                      ),
                    ),
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: student.status.color.withValues(alpha: 0.18),
                      backgroundImage: student.avatarUrl != null
                          ? NetworkImage(student.avatarUrl!)
                          : null,
                      child: student.avatarUrl == null
                          ? Text(student.initials,
                              style: AppTypography.headlineLg
                                  .copyWith(color: student.status.color, fontSize: 22))
                          : null,
                    ),
                    const SizedBox(height: AppSpacing.stackSm),
                    Text(student.name,
                        style: AppTypography.headlineLg.copyWith(fontSize: 22)),
                    const SizedBox(height: 2),
                    Text('Roll: #${student.roll}', style: AppTypography.bodyMd),
                    const SizedBox(height: AppSpacing.stackMd),
                    Row(
                      children: [
                        Expanded(child: _InfoPill(label: 'GRADE', value: student.grade)),
                        const SizedBox(width: AppSpacing.stackSm),
                        Expanded(child: _InfoPill(label: 'SECTION', value: student.section)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final String label;
  final String value;
  const _InfoPill({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Column(
        children: [
          Text(label,
              style: AppTypography.labelCaps
                  .copyWith(color: AppColors.onSurfaceVariant)),
          Text(value, style: AppTypography.titleMd.copyWith(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
