import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared/shared.dart';

import '../../../../../widgets/skeletons.dart';
import '../controller/exam_categories_controller.dart';
import '../models/exam_category.dart';

/// Headmaster: add / edit / delete exam categories (terms) used when creating
/// exams — e.g. "Mid Term", "Final Term".
class ExamCategoriesView extends GetView<ExamCategoriesController> {
  const ExamCategoriesView({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(title: const Text('Exam Categories')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: controller.createFlow,
        icon: const Icon(AppIcons.addRounded),
        label: const Text('New Category'),
      ),
      body: Obx(() {
        if (controller.loading.value) {
          return const SkeletonPage(body: SkeletonCardList(count: 4, height: 72));
        }
        if (controller.error.value != null) {
          return Center(
              child: Text(controller.error.value!, style: AppTypography.bodyLg));
        }
        if (controller.categories.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.stackXl),
              child: Text(
                  'No exam categories yet.\n'
                  'Add terms like "Mid Term" and "Final Term" to organise exams.',
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyLg),
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: controller.load,
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.containerPaddingMobile,
                AppSpacing.stackMd,
                AppSpacing.containerPaddingMobile,
                AppSpacing.stackXxl),
            itemCount: controller.categories.length,
            separatorBuilder: (_, _) =>
                const SizedBox(height: AppSpacing.stackMd),
            itemBuilder: (_, i) {
              final c = controller.categories[i];
              return _CategoryCard(category: c, controller: controller);
            },
          ),
        );
      }),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final ExamCategory category;
  final ExamCategoriesController controller;
  const _CategoryCard({required this.category, required this.controller});

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/'
      '${d.month.toString().padLeft(2, '0')}/${d.year}';

  String? get _window {
    final s = category.startDate;
    final e = category.endDate;
    if (s != null && e != null) return '${_fmt(s)} — ${_fmt(e)}';
    if (s != null) return 'From ${_fmt(s)}';
    if (e != null) return 'Until ${_fmt(e)}';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final window = _window;
    return GlassSurface(
      padding: const EdgeInsets.all(AppSpacing.stackLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(AppIcons.eventNoteRounded, color: AppColors.primary),
              const SizedBox(width: AppSpacing.stackMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(category.name,
                        style: AppTypography.titleMd
                            .copyWith(fontWeight: FontWeight.w700)),
                    if (window != null) ...[
                      const SizedBox(height: 2),
                      Text(window,
                          style: AppTypography.bodyMd
                              .copyWith(color: AppColors.onSurfaceVariant)),
                    ],
                  ],
                ),
              ),
              if (category.announced)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.tertiary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppRadius.button),
                  ),
                  child: Text('Announced',
                      style: AppTypography.labelCaps
                          .copyWith(color: AppColors.tertiary)),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.stackMd),
          Row(
            children: [
              _Action(
                icon: AppIcons.calendarMonthRounded,
                label: 'Timetable',
                onTap: () => controller.openTimetable(category),
              ),
              const SizedBox(width: AppSpacing.stackSm),
              _Action(
                icon: category.announced
                    ? AppIcons.campaignRounded
                    : AppIcons.campaignOutlined,
                label: category.announced ? 'Re-announce' : 'Announce',
                enabled: category.canAnnounce,
                onTap: () => controller.announceFlow(category),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(AppIcons.editOutlined, size: 20),
                onPressed: () => controller.editFlow(category),
              ),
              IconButton(
                icon: const Icon(AppIcons.deleteOutline,
                    size: 20, color: AppColors.error),
                onPressed: () => controller.deleteFlow(category),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Action extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool enabled;
  const _Action({
    required this.icon,
    required this.label,
    required this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final color = enabled ? AppColors.primary : AppColors.onSurfaceVariant;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.button),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: AppSpacing.stackMd, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.button),
          border: Border.all(color: color.withValues(alpha: 0.4), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(label,
                style: AppTypography.labelMd.copyWith(color: color)),
          ],
        ),
      ),
    );
  }
}
