import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared/shared.dart';

import '../../../../../widgets/portal_top_bar.dart';
import '../../../../../widgets/section_header.dart';
import '../../../../../widgets/status_pill.dart';
import '../../../shared/widgets/child_switcher.dart';
import '../controller/exam_controller.dart';
import '../models/exam_data.dart';
import '../../../../../widgets/skeletons.dart';

/// Exam Updates — drill-in screen listing upcoming exams (date/time/room/
/// syllabus) and published results for the active child.
class ExamView extends GetView<ExamController> {
  const ExamView({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      body: Column(
        children: [
          const PortalTopBar(title: 'Exam Updates', showAvatar: false),
          const ChildSwitcher(),
          Expanded(
            child: Obx(() {
              if (controller.loading.value) {
                return const SkeletonPage(body: SkeletonCardList(count: 5, height: 96));
              }
              final d = controller.data.value;
              if (d == null) return const SizedBox.shrink();
              return ListView(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.containerPaddingMobile,
                    AppSpacing.stackSm,
                    AppSpacing.containerPaddingMobile,
                    AppSpacing.stackXl),
                children: [
                  SectionHeader(title: 'Upcoming', actionLabel: d.termLabel),
                  const SizedBox(height: AppSpacing.stackMd),
                  if (d.upcoming.isEmpty)
                    _Empty(text: 'No upcoming exams scheduled.')
                  else
                    for (final e in d.upcoming) ...[
                      _UpcomingCard(entry: e),
                      const SizedBox(height: AppSpacing.stackSm),
                    ],
                  const SizedBox(height: AppSpacing.stackLg),
                  const SectionHeader(title: 'Results'),
                  const SizedBox(height: AppSpacing.stackMd),
                  if (d.results.isEmpty)
                    _Empty(text: 'No results published yet.')
                  else
                    for (final e in d.results) ...[
                      _ResultRow(entry: e),
                      const SizedBox(height: AppSpacing.stackSm),
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

class _UpcomingCard extends StatelessWidget {
  final ExamEntry entry;
  const _UpcomingCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(entry.subject,
                    style: AppTypography.titleLg),
              ),
              StatusPill(
                  label: entry.date,
                  color: AppColors.primary,
                  icon: Icons.event_rounded),
            ],
          ),
          const SizedBox(height: AppSpacing.stackSm),
          Row(
            children: [
              _Meta(icon: Icons.schedule_rounded, text: entry.time),
              const SizedBox(width: AppSpacing.stackMd),
              _Meta(icon: Icons.meeting_room_outlined, text: entry.room),
            ],
          ),
          if (entry.syllabus != null) ...[
            const SizedBox(height: AppSpacing.stackSm),
            _Meta(icon: Icons.menu_book_outlined, text: entry.syllabus!),
          ],
        ],
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  final IconData icon;
  final String text;
  const _Meta({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: AppColors.onSurfaceVariant),
        const SizedBox(width: 4),
        Text(text, style: AppTypography.bodyMd),
      ],
    );
  }
}

class _ResultRow extends StatelessWidget {
  final ExamEntry entry;
  const _ResultRow({required this.entry});

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      padding: const EdgeInsets.all(AppSpacing.stackMd),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.subject,
                    style: AppTypography.titleMd
                        .copyWith(fontWeight: FontWeight.w700)),
                Text(entry.date, style: AppTypography.bodyMd),
              ],
            ),
          ),
          StatusPill(
              label: entry.result!,
              color: AppColors.tertiary,
              icon: Icons.workspace_premium_outlined),
        ],
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  final String text;
  const _Empty({required this.text});

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      child: Row(
        children: [
          const Icon(Icons.inbox_outlined, color: AppColors.outline),
          const SizedBox(width: AppSpacing.stackSm),
          Expanded(child: Text(text, style: AppTypography.bodyMd)),
        ],
      ),
    );
  }
}
