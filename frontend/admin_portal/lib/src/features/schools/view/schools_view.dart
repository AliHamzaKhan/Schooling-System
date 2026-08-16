import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/admin_routes.dart';
import '../../../ui/admin_theme.dart';
import '../../../ui/admin_widgets/admin_confirm_dialog.dart';
import '../../../ui/admin_widgets/admin_search_field.dart';
import '../../../ui/admin_widgets/admin_surface.dart';
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
    accent: AdminPalette.positive,
    details: [
      AdminConfirmDetail(label: 'School', value: s.name),
      if (s.planName != null || s.planCode != null)
        AdminConfirmDetail(label: 'Plan', value: s.planName ?? s.planCode!),
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
  final confirmed = await showAdminConfirm(
    icon: Icons.block_rounded,
    title: 'Deactivate school?',
    message:
        '${s.name} will be suspended and lose access. You can reactivate it later.',
    confirmLabel: 'Deactivate',
    accent: AdminPalette.danger,
    details: [AdminConfirmDetail(label: 'School', value: s.name)],
  );
  if (!confirmed) return;
  final removed = await Get.find<SchoolsController>().deleteSchool(s.id);
  if (removed) {
    Get.snackbar('Deactivated', '${s.name} was suspended.',
        snackPosition: SnackPosition.BOTTOM);
  }
}

/// Schools Directory — searchable, filterable, paginated list of institutions
/// with a "+" FAB to create a new school.
class SchoolsView extends GetView<SchoolsController> {
  const SchoolsView({super.key});

  @override
  Widget build(BuildContext context) {
    return AdminScreen(
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AdminTopBar(showAvatar: true),
              const Padding(
                padding: EdgeInsets.fromLTRB(kAdminGutter, 4, kAdminGutter, 0),
                child: AdminPageHeader(
                  title: 'Schools Directory',
                  subtitle: 'Manage and monitor affiliated institutions.',
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: kAdminGutter),
                child: AdminSearchField(
                  hint: 'Search schools by name or ID...',
                  onChanged: controller.onSearch,
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: kAdminGutter),
                child: Obx(() => FilterChips(
                      options: SchoolsController.filters,
                      selectedIndex: controller.filterIndex.value,
                      onSelected: controller.selectFilter,
                    )),
              ),
              const SizedBox(height: 18),
              Expanded(child: _list(context)),
            ],
          ),
          Positioned(
            right: kAdminGutter,
            bottom: 24,
            child: _CreateFab(
              onPressed: () async {
                final created = await Get.toNamed(AdminRoutes.createSchool);
                if (created == true) controller.fetch();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _list(BuildContext context) {
    return Obx(() {
      if (controller.loading.value) {
        return const Center(
            child: CircularProgressIndicator(color: AdminPalette.ink));
      }
      if (controller.error.value != null) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Text(controller.error.value!,
                textAlign: TextAlign.center, style: AdminType.body),
          ),
        );
      }
      if (controller.schools.isEmpty) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const AdminIconTile(icon: Icons.search_off_rounded, size: 52),
              const SizedBox(height: 14),
              Text('No schools match your search.', style: AdminType.body),
            ],
          ),
        );
      }
      return ListView(
        padding: const EdgeInsets.fromLTRB(kAdminGutter, 0, kAdminGutter, 110),
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
            const SizedBox(height: 14),
          ],
          const SizedBox(height: 8),
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

/// Navy squircle FAB — the directory's single primary action.
class _CreateFab extends StatelessWidget {
  final VoidCallback onPressed;
  const _CreateFab({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: AdminPalette.raisedShadow,
      ),
      child: Material(
        color: AdminPalette.ink,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(20),
          child: const SizedBox(
            width: 60,
            height: 60,
            child: Icon(Icons.add_rounded, color: Colors.white, size: 28),
          ),
        ),
      ),
    );
  }
}
