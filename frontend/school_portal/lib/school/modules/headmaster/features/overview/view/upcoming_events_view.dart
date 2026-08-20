import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared/shared.dart';

import '../models/overview_data.dart';

/// Full "Upcoming Events" list, reached from School Overview's View All. The
/// events are passed in via [Get.arguments].
class UpcomingEventsView extends StatelessWidget {
  const UpcomingEventsView({super.key});

  List<UpcomingEvent> get _events {
    final arg = Get.arguments;
    return arg is List<UpcomingEvent> ? arg : const [];
  }

  @override
  Widget build(BuildContext context) {
    final events = _events;
    return AppScaffold(
      appBar: AppBar(title: const Text('Upcoming Events')),
      body: events.isEmpty
          ? Center(
              child: Text('No events scheduled.', style: AppTypography.bodyLg),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.containerPaddingMobile,
                  AppSpacing.stackMd,
                  AppSpacing.containerPaddingMobile,
                  AppSpacing.stackXl),
              itemCount: events.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(height: AppSpacing.stackMd),
              itemBuilder: (context, i) => _EventTile(event: events[i]),
            ),
    );
  }
}

class _EventTile extends StatelessWidget {
  final UpcomingEvent event;
  const _EventTile({required this.event});

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      padding: const EdgeInsets.all(AppSpacing.stackMd),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: event.tint.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(AppRadius.button),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(event.month.toUpperCase(),
                    style: AppTypography.labelCaps.copyWith(color: event.tint)),
                Text(event.day,
                    style: AppTypography.titleMd
                        .copyWith(color: event.tint, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.stackMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(event.title,
                    style: AppTypography.titleMd
                        .copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                _MetaRow(icon: AppIcons.scheduleRounded, label: event.time),
                if (event.location.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  _MetaRow(
                      icon: AppIcons.placeOutlined, label: event.location),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  final IconData icon;
  final String label;
  const _MetaRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.onSurfaceVariant),
        const SizedBox(width: 6),
        Expanded(
          child: Text(label,
              style: AppTypography.bodySm
                  .copyWith(color: AppColors.onSurfaceVariant)),
        ),
      ],
    );
  }
}
