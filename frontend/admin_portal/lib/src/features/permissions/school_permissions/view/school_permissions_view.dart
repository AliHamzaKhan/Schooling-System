import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared/shared.dart';

import '../../../../app/admin_routes.dart';
import '../../../../ui/admin_widgets/admin_search_field.dart';
import '../components/school_permission_card.dart';
import '../controller/school_permissions_controller.dart';
import '../../../../ui/admin_theme.dart';

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
                  tooltip: 'Back',
                  onPressed: () => Get.back<void>(),
                  icon: const Icon(AppIcons.arrowBackRounded, color: AdminPalette.ink),
                ),
                Expanded(
                  child: Text('School Permissions',
                      style: AdminType.screenTitle.copyWith(color: AdminPalette.ink)),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.containerPaddingMobile),
            child: AdminSearchField(
              hint: 'Find specific schools…',
              onChanged: controller.onSearch,
            ),
          ),
          const SizedBox(height: AppSpacing.stackLg),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.containerPaddingMobile),
            child: Text('Select a school to configure its modules',
                style: AdminType.body),
          ),
          const SizedBox(height: AppSpacing.stackMd),
          Expanded(
            child: Obx(() {
              if (controller.loading.value) {
                return const Center(child: CircularProgressIndicator());
              }
              if (controller.error.value != null) {
                return _ErrorState(
                  message: controller.error.value!,
                  onRetry: controller.load,
                );
              }
              if (controller.results.isEmpty) {
                return Center(
                  child: Text('No schools found.', style: AdminType.body),
                );
              }
              return ListView(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.containerPaddingMobile, 0, AppSpacing.containerPaddingMobile, AppSpacing.stackXl),
                children: [
                  for (final s in controller.results) ...[
                    SchoolPermissionCard(
                      school: s,
                      onTap: () => Get.toNamed<void>(
                        AdminRoutes.schoolModules,
                        arguments: s,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.stackLg),
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

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.containerPaddingMobile),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(AppIcons.cloudOffRounded, size: 40, color: AdminPalette.muted),
            const SizedBox(height: AppSpacing.stackMd),
            Text(message, textAlign: TextAlign.center, style: AdminType.body),
            const SizedBox(height: AppSpacing.stackMd),
            FilledButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
