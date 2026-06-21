import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

import '../models/dashboard_data.dart';

/// One row in the Pending Approvals list: icon, title + requester, then two
/// soft-tinted circular buttons (reject red / approve green).
class PendingApprovalRow extends StatelessWidget {
  final PendingApproval approval;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const PendingApprovalRow({
    super.key,
    required this.approval,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.stackMd),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.button),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(AppRadius.button),
            ),
            child: Icon(approval.icon, color: AppColors.onSurfaceVariant, size: 22),
          ),
          const SizedBox(width: AppSpacing.stackMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(approval.title,
                    style: AppTypography.titleMd
                        .copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(approval.requestedBy, style: AppTypography.bodySm),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.stackSm),
          _ActionDot(
            color: AppColors.error,
            icon: Icons.close_rounded,
            onTap: onReject,
          ),
          const SizedBox(width: 6),
          _ActionDot(
            color: AppColors.tertiary,
            icon: Icons.check_rounded,
            onTap: onApprove,
          ),
        ],
      ),
    );
  }
}

class _ActionDot extends StatelessWidget {
  final Color color;
  final IconData icon;
  final VoidCallback onTap;
  const _ActionDot({required this.color, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.14),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 32,
          height: 32,
          child: Icon(icon, color: color, size: 18),
        ),
      ),
    );
  }
}
