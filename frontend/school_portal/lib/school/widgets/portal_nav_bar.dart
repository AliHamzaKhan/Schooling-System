import 'package:flutter/material.dart';
import 'package:persistent_bottom_nav_bar/persistent_bottom_nav_bar.dart';
import 'package:shared/shared.dart';

import 'portal_tab_scaffold.dart';

/// Labeled mobile navigation with a softly tinted active indicator.
///
/// Hand-drawn rather than one of `persistent_bottom_nav_bar`'s built-in styles,
/// because none of them is this: style 7 (what this replaced) animates the
/// active item into a 120px capsule and shows its label inside, which is a
/// different shape and a different amount of text. The package still owns the
/// screens, the state and the Android back button — only the bar itself is
/// ours.
///
/// Each item exposes one semantic label and action, so its visible text and
/// tooltip do not cause duplicate announcements for screen readers.
class PortalNavBar extends StatelessWidget {
  final List<PortalTab> tabs;
  final PersistentTabController controller;

  const PortalNavBar({super.key, required this.tabs, required this.controller});

  /// Height of the bar itself, excluding the bottom safe area.
  static const double height = 76;

  @override
  Widget build(BuildContext context) {
    // Rebuilds on tab change: the controller is a ChangeNotifier, and it is the
    // single source of truth for which tab is active — a local copy here would
    // be a second one, and the two would disagree the first time a screen
    // switched tabs programmatically.
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) => Container(
        height: height,
        decoration: const BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          border: Border(
            top: BorderSide(color: AppColors.outlineVariant, width: 0.5),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            for (var i = 0; i < tabs.length; i++)
              Expanded(child: _NavItem(
                tab: tabs[i],
                selected: controller.index == i,
                onTap: () => controller.jumpToTab(i),
              )),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final PortalTab tab;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.tab,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: tab.label,
      excludeSemantics: true,
      onTap: onTap,
      child: Tooltip(
        message: tab.label,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.defaultR),
          // A 48×48 target regardless of how small the pill is drawn: the
          // visual is 44×40, which on its own is under the minimum tap size.
          child: SizedBox(
            width: 62,
            height: 68,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedContainer(
                  duration: MediaQuery.disableAnimationsOf(context)
                      ? Duration.zero
                      : AppMotion.fast,
                  curve: Curves.easeOut,
                  width: 48,
                  height: 34,
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.primary.withValues(alpha: .12)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(AppRadius.sm + 4),
                  ),
                  child: Icon(
                    tab.icon,
                    size: 22,
                    color: selected
                        ? AppColors.primary
                        : AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  tab.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.labelCaps.copyWith(
                    letterSpacing: 0,
                    color: selected
                        ? AppColors.primary
                        : AppColors.onSurfaceVariant,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
