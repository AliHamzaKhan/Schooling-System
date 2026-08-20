import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared/shared.dart';

import '../../../../../config/headmaster_routes.dart';
import '../../../../../widgets/portal_top_bar.dart';
import '../../student_report/view/section_students_view.dart';
import '../components/class_stat_tile.dart';
import '../components/grade_card.dart';
import '../controller/classes_controller.dart';
import '../../../../../widgets/skeletons.dart';

/// Class Directory — grades, sections, homeroom teacher assignments + KPIs.
class ClassesView extends GetView<HeadmasterClassesController> {
  const ClassesView({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PortalTopBar(showAvatar: true),
        Expanded(
          child: Obx(() {
            if (controller.loading.value) {
              return const SkeletonPage(body: Column(children: [SkeletonStatGrid(count: 4), SizedBox(height: AppSpacing.stackLg), SkeletonCardList(count: 3, height: 130)]));
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
                const SizedBox(height: AppSpacing.stackMd),
                PrimaryButton(
                  label: 'New Class',
                  leadingIcon: AppIcons.add,
                  trailingIcon: null,
                  onPressed: controller.createClassFlow,
                ),
                const SizedBox(height: AppSpacing.stackLg),
                _statGrid(data.stats),
                const SizedBox(height: AppSpacing.stackLg),
                for (final g in data.grades) ...[
                  GradeCard(
                    group: g,
                    onAddSection: () =>
                        controller.addSectionFlow(g.classId, g.className),
                    onMenu: () =>
                        controller.classMenuFlow(g.classId, g.className),
                    onSectionTap: (s) => Get.toNamed(
                      HeadmasterRoutes.sectionStudents,
                      arguments: SectionStudentsArgs(
                        sectionId: s.id,
                        title: '${g.className} · ${s.name}',
                      ),
                    ),
                  ),
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

