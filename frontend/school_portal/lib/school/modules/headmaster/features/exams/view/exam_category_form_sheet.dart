import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared/shared.dart';

/// Bottom-sheet form for creating / editing an exam category (term): a name and
/// an optional start / end date window. Returns `true` on a successful submit.
///
/// [onSubmit] receives the trimmed name and the chosen dates and returns `null`
/// on success or an error message to show inline.
Future<bool?> showExamCategoryFormSheet({
  required String title,
  required String submitLabel,
  required Future<String?> Function(String name, DateTime? start, DateTime? end)
      onSubmit,
  String? initialName,
  DateTime? initialStart,
  DateTime? initialEnd,
}) {
  return Get.bottomSheet<bool>(
    _ExamCategoryFormSheet(
      title: title,
      submitLabel: submitLabel,
      onSubmit: onSubmit,
      initialName: initialName,
      initialStart: initialStart,
      initialEnd: initialEnd,
    ),
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
  );
}

class _ExamCategoryFormSheet extends StatefulWidget {
  final String title;
  final String submitLabel;
  final Future<String?> Function(String name, DateTime? start, DateTime? end)
      onSubmit;
  final String? initialName;
  final DateTime? initialStart;
  final DateTime? initialEnd;
  const _ExamCategoryFormSheet({
    required this.title,
    required this.submitLabel,
    required this.onSubmit,
    this.initialName,
    this.initialStart,
    this.initialEnd,
  });

  @override
  State<_ExamCategoryFormSheet> createState() => _ExamCategoryFormSheetState();
}

class _ExamCategoryFormSheetState extends State<_ExamCategoryFormSheet> {
  late final TextEditingController _name =
      TextEditingController(text: widget.initialName ?? '');
  DateTime? _start;
  DateTime? _end;
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _start = widget.initialStart;
    _end = widget.initialEnd;
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  String _label(DateTime? d) => d == null
      ? 'Not set'
      : '${d.year.toString().padLeft(4, '0')}-'
          '${d.month.toString().padLeft(2, '0')}-'
          '${d.day.toString().padLeft(2, '0')}';

  Future<void> _pickStart() async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: _start ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2),
    );
    if (d != null) setState(() => _start = d);
  }

  Future<void> _pickEnd() async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: _end ?? _start ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2),
    );
    if (d != null) setState(() => _end = d);
  }

  Future<void> _submit() async {
    final name = _name.text.trim();
    if (name.length < 2) {
      setState(() => _error = 'A name of at least 2 characters is required');
      return;
    }
    if (_start != null && _end != null && _end!.isBefore(_start!)) {
      setState(() => _error = 'The end date is before the start date');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    final err = await widget.onSubmit(name, _start, _end);
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
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppRadius.card)),
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
            Text(widget.title,
                style: AppTypography.displayLg.copyWith(fontSize: 24)),
            const SizedBox(height: AppSpacing.stackLg),
            GlassInput(
                label: 'Category name', hint: 'e.g. Mid Term', controller: _name),
            const SizedBox(height: AppSpacing.stackMd),
            _DateTile(
                label: 'Start date',
                value: _label(_start),
                isSet: _start != null,
                onTap: _pickStart,
                onClear: _start == null ? null : () => setState(() => _start = null)),
            const SizedBox(height: AppSpacing.stackMd),
            _DateTile(
                label: 'End date',
                value: _label(_end),
                isSet: _end != null,
                onTap: _pickEnd,
                onClear: _end == null ? null : () => setState(() => _end = null)),
            const SizedBox(height: AppSpacing.stackSm),
            Text(
              'The Announce button unlocks once the start date arrives.',
              style: AppTypography.bodyMd
                  .copyWith(color: AppColors.onSurfaceVariant),
            ),
            if (_error != null) ...[
              const SizedBox(height: AppSpacing.stackMd),
              Text(_error!,
                  style:
                      AppTypography.bodyMd.copyWith(color: AppColors.error)),
            ],
            const SizedBox(height: AppSpacing.stackLg),
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

class _DateTile extends StatelessWidget {
  final String label;
  final String value;
  final bool isSet;
  final VoidCallback onTap;
  final VoidCallback? onClear;
  const _DateTile({
    required this.label,
    required this.value,
    required this.isSet,
    required this.onTap,
    this.onClear,
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
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.button),
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.stackMd, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(AppRadius.button),
              border: Border.all(color: AppColors.outlineVariant, width: 1),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today_rounded, size: 18),
                const SizedBox(width: AppSpacing.stackMd),
                Expanded(
                  child: Text(value,
                      style: AppTypography.bodyLg.copyWith(
                          color: isSet
                              ? AppColors.onSurface
                              : AppColors.onSurfaceVariant)),
                ),
                if (onClear != null)
                  GestureDetector(
                    onTap: onClear,
                    child: const Icon(Icons.close_rounded, size: 18),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
