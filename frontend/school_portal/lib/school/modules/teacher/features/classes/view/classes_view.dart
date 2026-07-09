import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared/shared.dart';

import '../../../../../widgets/portal_top_bar.dart';
import '../components/class_card.dart';
import '../controller/classes_controller.dart';
import '../models/teaching_class.dart';

/// My Classes — list of active classes the teacher owns.
class ClassesView extends GetView<ClassesController> {
  /// Opens the detail screen for a class (View Class / card menu).
  final ValueChanged<TeachingClass>? onOpenClass;

  const ClassesView({super.key, this.onOpenClass});

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
                  ClassCard(
                    item: c,
                    onView: () => onOpenClass?.call(c),
                    onMenu: () => _showClassMenu(context, c),
                  ),
                  const SizedBox(height: AppSpacing.stackMd),
                ],
              ],
            );
          }),
        ),
      ],
    );
  }

  Future<void> _showClassMenu(BuildContext context, TeachingClass c) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.card)),
      ),
      builder: (sheetContext) => SafeArea(
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
              leading: const Icon(Icons.visibility_outlined,
                  color: AppColors.primary),
              title: const Text('View Class'),
              subtitle: Text('${c.grade} · ${c.subject}'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                onOpenClass?.call(c);
              },
            ),
            const SizedBox(height: AppSpacing.stackSm),
          ],
        ),
      ),
    );
  }
}
