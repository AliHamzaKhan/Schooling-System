import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared/shared.dart';

import '../../../../app/admin_routes.dart';
import '../../../../ui/admin_widgets/admin_search_field.dart';
import '../components/school_permission_card.dart';
import '../controller/school_permissions_controller.dart';

/// Lists schools so the admin can pick one to configure module permissions for.
class SchoolPermissionsView extends GetView<SchoolPermissionsController> {
  const SchoolPermissionsView({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header.
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.stackSm, AppSpacing.stackSm, AppSpacing.containerPaddingMobile, AppSpacing.stackSm),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Get.back<void>(),
                  icon: const Icon(Icons.arrow_back_rounded, color: AppColors.primary),
                ),
                Expanded(
                  child: Text('School Permissions',
                      style: AppTypography.headlineLg.copyWith(color: AppColors.primary)),
                ),
                const Icon(Icons.settings_outlined, color: AppColors.onSurfaceVariant),
                const SizedBox(width: AppSpacing.stackMd),
                const CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.primaryContainer,
                  child: Icon(Icons.person, color: AppColors.onPrimary, size: 20),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.containerPaddingMobile),
            child: AdminSearchField(
              hint: 'Find specific schools…',
              onChanged: controller.onSearch,
              action: AdminIconButton(icon: Icons.filter_list_rounded, onTap: () {}),
            ),
          ),
          const SizedBox(height: AppSpacing.stackLg),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.containerPaddingMobile),
            child: Text('Select School to Configure', style: AppTypography.bodyLg),
          ),
          const SizedBox(height: AppSpacing.stackMd),
          Expanded(
            child: Obx(() => ListView(
                  padding: const EdgeInsets.fromLTRB(
                      AppSpacing.containerPaddingMobile, 0, AppSpacing.containerPaddingMobile, AppSpacing.stackXl),
                  children: [
                    for (final s in controller.results) ...[
                      SchoolPermissionCard(
                        school: s,
                        onTap: () => Get.toNamed(AdminRoutes.rolePolicy),
                      ),
                      const SizedBox(height: AppSpacing.stackLg),
                    ],
                  ],
                )),
          ),
        ],
      ),
    );
  }
}
