import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

/// Tag-style chip input — type a value, press add (Enter) → it appears as a
/// removable chip. Used for allergies, conditions, medications.
class ChipInput extends StatefulWidget {
  final String label;
  final String hint;
  final List<String> values;
  final ValueChanged<List<String>> onChanged;
  final bool optional;

  const ChipInput({
    super.key,
    required this.label,
    required this.hint,
    required this.values,
    required this.onChanged,
    this.optional = false,
  });

  @override
  State<ChipInput> createState() => _ChipInputState();
}

class _ChipInputState extends State<ChipInput> {
  final _ctrl = TextEditingController();

  void _add() {
    final v = _ctrl.text.trim();
    if (v.isEmpty || widget.values.contains(v)) return;
    final next = [...widget.values, v];
    widget.onChanged(next);
    _ctrl.clear();
  }

  void _remove(String v) {
    final next = widget.values.where((e) => e != v).toList();
    widget.onChanged(next);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(widget.label,
                  style: AppTypography.labelCaps.copyWith(color: AppColors.onSurfaceVariant),
                  overflow: TextOverflow.ellipsis),
            ),
            if (widget.optional) ...[
              const SizedBox(width: 6),
              Text('· OPTIONAL',
                  style: AppTypography.labelCaps.copyWith(color: AppColors.outline)),
            ],
          ],
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(AppRadius.button),
            border: Border.all(color: AppColors.outlineVariant, width: 1),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.values.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: widget.values
                        .map((v) => Chip(
                              label: Text(v, style: AppTypography.bodySm),
                              onDeleted: () => _remove(v),
                              deleteIconColor: AppColors.onSurfaceVariant,
                              side: BorderSide(color: AppColors.outlineVariant.withValues(alpha: 0.6)),
                              backgroundColor: AppColors.surfaceContainerLow,
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              visualDensity: VisualDensity.compact,
                            ))
                        .toList(),
                  ),
                ),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _ctrl,
                      onSubmitted: (_) => _add(),
                      style: AppTypography.bodyLg.copyWith(color: AppColors.onSurface),
                      decoration: InputDecoration(
                        hintText: widget.hint,
                        hintStyle: AppTypography.bodyLg.copyWith(color: AppColors.outline),
                        border: InputBorder.none,
                        isCollapsed: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 6),
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Add',
                    icon: const Icon(AppIcons.addCircleOutlineRounded,
                        color: AppColors.primary, size: 22),
                    onPressed: _add,
                    splashRadius: 18,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
