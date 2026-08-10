import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared/shared.dart';

import '../../../ui/admin_widgets/admin_confirm_dialog.dart';
import '../../../ui/admin_widgets/admin_search_field.dart';
import '../../../ui/admin_widgets/admin_text_field.dart';
import '../../../ui/admin_widgets/filter_chips.dart';
import '../components/headmaster_card.dart';
import '../controller/headmasters_controller.dart';
import '../models/headmaster.dart';

/// Confirms then soft-deletes (deactivates) a headmaster.
Future<void> _confirmDeleteHeadmaster(Headmaster h) async {
  final ok = await showAdminConfirm(
    icon: Icons.block_rounded,
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
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _Header(),
                  const SizedBox(height: AppSpacing.stackMd),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.containerPaddingMobile),
                    child: GlassSurface(
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
                  const SizedBox(height: AppSpacing.stackXl),
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
                style: AppTypography.bodyLg),
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

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.containerPaddingMobile,
        AppSpacing.stackSm,
        AppSpacing.containerPaddingMobile,
        AppSpacing.stackLg,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFCEAD6), Color(0xFFF3DCE6), Color(0xFFD9CDEF)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Get.back<void>(),
                child: const CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.primaryContainer,
                  child: Icon(Icons.person, color: AppColors.onPrimary, size: 20),
                ),
              ),
              const SizedBox(width: AppSpacing.stackSm),
              Text('EduMaster Admin',
                  style: AppTypography.titleLg.copyWith(
                      color: AppColors.primary, fontWeight: FontWeight.w700)),
              const Spacer(),
              const Icon(Icons.notifications_none_rounded, color: AppColors.onSurface),
            ],
          ),
          const SizedBox(height: AppSpacing.stackLg),
          Text('Headmasters',
              style: AppTypography.displayLg.copyWith(color: AppColors.primary, fontSize: 34)),
          const SizedBox(height: AppSpacing.stackSm),
          Text('Manage school leadership and administrative access.',
              style: AppTypography.bodyLg.copyWith(color: AppColors.onSurface)),
          const SizedBox(height: AppSpacing.stackLg),
          PrimaryButton(
            label: 'New Headmaster',
            leadingIcon: Icons.add,
            trailingIcon: null,
            onPressed: () => Get.dialog<void>(const _CreateHeadmasterDialog()),
          ),
        ],
      ),
    );
  }
}

/// Create-headmaster form: pick a school, enter the account details, and POST
/// to the backend via the controller. Refreshes the list on success.
class _CreateHeadmasterDialog extends StatefulWidget {
  const _CreateHeadmasterDialog();

  @override
  State<_CreateHeadmasterDialog> createState() => _CreateHeadmasterDialogState();
}

class _CreateHeadmasterDialogState extends State<_CreateHeadmasterDialog> {
  final _controller = Get.find<HeadmastersController>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _phone = TextEditingController();
  String? _schoolId;

