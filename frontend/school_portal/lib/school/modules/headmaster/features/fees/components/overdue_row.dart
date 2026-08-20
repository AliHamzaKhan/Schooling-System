import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

import '../models/fees_data.dart';

/// One row in the Overdue Payments list: avatar, name + grade + days-overdue,
/// red amount, and a navy send-reminder button.
class OverdueRow extends StatelessWidget {
  final OverduePayment payment;
  final VoidCallback? onSend;

  const OverdueRow({super.key, required this.payment, this.onSend});

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      padding: const EdgeInsets.all(AppSpacing.stackMd),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: payment.accent.withValues(alpha: 0.18),
            backgroundImage:
                payment.avatarUrl != null ? NetworkImage(payment.avatarUrl!) : null,
            child: payment.avatarUrl == null
                ? Text(
                    payment.studentName.characters.first,
                    style: AppTypography.titleLg.copyWith(color: payment.accent),
                  )
                : null,
          ),
          const SizedBox(width: AppSpacing.stackMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(payment.studentName,
                    style: AppTypography.titleMd.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(
                  '${payment.grade} • Overdue by ${payment.overdueDays} days',
                  style: AppTypography.bodySm,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.stackSm),
          Text(payment.amountLabel,
              style: AppTypography.titleLg
                  .copyWith(color: AppColors.error, fontWeight: FontWeight.w700)),
          const SizedBox(width: AppSpacing.stackSm),
          Material(
            color: AppColors.primary,
            shape: const CircleBorder(),
            child: InkWell(
              onTap: onSend,
              customBorder: const CircleBorder(),
              child: const SizedBox(
                width: 36,
                height: 36,
                child: Icon(AppIcons.sendRounded, color: AppColors.onPrimary, size: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
