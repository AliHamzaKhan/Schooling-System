import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

/// Numbered-circle step indicator with connecting lines and labels beneath
/// (e.g. 1 School Details — 2 Contact Info — 3 Initial Plan).
class NumberedStepper extends StatelessWidget {
  final List<String> steps;
  final int current;

  const NumberedStepper({super.key, required this.steps, required this.current});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < steps.length; i++) ...[
          _StepNode(index: i, label: steps[i], current: current),
          if (i != steps.length - 1)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 17),
                child: Container(
                  height: 2,
                  color: i < current
                      ? AppColors.primary
                      : AppColors.outlineVariant,
                ),
              ),
            ),
        ],
      ],
    );
  }
}

class _StepNode extends StatelessWidget {
  final int index;
  final String label;
  final int current;
  const _StepNode({required this.index, required this.label, required this.current});

  @override
  Widget build(BuildContext context) {
    final done = index < current;
    final active = index == current;
    final filled = done || active;
    return SizedBox(
      width: 72,
      child: Column(
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: filled ? AppColors.primary : AppColors.surfaceContainerHigh,
              shape: BoxShape.circle,
            ),
            child: done
                ? const Icon(Icons.check_rounded, color: AppColors.onPrimary, size: 18)
                : Text('${index + 1}',
                    style: AppTypography.titleMd.copyWith(
                      color: filled ? AppColors.onPrimary : AppColors.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    )),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            style: AppTypography.bodySm.copyWith(
              color: active ? AppColors.primary : AppColors.onSurfaceVariant,
              fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
