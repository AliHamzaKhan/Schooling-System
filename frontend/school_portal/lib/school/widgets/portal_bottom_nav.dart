import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

class PortalNavItem {
  final IconData icon;
  final String label;
  const PortalNavItem({required this.icon, required this.label});
}

/// Dark pill-rounded bottom nav matching the school_portal screens. Selected
/// item gets a navy chip; unselected sit muted in light text.
class PortalBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<PortalNavItem> items;

  const PortalBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: Container(
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: AppColors.inverseSurface,
            borderRadius: BorderRadius.circular(AppRadius.md),
            boxShadow: const [
              BoxShadow(color: Color(0x331A2A6C), blurRadius: 24, offset: Offset(0, 8)),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (var i = 0; i < items.length; i++)
                _Cell(
                  item: items[i],
                  selected: i == currentIndex,
                  onTap: () => onTap(i),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  final PortalNavItem item;
  final bool selected;
  final VoidCallback onTap;
  const _Cell({required this.item, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.onPrimary : AppColors.inverseOnSurface;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.button),
        child: AnimatedContainer(
          duration: AppMotion.fast,
          curve: Curves.easeOut,
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(item.icon, size: 20, color: color),
              const SizedBox(height: 2),
              Text(
                item.label,
                style: AppTypography.labelCaps.copyWith(
                  color: color,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
