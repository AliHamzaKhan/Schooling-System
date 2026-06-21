import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

import '../models/overview_data.dart';

/// Big identity card at the top of School Overview — graduation cap badge,
/// school name, address row, principal row, and an Edit Profile CTA.
class SchoolIdentityCard extends StatelessWidget {
  final SchoolIdentity school;
  final VoidCallback? onEdit;
  const SchoolIdentityCard({super.key, required this.school, this.onEdit});

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      padding: const EdgeInsets.all(AppSpacing.stackLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(AppRadius.button),
                ),
                child: const Icon(Icons.school_outlined,
                    color: AppColors.onSurfaceVariant, size: 32),
              ),
              const SizedBox(width: AppSpacing.stackMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(school.name,
                        style: AppTypography.displayLg
                            .copyWith(fontSize: 28, color: AppColors.primary)),
                    const SizedBox(height: AppSpacing.stackSm),
                    _MetaRow(icon: Icons.location_on_outlined, text: school.address),
                    const SizedBox(height: 4),
                    _MetaRow(
                        icon: Icons.person_outline,
                        text: 'Principal: ${school.principal}'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.stackLg),
          PrimaryButton(
            label: 'Edit Profile',
            leadingIcon: Icons.edit_outlined,
            trailingIcon: null,
            onPressed: onEdit,
          ),
        ],
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _MetaRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.onSurfaceVariant),
        const SizedBox(width: 6),
        Expanded(child: Text(text, style: AppTypography.bodyMd)),
      ],
    );
  }
}
