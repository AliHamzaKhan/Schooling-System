import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared/shared.dart';

import '../../../app/admin_routes.dart';
import '../../../ui/admin_widgets/admin_search_field.dart';
import '../../../ui/admin_widgets/admin_top_bar.dart';
import '../../../ui/admin_widgets/filter_chips.dart';
import '../../../ui/admin_widgets/pagination_bar.dart';
import '../components/school_card.dart';
import '../controller/schools_controller.dart';

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
                // Reuse the create wizard in edit mode (prefilled via arguments).
                final saved =
                    await Get.toNamed(AdminRoutes.createSchool, arguments: s);
                if (saved == true) controller.fetch();
              },
              onMenu: () {},
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
