import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

import '../../../../../widgets/portal_top_bar.dart';

/// Student Dashboard — placeholder until the spec is delivered.
/// The bell on the top bar opens the Notifications Center.
class DashboardView extends StatelessWidget {
  final VoidCallback? onNotifications;
  const DashboardView({super.key, this.onNotifications});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        PortalTopBar(title: 'EduMaster', onBell: onNotifications),
        Expanded(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.dashboard_customize_outlined,
                    size: 40, color: AppColors.outline),
                const SizedBox(height: AppSpacing.stackMd),
                Text('Student Dashboard', style: AppTypography.titleLg),
                const SizedBox(height: 4),
                Text('Spec pending — coming next batch.',
                    style: AppTypography.bodyMd),
                const SizedBox(height: AppSpacing.stackLg),
                GhostButton(
                  label: 'Open Notifications',
                  trailingIcon: Icons.arrow_forward,
                  onPressed: onNotifications,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
