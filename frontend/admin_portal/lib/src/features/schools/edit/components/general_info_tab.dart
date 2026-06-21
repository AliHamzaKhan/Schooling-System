import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared/shared.dart';

import '../../../../ui/admin_widgets/admin_text_field.dart';
import '../../../../ui/admin_widgets/segmented_pills.dart';
import '../controller/edit_school_controller.dart';
import 'edit_section_card.dart';

/// General Info tab — basic details, contact & location, logo, account status,
/// and a read-only platform usage overview.
class GeneralInfoTab extends StatelessWidget {
  final EditSchoolController controller;
  const GeneralInfoTab({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        EditSectionCard(
          title: 'Basic Details',
          children: [
            AdminTextField(label: 'School Name', controller: controller.nameCtrl, filled: true),
            const SizedBox(height: AppSpacing.stackMd),
            AdminTextField(
                label: 'Registration Number',
                controller: controller.registrationCtrl,
                filled: true),
            const SizedBox(height: AppSpacing.stackMd),
            AdminTextField(
                label: 'Establishment Year',
                controller: controller.establishedCtrl,
                keyboardType: TextInputType.number,
                filled: true),
            const SizedBox(height: AppSpacing.stackMd),
            Text('Institution Type',
                style: AppTypography.labelMd.copyWith(color: AppColors.onSurface)),
            const SizedBox(height: 6),
            Obx(() => SegmentedPills(
                  options: EditSchoolController.institutionTypes,
                  selected: controller.institutionType.value,
                  onSelected: controller.selectInstitutionType,
                )),
          ],
        ),
        const SizedBox(height: AppSpacing.stackLg),
        EditSectionCard(
          title: 'Contact & Location',
          accent: const Color(0xFFE8A317),
          children: [
            AdminTextField(label: 'Primary Phone', controller: controller.phoneCtrl, filled: true),
            const SizedBox(height: AppSpacing.stackMd),
            AdminTextField(label: 'Official Email', controller: controller.emailCtrl, filled: true),
            const SizedBox(height: AppSpacing.stackMd),
            AdminTextField(
                label: 'Physical Address',
                controller: controller.addressCtrl,
                maxLines: 2,
                filled: true),
            const SizedBox(height: AppSpacing.stackMd),
            AdminTextField(label: 'City', controller: controller.cityCtrl, filled: true),
            const SizedBox(height: AppSpacing.stackMd),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: AdminTextField(
                      label: 'State / Region', controller: controller.stateCtrl, filled: true),
                ),
                const SizedBox(width: AppSpacing.stackMd),
                Expanded(
                  child: AdminTextField(
                      label: 'Postal Code',
                      controller: controller.postalCtrl,
                      keyboardType: TextInputType.number,
                      filled: true),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.stackLg),
        _LogoCard(),
        const SizedBox(height: AppSpacing.stackLg),
        _AccountStatusCard(controller: controller),
        const SizedBox(height: AppSpacing.stackLg),
        _UsageCard(students: controller.school.students),
      ],
    );
  }
}

class _LogoCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('School Crest / Logo',
              style: AppTypography.labelMd.copyWith(color: AppColors.onSurface)),
          const SizedBox(height: AppSpacing.stackMd),
          Center(
            child: Column(
              children: [
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: AppColors.inverseSurface,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: const Icon(Icons.shield_moon_outlined,
                      color: Color(0xFFE8A317), size: 44),
                ),
                const SizedBox(height: AppSpacing.stackSm),
                Text('Recommended: 512×512px PNG', style: AppTypography.bodySm),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AccountStatusCard extends StatelessWidget {
  final EditSchoolController controller;
  const _AccountStatusCard({required this.controller});

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Account Status', style: AppTypography.titleLg),
          const SizedBox(height: AppSpacing.stackMd),
          Obx(() => Container(
                padding: const EdgeInsets.all(AppSpacing.stackMd),
                decoration: BoxDecoration(
                  color: controller.suspended.value
                      ? AppColors.error.withValues(alpha: 0.08)
                      : AppColors.tertiary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(AppRadius.button),
                ),
                child: Row(
                  children: [
                    Icon(
                      controller.suspended.value
                          ? Icons.pause_circle_outline_rounded
                          : Icons.check_circle_outline_rounded,
                      color: controller.suspended.value ? AppColors.error : AppColors.tertiary,
                    ),
                    const SizedBox(width: AppSpacing.stackSm),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          controller.suspended.value ? 'Suspended' : 'Active Account',
                          style: AppTypography.titleMd.copyWith(
                            fontWeight: FontWeight.w600,
                            color: controller.suspended.value ? AppColors.error : AppColors.tertiary,
                          ),
                        ),
                        Text(
                          controller.suspended.value
                              ? 'Hidden from public directories'
                              : 'Visible in public directories',
                          style: AppTypography.bodySm,
                        ),
                      ],
                    ),
                  ],
                ),
              )),
          const SizedBox(height: AppSpacing.stackMd),
          Row(
            children: [
              Expanded(
                  child: Text('Temporarily Suspend', style: AppTypography.titleMd)),
              Obx(() => Switch(
                    value: controller.suspended.value,
                    onChanged: controller.toggleSuspend,
                  )),
            ],
          ),
        ],
      ),
    );
  }
}

class _UsageCard extends StatelessWidget {
  final int students;
  const _UsageCard({required this.students});

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Platform Usage Overview', style: AppTypography.titleLg),
          const SizedBox(height: AppSpacing.stackMd),
          _row('Registered Students', '$students'),
          const Divider(height: AppSpacing.stackLg, color: AppColors.outlineVariant),
          _row('Active Teachers', '84'),
          const Divider(height: AppSpacing.stackLg, color: AppColors.outlineVariant),
          _row('Storage Used', '46 GB'),
        ],
      ),
    );
  }

  Widget _row(String label, String value) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTypography.bodyLg),
          Text(value, style: AppTypography.titleMd.copyWith(fontWeight: FontWeight.w700)),
        ],
      );
}
