import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../anim/app_motion.dart';
import '../tokens/app_colors.dart';
import '../tokens/app_radius.dart';
import '../tokens/app_spacing.dart';
import '../tokens/app_typography.dart';
import 'ghost_button.dart';

/// Animated dialogs for the whole app.
///
/// Every dialog enters with a spring scale-up + fade (via [showAppDialog]) so
/// confirmations — log out, delete, submit, etc. — feel alive instead of
/// snapping in. Use the high-level helpers:
///
/// * [showAppConfirm] — a two-button confirm (Cancel / confirm) returning a
///   `Future<bool>` that is `true` only when confirmed.
/// * [showAppAlert] — a single-button acknowledgement.
/// * [showAppDialog] — the low-level animated presenter for a custom child.

/// Presents [child] centered, over a dimmed scrim, with the shared spring
/// entrance (scale 0.92 → 1.0 with a slight overshoot, plus a fade). Reverses
/// on dismiss. Returns whatever the child pops via `Get.back<T>(result: …)`.
Future<T?> showAppDialog<T>({
  required Widget child,
  bool barrierDismissible = true,
}) {
  return Get.generalDialog<T>(
    barrierDismissible: barrierDismissible,
    barrierLabel: 'Dismiss',
    barrierColor: Colors.black.withValues(alpha: 0.45),
    transitionDuration: AppMotion.normal,
    pageBuilder: (_, _, _) => child,
    transitionBuilder: (context, animation, _, dialog) {
      if (MediaQuery.disableAnimationsOf(context)) return dialog;
      final scale = Tween<double>(begin: 0.92, end: 1).animate(
        CurvedAnimation(
          parent: animation,
          curve: AppMotion.emphasized, // easeOutBack — the gentle overshoot
          reverseCurve: Curves.easeInCubic,
        ),
      );
      return FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
        child: ScaleTransition(scale: scale, child: dialog),
      );
    },
  );
}

/// A styled confirmation dialog for important actions (log out, delete, submit,
/// …). Shows an icon badge, title + message, optional [details], and a
/// Cancel / confirm pair. Resolves to `true` only when confirm is tapped.
Future<bool> showAppConfirm({
  required IconData icon,
  required String title,
  required String message,
  String confirmLabel = 'Confirm',
  String cancelLabel = 'Cancel',
  Color accent = AppColors.primary,
  bool destructive = false,
  List<Widget> details = const [],
}) async {
  final result = await showAppDialog<bool>(
    child: _AppDialogCard(
      icon: icon,
      title: title,
      message: message,
      accent: destructive ? AppColors.error : accent,
      details: details,
      actions: [
        Expanded(
          child: GhostButton(
            label: cancelLabel,
            expanded: true,
            onPressed: () => Get.back<bool>(result: false),
          ),
        ),
        const SizedBox(width: AppSpacing.stackMd),
        Expanded(
          child: _FilledAction(
            label: confirmLabel,
            color: destructive ? AppColors.error : accent,
            onPressed: () => Get.back<bool>(result: true),
          ),
        ),
      ],
    ),
  );
  return result == true;
}

/// A single-button acknowledgement dialog. Resolves when dismissed.
Future<void> showAppAlert({
  required IconData icon,
  required String title,
  required String message,
  String buttonLabel = 'Got it',
  Color accent = AppColors.primary,
}) {
  return showAppDialog<void>(
    child: _AppDialogCard(
      icon: icon,
      title: title,
      message: message,
      accent: accent,
      actions: [
        Expanded(
          child: _FilledAction(
            label: buttonLabel,
            color: accent,
            onPressed: () => Get.back<void>(),
          ),
        ),
      ],
    ),
  );
}

/// The framed dialog body shared by [showAppConfirm] / [showAppAlert].
class _AppDialogCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final Color accent;
  final List<Widget> details;
  final List<Widget> actions;

  const _AppDialogCard({
    required this.icon,
    required this.title,
    required this.message,
    required this.accent,
    required this.actions,
    this.details = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      insetPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.containerPaddingMobile,
        vertical: 24,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
        side: const BorderSide(color: AppColors.cardBorder),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.stackLg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _PoppingBadge(icon: icon, accent: accent),
              const SizedBox(height: AppSpacing.stackMd),
              Text(
                title,
                style: AppTypography.titleLg.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                message,
                style: AppTypography.bodyMd.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              if (details.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.stackMd),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.stackMd,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(AppRadius.button),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Column(children: details),
                ),
              ],
              const SizedBox(height: AppSpacing.stackLg),
              Row(children: actions),
            ],
          ),
        ),
      ),
    );
  }
}

/// The accent icon badge, which pops in (scale + fade) just after the dialog
/// settles — the small flourish that sells the animation.
class _PoppingBadge extends StatelessWidget {
  final IconData icon;
  final Color accent;
  const _PoppingBadge({required this.icon, required this.accent});

  @override
  Widget build(BuildContext context) {
    final badge = Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.button),
      ),
      child: Icon(icon, color: accent, size: 26),
    );
    if (MediaQuery.disableAnimationsOf(context)) return badge;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: AppMotion.slow,
      curve: AppMotion.emphasized,
      builder: (context, t, child) => Transform.scale(
        scale: 0.6 + 0.4 * t,
        child: Opacity(opacity: t.clamp(0, 1), child: child),
      ),
      child: badge,
    );
  }
}

/// A filled action button that honours an arbitrary [color] (PrimaryButton is
/// locked to the primary gradient, so confirms that must go red need this).
class _FilledAction extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onPressed;
  const _FilledAction({
    required this.label,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(AppRadius.button),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppRadius.button),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          alignment: Alignment.center,
          child: Text(
            label,
            style: AppTypography.labelMd.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
