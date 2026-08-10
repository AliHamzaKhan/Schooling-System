import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared/shared.dart';

import '../../../app/admin_routes.dart';
import '../../../ui/admin_widgets/admin_confirm_dialog.dart';
import '../../../ui/admin_widgets/admin_search_field.dart';
import '../../../ui/admin_widgets/admin_top_bar.dart';
import '../../../ui/admin_widgets/filter_chips.dart';
import '../../../ui/admin_widgets/pagination_bar.dart';
import '../components/school_card.dart';
import '../components/subscription_sheet.dart';
import '../controller/schools_controller.dart';
import '../models/school.dart';

/// Confirms then reactivates a suspended school.
Future<void> _activateSchool(School s) async {
  final confirmed = await showAdminConfirm(
    icon: Icons.check_circle_outline_rounded,
    title: 'Activate school?',
    message:
        '${s.name} will be reactivated and regain full access for its staff and students.',
    confirmLabel: 'Activate',
    accent: AppColors.tertiary,
    details: [
      AdminConfirmDetail(label: 'School', value: s.name),
      if (s.planName != null || s.planCode != null)
        AdminConfirmDetail(
            label: 'Plan', value: s.planName ?? s.planCode!),
    ],
  );
  if (!confirmed) return;
  final ok = await Get.find<SchoolsController>().activateSchool(s.id);
  if (ok) {
    Get.snackbar('Activated', '${s.name} is now active.',
        snackPosition: SnackPosition.BOTTOM);
  }
}

/// Confirms then "deletes" (suspends) a school — the backend has no hard delete.
Future<void> _confirmDeleteSchool(School s) async {
  final ok = await Get.dialog<bool>(
    AlertDialog(
      title: const Text('Deactivate school?'),
      content: Text(
          '${s.name} will be suspended and lose access. You can reactivate it later.'),
      actions: [
        TextButton(onPressed: () => Get.back<bool>(result: false), child: const Text('Cancel')),
        TextButton(
          onPressed: () => Get.back<bool>(result: true),
          child: const Text('Deactivate', style: TextStyle(color: AppColors.error)),
        ),
      ],
    ),
  );
  if (ok != true) return;
  final removed = await Get.find<SchoolsController>().deleteSchool(s.id);
  if (removed) {
    Get.snackbar('Deactivated', '${s.name} was suspended.',
        snackPosition: SnackPosition.BOTTOM);
  }
}

/// School Management — searchable, filterable, paginated list of institutions
/// with a "+" FAB to create a new school.
class SchoolsView extends GetView<SchoolsController> {
  const SchoolsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AdminTopBar(showAvatar: true),
            const Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.containerPaddingMobile, 0, AppSpacing.containerPaddingMobile, AppSpacing.stackSm),
              child: Text('Schools', style: AppTypography.headlineLg),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.containerPaddingMobile),
              child: AdminSearchField(
                hint: 'Search institutions by name, location',
                onChanged: controller.onSearch,
                action: AdminIconButton(icon: Icons.tune_rounded, onTap: () {}),
              ),
            ),
            const SizedBox(height: AppSpacing.stackMd),
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.containerPaddingMobile),
              child: Obx(() => FilterChips(
                    options: SchoolsController.filters,
                    selectedIndex: controller.filterIndex.value,
                    onSelected: controller.selectFilter,
                  )),
            ),
            const SizedBox(height: AppSpacing.stackMd),
            Expanded(child: _list(context)),
          ],
        ),
        Positioned(
          right: AppSpacing.stackLg,
          bottom: AppSpacing.stackLg,
          child: FloatingActionButton(
            onPressed: () async {
              final created = await Get.toNamed(AdminRoutes.createSchool);
              if (created == true) controller.fetch();
            },
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.onPrimary,
            child: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }

  Widget _list(BuildContext context) {
    return Obx(() {
      if (controller.loading.value) {
        return const Center(child: CircularProgressIndicator());
      }
      if (controller.error.value != null) {
        return Center(child: Text(controller.error.value!, style: AppTypography.bodyLg));
      }
      if (controller.schools.isEmpty) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.search_off_rounded, size: 40, color: AppColors.outline),
              const SizedBox(height: AppSpacing.stackSm),
              Text('No schools match your search.', style: AppTypography.bodyLg),
            ],
          ),
        );
      }
      return ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.containerPaddingMobile, 0, AppSpacing.containerPaddingMobile, 96),
        children: [
          for (final s in controller.schools) ...[
            SchoolCard(
              school: s,
              onTap: () async {
                await Get.toNamed(AdminRoutes.schoolDetail, arguments: s);
                // Detail may have changed status/plan; refresh on return.
                controller.fetch();
              },
              onEdit: () async {
                // Reuse the create wizard in edit mode (prefilled via arguments).
                final saved =
                    await Get.toNamed(AdminRoutes.createSchool, arguments: s);
                if (saved == true) controller.fetch();
              },
              onSubscription: () =>
                  showSubscriptionSheet(s, onChanged: controller.fetch),
              onDelete: () => _confirmDeleteSchool(s),
              onActivate: () => _activateSchool(s),
            ),
            const SizedBox(height: AppSpacing.stackMd),
          ],
          const SizedBox(height: AppSpacing.stackSm),
          PaginationBar(
            current: controller.page.value,
            total: controller.totalPages.value,
            onChanged: controller.goToPage,
          ),
        ],
      );
    });
  }
}
