import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared/shared.dart';

import '../../../ui/admin_widgets/admin_top_bar.dart';
import '../components/matrix_table.dart';
import '../controller/matrix_controller.dart';

/// Permission Assignment — a role-based matrix table. Tap any cell to grant or
/// revoke a permission for a role; tap a column header to flip a whole role.
/// Save / Discard track unsaved edits.
class MatrixView extends GetView<MatrixController> {
  const MatrixView({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AdminTopBar(
            title: 'Permission Assignment',
            showAvatar: false,
            actions: [
              IconButton(
                onPressed: () => Get.back<void>(),
                icon: const Icon(Icons.arrow_back_rounded,
                    color: AppColors.onSurface),
              ),
            ],
          ),
          Expanded(
            child: Obx(() {
              if (controller.loading.value) {
                return const Center(child: CircularProgressIndicator());
              }
              if (controller.matrix.value == null) {
                return const SizedBox.shrink();
              }
              return ListView(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.containerPaddingMobile,
                    0,
                    AppSpacing.containerPaddingMobile,
                    AppSpacing.stackXl),
                children: [
                  Text('Assign Permissions', style: AppTypography.headlineLg),
                  const SizedBox(height: AppSpacing.stackSm),
                  Text(
                      'Toggle which roles can perform each action. '
                      'Tap a role header to grant or revoke the entire column.',
                      style: AppTypography.bodyLg),
                  const SizedBox(height: AppSpacing.stackLg),
                  MatrixTable(controller: controller),
                  const SizedBox(height: AppSpacing.stackLg),
                  Obx(() => Row(
                        children: [
                          Expanded(
                            child: GhostButton(
                              label: 'Discard',
                              expanded: true,
                              onPressed: controller.dirty.value
                                  ? controller.discard
                                  : null,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.stackMd),
                          Expanded(
                            child: PrimaryButton(
                              label: 'Save Matrix',
                              expanded: true,
                              leadingIcon: Icons.save_outlined,
                              onPressed: controller.dirty.value
                                  ? () async {
                                      await controller.save();
                                      Get.snackbar('Saved',
                                          'Permission matrix updated.',
                                          snackPosition: SnackPosition.BOTTOM);
                                    }
                                  : null,
                            ),
                          ),
                        ],
                      )),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }
}
