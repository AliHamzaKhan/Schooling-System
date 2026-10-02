import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

import '../models/classes_data.dart';

/// Grade card: level badge ("Primary" / "Middle" / "High") + "Grade N" title
/// with overflow menu, then a stack of section rows and an "Add Section" CTA.
class GradeCard extends StatelessWidget {
  final GradeGroup group;
  final VoidCallback? onAddSection;
  final VoidCallback? onMenu;

  /// Fired when a section row is tapped (opens that section's student list).
  final ValueChanged<ClassSection>? onSectionTap;

  const GradeCard({
    super.key,
    required this.group,
    this.onAddSection,
    this.onMenu,
    this.onSectionTap,
  });

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _LevelBadge(level: group.level),
              const Spacer(),
              InkWell(
                onTap: onMenu,
                borderRadius: BorderRadius.circular(AppRadius.full),
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(AppIcons.moreVertRounded,
                      size: 20, color: AppColors.onSurfaceVariant),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.stackSm),
          Text(group.className.isNotEmpty ? group.className : 'Grade ${group.grade}',
              style: AppTypography.headlineLg
                  .copyWith(fontSize: 24, color: AppColors.primary)),
          const SizedBox(height: AppSpacing.stackMd),
          for (var i = 0; i < group.sections.length; i++) ...[
            AccessibleTap(
              onTap: onSectionTap == null
                  ? null
                  : () => onSectionTap!(group.sections[i]),
              child: _SectionRow(section: group.sections[i]),
            ),
            if (i != group.sections.length - 1)
              const SizedBox(height: AppSpacing.stackSm),
          ],
          const SizedBox(height: AppSpacing.stackMd),
          _AddSectionButton(onTap: onAddSection),
        ],
      ),
    );
  }
}

class _LevelBadge extends StatelessWidget {
  final GradeLevel level;
  const _LevelBadge({required this.level});

  @override
  Widget build(BuildContext context) {
    final color = level == GradeLevel.middle ? AppColors.tertiary : level.color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (level == GradeLevel.primary) ...[
            Icon(AppIcons.starRounded, size: 14, color: color),
            const SizedBox(width: 4),
          ],
          Text(level.label,
              style: AppTypography.labelMd.copyWith(color: color, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _SectionRow extends StatelessWidget {
  final ClassSection section;
  const _SectionRow({required this.section});

  @override
  Widget build(BuildContext context) {
    final letter = section.name.split(' ').last.characters.first;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.stackMd),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.button),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: section.accent.withValues(alpha: 0.18),
                child: Text(letter,
                    style: AppTypography.labelMd
                        .copyWith(color: section.accent, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: AppSpacing.stackSm),
              Expanded(
                child: Text(section.name,
                    style: AppTypography.titleMd.copyWith(fontWeight: FontWeight.w600)),
              ),
              const Icon(AppIcons.personOutlineRounded,
                  size: 14, color: AppColors.onSurfaceVariant),
              const SizedBox(width: 4),
              Text('${section.students} Students', style: AppTypography.bodySm),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: AppColors.surfaceContainerHigh,
                backgroundImage: section.teacherAvatarUrl != null
                    ? schoolImage(section.teacherAvatarUrl!)
                    : null,
                child: section.teacherAvatarUrl == null
                    ? const Icon(AppIcons.person, size: 16, color: AppColors.outline)
                    : null,
              ),
              const SizedBox(width: AppSpacing.stackSm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(section.teacher ?? 'Unassigned',
                        style: AppTypography.bodyLg.copyWith(fontWeight: FontWeight.w600)),
                    Text('Homeroom Teacher', style: AppTypography.bodySm),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AddSectionButton extends StatelessWidget {
  final VoidCallback? onTap;
  const _AddSectionButton({this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.button),
      child: DottedBorder(
        radius: AppRadius.button,
        color: AppColors.outlineVariant,
        child: Container(
          height: 44,
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(AppIcons.addCircleOutlineRounded,
                  size: 18, color: AppColors.primary),
              const SizedBox(width: 6),
              Text('Add Section',
                  style: AppTypography.labelMd.copyWith(color: AppColors.primary)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Minimal dashed-rect outline. Kept private to this file — no shared dep.
class DottedBorder extends StatelessWidget {
  final Widget child;
  final Color color;
  final double radius;
  const DottedBorder({
    super.key,
    required this.child,
    required this.color,
    this.radius = 12,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedPainter(color: color, radius: radius),
      child: child,
    );
  }
}

class _DashedPainter extends CustomPainter {
  final Color color;
  final double radius;
  _DashedPainter({required this.color, required this.radius});

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );
    final path = Path()..addRRect(rrect);
    final dashed = Path();
    const dash = 6.0, gap = 4.0;
    for (final metric in path.computeMetrics()) {
      double dist = 0;
      while (dist < metric.length) {
        dashed.addPath(metric.extractPath(dist, dist + dash), Offset.zero);
        dist += dash + gap;
      }
    }
    canvas.drawPath(
      dashed,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(covariant _DashedPainter old) =>
      old.color != color || old.radius != radius;
}
