import 'package:flutter/material.dart';
import 'package:persistent_bottom_nav_bar/persistent_bottom_nav_bar.dart';
import 'package:shared/shared.dart';

import 'portal_tab_scaffold.dart';

/// The module bottom navigation bar: **icons only**, with the active tab drawn
/// as a filled navy rounded square.
///
/// Hand-drawn rather than one of `persistent_bottom_nav_bar`'s built-in styles,
/// because none of them is this: style 7 (what this replaced) animates the
/// active item into a 120px capsule and shows its label inside, which is a
/// different shape and a different amount of text. The package still owns the
/// screens, the state and the Android back button — only the bar itself is
/// ours.
///
/// Dropping the labels costs the one thing labels were doing, so it is paid
/// back explicitly: every item carries a [Semantics] label and a tooltip, so
/// the tab names are still there for a screen reader and for a long press.
class PortalNavBar extends StatelessWidget {
  final List<PortalTab> tabs;
  final PersistentTabController controller;

  const PortalNavBar({
    super.key,
    required this.tabs,
    required this.controller,
  });

  /// Height of the bar itself, excluding the bottom safe area.
  static const double height = 64;

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
              _NavItem(
                tab: tabs[i],
                selected: controller.index == i,
                onTap: () => controller.jumpToTab(i),
              ),
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
      child: Tooltip(
        message: tab.label,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.defaultR),
          // A 48×48 target regardless of how small the pill is drawn: the
          // visual is 44×40, which on its own is under the minimum tap size.
          child: SizedBox(
            width: 56,
            height: 48,
            child: Center(
              child: AnimatedContainer(
                duration: AppMotion.fast,
                curve: Curves.easeOut,
                width: 44,
                height: 40,
                decoration: BoxDecoration(
                  color: selected ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppRadius.sm + 4),
                ),
                child: Icon(
                  tab.icon,
                  size: 22,
                  color: selected
                      ? AppColors.surfaceContainerLowest
                      : AppColors.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