  @override
  void initState() {
    super.initState();
    _controller.submitError.value = null;
    _controller.loadSchools();
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_schoolId == null ||
        _name.text.trim().isEmpty ||
        _email.text.trim().isEmpty ||
        _password.text.length < 8) {
      _controller.submitError.value =
          'Pick a school and fill name, email, and a password (8+ chars).';
      return;
    }
    final ok = await _controller.createHeadmaster(
      schoolId: _schoolId!,
      fullName: _name.text.trim(),
      email: _email.text.trim(),
      password: _password.text,
      phone: _phone.text.trim(),
    );
    if (ok) {
      Get.back<void>();
      Get.snackbar('Headmaster created', '${_name.text.trim()} was added.',
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _HeadmasterDialogShell(
      icon: Icons.person_add_alt_1_rounded,
      title: 'New Headmaster',
      subtitle: 'Provision a school administrator account.',
      submitLabel: 'Create',
      submittingLabel: 'Creating…',
      onSubmit: _submit,
      fields: [
        Obx(() {
          final loading = _controller.loadingSchools.value;
          final schools = _controller.schools;
          return _LabeledField(
            label: 'School',
            required: true,
            child: DropdownButtonFormField<String>(
              initialValue: _schoolId,
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down_rounded,
                  color: AppColors.onSurfaceVariant),
              hint: Text(loading ? 'Loading schools…' : 'Select a school',
                  style: AppTypography.bodyLg.copyWith(color: AppColors.outline)),
              style: AppTypography.bodyLg.copyWith(color: AppColors.onSurface),
              decoration: _fieldDecoration(),
              items: [
                for (final s in schools)
                  DropdownMenuItem(value: s.id, child: Text(s.name)),
              ],
              onChanged:
                  loading ? null : (v) => setState(() => _schoolId = v),
            ),
          );
        }),
        const SizedBox(height: AppSpacing.stackMd),
        AdminTextField(
          label: 'Full name',
          hint: 'Jane Doe',
          controller: _name,
          required: true,
        ),
        const SizedBox(height: AppSpacing.stackMd),
        AdminTextField(
          label: 'Email',
          hint: 'head@school.edu',
          controller: _email,
          required: true,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: AppSpacing.stackMd),
        _PasswordField(
          controller: _password,
          label: 'Password',
          hint: 'At least 8 characters',
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
          onPressed: page > 1 ? onPrev : null,
          icon: const Icon(Icons.chevron_left_rounded),
        ),
        Text('Page $page of $total', style: AppTypography.labelMd),
        IconButton(
          onPressed: page < total ? onNext : null,
          icon: const Icon(Icons.chevron_right_rounded),
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
      icon: Icons.edit_rounded,
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
      backgroundColor: AppColors.surface,
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
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppRadius.button),
                    ),
                    child: Icon(icon, color: AppColors.primary, size: 24),
                  ),
                  const SizedBox(width: AppSpacing.stackMd),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title,
                            style: AppTypography.titleLg
                                .copyWith(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 2),
                        Text(subtitle,
                            style: AppTypography.bodySm.copyWith(
                                color: AppColors.onSurfaceVariant),
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
                      color: AppColors.errorContainer,
                      borderRadius: BorderRadius.circular(AppRadius.button),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline_rounded,
                            color: AppColors.onErrorContainer, size: 18),
                        const SizedBox(width: AppSpacing.stackSm),
                        Expanded(
                          child: Text(err,
                              style: AppTypography.bodyMd.copyWith(
                                  color: AppColors.onErrorContainer)),
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

/// Persistent-label wrapper matching [AdminTextField]'s look, for arbitrary
/// field widgets (the school dropdown).
class _LabeledField extends StatelessWidget {
  final String label;
  final bool required;
  final Widget child;
  const _LabeledField(
      {required this.label, required this.child, this.required = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            text: label,
            style: AppTypography.labelMd.copyWith(color: AppColors.onSurface),
            children: [
              if (required)
                const TextSpan(
                    text: ' *', style: TextStyle(color: AppColors.error)),
            ],
          ),
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}

/// Obscured password field with a show/hide toggle, styled like
/// [AdminTextField].
class _PasswordField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final bool required;
  const _PasswordField({
    required this.controller,
    required this.label,
    required this.hint,
    this.required = false,
  });

  @override
  State<_PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<_PasswordField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return _LabeledField(
      label: widget.label,
      required: widget.required,
      child: TextField(
        controller: widget.controller,
        obscureText: _obscure,
        style: AppTypography.bodyLg.copyWith(color: AppColors.onSurface),
        decoration: _fieldDecoration(hint: widget.hint).copyWith(
          suffixIcon: IconButton(
            icon: Icon(
              _obscure
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              color: AppColors.onSurfaceVariant,
              size: 20,
            ),
            onPressed: () => setState(() => _obscure = !_obscure),
          ),
        ),
      ),
    );
  }
}

/// Shared input decoration matching [AdminTextField] for the bespoke fields
/// (dropdown, password) in the headmaster dialogs.
InputDecoration _fieldDecoration({String? hint}) {
  OutlineInputBorder border(Color color, {double width = 1}) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.button),
        borderSide: BorderSide(color: color, width: width),
      );
  return InputDecoration(
    hintText: hint,
    hintStyle: AppTypography.bodyLg.copyWith(color: AppColors.outline),
    filled: true,
    fillColor: AppColors.surfaceContainerLowest,
    isDense: true,
    contentPadding:
        const EdgeInsets.symmetric(horizontal: AppSpacing.stackMd, vertical: 14),
    enabledBorder: border(AppColors.outlineVariant),
    focusedBorder: border(AppColors.primary, width: 1.5),
    border: border(AppColors.outlineVariant),
  );
}
