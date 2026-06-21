import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared/shared.dart';

import '../../../../ui/admin_widgets/admin_top_bar.dart';
import '../components/permission_group_card.dart';
import '../components/role_tabs.dart';
import '../controller/role_policy_controller.dart';

/// Role-Based Access Control — pick a role, toggle its module/permission access,
/// then Save or Discard. Header sits on a soft brand gradient.
class RolePolicyView extends GetView<RolePolicyController> {
  const RolePolicyView({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      safeArea: false,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AdminTopBar(
              title: 'EduMaster',
              showAvatar: false,
              onBell: () {},
              actions: [
                IconButton(
                  onPressed: () => Get.back<void>(),
                  icon: const Icon(Icons.menu_rounded, color: AppColors.onSurface),
                ),
              ],
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _GradientHeader(),
                  const SizedBox(height: AppSpacing.stackLg),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.containerPaddingMobile),
                    child: Obx(() => Column(
                          children: [
                            for (var i = 0; i < controller.groups.length; i++) ...[
                              PermissionGroupCard(
                                group: controller.groups[i],
                                onToggle: (key, v) => controller.toggle(i, key, v),
                              ),
                              const SizedBox(height: AppSpacing.stackLg),
                            ],
                          ],
                        )),
                  ),
                  const SizedBox(height: AppSpacing.stackXl),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GradientHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final controller = Get.find<RolePolicyController>();
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.containerPaddingMobile,
        AppSpacing.stackMd,
        AppSpacing.containerPaddingMobile,
        AppSpacing.stackXl,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFFE3C2),
            Color(0xFFF6D9E4),
            Color(0xFFBFE9F5),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Role-Based Access Control',
              style: AppTypography.displayLg.copyWith(color: AppColors.primary, fontSize: 32)),
          const SizedBox(height: AppSpacing.stackSm),
          Text(
            'Manage permissions and module access across different user roles '
            'within the platform. Changes take effect immediately.',
            style: AppTypography.bodyLg.copyWith(color: AppColors.onSurface),
          ),
          const SizedBox(height: AppSpacing.stackLg),
          Row(
            children: [
              Expanded(
                child: GhostButton(
                  label: 'Discard Changes',
                  expanded: true,
                  onPressed: controller.discard,
                ),
              ),
              const SizedBox(width: AppSpacing.stackMd),
              Expanded(
                child: PrimaryButton(
                  label: 'Save Policy',
                  expanded: true,
                  leadingIcon: Icons.save_outlined,
                  trailingIcon: null,
                  onPressed: () async {
                    await controller.save();
                    Get.snackbar('Saved', 'Policy updated successfully.',
                        snackPosition: SnackPosition.BOTTOM);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.stackLg),
          Obx(() => RoleTabs(
                roles: controller.roles,
                selectedId: controller.selectedRole.value.id,
                onSelected: controller.selectRole,
              )),
        ],
      ),
    );
  }
}
