import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared/shared.dart';

import '../../../../../config/student_routes.dart';
import '../../../../../widgets/portal_top_bar.dart';
import '../components/countdown_card.dart';
import '../components/timeline_card.dart';
import '../controller/exams_controller.dart';
import '../../../../../widgets/skeletons.dart';

/// Student Exam Schedule — countdown to the next exam + an upcoming timeline.
class ExamsView extends GetView<StudentExamsController> {
  final VoidCallback? onNotifications;
  const ExamsView({super.key, this.onNotifications});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        PortalTopBar(title: 'EduMaster', onBell: onNotifications),
        Expanded(
          child: Obx(() {
            if (controller.loading.value) {
              return const SkeletonPage(body: SkeletonCardList(count: 5, height: 96));
            }
            final data = controller.data.value;
            if (data == null) return const SizedBox.shrink();
            return ListView(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.containerPaddingMobile,
                  0,
                  AppSpacing.containerPaddingMobile,
                  AppSpacing.stackXl),
              children: [
                Text('Exam Schedule', style: AppTypography.headlineLg),
                const SizedBox(height: AppSpacing.stackSm),
                Text('You have ${data.comingThisMonth} exams coming up this month.',
                    style: AppTypography.bodyLg),
                const SizedBox(height: AppSpacing.stackLg),
                CountdownCard(
                  next: data.next,
                  onTap: data.nextEntry == null
                      ? null
                      : () => Get.toNamed(StudentRoutes.examDetail,
                          arguments: data.nextEntry),
                ),
                const SizedBox(height: AppSpacing.stackXl),
                Text('Upcoming Timeline',
                    style: AppTypography.displayLg.copyWith(fontSize: 28)),
                const SizedBox(height: AppSpacing.stackMd),
                for (var i = 0; i < data.timeline.length; i++)
                  TimelineCard(
                    exam: data.timeline[i],
                    isLast: i == data.timeline.length - 1,
                    onTap: () => Get.toNamed(StudentRoutes.examDetail,
                        arguments: data.timeline[i]),
                  ),
              ],
            );
          }),
        ),
      ],
    );
  }
}
