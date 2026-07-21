import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared/shared.dart';

import '../../../../../config/headmaster_routes.dart';
import '../../../../../config/teacher_routes.dart';
import '../../../../../widgets/portal_top_bar.dart';
import '../components/student_standing_card.dart';
import '../controller/class_performance_controller.dart';
import '../models/section_performance.dart';
import '../../../../../widgets/skeletons.dart';

/// Performance tab — a tab per section the teacher takes, each listing that
/// section's students ranked by attendance and marks, best first.
class ClassPerformanceView extends GetView<ClassPerformanceController> {
  const ClassPerformanceView({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PortalTopBar(title: 'Teacher Portal'),
        Expanded(
          child: Obx(() {
            if (controller.loadingSections.value) {
              return const SkeletonPage(
                withAction: false,
                body: Column(
                  children: [
                    SkeletonStatRow(count: 3, height: 34),
                    SizedBox(height: AppSpacing.stackLg),
                    SkeletonRosterList(),
                  ],
                ),
              );
            }
            if (controller.sectionsError.value != null) {
              return _Message(
                icon: Icons.cloud_off_rounded,
                text: controller.sectionsError.value!,
                onRetry: controller.loadSections,
              );
            }
            if (controller.sections.isEmpty) {
              return const _Message(
                icon: Icons.insights_rounded,
                text: 'No sections are timetabled to you yet.',
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.containerPaddingMobile),
                  child: Text('Class Performance',
                      style: AppTypography.headlineLg
                          .copyWith(color: AppColors.primary)),
                ),
                const SizedBox(height: AppSpacing.stackSm),
                _SectionTabs(controller: controller),
                const SizedBox(height: AppSpacing.stackMd),
                Expanded(child: _Roster(controller: controller)),
              ],
            );
          }),
        ),
      ],
    );
  }
}

/// Horizontally scrollable tab strip — a fixed TabBar would squeeze labels
/// unreadably once a teacher has more than three or four sections.
class _SectionTabs extends StatelessWidget {
  final ClassPerformanceController controller;
  const _SectionTabs({required this.controller});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: Obx(() {
        final selected = controller.selectedSectionId.value;
        return ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.containerPaddingMobile),
          itemCount: controller.sections.length,
          separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.stackSm),
          itemBuilder: (context, i) {
            final s = controller.sections[i];
            final active = s.sectionId == selected;
            return GestureDetector(
              onTap: () => controller.selectSection(s.sectionId),
              child: AnimatedContainer(
                duration: AppMotion.fast,
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.stackMd),
                decoration: BoxDecoration(
                  color: active
                      ? AppColors.primary
                      : AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                  border: Border.all(
                    color: active ? AppColors.primary : AppColors.outlineVariant,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (s.isClassTeacher) ...[
                      Icon(Icons.star_rounded,
                          size: 13,
                          color:
                              active ? AppColors.onPrimary : AppColors.primary),
                      const SizedBox(width: 4),
                    ],
                    Text(s.title,
                        style: AppTypography.labelMd.copyWith(
                          fontWeight: FontWeight.w700,
                          color: active
                              ? AppColors.onPrimary
                              : AppColors.onSurfaceVariant,
                        )),
                  ],
                ),
              ),
            );
          },
        );
      }),
    );
  }
}

class _Roster extends StatelessWidget {
  final ClassPerformanceController controller;
  const _Roster({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isCurrentLoading) {
        return const Shimmer(
          child: Padding(
            padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.containerPaddingMobile),
            child: SkeletonRosterList(),
          ),
        );
      }
      final err = controller.currentError;
      if (err != null) {
        return _Message(
          icon: Icons.cloud_off_rounded,
          text: err,
          onRetry: controller.refreshCurrent,
        );
      }
      final data = controller.current;
      if (data == null) return const SizedBox.shrink();
      if (data.students.isEmpty) {
        return const _Message(
          icon: Icons.people_outline_rounded,
          text: 'No students are enrolled in this section yet.',
        );
      }

