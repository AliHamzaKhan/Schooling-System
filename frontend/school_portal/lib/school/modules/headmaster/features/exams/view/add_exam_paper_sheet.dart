import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared/shared.dart';

import '../controller/exam_timetable_controller.dart';

/// Bottom sheet to add one subject paper to the selected class's exam: subject,
/// date, optional time, and max / pass marks.
Future<bool?> showAddExamPaperSheet(ExamTimetableController controller) {
  return Get.bottomSheet<bool>(
    _AddExamPaperSheet(controller: controller),
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
  );
}

class _AddExamPaperSheet extends StatefulWidget {
  final ExamTimetableController controller;
  const _AddExamPaperSheet({required this.controller});

  @override
  State<_AddExamPaperSheet> createState() => _AddExamPaperSheetState();
}

class _AddExamPaperSheetState extends State<_AddExamPaperSheet> {
  String? _subjectId;
  DateTime? _date;
  TimeOfDay? _time;
  final _max = TextEditingController(text: '100');
  final _pass = TextEditingController(text: '40');
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _max.dispose();
    _pass.dispose();
    super.dispose();
  }

  String _dateLabel() => _date == null
      ? 'Set date'
      : '${_date!.day.toString().padLeft(2, '0')}/'
          '${_date!.month.toString().padLeft(2, '0')}/${_date!.year}';

  String _timeLabel() =>
      _time == null ? 'Optional' : _time!.format(context);

  String? _timeWire() => _time == null
      ? null
      : '${_time!.hour.toString().padLeft(2, '0')}:'
          '${_time!.minute.toString().padLeft(2, '0')}';

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: _date ?? widget.controller.termStart ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2),
    );
    if (d != null) setState(() => _date = d);
  }

  Future<void> _pickTime() async {
    final t = await showTimePicker(
        context: context, initialTime: _time ?? const TimeOfDay(hour: 9, minute: 0));
    if (t != null) setState(() => _time = t);
  }

  Future<void> _submit() async {
    if (_subjectId == null) {
      setState(() => _error = 'Choose a subject');
      return;
    }
    final max = double.tryParse(_max.text.trim());
    final pass = double.tryParse(_pass.text.trim());
    if (max == null || max <= 0) {
      setState(() => _error = 'Enter valid maximum marks');
      return;
    }
    if (pass == null || pass < 0 || pass > max) {
      setState(() => _error = 'Pass marks must be between 0 and the maximum');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    final err = await widget.controller.addPaper(
      subjectId: _subjectId!,
      maxMarks: max,
      passMarks: pass,
      examDate: _date,
      examTime: _timeWire(),
    );
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
            Text('Add Subject',
                style: AppTypography.displayLg.copyWith(fontSize: 24)),
            const SizedBox(height: AppSpacing.stackLg),
            Text('SUBJECT',
                style: AppTypography.labelCaps
                    .copyWith(color: AppColors.onSurfaceVariant)),
            const SizedBox(height: 6),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: AppSpacing.stackMd),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(AppRadius.button),
                border: Border.all(color: AppColors.outlineVariant, width: 1),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _subjectId,
                  isExpanded: true,
                  hint: Text('Select a subject', style: AppTypography.bodyLg),
                  items: [
                    for (final s in widget.controller.subjects)
                      DropdownMenuItem(
                        value: s.id,
                        child: Text(s.name.isNotEmpty ? s.name : s.code),
                      ),
                  ],
                  onChanged: (v) => setState(() => _subjectId = v),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.stackMd),
            Row(
              children: [
                Expanded(
                  child: _PickerTile(
                    label: 'DATE',
                    value: _dateLabel(),
                    icon: Icons.calendar_today_rounded,
                    onTap: _pickDate,
                  ),
                ),
                const SizedBox(width: AppSpacing.stackMd),
                Expanded(
                  child: _PickerTile(
                    label: 'TIME',
                    value: _timeLabel(),
                    icon: Icons.schedule_rounded,
                    onTap: _pickTime,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.stackMd),
            Row(
              children: [
                Expanded(
                  child: GlassInput(
                    label: 'Max marks',
                    controller: _max,
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: AppSpacing.stackMd),
                Expanded(
                  child: GlassInput(
                    label: 'Pass marks',
                    controller: _pass,
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            if (_error != null) ...[
              const SizedBox(height: AppSpacing.stackMd),
              Text(_error!,
                  style:
                      AppTypography.bodyMd.copyWith(color: AppColors.error)),
            ],
            const SizedBox(height: AppSpacing.stackLg),
            PrimaryButton(
              label: 'Add subject',
              isLoading: _submitting,
              onPressed: _submitting ? null : _submit,
            ),
          ],
        ),
      ),
    );
  }
}

class _PickerTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final VoidCallback onTap;
  const _PickerTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
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
                Icon(icon, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(value,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodyMd),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
