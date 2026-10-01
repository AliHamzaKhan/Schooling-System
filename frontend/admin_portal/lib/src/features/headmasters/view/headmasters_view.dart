import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared/shared.dart';

import '../../../app/admin_routes.dart';
import '../../../ui/admin_widgets/admin_confirm_dialog.dart';
import '../../../ui/admin_widgets/admin_page_header.dart';
import '../../../ui/admin_widgets/admin_search_field.dart';
import '../../../ui/admin_widgets/admin_text_field.dart';
import '../../../ui/admin_widgets/filter_chips.dart';
import '../components/headmaster_card.dart';
import '../controller/headmasters_controller.dart';
import '../models/headmaster.dart';
import '../../../ui/admin_theme.dart';
import '../../../ui/admin_widgets/admin_surface.dart';

/// Confirms then soft-deletes (deactivates) a headmaster.
Future<void> _confirmDeleteHeadmaster(Headmaster h) async {
  final ok = await showAdminConfirm(
    icon: AppIcons.blockRounded,
    title: 'Deactivate headmaster?',
    message:
        '${h.name} will be deactivated and lose access. You can reactivate them later.',
    confirmLabel: 'Deactivate',
    destructive: true,
    details: [
      AdminConfirmDetail(label: 'Name', value: h.name),
      if (h.email.isNotEmpty) AdminConfirmDetail(label: 'Email', value: h.email),
    ],
  );
  if (!ok) return;
  final removed = await Get.find<HeadmastersController>().deleteHeadmaster(h);
  if (removed) {
    Get.snackbar('Deactivated', '${h.name} was deactivated.',
        snackPosition: SnackPosition.BOTTOM);
  }
}

/// Headmaster Management — manage school leadership and administrative access.
class HeadmastersView extends GetView<HeadmastersController> {
  const HeadmastersView({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      safeArea: false,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Get.toNamed<void>(AdminRoutes.createHeadmaster),
        backgroundColor: AdminPalette.ink,
        foregroundColor: Colors.white,
        icon: const Icon(AppIcons.add),
        label: const Text('New Headmaster'),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  const AdminScreenHeader(title: 'Headmasters'),
                  const SizedBox(height: AppSpacing.stackMd),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.containerPaddingMobile),
                    child: AdminCard(
                      padding: const EdgeInsets.all(AppSpacing.stackMd),
                      child: Column(
                        children: [
                          AdminSearchField(
                            hint: 'Search by name, email, or school',
                            onChanged: controller.onSearch,
                          ),
                          const SizedBox(height: AppSpacing.stackMd),
                          Obx(() => FilterChips(
                                options: HeadmastersController.filters,
                                selectedIndex: controller.filterIndex.value,
                                onSelected: controller.selectFilter,
                              )),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.stackLg),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.containerPaddingMobile),
                    child: _list(),
                  ),
                  // Extra bottom gap so the floating "New Headmaster" button
                  // never covers the pager / last card.
                  const SizedBox(height: 96),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _list() {
    return Obx(() {
      if (controller.loading.value) {
        return const Padding(
          padding: EdgeInsets.all(AppSpacing.stackXl),
          child: Center(child: CircularProgressIndicator()),
        );
      }
      final items = controller.pageItems;
      if (items.isEmpty) {
        return Padding(
          padding: const EdgeInsets.all(AppSpacing.stackXl),
          child: Center(
            child: Text('No headmasters match your filters.',
                style: AdminType.body),
          ),
        );
      }
      return Column(
        children: [
          for (final h in items) ...[
            HeadmasterCard(
              headmaster: h,
              onEdit: () => Get.dialog<void>(_EditHeadmasterDialog(headmaster: h)),
              onDelete: () => _confirmDeleteHeadmaster(h),
            ),
            const SizedBox(height: AppSpacing.stackLg),
          ],
          const SizedBox(height: AppSpacing.stackSm),
          _Pager(
            page: controller.page.value,
            total: controller.totalPages,
            onPrev: controller.prevPage,
            onNext: controller.nextPage,
          ),
        ],
      );
    });
  }
}



class _Pager extends StatelessWidget {
  final int page;
  final int total;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  const _Pager({
    required this.page,
    required this.total,
    required this.onPrev,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          tooltip: 'Previous',
          onPressed: page > 1 ? onPrev : null,
          icon: const Icon(AppIcons.chevronLeftRounded),
        ),
        Text('Page $page of $total', style: AdminType.label),
        IconButton(
          tooltip: 'Next',
          onPressed: page < total ? onNext : null,
          icon: const Icon(AppIcons.chevronRightRounded),
        ),
      ],
    );
  }
}

