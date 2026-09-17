import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared/shared.dart';

import '../../../../../widgets/portal_top_bar.dart';
import '../components/announcement_card.dart';
import '../controller/announcements_controller.dart';
import '../../../../../widgets/skeletons.dart';

/// Announcements Hub — filterable feed of announcements with a FAB to compose
/// a new one.
class AnnouncementsView extends GetView<AnnouncementsController> {
  const AnnouncementsView({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      body: Stack(
        children: [
          Column(
            children: [
              const PortalTopBar(showAvatar: true),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(
                      AppSpacing.containerPaddingMobile,
                      0,
                      AppSpacing.containerPaddingMobile,
                      120),
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text('Announcements\nHub',
                              style: AppTypography.headlineLg),
                        ),
                        Obx(() => _FilterPill(
                              value: controller.filter.value,
                              options: AnnouncementsController.filters,
                              onChanged: controller.selectFilter,
                            )),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.stackLg),
                    Obx(() {
                      if (controller.loading.value) {
                        return const Shimmer(
                          child: SkeletonCardList(count: 4, height: 110),
                        );
                      }
                      if (controller.error.value != null) {
                        return Column(children: [
                          Text(controller.error.value!),
                          TextButton(onPressed: controller.fetch, child: const Text('Try again')),
                        ]);
                      }
                      if (controller.items.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.all(AppSpacing.stackXl),
                          child: Center(
                            child: Text('No announcements yet.',
                                style: AppTypography.bodyLg),
                          ),
                        );
                      }
                      return Column(
                        children: [
                          for (final a in controller.items) ...[
                            AnnouncementCard(announcement: a, onReview: () => controller.review(context, a.id)),
                            const SizedBox(height: AppSpacing.stackLg),
                          ],
                        ],
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
          Positioned(
            right: AppSpacing.stackLg,
            bottom: AppSpacing.stackLg,
            child: FloatingActionButton(
              onPressed: controller.composeFlow,
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.onPrimary,
              child: const Icon(AppIcons.editOutlined),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  final String value;
  final List<String> options;
  final ValueChanged<String> onChanged;
  const _FilterPill({required this.value, required this.options, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: onChanged,
      itemBuilder: (context) => [
        for (final o in options)
          PopupMenuItem<String>(value: o, child: Text(o)),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(AppRadius.full),
          border: Border.all(color: AppColors.outlineVariant, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(AppIcons.tuneRounded, size: 16, color: AppColors.onSurfaceVariant),
            const SizedBox(width: 6),
            Text(value,
                style: AppTypography.labelMd.copyWith(color: AppColors.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}
