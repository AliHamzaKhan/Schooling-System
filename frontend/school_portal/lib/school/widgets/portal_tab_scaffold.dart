import 'package:flutter/material.dart';
import 'package:get/get.dart';
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
  final String? schoolName;
  final String? sessionName;

  /// Optional externally-owned controller — pass one when a screen needs to
  /// switch tabs programmatically (e.g. a button that jumps to "Alerts").
  final PersistentTabController? controller;

  const PortalTabScaffold({
    super.key,
    required this.title,
    required this.tabs,
    required this.screens,
    this.schoolName,
    this.sessionName,
    this.controller,
  }) : assert(tabs.length == screens.length);

  @override
  State<PortalTabScaffold> createState() => _PortalTabScaffoldState();
}

class _PortalTabScaffoldState extends State<PortalTabScaffold> {
  static const _desktopBreakpoint = 1024.0;
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
    if (_tabController.index != 0) _selectTab(0);
  }

  void _selectTab(int index) {
    _tabController.jumpToTab(index);
    if (mounted) setState(() {});
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
        body: LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth >= _desktopBreakpoint) {
              return Row(
                children: [
                  _PortalSidebar(
                    title: widget.title,
                    tabs: widget.tabs,
                    selectedIndex: _tabController.index,
                    onSelected: _selectTab,
                    schoolName: widget.schoolName,
                    sessionName: widget.sessionName,
                  ),
                  const VerticalDivider(
                    width: 1,
                    color: AppColors.outlineVariant,
                  ),
                  Expanded(
                    child: SafeArea(
                      left: false,
                      child: IndexedStack(
                        index: _tabController.index,
                        children: widget.screens,
                      ),
                    ),
                  ),
                ],
              );
            }

            return SafeArea(
              bottom: false,
              child: PersistentTabView.custom(
                context,
                controller: _tabController,
                itemCount: widget.tabs.length,
                screens: [
                  for (final screen in widget.screens)
                    CustomNavBarScreen(screen: screen),
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
            );
          },
        ),
      ),
    );
  }
}

/// Desktop navigation for role portals. Mobile retains the thumb-friendly
/// bottom bar; wide windows gain persistent labels and more content height.
class _PortalSidebar extends StatelessWidget {
  final String title;
  final List<PortalTab> tabs;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final String? schoolName;
  final String? sessionName;

  const _PortalSidebar({
    required this.title,
    required this.tabs,
    required this.selectedIndex,
    required this.onSelected,
    required this.schoolName,
    required this.sessionName,
  });

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthService>();
    return SafeArea(
      child: Container(
        width: 248,
        color: AppColors.surfaceContainerLowest,
        padding: const EdgeInsets.fromLTRB(16, 22, 16, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          AppColors.primary,
                          AppColors.primaryGradientEnd,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(AppRadius.button),
                    ),
                    child: const Icon(
                      AppIcons.schoolRounded,
                      color: AppColors.onPrimary,
                      size: 21,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Meri Taleem', style: AppTypography.titleMd),
                        Text(
                          '$title portal',
                          style: AppTypography.bodySm.copyWith(
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (schoolName != null || sessionName != null) ...[
              const SizedBox(height: AppSpacing.stackLg),
              AppCard(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      schoolName ?? 'School workspace',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.labelMd,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          AppIcons.calendarMonthOutlined,
                          size: 15,
                          color: AppColors.onSurfaceVariant,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            sessionName == null
                                ? 'No active academic session'
                                : 'Session: $sessionName',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.bodySm.copyWith(
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.stackXl),
            for (var i = 0; i < tabs.length; i++) ...[
              _PortalSidebarItem(
                tab: tabs[i],
                selected: selectedIndex == i,
                onTap: () => onSelected(i),
              ),
              const SizedBox(height: 6),
            ],
            const Spacer(),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainer,
                borderRadius: BorderRadius.circular(AppRadius.button),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.onPrimary,
                    child: Text(
                      (auth.fullName?.trim().isNotEmpty ?? false)
                          ? auth.fullName!.trim()[0].toUpperCase()
                          : 'H',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          auth.fullName ?? title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.labelMd,
                        ),
                        Text(
                          schoolName == null
                              ? auth.schoolName ?? 'School workspace'
                              : '$title account',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.bodySm.copyWith(
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PortalSidebarItem extends StatelessWidget {
  final PortalTab tab;
  final bool selected;
  final VoidCallback onTap;

  const _PortalSidebarItem({
    required this.tab,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final foreground = selected
        ? AppColors.onPrimary
        : AppColors.onSurfaceVariant;
    return Material(
      color: selected ? AppColors.primary : Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.button),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.button),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          child: Row(
            children: [
              Icon(tab.icon, size: 19, color: foreground),
              const SizedBox(width: 12),
              Text(
                tab.label,
                style: AppTypography.labelMd.copyWith(color: foreground),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
