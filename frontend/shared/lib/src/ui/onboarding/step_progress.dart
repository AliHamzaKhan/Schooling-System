import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

/// Tab-style step indicator + animated progress bar.
class StepProgress extends StatelessWidget {
  final List<String> steps;
  final int current;
  final ValueChanged<int>? onTap;

  const StepProgress({
    super.key,
    required this.steps,
    required this.current,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 600;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Labels — tappable for already-visited steps
            Row(
              children: steps.asMap().entries.map((e) {
                final i = e.key;
                final isActive = i == current;
                final isVisited = i <= current;
                final canTap = onTap != null && isVisited;
                return Expanded(
                  child: InkWell(
                    onTap: canTap ? () => onTap!(i) : null,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                      child: Text(
                        compact ? '${i + 1}. ${_short(e.value)}' : e.value,
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.labelCaps.copyWith(
                          color: isActive ? AppColors.primary : (isVisited ? AppColors.onSurfaceVariant : AppColors.outline),
                          fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 6),
            // Progress bar
            Stack(
              children: [
                Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                AnimatedFractionallySizedBox(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  widthFactor: (current + 1) / steps.length,
                  child: Container(
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  String _short(String label) {
    // Trim long step labels in compact mode.
    final words = label.split(' ');
    if (words.length == 1) return label;
    return words.first;
  }
}
