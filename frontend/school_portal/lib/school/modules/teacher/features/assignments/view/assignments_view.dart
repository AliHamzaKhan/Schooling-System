import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared/shared.dart';

import '../../../../../widgets/filter_chips.dart';
import '../../../../../widgets/portal_search_field.dart';
import '../../../../../widgets/portal_top_bar.dart';
import '../components/assignment_card.dart';
import '../components/assignment_stat_card.dart';
import '../controller/assignments_controller.dart';

/// Assignments Management — Tasks tab content. KPI stats, search, class
/// filter chips, list of assignments. FAB opens the New Assignment menu.
class AssignmentsView extends GetView<AssignmentsController> {
  final VoidCallback? onCreateHomework;
  final VoidCallback? onCreateExam;
  final VoidCallback? onOpenGradebook;

  const AssignmentsView({
    super.key,
    this.onCreateHomework,
    this.onCreateExam,
    this.onOpenGradebook,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Column(
          children: [
            const PortalTopBar(title: 'Teacher Portal'),
            Expanded(
              child: Obx(() {
                if (controller.loading.value) {
                  return const Center(child: CircularProgressIndicator());
                }
                final data = controller.data.value;
                if (data == null) {
                  return Center(
                      child: Text(controller.error.value ?? 'No data',
                          style: AppTypography.bodyLg));
                }
                return ListView(
                  padding: const EdgeInsets.fromLTRB(
                      AppSpacing.containerPaddingMobile,
                      0,
                      AppSpacing.containerPaddingMobile,
                      120),
                  children: [
                    Text('Assignments', style: AppTypography.headlineLg),
                    const SizedBox(height: AppSpacing.stackSm),
                    Text('Manage and track student coursework across all your classes.',
                        style: AppTypography.bodyLg),
                    const SizedBox(height: AppSpacing.stackMd),
                    PrimaryButton(
                      label: 'New Assignment',
                      leadingIcon: Icons.add,
                      trailingIcon: null,
                      onPressed: () => _showCreatePicker(context),
                    ),
                    const SizedBox(height: AppSpacing.stackLg),
                    // KPI list — divided rows, no card per stat.
                    GlassSurface(
                      padding: EdgeInsets.zero,
                      child: Column(
                        children: [
                          AssignmentStatCard(
                            label: 'To Grade',
                            value: '${data.stats.toGrade}',
                            trend: '↑ ${data.stats.toGradeDelta} since yesterday',
                            icon: Icons.menu_book_outlined,
                            accent: const Color(0xFFE8A317),
                            trendColor: AppColors.error,
                          ),
                          const Divider(height: 1, color: AppColors.outlineVariant),
                          AssignmentStatCard(
                            label: 'Active Assignments',
                            value: '${data.stats.activeCount}',
                            trend:
                                'Across ${data.stats.activeAcrossClasses} classes',
                            icon: Icons.assignment_outlined,
                            accent: AppColors.primary,
                            trendColor: AppColors.onSurfaceVariant,
                          ),
                          const Divider(height: 1, color: AppColors.outlineVariant),
                          AssignmentStatCard(
                            label: 'Average Turn-in Rate',
                            value:
                                '${(data.stats.averageTurnInRate * 100).toStringAsFixed(0)}%',
                            trend:
                                '↑ +${(data.stats.averageTurnInDelta * 100).toStringAsFixed(0)}% this week',
                            icon: Icons.group_outlined,
                            accent: AppColors.aiAccent,
                            trendColor: AppColors.tertiary,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.stackLg),
                    PortalSearchField(
                      hint: 'Search assignments…',
                      onChanged: controller.onSearch,
                    ),
                    const SizedBox(height: AppSpacing.stackMd),
                    Obx(() => FilterChips(
                          options: AssignmentsController.classFilters,
                          selectedIndex: controller.classFilterIndex.value,
                          onSelected: controller.selectClass,
                        )),
                    const SizedBox(height: AppSpacing.stackLg),
                    for (final a in data.assignments) ...[
                      AssignmentCard(assignment: a, onTap: onOpenGradebook),
                      const SizedBox(height: AppSpacing.stackLg),
                    ],
                    Center(
                      child: TextButton(
                        onPressed: () {},
                        child: Text('Load More Assignments',
                            style: AppTypography.labelMd
                                .copyWith(color: AppColors.primary)),
                      ),
                    ),
                  ],
                );
              }),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _showCreatePicker(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.card)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: AppSpacing.stackMd),
            Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                    color: AppColors.outlineVariant,
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: AppSpacing.stackMd),
            ListTile(
              leading: const Icon(Icons.assignment_add, color: AppColors.primary),
              title: const Text('Homework'),
              subtitle: const Text('A quick task for students'),
              onTap: () {
                Navigator.of(context).pop();
                onCreateHomework?.call();
              },
            ),
            ListTile(
              leading: const Icon(Icons.fact_check_outlined, color: AppColors.primary),
              title: const Text('Exam'),
              subtitle: const Text('A graded assessment with logistics'),
              onTap: () {
                Navigator.of(context).pop();
                onCreateExam?.call();
              },
            ),
            const SizedBox(height: AppSpacing.stackMd),
          ],
        ),
      ),
    );
  }
}
