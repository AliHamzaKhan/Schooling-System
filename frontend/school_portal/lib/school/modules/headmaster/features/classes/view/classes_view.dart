import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared/shared.dart';

import '../../../../../widgets/portal_top_bar.dart';
import '../components/class_stat_tile.dart';
import '../components/grade_card.dart';
import '../controller/classes_controller.dart';

/// Class Directory — grades, sections, homeroom teacher assignments + KPIs.
class ClassesView extends GetView<ClassesController> {
  final VoidCallback? onManageStudents;
  final VoidCallback? onManageGuardians;
  final VoidCallback? onManageTeachers;
  const ClassesView({
    super.key,
    this.onManageStudents,
    this.onManageGuardians,
    this.onManageTeachers,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PortalTopBar(showAvatar: true),
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
                Text('Class Directory',
                    style: AppTypography.displayLg.copyWith(fontSize: 32)),
                const SizedBox(height: AppSpacing.stackSm),
                Text('Manage grades, sections, and homeroom assignments.',
                    style: AppTypography.bodyLg),
                const SizedBox(height: AppSpacing.stackMd),
                Row(
                  children: const [
                    _IconLink(icon: Icons.filter_list_rounded, label: 'All Grades'),
                    SizedBox(width: AppSpacing.stackLg),
                    _IconLink(icon: Icons.grid_view_rounded, label: 'View'),
                  ],
                ),
                const SizedBox(height: AppSpacing.stackMd),
                PrimaryButton(
                  label: 'New Class',
                  leadingIcon: Icons.add,
                  trailingIcon: null,
                  onPressed: () {},
                ),
                const SizedBox(height: AppSpacing.stackMd),
                Row(
                  children: [
                    Expanded(
                      child: _PeopleLink(
                        icon: Icons.school_outlined,
                        label: 'Students',
                        onTap: onManageStudents,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.stackMd),
                    Expanded(
                      child: _PeopleLink(
                        icon: Icons.record_voice_over_outlined,
                        label: 'Teachers',
                        onTap: onManageTeachers,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.stackMd),
                    Expanded(
                      child: _PeopleLink(
                        icon: Icons.family_restroom_outlined,
                        label: 'Guardians',
                        onTap: onManageGuardians,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.stackLg),
                _statGrid(data.stats),
                const SizedBox(height: AppSpacing.stackLg),
                for (final g in data.grades) ...[
                  GradeCard(group: g, onAddSection: () {}, onMenu: () {}),
                  const SizedBox(height: AppSpacing.stackLg),
                ],
              ],
            );
          }),
        ),
      ],
    );
  }

  Widget _statGrid(List<dynamic> stats) {
    // 2×N grid: two tiles per row, fixed gutters.
    return Column(
      children: [
        for (var i = 0; i < stats.length; i += 2) ...[
          Row(
            children: [
              Expanded(child: ClassStatTile(stat: stats[i])),
              const SizedBox(width: AppSpacing.stackMd),
              if (i + 1 < stats.length)
                Expanded(child: ClassStatTile(stat: stats[i + 1]))
              else
                const Expanded(child: SizedBox()),
            ],
          ),
          if (i + 2 < stats.length) const SizedBox(height: AppSpacing.stackMd),
        ],
      ],
    );
  }
}

class _PeopleLink extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  const _PeopleLink({required this.icon, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.button),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.stackMd),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(AppRadius.button),
          border: Border.all(color: AppColors.outlineVariant, width: 1),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppColors.primary),
            const SizedBox(width: AppSpacing.stackSm),
            Expanded(
              child: Text(label,
                  style: AppTypography.labelMd
                      .copyWith(color: AppColors.primary, fontWeight: FontWeight.w700)),
            ),
            const Icon(Icons.chevron_right_rounded,
                size: 18, color: AppColors.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

class _IconLink extends StatelessWidget {
  final IconData icon;
  final String label;
  const _IconLink({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppColors.onSurfaceVariant),
        const SizedBox(width: 6),
        Text(label, style: AppTypography.labelMd),
      ],
    );
  }
}
