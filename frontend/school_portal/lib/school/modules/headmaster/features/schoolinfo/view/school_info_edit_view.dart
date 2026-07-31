import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared/shared.dart';

import '../../../../../widgets/action_form_sheet.dart';
import '../../../../../widgets/portal_form_field.dart';
import '../../../../../widgets/skeletons.dart';
import '../controller/school_info_edit_controller.dart';

/// Headmaster: edit About Us, Achievements, and the school uniform image. Name,
/// address and contacts stay on School Settings.
class SchoolInfoEditView extends GetView<SchoolInfoEditController> {
  const SchoolInfoEditView({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(title: const Text('School Info')),
      body: Obx(() {
        if (controller.loading.value) {
          return const SkeletonPage(body: SkeletonCardList(count: 3, height: 120));
        }
        return ListView(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.containerPaddingMobile,
              AppSpacing.stackLg,
              AppSpacing.containerPaddingMobile,
              AppSpacing.stackXxl),
          children: [
            // About.
            GlassSurface(
              padding: const EdgeInsets.all(AppSpacing.stackLg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('About Us',
                      style: AppTypography.titleMd
                          .copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: AppSpacing.stackMd),
                  PortalFormField(
                    label: 'Description',
                    hint: 'Tell students and guardians about the school…',
                    controller: controller.aboutCtrl,
                    maxLines: 5,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.stackMd),

            // Achievements.
            GlassSurface(
              padding: const EdgeInsets.all(AppSpacing.stackLg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('Achievements',
                          style: AppTypography.titleMd
                              .copyWith(fontWeight: FontWeight.w700)),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: () => _addAchievement(context),
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text('Add'),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.stackSm),
                  Obx(() {
                    if (controller.achievements.isEmpty) {
                      return Text('No achievements added yet.',
                          style: AppTypography.bodyMd
                              .copyWith(color: AppColors.onSurfaceVariant));
                    }
                    return Column(
                      children: [
                        for (var i = 0; i < controller.achievements.length; i++)
                          _AchievementRow(
                            data: controller.achievements[i],
                            onRemove: () => controller.removeAchievement(i),
                          ),
                      ],
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.stackMd),

            // Uniform.
            GlassSurface(
              padding: const EdgeInsets.all(AppSpacing.stackLg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('School Uniform',
                      style: AppTypography.titleMd
                          .copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: AppSpacing.stackMd),
                  Obx(() {
                    final url = controller.uniformImageUrl.value;
                    if ((url ?? '').isEmpty) {
                      return Text('No uniform image uploaded.',
                          style: AppTypography.bodyMd
                              .copyWith(color: AppColors.onSurfaceVariant));
                    }
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.button),
                      child: Image.network(
                        EnvConfig.mediaUrl(url!),
                        height: 180,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Container(
                          height: 120,
                          alignment: Alignment.center,
                          color: AppColors.surfaceContainerLow,
                          child: Text('Preview unavailable',
                              style: AppTypography.bodySm),
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: AppSpacing.stackMd),
                  Obx(() => GhostButton(
                        label: controller.uploading.value
                            ? 'Uploading…'
                            : ((controller.uniformImageUrl.value ?? '').isEmpty
                                ? 'Upload Image'
                                : 'Replace Image'),
                        leadingIcon: Icons.upload_rounded,
                        expanded: true,
                        onPressed: controller.uploading.value
                            ? null
                            : controller.pickUniform,
                      )),
                ],
              ),
            ),

            Obx(() {
              final err = controller.error.value;
              if (err == null) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(top: AppSpacing.stackMd),
                child: Text(err,
                    style:
                        AppTypography.bodyMd.copyWith(color: AppColors.error)),
              );
            }),
            const SizedBox(height: AppSpacing.stackLg),

            Obx(() => PrimaryButton(
                  label: 'Save Changes',
                  leadingIcon: Icons.save_rounded,
                  expanded: true,
                  isLoading: controller.saving.value,
                  onPressed: () async {
                    final ok = await controller.save();
                    if (ok) {
                      Get.snackbar('Saved', 'School info updated.',
                          snackPosition: SnackPosition.BOTTOM);
                    }
                  },
                )),
          ],
        );
      }),
    );
  }

  Future<void> _addAchievement(BuildContext context) async {
    final title = TextEditingController();
    final description = TextEditingController();
    final year = TextEditingController();
    await showActionFormSheet(
      title: 'Add Achievement',
      fields: [
        GlassInput(label: 'Title', hint: 'e.g. Science Fair Winner', controller: title),
        GlassInput(label: 'Description (optional)', hint: 'Details', controller: description),
        GlassInput(label: 'Year (optional)', hint: 'e.g. 2025', controller: year),
      ],
      onSubmit: () async {
        if (title.text.trim().isEmpty) return 'A title is required';
        controller.addAchievement(
            title.text.trim(), description.text.trim(), year.text.trim());
        return null;
      },
    );
  }
}

class _AchievementRow extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback onRemove;
  const _AchievementRow({required this.data, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final title = data['title'] as String? ?? '';
    final year = data['year'] as String?;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.stackSm),
      child: Row(
        children: [
          const Icon(Icons.military_tech_outlined,
              size: 18, color: Color(0xFFE8A317)),
          const SizedBox(width: AppSpacing.stackSm),
          Expanded(
            child: Text(
              (year ?? '').isEmpty ? title : '$title ($year)',
              style: AppTypography.bodyMd,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 18),
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }
}
