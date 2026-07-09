import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared/shared.dart';

import '../components/overdue_row.dart';
import '../controller/fees_controller.dart';
import '../models/fees_data.dart';

/// Full "Overdue Payments" list, reached from Fee Management's View All. The
/// list is passed in via [Get.arguments]; the send-reminder action reuses the
/// shell's [FeesController].
class OverduePaymentsView extends StatelessWidget {
  const OverduePaymentsView({super.key});

  List<OverduePayment> get _overdue {
    final arg = Get.arguments;
    return arg is List<OverduePayment> ? arg : const [];
  }

  @override
  Widget build(BuildContext context) {
    final overdue = _overdue;
    final controller = Get.find<FeesController>();
    return AppScaffold(
      appBar: AppBar(
        title: const Text('Overdue Payments'),
        actions: [
          if (overdue.isNotEmpty)
            TextButton(
              onPressed: controller.remindAll,
              child: Text('Remind All',
                  style: AppTypography.labelMd
                      .copyWith(color: AppColors.primary)),
            ),
        ],
      ),
      body: overdue.isEmpty
          ? Center(
              child: Text('No overdue payments. Nicely done!',
                  style: AppTypography.bodyLg),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.containerPaddingMobile,
                  AppSpacing.stackMd,
                  AppSpacing.containerPaddingMobile,
                  AppSpacing.stackXl),
              itemCount: overdue.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(height: AppSpacing.stackMd),
              itemBuilder: (context, i) => OverdueRow(
                payment: overdue[i],
                onSend: () => controller.remind(overdue[i]),
              ),
            ),
    );
  }
}
