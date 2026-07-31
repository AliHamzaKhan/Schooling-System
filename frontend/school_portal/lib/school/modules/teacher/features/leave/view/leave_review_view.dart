import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared/shared.dart';

import '../../../../../widgets/leave_review.dart';
import '../../../../../widgets/skeletons.dart';
import '../controller/leave_review_controller.dart';

/// Class teacher: leave requests for their own section students.
class TeacherLeaveReviewView extends GetView<TeacherLeaveReviewController> {
  const TeacherLeaveReviewView({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(title: const Text('Leave Requests')),
      body: Obx(() {
        if (controller.loading.value) {
          return const SkeletonPage(body: SkeletonCardList(count: 4, height: 140));
        }
        if (controller.error.value != null) {
          return Center(
              child: Text(controller.error.value!, style: AppTypography.bodyLg));
        }
        if (controller.items.isEmpty) {
          return Center(
              child: Text('No leave requests from your students.',
                  textAlign: TextAlign.center, style: AppTypography.bodyLg));
        }
        final pending = controller.pending;
        final reviewed = controller.reviewed;
        return RefreshIndicator(
          onRefresh: controller.load,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.containerPaddingMobile,
                AppSpacing.stackLg,
                AppSpacing.containerPaddingMobile,
                AppSpacing.stackXxl),
            children: [
              if (pending.isNotEmpty) ...[
                Text('Pending (${pending.length})',
                    style: AppTypography.titleMd
                        .copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: AppSpacing.stackMd),
                for (final l in pending) ...[
                  LeaveReviewCard(
                    item: l,
                    onApprove: () => controller.review(l.id, true),
                    onReject: () => controller.review(l.id, false),
                  ),
                  const SizedBox(height: AppSpacing.stackMd),
                ],
              ],
              if (reviewed.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.stackSm),
                Text('Reviewed',
                    style: AppTypography.titleMd
                        .copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: AppSpacing.stackMd),
                for (final l in reviewed) ...[
                  LeaveReviewCard(item: l),
                  const SizedBox(height: AppSpacing.stackMd),
                ],
              ],
            ],
          ),
        );
      }),
    );
  }
}
