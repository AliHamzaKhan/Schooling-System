import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared/shared.dart';

import '../../../../../widgets/entity_detail_sheet.dart';
import '../../../../../widgets/portal_search_field.dart';
import '../../../../../widgets/portal_top_bar.dart';
import '../components/guardian_card.dart';
import '../controller/guardians_controller.dart';
import '../models/guardian.dart';

/// Guardian Management — searchable list of guardians with linked students.
class GuardiansView extends GetView<GuardiansController> {
  const GuardiansView({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PortalTopBar(),
          Expanded(
            child: Obx(() {
              if (controller.loading.value) {
                return const Center(child: CircularProgressIndicator());
              }
              return ListView(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.containerPaddingMobile,
                    0,
                    AppSpacing.containerPaddingMobile,
                    AppSpacing.stackXl),
                children: [
                  Text('Guardian\nManagement',
                      style: AppTypography.headlineLg.copyWith(color: AppColors.primary)),
                  const SizedBox(height: AppSpacing.stackSm),
                  Text('Oversee and connect with student families.',
                      style: AppTypography.bodyLg),
                  const SizedBox(height: AppSpacing.stackMd),
                  Row(
                    children: [
                      Expanded(
                        child: PortalSearchField(
                          hint: 'Search guardians…',
                          onChanged: controller.onSearch,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.stackMd),
                      PrimaryButton(
                        label: 'Add Guardian',
                        leadingIcon: Icons.add,
                        trailingIcon: null,
                        onPressed: controller.addGuardianFlow,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.stackMd),
                  _AllGuardiansChip(count: controller.total),
                  const SizedBox(height: AppSpacing.stackLg),
                  if (controller.results.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.stackXl),
                      child: Center(
                        child: Text('No guardians match your search.',
                            style: AppTypography.bodyLg),
                      ),
                    )
                  else
                    for (final g in controller.results) ...[
                      GuardianCard(
                        guardian: g,
                        onView: () => _showGuardian(context, g),
                        onInvite: () => controller.invite(g.id),
                        onMenu: () => _showGuardian(context, g),
                      ),
                      const SizedBox(height: AppSpacing.stackLg),
                    ],
                ],
              );
            }),
          ),
        ],
      ),
    );
  }
}

void _showGuardian(BuildContext context, Guardian g) {
  showEntityDetailSheet(
    context,
    title: g.name,
    subtitle: g.email,
    initials: g.initials,
    statusLabel: g.status.label,
    statusColor: g.status.color,
    fields: [
      DetailField(Icons.email_outlined, 'Email', g.email),
      if (g.phone != null) DetailField(Icons.phone_outlined, 'Phone', g.phone!),
    ],
    chipsLabel: g.linkedStudents.isEmpty ? null : 'LINKED STUDENTS',
    chips: [for (final s in g.linkedStudents) s.label],
  );
}

class _AllGuardiansChip extends StatelessWidget {
  final int count;
  const _AllGuardiansChip({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: AppColors.outlineVariant, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.groups_outlined, size: 16, color: AppColors.primary),
          const SizedBox(width: 6),
          Text('All Guardians ($count)',
              style: AppTypography.labelMd
                  .copyWith(color: AppColors.primary, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
