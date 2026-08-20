import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared/shared.dart';

import '../../../../../widgets/portal_top_bar.dart';
import '../../../../../widgets/status_pill.dart';
import '../../../shared/controller/guardian_session_controller.dart';
import '../../../shared/models/child.dart';
import '../../../shared/widgets/child_avatar.dart';
import '../../../../../widgets/skeletons.dart';

/// Child Selection Screen — full-page list of the guardian's children. Picking
/// one sets it active in the session and pops back to the dashboard.
class ChildSelectionView extends StatelessWidget {
  const ChildSelectionView({super.key});

  @override
  Widget build(BuildContext context) {
    final session = Get.find<GuardianSessionController>();
    return AppScaffold(
      body: Column(
        children: [
          const PortalTopBar(title: 'My Children', showAvatar: false),
          Expanded(
            child: Obx(() {
              if (session.loading.value) {
                return const SkeletonPage(body: SkeletonCardList(count: 3, height: 110));
              }
              return ListView(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.containerPaddingMobile,
                    0,
                    AppSpacing.containerPaddingMobile,
                    AppSpacing.stackXl),
                children: [
                  Text('Select a child',
                      style: AppTypography.headlineLg),
                  const SizedBox(height: AppSpacing.stackSm),
                  Text('Switch the active profile across the parent portal.',
                      style: AppTypography.bodyLg),
                  const SizedBox(height: AppSpacing.stackLg),
                  for (final c in session.children) ...[
                    _ChildCard(
                      child: c,
                      selected: c.id == session.selectedId.value,
                      onTap: () {
                        session.select(c.id);
                        Get.back<void>();
                      },
                    ),
                    const SizedBox(height: AppSpacing.stackMd),
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

class _ChildCard extends StatelessWidget {
  final Child child;
  final bool selected;
  final VoidCallback onTap;
  const _ChildCard(
      {required this.child, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: GlassSurface(
        padding: const EdgeInsets.all(AppSpacing.stackMd),
        child: Row(
          children: [
            ChildAvatar(child: child, size: 52),
            const SizedBox(width: AppSpacing.stackMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(child.name,
                            style: AppTypography.titleLg),
                      ),
                      if (selected)
                        const StatusPill(
                            label: 'Active', color: AppColors.tertiary),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(child.grade, style: AppTypography.bodyMd),
                  const SizedBox(height: AppSpacing.stackSm),
                  Row(
                    children: [
                      _MiniStat(
                          label: 'Attd',
                          value: '${child.attendancePercent}%'),
                      _MiniStat(
                          label: 'GPA',
                          value: child.gpa.toStringAsFixed(1)),
                      _MiniStat(
                          label: 'HW',
                          value: '${child.pendingHomework}'),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(AppIcons.chevronRightRounded,
                color: AppColors.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  const _MiniStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.stackMd),
      child: Row(
        children: [
          Text('$value ',
              style: AppTypography.labelMd
                  .copyWith(fontWeight: FontWeight.w800)),
          Text(label,
              style: AppTypography.labelMd
                  .copyWith(color: AppColors.onSurfaceVariant)),
        ],
      ),
    );
  }
}
