import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared/shared.dart';

import '../admin_theme.dart';

/// Plain screen heading for drill-in admin screens: a back arrow and the page
/// title on the normal page background — no tinted/gradient banner, no
/// description. Optional [actions] sit on the trailing edge.
class AdminScreenHeader extends StatelessWidget {
  final String title;
  final bool showBack;
  final List<Widget> actions;

  const AdminScreenHeader({
    super.key,
    required this.title,
    this.showBack = true,
    this.actions = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.containerPaddingMobile,
        AppSpacing.stackMd,
        AppSpacing.containerPaddingMobile,
        AppSpacing.stackSm,
      ),
      child: Row(
        children: [
          if (showBack) ...[
            _RoundIconButton(
              icon: AppIcons.arrowBackRounded,
              tooltip: 'Back',
              onTap: () => Get.back<void>(),
            ),
            const SizedBox(width: AppSpacing.stackMd),
          ],
          Expanded(child: Text(title, style: AdminType.screenTitle)),
          ...actions,
        ],
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  const _RoundIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Icon-only control: named for screen readers, hinted on hover.
    return Tooltip(
      message: tooltip,
      excludeFromSemantics: true,
      child: Semantics(
        button: true,
        label: tooltip,
        child: Material(
          color: AdminPalette.card,
          borderRadius: BorderRadius.circular(11),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(11),
            child: Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(11),
                border: Border.all(color: AdminPalette.border),
              ),
              child: Icon(icon, color: AdminPalette.ink, size: 20),
            ),
          ),
        ),
      ),
    );
  }
}
