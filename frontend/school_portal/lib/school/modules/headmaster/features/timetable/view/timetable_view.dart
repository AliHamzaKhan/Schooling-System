import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared/shared.dart';

import '../../../../../widgets/portal_top_bar.dart';
import '../components/dropdown_filter.dart';
import '../components/timetable_grid.dart';
import '../controller/timetable_controller.dart';

/// Timetable Management — class/teacher filters, a New Class CTA, and the
/// weekly schedule grid with horizontal day scrolling.
class TimetableView extends GetView<TimetableController> {
  const TimetableView({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PortalTopBar(),
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
                  Text('Timetable Management',
                      style: AppTypography.displayLg
                          .copyWith(fontSize: 30, color: AppColors.primary)),
                  const SizedBox(height: AppSpacing.stackSm),
                  Text('Organize and view class schedules across the island.',
                      style: AppTypography.bodyLg),
                  const SizedBox(height: AppSpacing.stackLg),
                  DropdownFilter(
                    icon: Icons.filter_list_rounded,
                    value: controller.classFilter.value,
                    options: TimetableController.classOptions,
                    onChanged: controller.selectClass,
                  ),
                  const SizedBox(height: AppSpacing.stackSm),
                  DropdownFilter(
                    icon: Icons.person_outline_rounded,
                    value: controller.teacherFilter.value,
                    options: TimetableController.teacherOptions,
                    onChanged: controller.selectTeacher,
                  ),
                  const SizedBox(height: AppSpacing.stackMd),
                  PrimaryButton(
                    label: 'New Class',
                    leadingIcon: Icons.add,
                    trailingIcon: null,
                    onPressed: controller.createClassFlow,
                  ),
                  const SizedBox(height: AppSpacing.stackLg),
                  TimetableGrid(data: data),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }
}
