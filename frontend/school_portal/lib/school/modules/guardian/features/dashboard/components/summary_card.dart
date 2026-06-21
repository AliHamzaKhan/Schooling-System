import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

/// Compact summary metric card used in the dashboard's per-child grid.
class SummaryCard extends StatelessWidget {
  final IconData icon;
  final Color accent;
  final String label;
  final String value;
  final String? sub;
  final VoidCallback? onTap;

  const SummaryCard({
    super.key,
    required this.icon,
    required this.accent,
    required this.label,
    required this.value,
    this.sub,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: GlassSurface(
        padding: const EdgeInsets.all(AppSpacing.stackMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.14),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 18, color: accent),
            ),
            const SizedBox(height: AppSpacing.stackMd),
            Text(value,
                style: AppTypography.headlineLg.copyWith(fontSize: 24)),
            const SizedBox(height: 2),
            Text(label, style: AppTypography.bodyMd),
            if (sub != null) ...[
              const SizedBox(height: 2),
              Text(sub!,
                  style: AppTypography.labelMd.copyWith(color: accent)),
            ],
          ],
        ),
      ),
    );
  }
}
