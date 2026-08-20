import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared/shared.dart';

import '../../../../../widgets/portal_top_bar.dart';
import '../../../../../widgets/section_header.dart';
import '../../../../../widgets/status_pill.dart';
import '../../../shared/widgets/child_switcher.dart';
import '../controller/meeting_controller.dart';
import '../models/meeting_data.dart';
import '../../../../../widgets/skeletons.dart';

/// Meeting Schedule — drill-in screen for parent-teacher meetings. Shows
/// upcoming and past meetings with status pills and a request action.
class MeetingView extends GetView<MeetingController> {
  const MeetingView({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      body: Column(
        children: [
          const PortalTopBar(title: 'Meetings', showAvatar: false),
          const ChildSwitcher(),
          Expanded(
            child: Obx(() {
              if (controller.loading.value) {
                return const SkeletonPage(body: SkeletonCardList(count: 4, height: 110));
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
                  PrimaryButton(
                    label: 'Request a meeting',
                    onPressed: () => Get.snackbar('Request sent',
                        'A meeting request flow is not wired in this build.',
                        snackPosition: SnackPosition.BOTTOM),
                  ),
                  const SizedBox(height: AppSpacing.stackLg),
                  const SectionHeader(title: 'Upcoming'),
                  const SizedBox(height: AppSpacing.stackMd),
                  if (d.upcoming.isEmpty)
                    _Empty(text: 'No upcoming meetings.')
                  else
                    for (final m in d.upcoming) ...[
                      _MeetingCard(meeting: m),
                      const SizedBox(height: AppSpacing.stackSm),
                    ],
                  const SizedBox(height: AppSpacing.stackLg),
                  const SectionHeader(title: 'Past'),
                  const SizedBox(height: AppSpacing.stackMd),
                  if (d.past.isEmpty)
                    _Empty(text: 'No past meetings.')
                  else
                    for (final m in d.past) ...[
                      _MeetingCard(meeting: m),
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

class _MeetingCard extends StatelessWidget {
  final Meeting meeting;
  const _MeetingCard({required this.meeting});

  ({String label, Color color}) get _statusStyle => switch (meeting.status) {
        MeetingStatus.requested =>
          (label: 'Requested', color: Color(0xFFE8A317)),
        MeetingStatus.confirmed =>
          (label: 'Confirmed', color: AppColors.tertiary),
        MeetingStatus.completed =>
          (label: 'Completed', color: AppColors.onSurfaceVariant),
        MeetingStatus.cancelled => (label: 'Cancelled', color: AppColors.error),
      };

  @override
  Widget build(BuildContext context) {
    final s = _statusStyle;
    return GlassSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primaryFixed,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                    meeting.mode == MeetingMode.video
                        ? AppIcons.videocamOutlined
                        : AppIcons.groupsOutlined,
                    size: 20,
                    color: AppColors.primary),
              ),
              const SizedBox(width: AppSpacing.stackMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(meeting.teacher,
                        style: AppTypography.titleMd
                            .copyWith(fontWeight: FontWeight.w700)),
                    Text(meeting.subject, style: AppTypography.bodyMd),
                  ],
                ),
              ),
              StatusPill(label: s.label, color: s.color),
            ],
          ),
          const SizedBox(height: AppSpacing.stackSm),
          Row(
            children: [
              const Icon(AppIcons.eventRounded,
                  size: 15, color: AppColors.onSurfaceVariant),
              const SizedBox(width: 4),
              Text('${meeting.date} · ${meeting.time}',
                  style: AppTypography.bodyMd),
            ],
          ),
          if (meeting.note != null) ...[
            const SizedBox(height: 4),
            Text(meeting.note!,
                style: AppTypography.bodyMd
                    .copyWith(color: AppColors.onSurfaceVariant)),
          ],
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
          const Icon(AppIcons.inboxOutlined, color: AppColors.outline),
          const SizedBox(width: AppSpacing.stackSm),
          Expanded(child: Text(text, style: AppTypography.bodyMd)),
        ],
      ),
    );
  }
}
