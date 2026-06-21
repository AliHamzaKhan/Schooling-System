import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

/// Numbered pager with prev/next chevrons and ellipsis collapsing
/// (e.g. `‹ 1 2 3 … 12 ›`). 1-based [current] page.
class PaginationBar extends StatelessWidget {
  final int current;
  final int total;
  final ValueChanged<int> onChanged;

  const PaginationBar({
    super.key,
    required this.current,
    required this.total,
    required this.onChanged,
  });

  /// Page numbers to render, with `null` marking an ellipsis gap.
  List<int?> get _pages {
    if (total <= 4) return [for (var i = 1; i <= total; i++) i];
    final pages = <int>{1, 2, 3};
    if (current > 3 && current < total) pages.add(current);
    pages.add(total);
    final sorted = pages.toList()..sort();
    final out = <int?>[];
    int? prev;
    for (final p in sorted) {
      if (prev != null && p - prev > 1) out.add(null);
      out.add(p);
      prev = p;
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _Chevron(
          icon: Icons.chevron_left_rounded,
          enabled: current > 1,
          onTap: () => onChanged(current - 1),
        ),
        const SizedBox(width: 6),
        for (final p in _pages) ...[
          if (p == null)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 6),
              child: Text('…', style: AppTypography.bodyMd),
            )
          else
            _PageDot(page: p, selected: p == current, onTap: () => onChanged(p)),
          const SizedBox(width: 6),
        ],
        _Chevron(
          icon: Icons.chevron_right_rounded,
          enabled: current < total,
          onTap: () => onChanged(current + 1),
        ),
      ],
    );
  }
}

class _PageDot extends StatelessWidget {
  final int page;
  final bool selected;
  final VoidCallback onTap;
  const _PageDot({required this.page, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surfaceContainerLowest,
          shape: BoxShape.circle,
        ),
        child: Text(
          '$page',
          style: AppTypography.labelMd.copyWith(
            color: selected ? AppColors.onPrimary : AppColors.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _Chevron extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;
  const _Chevron({required this.icon, required this.enabled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 36,
        height: 36,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 20,
          color: enabled ? AppColors.onSurfaceVariant : AppColors.outlineVariant,
        ),
      ),
    );
  }
}
