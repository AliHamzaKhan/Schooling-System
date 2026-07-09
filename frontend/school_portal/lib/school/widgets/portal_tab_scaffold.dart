import 'package:flutter/material.dart';
import 'package:persistent_bottom_nav_bar/persistent_bottom_nav_bar.dart';
import 'package:shared/shared.dart';

/// One bottom-nav tab spec (icon + label).
class PortalTab {
  final IconData icon;
  final String label;
  const PortalTab(this.icon, this.label);
}

/// Shared module shell: a style-7 persistent bottom nav
/// (persistent_bottom_nav_bar) with no Material app bar — each tab screen owns
/// its single compact [PortalTopBar] header (which carries the account/logout
/// menu). The first tab gets an animated home⇄menu icon; the rest use their
/// Material icon.
class PortalTabScaffold extends StatefulWidget {
  /// Retained for call-site compatibility; no longer rendered (the header now
  /// lives inside each tab screen's [PortalTopBar]).
  final String title;
  final List<PortalTab> tabs;
  final List<Widget> screens;

  /// Optional externally-owned controller — pass one when a screen needs to
  /// switch tabs programmatically (e.g. a button that jumps to "Alerts").
  final PersistentTabController? controller;

  const PortalTabScaffold({
    super.key,
    required this.title,
    required this.tabs,
    required this.screens,
    this.controller,
  });

  @override
  State<PortalTabScaffold> createState() => _PortalTabScaffoldState();
}

class _PortalTabScaffoldState extends State<PortalTabScaffold>
    with TickerProviderStateMixin {
  late final PersistentTabController _tabController =
      widget.controller ?? PersistentTabController(initialIndex: 0);
  bool get _ownsController => widget.controller == null;
  late final AnimationController _homeAnim =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
  late final Animation<double> _homeAnimValue =
      Tween<double>(begin: 0, end: 1).animate(_homeAnim);

  @override
  void initState() {
    super.initState();
    _homeAnim.forward();
  }

  @override
  void dispose() {
    _homeAnim.dispose();
    if (_ownsController) _tabController.dispose();
    super.dispose();
  }

  List<PersistentBottomNavBarItem> _items() => [
        for (var i = 0; i < widget.tabs.length; i++)
          PersistentBottomNavBarItem(
            icon: i == 0
                ? AnimatedIcon(icon: AnimatedIcons.home_menu, progress: _homeAnimValue)
                : Icon(widget.tabs[i].icon),
            iconAnimationController: i == 0 ? _homeAnim : null,
            title: widget.tabs[i].label,
            activeColorPrimary: AppColors.primary,
            activeColorSecondary: Colors.white,
            inactiveColorPrimary: AppColors.onSurfaceVariant,
          ),
      ];

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      safeArea: false,
      // Top inset only: the persistent nav manages its own bottom safe area via
      // [confineToSafeArea]. This replaces the removed Material app bar's inset
      // so each screen's [PortalTopBar] clears the status bar.
      body: SafeArea(
        bottom: false,
        child: PersistentTabView(
          context,
          controller: _tabController,
          screens: widget.screens,
          items: _items(),
          navBarStyle: NavBarStyle.style7,
          backgroundColor: AppColors.surface,
          confineToSafeArea: true,
          handleAndroidBackButtonPress: true,
          resizeToAvoidBottomInset: true,
          stateManagement: true,
        ),
      ),
    );
  }
}
