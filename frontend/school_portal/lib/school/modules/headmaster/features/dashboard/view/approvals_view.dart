import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared/shared.dart';

import '../components/pending_approval_row.dart';
import '../controller/dashboard_controller.dart';
import '../models/dashboard_data.dart';

/// Full "Pending Approvals" list, reached from the dashboard's View All. The
/// list is passed in via [Get.arguments]; approve/reject reuse the shell's
/// [HeadmasterDashboardController].
class ApprovalsView extends StatelessWidget {
  const ApprovalsView({super.key});

  List<PendingApproval> get _approvals {
    final arg = Get.arguments;
    return arg is List<PendingApproval> ? arg : const [];
  }

  @override
  Widget build(BuildContext context) {
    final approvals = _approvals;
    final controller = Get.find<HeadmasterDashboardController>();
    return AppScaffold(
      appBar: AppBar(title: const Text('Pending Approvals')),
      body: approvals.isEmpty
          ? Center(
              child: Text('Nothing awaiting approval.',
                  style: AppTypography.bodyLg),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.containerPaddingMobile,
                  AppSpacing.stackMd,
                  AppSpacing.containerPaddingMobile,
                  AppSpacing.stackXl),
              itemCount: approvals.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(height: AppSpacing.stackSm),
              itemBuilder: (context, i) => PendingApprovalRow(
                approval: approvals[i],
                onApprove: () => controller.approve(approvals[i].id),
                onReject: () => controller.reject(approvals[i].id),
              ),
            ),
    );
  }
}
