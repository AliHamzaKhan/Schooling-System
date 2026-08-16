import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared/shared.dart';

/// A modal bottom-sheet form used by the "add / create" actions across the
/// portal. Owns the submit lifecycle (loading spinner + inline error), so
/// callers only provide the fields and an [onSubmit] that returns `null` on
/// success or an error message to display.
///
/// Returns `true` when the action succeeded (so the caller can refresh a list).
///
/// Pass every `TextEditingController` you created for [fields] as
/// [ownedControllers]: the sheet takes ownership and disposes them when it
/// closes, so a form's fields never outlive the form that showed them.
Future<bool?> showActionFormSheet({
  required String title,
  required List<Widget> fields,
  required Future<String?> Function() onSubmit,
  String submitLabel = 'Save',
  List<TextEditingController> ownedControllers = const [],
}) {
  return Get.bottomSheet<bool>(
    _ActionFormSheet(
      title: title,
      fields: fields,
      onSubmit: onSubmit,
      submitLabel: submitLabel,
      ownedControllers: ownedControllers,
    ),
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
  );
}

/// Shared "add a person" form (full name + email + password) used by the Add
/// Teacher / Add Guardian flows. [onSubmit] performs the create and its
/// `ApiResponse` drives success/error handling.
Future<bool?> showAddPersonSheet({
  required String title,
  required String submitLabel,
  required Future<ApiResponse<dynamic>> Function(
          String email, String password, String fullName)
      onSubmit,
}) {
  final name = TextEditingController();
  final email = TextEditingController();
  final password = TextEditingController();
  return showActionFormSheet(
    title: title,
    submitLabel: submitLabel,
    ownedControllers: [name, email, password],
    fields: [
      GlassInput(label: 'Full name', hint: 'Jane Doe', controller: name),
      GlassInput(
        label: 'Email',
        hint: 'jane@school.edu',
        controller: email,
        keyboardType: TextInputType.emailAddress,
      ),
      GlassInput(
        label: 'Temporary password',
        hint: 'At least 8 characters',
        controller: password,
        obscureText: true,
      ),
    ],
    onSubmit: () async {
      if (name.text.trim().isEmpty) return 'Full name is required';
      if (!email.text.contains('@')) return 'A valid email is required';
      if (password.text.trim().length < 8) {
        return 'Password must be at least 8 characters';
      }
      final res =
          await onSubmit(email.text.trim(), password.text.trim(), name.text.trim());
      return res.success ? null : (res.error ?? 'Could not create the account');
    },
  );
}

class _ActionFormSheet extends StatefulWidget {
  final String title;
  final List<Widget> fields;
  final Future<String?> Function() onSubmit;
  final String submitLabel;
  final List<TextEditingController> ownedControllers;
  const _ActionFormSheet({
    required this.title,
    required this.fields,
    required this.onSubmit,
    required this.submitLabel,
    required this.ownedControllers,
  });

  @override
  State<_ActionFormSheet> createState() => _ActionFormSheetState();
}

class _ActionFormSheetState extends State<_ActionFormSheet> {
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    // The sheet owns its fields' controllers — dispose them with the sheet so
    // they cannot leak or be reused by the next one.
    for (final controller in widget.ownedControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _submitting = true;
      _error = null;
    });
    final err = await widget.onSubmit();
    if (!mounted) return;
    if (err == null) {
      Get.back<bool>(result: true);
    } else {
      setState(() {
        _submitting = false;
        _error = err;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(
          AppSpacing.containerPaddingMobile,
          AppSpacing.stackLg,
          AppSpacing.containerPaddingMobile,
          AppSpacing.stackLg + bottomInset),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.card)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: AppSpacing.stackMd),
                decoration: BoxDecoration(
                  color: AppColors.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(widget.title, style: AppTypography.displayLg.copyWith(fontSize: 24)),
            const SizedBox(height: AppSpacing.stackLg),
            for (final f in widget.fields) ...[
              f,
              const SizedBox(height: AppSpacing.stackMd),
            ],
            if (_error != null) ...[
              Text(_error!,
                  style: AppTypography.bodyMd.copyWith(color: AppColors.error)),
              const SizedBox(height: AppSpacing.stackMd),
            ],
            const SizedBox(height: AppSpacing.stackSm),
            PrimaryButton(
              label: widget.submitLabel,
              isLoading: _submitting,
              onPressed: _submitting ? null : _submit,
            ),
          ],
        ),
      ),
    );
  }
}

/// A labelled dropdown styled to match [GlassInput], for id/label pickers.
class ActionDropdownField<T> extends StatelessWidget {
  final String label;
  final String hint;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;
  const ActionDropdownField({
    super.key,
    required this.label,
    required this.hint,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(),
            style: AppTypography.labelCaps
                .copyWith(color: AppColors.onSurfaceVariant)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.stackMd),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(AppRadius.button),
            border: Border.all(color: AppColors.outlineVariant, width: 1),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              isExpanded: true,
              hint: Text(hint, style: AppTypography.bodyLg),
              items: items,
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}
