import 'package:flutter/material.dart';

import '../../../ui/tokens/app_colors.dart';

/// Password rule + live pass/fail used by the reset-password requirements list.
class PasswordRule {
  final String label;
  final bool Function(String) test;
  const PasswordRule(this.label, this.test);
}

/// The rules shown on the "Create New Password" screen, mirroring the mockup.
const kPasswordRules = <PasswordRule>[
  PasswordRule('At least 8 characters', _minLength),
  PasswordRule('One special character (@#\$%...)', _hasSpecial),
  PasswordRule('One numeric digit', _hasDigit),
];

bool _minLength(String v) => v.length >= 8;
bool _hasSpecial(String v) => RegExp(r'[!@#$%^&*(),.?":{}|<>_\-\[\]/\\;+=~`]').hasMatch(v);
bool _hasDigit(String v) => RegExp(r'\d').hasMatch(v);

/// 0–4 strength score derived from the rule set + length bonus, with a label
/// and color for the 4-segment strength bar.
class PasswordStrength {
  final int score; // 0..4
  final String label;
  final Color color;

  const PasswordStrength(this.score, this.label, this.color);

  static PasswordStrength of(String v) {
    if (v.isEmpty) return const PasswordStrength(0, '', AppColors.outlineVariant);
    var passed = kPasswordRules.where((r) => r.test(v)).length;
    if (v.length >= 12) passed = (passed + 1).clamp(0, 4);
    switch (passed) {
      case 0:
      case 1:
        return const PasswordStrength(1, 'Weak', AppColors.error);
      case 2:
        return const PasswordStrength(2, 'Fair', Color(0xFFE0A100));
      case 3:
        return const PasswordStrength(3, 'Good', Color(0xFF2A9D2A));
      default:
        return const PasswordStrength(4, 'Strong', AppColors.tertiary);
    }
  }
}

/// True when every [kPasswordRules] rule passes for [v].
bool passwordMeetsAllRules(String v) => kPasswordRules.every((r) => r.test(v));

