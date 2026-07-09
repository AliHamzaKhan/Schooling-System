import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared/shared.dart';

import '../../../../../widgets/portal_top_bar.dart';
import '../components/assignment_card.dart';
import '../components/weekly_progress_card.dart';
import '../controller/assignments_controller.dart';
import '../models/assignment.dart';

/// Student My Assignments — weekly progress card + active assignments list.
class AssignmentsView extends GetView<AssignmentsController> {
  final ValueChanged<StudentAssignment>? onOpenAssignment;
  final VoidCallback? onNotifications;

  const AssignmentsView({super.key, this.onOpenAssignment, this.onNotifications});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        PortalTopBar(title: 'EduMaster', onBell: onNotifications),
        Expanded(
          child: Obx(() {
            if (controller.loading.value) {
              return const Center(child: CircularProgressIndicator());
            }
            final data = controller.data.value;
            if (data == null) return const SizedBox.shrink();
            return ListView(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.containerPaddingMobile,
                  0,
                  AppSpacing.containerPaddingMobile,
                  AppSpacing.stackXl),
              children: [
                Text('My Assignments', style: AppTypography.headlineLg),
                const SizedBox(height: AppSpacing.stackSm),
                Text("Keep up the great work! You're making solid progress this week.",
                    style: AppTypography.bodyLg),
                const SizedBox(height: AppSpacing.stackLg),
                WeeklyProgressCard(summary: data.summary),
                const SizedBox(height: AppSpacing.stackLg),
                Row(
                  children: [
                    Expanded(
                      child: Text('Active Assignments',
                          style: AppTypography.headlineLg.copyWith(fontSize: 22)),
                    ),
                    _FilterPill(
                      onTap: controller.openFilter,
                      count: controller.activeFilterCount,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.stackMd),
                if (controller.visibleAssignments.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.stackXl),
                    child: Center(
                      child: Text('No assignments match your filters.',
                          style: AppTypography.bodyLg),
                    ),
                  )
                else
                  for (final a in controller.visibleAssignments) ...[
                    AssignmentCard(
                      assignment: a,
                      onTap: () => onOpenAssignment?.call(a),
                    ),
                    const SizedBox(height: AppSpacing.stackMd),
                  ],
              ],
            );
          }),
        ),
      ],
    );
  }
}

class _FilterPill extends StatelessWidget {
  final VoidCallback onTap;
  final int count;
  const _FilterPill({required this.onTap, this.count = 0});

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
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
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
              const Icon(Icons.tune_rounded, size: 16, color: AppColors.primary),
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
