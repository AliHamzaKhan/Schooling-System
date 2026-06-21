import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

import '../../../ui/admin_widgets/status_pill.dart';
import '../models/feature_models.dart';

/// Glass card for one feature module: coloured left rail, titled header, then
/// a divided list of enable/disable switch rows.
class FeatureModuleCard extends StatelessWidget {
  final FeatureModule module;
  final void Function(String key, bool value) onToggle;

  const FeatureModuleCard(
      {super.key, required this.module, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      padding: EdgeInsets.zero,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 5,
              decoration: BoxDecoration(
                color: module.color,
                borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(AppRadius.card)),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.stackLg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(module.icon, color: module.color, size: 22),
                        const SizedBox(width: AppSpacing.stackSm),
                        Text(module.title,
                            style: AppTypography.titleMd
                                .copyWith(fontWeight: FontWeight.w700)),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.stackMd),
                    for (var i = 0; i < module.features.length; i++) ...[
                      _FeatureRow(
                        feature: module.features[i],
                        onChanged: (v) =>
                            onToggle(module.features[i].key, v),
                      ),
                      if (i != module.features.length - 1)
                        const Divider(
                            height: AppSpacing.stackLg,
                            color: AppColors.outlineVariant),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final FeatureFlag feature;
  final ValueChanged<bool> onChanged;
  const _FeatureRow({required this.feature, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(feature.name,
                        style: AppTypography.titleMd
                            .copyWith(fontWeight: FontWeight.w600)),
                  ),
                  if (feature.beta) ...[
                    const SizedBox(width: AppSpacing.stackSm),
                    const StatusPill(label: 'Beta', color: AppColors.aiAccent),
                  ],
                ],
              ),
              const SizedBox(height: 2),
              Text(feature.description, style: AppTypography.bodyMd),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.stackMd),
        Switch(
          value: feature.enabled,
          onChanged: onChanged,
          activeThumbColor: AppColors.onPrimary,
          activeTrackColor: const Color(0xFF3B82F6),
          inactiveThumbColor: AppColors.onSurfaceVariant,
          inactiveTrackColor: AppColors.surfaceContainerHighest,
        ),
      ],
    );
  }
}
