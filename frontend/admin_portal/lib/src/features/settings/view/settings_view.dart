import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared/shared.dart';

import '../../../app/admin_routes.dart';
import '../../../ui/admin_theme.dart';
import '../../../ui/admin_widgets/admin_confirm_dialog.dart';
import '../../../ui/admin_widgets/admin_surface.dart';
import '../../../ui/admin_widgets/admin_top_bar.dart';

/// Settings hub — entry points to admin configuration areas that live off the
/// main tab bar (permissions, plans, billing history), plus sign-out.
class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  Future<void> _signOut() async {
    final confirmed = await showAdminConfirm(
      icon: AppIcons.logoutRounded,
      title: 'Sign out?',
      message: 'You will need to sign in again to manage the platform.',
      confirmLabel: 'Sign Out',
      accent: AdminPalette.danger,
      destructive: true,
    );
    if (!confirmed) return;
    await Get.find<AuthService>().logout();
    Get.offAllNamed(AuthRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    return AdminScreen(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AdminTopBar(showAvatar: true),
          Expanded(
            child: ListView(
              padding:
                  const EdgeInsets.fromLTRB(kAdminGutter, 4, kAdminGutter, 36),
              children: [
                const AdminPageHeader(title: 'Settings'),

                const AdminGroupLabel('Access Control'),
                AdminNavTile(
                  icon: AppIcons.adminPanelSettingsOutlined,
                  title: 'School Permissions',
                  subtitle: 'Manage modules and access levels per school.',
                  onTap: () => Get.toNamed(AdminRoutes.schoolPermissions),
                ),
                const SizedBox(height: 12),
                AdminNavTile(
                  icon: AppIcons.manageAccountsOutlined,
                  title: 'Headmasters',
                  subtitle: 'Review and manage headmaster accounts.',
                  onTap: () => Get.toNamed(AdminRoutes.headmasters),
                ),

                const SizedBox(height: 28),
                const AdminGroupLabel('Billing'),
                AdminNavTile(
                  icon: AppIcons.creditCardOutlined,
                  title: 'Subscription Plans',
                  subtitle: 'Review and edit pricing tiers.',
                  onTap: () => Get.toNamed(AdminRoutes.subscriptions),
                ),
                const SizedBox(height: 12),
                AdminNavTile(
                  icon: AppIcons.receiptLongOutlined,
                  title: 'School Subscriptions',
                  subtitle: 'Assign plans and review billing status.',
                  onTap: () => Get.toNamed(AdminRoutes.subscriptionManagement),
                ),
                const SizedBox(height: 12),
                AdminNavTile(
                  icon: AppIcons.accountBalanceOutlined,
                  title: 'Revenue Report',
                  subtitle: 'Monthly revenue and payment history.',
                  onTap: () => Get.toNamed(AdminRoutes.revenue),
                ),

                const SizedBox(height: 36),
                Center(
                  child: TextButton.icon(
                    onPressed: _signOut,
                    icon: const Icon(AppIcons.logoutRounded, size: 18),
                    label: const Text('Sign Out'),
                    style: TextButton.styleFrom(
                      foregroundColor: AdminPalette.danger,
                      textStyle:
                          AdminType.label.copyWith(fontWeight: FontWeight.w700),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
