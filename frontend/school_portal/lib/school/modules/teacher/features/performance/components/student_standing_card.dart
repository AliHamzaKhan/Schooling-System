import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

import '../models/section_performance.dart';

/// One ranked student row: rank badge, name, and the three measures the
/// ranking is built from — attendance, average marks, grade.
///
/// Actions live behind the overflow menu rather than as inline buttons, so the
/// row stays readable across a whole class list.
class StudentStandingCard extends StatelessWidget {
  final StudentStanding student;
  final int rank;
  final VoidCallback? onTap;
  final VoidCallback? onMenu;

  const StudentStandingCard({
    super.key,
    required this.student,
    required this.rank,
    this.onTap,
    this.onMenu,
  });

  /// Top three get a medal tint; everyone else a neutral chip.
  Color get _rankColor => switch (rank) {
        1 => const Color(0xFFD4AF37),
        2 => const Color(0xFF9CA3AF),
        3 => const Color(0xFFB87333),
        _ => AppColors.outlineVariant,
      };

  @override
  Widget build(BuildContext context) {
    final noData = student.hasNoData;
    return GlassSurface(
      padding: const EdgeInsets.all(AppSpacing.stackMd),
      onTap: onTap,
      child: Row(
        children: [
          _RankBadge(rank: rank, color: _rankColor),
          const SizedBox(width: AppSpacing.stackSm),
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.primaryContainer,
            child: Text(student.initials,
                style: AppTypography.labelMd
                    .copyWith(color: AppColors.onPrimary, fontWeight: FontWeight.w800)),
          ),
          const SizedBox(width: AppSpacing.stackSm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(student.fullName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.titleMd
                        .copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                if (noData)
                  Text('No attendance or marks recorded yet',
                      style: AppTypography.bodySm
                          .copyWith(color: AppColors.onSurfaceVariant))
                else
                  Row(
                    children: [
                      _Metric(
                        icon: AppIcons.eventAvailableOutlined,
                        label: student.totalDays == 0
                            ? '—'
                            : '${(student.attendanceRate * 100).round()}%',
                        tint: _attendanceTint(student),
                      ),
                      const SizedBox(width: AppSpacing.stackMd),
                      _Metric(
                        icon: AppIcons.schoolOutlined,
                        label: student.papersCounted == 0
                            ? '—'
                            : '${student.averagePercentage.toStringAsFixed(0)}%',
                        tint: AppColors.onSurfaceVariant,
                      ),
                    ],
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.stackSm),
          _GradePill(grade: student.grade),
          if (onMenu != null)
            IconButton(
              onPressed: onMenu,
              visualDensity: VisualDensity.compact,
              icon: const Icon(AppIcons.moreVertRounded,
                  size: 20, color: AppColors.onSurfaceVariant),
            ),
        ],
      ),
    );
  }

  static Color _attendanceTint(StudentStanding s) {
    if (s.totalDays == 0) return AppColors.onSurfaceVariant;
    if (s.attendanceRate >= 0.9) return AppColors.tertiary;
    if (s.attendanceRate >= 0.75) return const Color(0xFFE8A317);
    return AppColors.error;
  }
}

class _RankBadge extends StatelessWidget {
  final int rank;
  final Color color;
  const _RankBadge({required this.rank, required this.color});

  @override
  Widget build(BuildContext context) {
    final medal = rank <= 3;
    return Container(
      width: 26,
      height: 26,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: medal ? color.withValues(alpha: 0.18) : AppColors.surfaceContainerLow,
        shape: BoxShape.circle,
        border: Border.all(color: medal ? color : AppColors.outlineVariant),
      ),
      child: Text('$rank',
          style: AppTypography.labelMd.copyWith(
            fontWeight: FontWeight.w800,
            color: medal ? color : AppColors.onSurfaceVariant,
          )),
    );
  }
}

class _Metric extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color tint;
  const _Metric({required this.icon, required this.label, required this.tint});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: tint),
        const SizedBox(width: 3),
        Text(label,
            style: AppTypography.bodySm
                .copyWith(color: tint, fontWeight: FontWeight.w700)),
      ],
    );
  }
}

class _GradePill extends StatelessWidget {
  final String grade;
  const _GradePill({required this.grade});

  @override
  Widget build(BuildContext context) {
    final unknown = grade == '—';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: unknown
            ? AppColors.surfaceContainerLow
            : AppColors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Text(grade,
          style: AppTypography.labelMd.copyWith(
            fontWeight: FontWeight.w800,
            color: unknown ? AppColors.onSurfaceVariant : AppColors.primary,
          )),
    );
  }
}
