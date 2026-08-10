import 'package:flutter/material.dart';
import 'package:persistent_bottom_nav_bar/persistent_bottom_nav_bar.dart';
import 'package:shared/shared.dart';

import 'portal_nav_bar.dart';

/// One bottom-nav tab spec (icon + label).
///
/// The label is no longer painted — [PortalNavBar] is icon-only — but it is
/// still required, because it is what a screen reader announces and what a
/// long press shows. An unnamed tab is a tab nobody using assistive technology
/// can identify.
class PortalTab {
  final IconData icon;
  final String label;
  const PortalTab(this.icon, this.label);
}

/// Shared module shell: [PortalNavBar] over persistent_bottom_nav_bar's custom
/// tab view, with no Material app bar — each tab screen owns its single compact
/// [PortalTopBar] header (which carries the account/logout menu).
///
/// Every module builds its shell from this, so the navigation looks and behaves
/// the same in all four of them by construction rather than by four files
/// agreeing with each other.
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

class _PortalTabScaffoldState extends State<PortalTabScaffold> {
  late final PersistentTabController _tabController =
      widget.controller ?? PersistentTabController(initialIndex: 0);
  bool get _ownsController => widget.controller == null;

  @override
  void dispose() {
    if (_ownsController) _tabController.dispose();
    super.dispose();
  }

  /// Android back handling for the module root. We take it over from the nav
  /// bar (`handleAndroidBackButtonPress: false`) so that back on a non-Home tab
  /// returns to Home, and back on the Home tab is blocked — the user is never
  /// popped off the shell back to the login screen. They leave via logout or
  /// the OS home button.
  void _onBack(bool didPop, Object? result) {
    if (didPop) return;
    if (_tabController.index != 0) _tabController.jumpToTab(0);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: _onBack,
      child: AppScaffold(
        safeArea: false,
        // Top inset only: the persistent nav manages its own bottom safe area
        // via [confineToSafeArea]. This replaces the removed Material app bar's
        // inset so each screen's [PortalTopBar] clears the status bar.
        body: SafeArea(
          bottom: false,
          child: PersistentTabView.custom(
            context,
            controller: _tabController,
            itemCount: widget.tabs.length,
            screens: [
              for (final screen in widget.screens) CustomNavBarScreen(screen: screen),
            ],
            customWidget: PortalNavBar(
              tabs: widget.tabs,
              controller: _tabController,
            ),
            navBarHeight: PortalNavBar.height,
            backgroundColor: AppColors.surface,
            confineToSafeArea: true,
            handleAndroidBackButtonPress: false,
            resizeToAvoidBottomInset: true,
            stateManagement: true,
          ),
        ),
      ),
    );
  }
}