/// Edit a headmaster's name + phone (email/school aren't editable here).
class _EditHeadmasterDialog extends StatefulWidget {
  final Headmaster headmaster;
  const _EditHeadmasterDialog({required this.headmaster});

  @override
  State<_EditHeadmasterDialog> createState() => _EditHeadmasterDialogState();
}

class _EditHeadmasterDialogState extends State<_EditHeadmasterDialog> {
  final _controller = Get.find<HeadmastersController>();
  late final _name = TextEditingController(text: widget.headmaster.name);
  late final _phone = TextEditingController(text: widget.headmaster.phone ?? '');

  @override
  void initState() {
    super.initState();
    _controller.submitError.value = null;
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_name.text.trim().length < 2) {
      _controller.submitError.value = 'Enter a valid name.';
      return;
    }
    final ok = await _controller.updateHeadmaster(
      headmaster: widget.headmaster,
      fullName: _name.text.trim(),
      phone: _phone.text.trim(),
    );
    if (ok) {
      Get.back<void>();
      Get.snackbar('Saved', 'Headmaster updated.', snackPosition: SnackPosition.BOTTOM);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _HeadmasterDialogShell(
      icon: AppIcons.editRounded,
      title: 'Edit Headmaster',
      subtitle: widget.headmaster.email.isNotEmpty
          ? widget.headmaster.email
          : 'Update name and contact details.',
      submitLabel: 'Save',
      submittingLabel: 'Saving…',
      onSubmit: _submit,
      fields: [
        AdminTextField(
          label: 'Full name',
          hint: 'Jane Doe',
          controller: _name,
          required: true,
        ),
        const SizedBox(height: AppSpacing.stackMd),
        AdminTextField(
          label: 'Phone (optional)',
          hint: '+1 (555) 123-4567',
          controller: _phone,
          keyboardType: TextInputType.phone,
        ),
      ],
    );
  }
}

/// Shared visual scaffold for the New / Edit headmaster dialogs: an icon-badged
/// header, a scrollable field list, a reactive error banner, and a Cancel /
/// submit action row. Field content is provided by the caller via [fields].
class _HeadmasterDialogShell extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final List<Widget> fields;
  final String submitLabel;
  final String submittingLabel;
  final VoidCallback onSubmit;

  const _HeadmasterDialogShell({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.fields,
    required this.submitLabel,
    required this.submittingLabel,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<HeadmastersController>();
    return Dialog(
      backgroundColor: AdminPalette.canvas,
      insetPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.containerPaddingMobile, vertical: 24),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
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
                      color: AdminPalette.ink.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppRadius.button),
                    ),
                    child: Icon(icon, color: AdminPalette.ink, size: 24),
                  ),
                  const SizedBox(width: AppSpacing.stackMd),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title,
                            style: AdminType.cardTitle
                                .copyWith(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 2),
                        Text(subtitle,
                            style: AdminType.meta.copyWith(
                                color: AdminPalette.muted),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.stackLg),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: fields,
                  ),
                ),
              ),
              Obx(() {
                final err = controller.submitError.value;
                if (err == null) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.stackMd),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.stackMd, vertical: 10),
                    decoration: BoxDecoration(
                      color: AdminPalette.dangerSoft,
                      borderRadius: BorderRadius.circular(AppRadius.button),
                    ),
                    child: Row(
                      children: [
                        const Icon(AppIcons.errorOutlineRounded,
                            color: AdminPalette.danger, size: 18),
                        const SizedBox(width: AppSpacing.stackSm),
                        Expanded(
                          child: Text(err,
                              style: AdminType.body.copyWith(
                                  color: AdminPalette.danger)),
                        ),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: AppSpacing.stackLg),
              Row(
                children: [
                  Expanded(
                    child: GhostButton(
                      label: 'Cancel',
                      expanded: true,
                      onPressed: () => Get.back<void>(),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.stackMd),
                  Expanded(
                    child: Obx(() => PrimaryButton(
                          label: controller.submitting.value
                              ? submittingLabel
                              : submitLabel,
                          expanded: true,
                          trailingIcon: null,
                          isLoading: controller.submitting.value,
                          onPressed:
                              controller.submitting.value ? null : onSubmit,
                        )),
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

