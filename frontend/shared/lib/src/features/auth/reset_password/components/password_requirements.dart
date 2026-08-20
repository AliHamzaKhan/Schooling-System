import 'package:flutter/material.dart';

import '../../../../ui/tokens/app_colors.dart';
import '../../../../ui/tokens/app_radius.dart';
import '../../../../ui/tokens/app_spacing.dart';
import '../../../../ui/tokens/app_typography.dart';
import '../../models/password_strength.dart';
import 'package:shared/shared.dart';

/// "Password must include:" checklist that ticks each rule live.
class PasswordRequirements extends StatelessWidget {
  final String password;

  const PasswordRequirements({super.key, required this.password});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.stackMd),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.defaultR),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Password must include:', style: AppTypography.labelMd),
          const SizedBox(height: AppSpacing.stackSm),
          for (final rule in kPasswordRules) _RuleRow(rule: rule, password: password),
        ],
      ),
    );
  }
}

class _RuleRow extends StatelessWidget {
  final PasswordRule rule;
  final String password;
  const _RuleRow({required this.rule, required this.password});

  @override
  Widget build(BuildContext context) {
    final ok = rule.test(password);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            ok ? AppIcons.checkCircle : AppIcons.checkCircleOutline,
            size: 18,
            color: ok ? AppColors.tertiary : AppColors.outline,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(rule.label,
                style: AppTypography.bodyMd.copyWith(
                  color: ok ? AppColors.onSurface : AppColors.onSurfaceVariant,
                )),
          ),
        ],
      ),
    );
  }
}