      return RefreshIndicator(
        onRefresh: controller.refreshCurrent,
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.containerPaddingMobile,
              0,
              AppSpacing.containerPaddingMobile,
              AppSpacing.stackXl),
          itemCount: data.students.length + 1,
          separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.stackSm),
          itemBuilder: (context, i) {
            if (i == 0) return _Summary(data: data);
            final student = data.students[i - 1];
            return StudentStandingCard(
              student: student,
              rank: i,
              onTap: () => Get.toNamed(TeacherRoutes.studentPerformance,
                  arguments: student.studentId),
              onMenu: () => _showMenu(context, student),
            );
          },
        ),
      );
    });
  }

  Future<void> _showMenu(BuildContext context, StudentStanding s) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.card)),
      ),
      builder: (sheet) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: AppSpacing.stackMd),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: AppSpacing.stackSm),
            ListTile(
              leading: const Icon(Icons.insights_rounded,
                  color: AppColors.primary),
              title: const Text('View performance'),
              subtitle: Text(s.fullName),
              onTap: () {
                Navigator.of(sheet).pop();
                Get.toNamed(TeacherRoutes.studentPerformance,
                    arguments: s.studentId);
              },
            ),
            ListTile(
              leading: const Icon(Icons.description_outlined,
                  color: AppColors.primary),
              title: const Text('Full student report'),
              onTap: () {
                Navigator.of(sheet).pop();
                Get.toNamed(HeadmasterRoutes.studentReport,
                    arguments: s.studentId);
              },
            ),
            const SizedBox(height: AppSpacing.stackSm),
          ],
        ),
      ),
    );
  }
}

/// Class-level roll-up above the ranking.
class _Summary extends StatelessWidget {
  final SectionPerformance data;
  const _Summary({required this.data});

  @override
  Widget build(BuildContext context) {
    final withMarks = data.students.where((s) => s.papersCounted > 0).toList();
    final withDays = data.students.where((s) => s.totalDays > 0).toList();
    final avgMark = withMarks.isEmpty
        ? null
        : withMarks.map((s) => s.averagePercentage).reduce((a, b) => a + b) /
            withMarks.length;
    final avgAtt = withDays.isEmpty
        ? null
        : withDays.map((s) => s.attendanceRate).reduce((a, b) => a + b) /
            withDays.length;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.stackSm),
      child: Row(
        children: [
          Expanded(
            child: _SummaryTile(
              label: 'Students',
              value: '${data.students.length}',
              icon: Icons.people_alt_outlined,
            ),
          ),
          const SizedBox(width: AppSpacing.stackSm),
          Expanded(
            child: _SummaryTile(
              label: 'Avg attendance',
              value: avgAtt == null ? '—' : '${(avgAtt * 100).round()}%',
              icon: Icons.event_available_outlined,
            ),
          ),
          const SizedBox(width: AppSpacing.stackSm),
          Expanded(
            child: _SummaryTile(
              label: 'Avg marks',
              value: avgMark == null ? '—' : '${avgMark.toStringAsFixed(0)}%',
              icon: Icons.school_outlined,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const _SummaryTile(
      {required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      padding: const EdgeInsets.all(AppSpacing.stackMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppColors.onSurfaceVariant),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value,
                style: AppTypography.titleLg
                    .copyWith(fontWeight: FontWeight.w800)),
          ),
          Text(label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.bodySm),
        ],
      ),
    );
  }
}

class _Message extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback? onRetry;
  const _Message({required this.icon, required this.text, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.stackXl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 40, color: AppColors.outline),
          const SizedBox(height: AppSpacing.stackMd),
          Text(text, style: AppTypography.bodyLg, textAlign: TextAlign.center),
          if (onRetry != null) ...[
            const SizedBox(height: AppSpacing.stackMd),
            TextButton(onPressed: onRetry, child: const Text('Try again')),
          ],
        ],
      ),
    );
  }
}
