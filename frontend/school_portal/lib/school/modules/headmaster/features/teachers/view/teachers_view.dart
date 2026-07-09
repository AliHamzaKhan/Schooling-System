import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared/shared.dart';

import '../../../../../widgets/entity_detail_sheet.dart';
import '../../../../../widgets/portal_search_field.dart';
import '../../../../../widgets/portal_top_bar.dart';
import '../components/teacher_card.dart';
import '../controller/teachers_controller.dart';
import '../models/teacher.dart';

/// Teacher Roster — search + filter teachers with quick-contact actions and an
/// "Add Teacher" FAB.
class TeachersView extends GetView<TeachersController> {
  const TeachersView({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      body: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const PortalTopBar(),
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
                        120),
                    children: [
                      Text('Teacher Roster',
                          style: AppTypography.displayLg
                              .copyWith(fontSize: 32, color: AppColors.primary)),
                      const SizedBox(height: AppSpacing.stackSm),
                      Text("Manage your island's educators and staff.",
                          style: AppTypography.bodyLg),
                      const SizedBox(height: AppSpacing.stackMd),
                      Row(
                        children: [
                          Expanded(
                            child: PortalSearchField(
                              hint: 'Search by name or dept…',
                              onChanged: controller.onSearch,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.stackSm),
                          _FilterButton(
                            onTap: controller.openFilter,
                            count: controller.activeFilterCount,
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.stackLg),
                      if (controller.visibleTeachers.isEmpty)
                        Padding(
                          padding: const EdgeInsets.all(AppSpacing.stackXl),
                          child: Center(
                            child: Text('No teachers match your search.',
                                style: AppTypography.bodyLg),
                          ),
                        )
                      else
                        for (final t in controller.visibleTeachers) ...[
                          TeacherCard(
                            teacher: t,
                            onView: () => _showTeacher(context, t),
                            onMail: () => _showTeacher(context, t),
                            onChat: () => _showTeacher(context, t),
                          ),
                          const SizedBox(height: AppSpacing.stackLg),
                        ],
                    ],
                  );
                }),
              ),
            ],
          ),
          Positioned(
            right: AppSpacing.stackLg,
            bottom: AppSpacing.stackLg,
            child: FloatingActionButton(
              onPressed: controller.addTeacherFlow,
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.onPrimary,
              child: const Icon(Icons.add),
            ),
          ),
        ],
      ),
    );
  }
}

void _showTeacher(BuildContext context, Teacher t) {
  showEntityDetailSheet(
    context,
    title: t.name,
    subtitle: t.department,
    initials: t.initials,
    accent: t.accent,
    statusLabel: t.status.label,
    statusColor: t.status.color,
    fields: [
      DetailField(Icons.badge_outlined, 'ID', t.id),
      DetailField(Icons.apartment_outlined, 'Department', t.department),
    ],
  );
}

class _FilterButton extends StatelessWidget {
  final VoidCallback onTap;
  final int count;
  const _FilterButton({required this.onTap, this.count = 0});

  @override
  Widget build(BuildContext context) {
    final active = count > 0;
    return Material(
      color: AppColors.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(AppRadius.full),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.full),
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.stackMd),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.full),
            border: Border.all(
              color: active ? AppColors.primary : AppColors.outlineVariant,
              width: active ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.tune_rounded, size: 18, color: AppColors.primary),
              const SizedBox(width: 6),
              Text(active ? 'Filter ($count)' : 'Filter',
                  style: AppTypography.labelMd
                      .copyWith(color: AppColors.primary, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
  }
}
