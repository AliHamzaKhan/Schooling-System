import 'package:flutter/material.dart';

import '../tokens/app_colors.dart';
import '../tokens/app_spacing.dart';
import '../tokens/app_typography.dart';
import 'ghost_button.dart';
import 'primary_button.dart';

enum AppStateKind { empty, error, loading }

/// Consistent empty, error, and loading feedback for full-page or panel use.
class AppStateView extends StatelessWidget {
  final AppStateKind kind;
  final String title;
  final String message;
  final IconData? icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  const AppStateView({
    super.key,
    required this.kind,
    required this.title,
    required this.message,
    this.icon,
    this.actionLabel,
    this.onAction,
  }) : assert(
         (actionLabel == null) == (onAction == null),
         'actionLabel and onAction must be supplied together.',
       );

  const AppStateView.empty({
    super.key,
    required this.title,
    required this.message,
    this.icon,
    this.actionLabel,
    this.onAction,
  }) : kind = AppStateKind.empty,
       assert((actionLabel == null) == (onAction == null));

  const AppStateView.error({
    super.key,
    required this.title,
    required this.message,
    this.icon,
    this.actionLabel,
    this.onAction,
  }) : kind = AppStateKind.error,
       assert((actionLabel == null) == (onAction == null));

  const AppStateView.loading({
    super.key,
    this.title = 'Loading',
    this.message = 'Please wait while the latest information is loaded.',
  }) : kind = AppStateKind.loading,
       icon = null,
       actionLabel = null,
       onAction = null;

  @override
  Widget build(BuildContext context) {
    final isError = kind == AppStateKind.error;
    final isLoading = kind == AppStateKind.loading;
    final accent = isError ? AppColors.error : AppColors.primary;

    return Semantics(
      container: true,
      explicitChildNodes: true,
      liveRegion: isError || isLoading,
      label: '$title. $message',
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.stackLg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ExcludeSemantics(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isLoading)
                        const SizedBox.square(
                          dimension: 36,
                          child: CircularProgressIndicator(strokeWidth: 3),
                        )
                      else
                        Icon(
                          icon ??
                              (isError
                                  ? Icons.error_outline_rounded
                                  : Icons.inbox_outlined),
                          color: accent,
                          size: 44,
                        ),
                      const SizedBox(height: AppSpacing.stackMd),
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style: AppTypography.titleLg,
                      ),
                      const SizedBox(height: AppSpacing.stackSm),
                      Text(
                        message,
                        textAlign: TextAlign.center,
                        style: AppTypography.bodyMd,
                      ),
                    ],
                  ),
                ),
                if (actionLabel != null) ...[
                  const SizedBox(height: AppSpacing.stackLg),
                  if (isError)
                    PrimaryButton(
                      label: actionLabel!,
                      onPressed: onAction,
                      trailingIcon: null,
                    )
                  else
                    GhostButton(label: actionLabel!, onPressed: onAction),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
