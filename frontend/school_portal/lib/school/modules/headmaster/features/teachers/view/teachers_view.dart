import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared/shared.dart';

import '../../../../../widgets/entity_detail_sheet.dart';
import '../../../../../widgets/portal_filter_button.dart';
import '../../../../../widgets/portal_search_field.dart';
import '../../../../../widgets/portal_top_bar.dart';
import '../components/teacher_card.dart';
import '../controller/teachers_controller.dart';
import '../models/teacher.dart';
import '../../../../../widgets/skeletons.dart';

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
                    return const SkeletonPage(body: SkeletonRosterList());
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
                              hint: 'Search by name…',
                              onChanged: controller.onSearch,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.stackSm),
                          PortalFilterButton(
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
            child: FloatingActionButton.extended(
              onPressed: controller.addTeacherFlow,
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.onPrimary,
              icon: const Icon(Icons.person_add_alt_1_rounded),
              label: const Text('Add Teacher'),
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
