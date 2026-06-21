import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared/shared.dart';

import '../../../../../widgets/portal_top_bar.dart';
import '../../../../../widgets/section_header.dart';
import '../components/pulse_card.dart';
import '../components/school_identity_card.dart';
import '../components/upcoming_event_card.dart';
import '../controller/overview_controller.dart';

/// School Overview — identity card, "Island Pulse" KPIs, upcoming events.
class OverviewView extends GetView<OverviewController> {
  const OverviewView({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      body: Column(
        children: [
          PortalTopBar(onBell: () => Get.back<void>()),
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
                    AppSpacing.stackXl),
                children: [
                  SchoolIdentityCard(school: data.school, onEdit: () {}),
                  const SizedBox(height: AppSpacing.stackLg),
                  Text('Island Pulse', style: AppTypography.headlineLg.copyWith(fontSize: 24)),
                  const SizedBox(height: AppSpacing.stackMd),
                  for (final p in data.pulse) ...[
                    PulseCard(metric: p),
                    const SizedBox(height: AppSpacing.stackMd),
                  ],
                  const SizedBox(height: AppSpacing.stackMd),
                  SectionHeader(
                    title: 'Upcoming Events',
                    actionLabel: 'View All',
                    actionIcon: Icons.arrow_forward_rounded,
                    onAction: () {},
                  ),
                  const SizedBox(height: AppSpacing.stackMd),
                  SizedBox(
                    height: 220,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: data.events.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(width: AppSpacing.stackMd),
                      itemBuilder: (context, i) =>
                          UpcomingEventCard(event: data.events[i]),
                    ),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }
}
