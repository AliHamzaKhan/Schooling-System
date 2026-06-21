import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared/shared.dart';

import '../../../../../widgets/portal_top_bar.dart';
import '../components/class_card.dart';
import '../controller/classes_controller.dart';

/// My Classes — list of active classes the teacher owns.
class ClassesView extends GetView<ClassesController> {
  const ClassesView({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PortalTopBar(title: 'Teacher Portal'),
        Expanded(
          child: Obx(() {
            if (controller.loading.value) {
              return const Center(child: CircularProgressIndicator());
            }
            return ListView(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.containerPaddingMobile,
                  0,
                  AppSpacing.containerPaddingMobile,
                  AppSpacing.stackXl),
              children: [
                Text('My Classes',
                    style: AppTypography.displayLg.copyWith(fontSize: 32)),
                const SizedBox(height: AppSpacing.stackSm),
                Text('Manage your current active classes and students.',
                    style: AppTypography.bodyLg),
                const SizedBox(height: AppSpacing.stackLg),
                for (final c in controller.classes) ...[
                  ClassCard(item: c, onView: () {}, onMenu: () {}),
                  const SizedBox(height: AppSpacing.stackMd),
                ],
              ],
            );
          }),
        ),
      ],
    );
  }
}
