import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared/shared.dart';
import '../admin_theme.dart';

/// A styled confirmation dialog for important admin actions (activating a
/// school, changing a subscription, deactivating, …). Presents an icon badge,
/// a title and message, optional summary [details], and a Cancel / confirm
/// pair. Returns `true` only when the user taps confirm.
Future<bool> showAdminConfirm({
  required IconData icon,
  required String title,
  required String message,
  String confirmLabel = 'Confirm',
  String cancelLabel = 'Cancel',
  Color accent = AdminPalette.ink,
  bool destructive = false,
  List<Widget> details = const [],
}) async {
  final result = await showAppDialog<bool>(
    child: _AdminConfirmDialog(
      icon: icon,
      title: title,
      message: message,
      confirmLabel: confirmLabel,
      cancelLabel: cancelLabel,
      accent: accent,
      destructive: destructive,
      details: details,
    ),
  );
  return result == true;
}

/// A framed key/value row for the [showAdminConfirm] `details` slot.
class AdminConfirmDetail extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool emphasize;
  const AdminConfirmDetail({
    super.key,
    required this.label,
    required this.value,
    this.valueColor,
    this.emphasize = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: AdminType.body
                  .copyWith(color: AdminPalette.muted)),
          const Spacer(),
          const SizedBox(width: AppSpacing.stackMd),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: (emphasize ? AdminType.rowTitle : AdminType.body)
                  .copyWith(
                color: valueColor ?? AdminPalette.ink,
                fontWeight: emphasize ? FontWeight.w700 : FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminConfirmDialog extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final Color accent;
  final bool destructive;
  final List<Widget> details;

  const _AdminConfirmDialog({
    required this.icon,
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.cancelLabel,
    required this.accent,
    required this.destructive,
    required this.details,
  });

  @override
  Widget build(BuildContext context) {
    final accentColor = destructive ? AdminPalette.danger : accent;
    return Dialog(
      backgroundColor: AdminPalette.canvas,
      insetPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.containerPaddingMobile, vertical: 24),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.stackLg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppRadius.button),
                    ),
                    child: Icon(icon, color: accentColor, size: 24),
                  ),
                  const SizedBox(width: AppSpacing.stackMd),
                  Expanded(
                    child: Text(title,
                        style: AdminType.cardTitle
                            .copyWith(fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.stackMd),
              Text(message,
                  style: AdminType.body
                      .copyWith(color: AdminPalette.muted)),
              if (details.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.stackMd),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.stackMd, vertical: 6),
                  decoration: BoxDecoration(
                    color: AdminPalette.tint,
                    borderRadius: BorderRadius.circular(AppRadius.button),
                    border: Border.all(color: AdminPalette.border),
                  ),
                  child: Column(children: details),
                ),
              ],
              const SizedBox(height: AppSpacing.stackLg),
              Row(
                children: [
                  Expanded(
                    child: GhostButton(
                      label: cancelLabel,
                      expanded: true,
                      onPressed: () => Get.back<bool>(result: false),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.stackMd),
                  Expanded(
                    child: _ConfirmButton(
                      label: confirmLabel,
                      color: accentColor,
                      onPressed: () => Get.back<bool>(result: true),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Filled confirm button that honours an arbitrary [color] (PrimaryButton is
/// locked to the primary gradient, so we need a colour-flexible variant).
class _ConfirmButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onPressed;
  const _ConfirmButton(
      {required this.label, required this.color, required this.onPressed});

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
          child: Text(label,
              style: AdminType.rowTitle.copyWith(
                  color: Colors.white, fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }
}
