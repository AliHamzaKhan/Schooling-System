import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared/shared.dart';

import '../components/pending_approval_row.dart';
import '../controller/approvals_controller.dart';

/// Full pending-approvals list. Its route-local controller reloads the list so
/// the page works on direct entry instead of depending on dashboard memory.
class ApprovalsView extends GetView<ApprovalsController> {
  const ApprovalsView({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(title: const Text('Pending Approvals')),
      body: Obx(() {
        if (controller.loading.value) {
          return const AppStateView.loading(
            title: 'Loading approvals',
            message: 'Checking for the latest requests awaiting review.',
          );
        }
        if (controller.error.value != null) {
          return AppStateView.error(
            title: 'Could not load pending approvals',
            message: controller.error.value!,
            actionLabel: 'Try again',
            onAction: controller.load,
          );
        }
        final approvals = controller.approvals;
        if (approvals.isEmpty) {
          return const AppStateView.empty(
            title: 'Nothing awaiting approval',
            message: 'New approval requests will appear here.',
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.containerPaddingMobile,
            AppSpacing.stackMd,
            AppSpacing.containerPaddingMobile,
            AppSpacing.stackXl,
          ),
          itemCount: approvals.length,
          separatorBuilder: (_, _) =>
              const SizedBox(height: AppSpacing.stackSm),
          itemBuilder: (context, i) => PendingApprovalRow(
            approval: approvals[i],
            onApprove: () => controller.approve(approvals[i].id),
            onReject: () => controller.reject(approvals[i].id),
          ),
        );
      }),
    );
  }
}
