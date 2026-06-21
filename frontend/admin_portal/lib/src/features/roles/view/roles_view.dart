import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared/shared.dart';

import '../../../app/admin_routes.dart';
import '../../../ui/admin_widgets/admin_top_bar.dart';
import '../../../ui/admin_widgets/section_header.dart';
import '../components/role_card.dart';
import '../components/role_hierarchy.dart';
import '../controller/roles_controller.dart';

/// Role Management — list every platform role with user/permission counts and
/// an active toggle, plus a hierarchical permission visualization. Tapping a
/// role opens the Permission Assignment matrix.
class RolesView extends GetView<RolesController> {
  const RolesView({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AdminTopBar(
            title: 'Role Management',
            showAvatar: false,
            actions: [
              IconButton(
                onPressed: () => Get.back<void>(),
                icon: const Icon(Icons.arrow_back_rounded,
                    color: AppColors.onSurface),
              ),
            ],
          ),
          Expanded(
            child: Obx(() {
              if (controller.loading.value) {
                return const Center(child: CircularProgressIndicator());
              }
              return ListView(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.containerPaddingMobile,
                    0,
                    AppSpacing.containerPaddingMobile,
                    AppSpacing.stackXl),
                children: [
                  Text('Roles & Hierarchy', style: AppTypography.headlineLg),
                  const SizedBox(height: AppSpacing.stackSm),
                  Text(
                      'Define who can do what. System roles are built-in; '
                      'custom roles can be tailored per organization.',
                      style: AppTypography.bodyLg),
                  const SizedBox(height: AppSpacing.stackLg),
                  RoleHierarchy(levels: controller.byLevel),
                  const SizedBox(height: AppSpacing.stackLg),
                  SectionHeader(
                    title: 'All Roles (${controller.roles.length})',
                    actionLabel: '+ New Role',
                    onAction: () => Get.snackbar('Create Role',
                        'Custom role creation is not wired in this build.',
                        snackPosition: SnackPosition.BOTTOM),
                  ),
                  const SizedBox(height: AppSpacing.stackMd),
                  for (final r in controller.roles) ...[
                    RoleCard(
                      role: r,
                      onToggle: (v) => controller.toggleActive(r.id, v),
                      onConfigure: () => Get.toNamed(
                          AdminRoutes.permissionMatrix,
                          arguments: r.id),
                    ),
                    const SizedBox(height: AppSpacing.stackMd),
                  ],
                ],
              );
            }),
          ),
        ],
      ),
    );
  }
}
