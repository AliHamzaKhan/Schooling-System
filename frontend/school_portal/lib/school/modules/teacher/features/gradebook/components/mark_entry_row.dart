import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

import '../models/gradebook_data.dart';

/// One student row in the gradebook: avatar + name + ID, Obtained input,
/// Total label, and a status dot (filled green check once a mark is entered).
class MarkEntryRow extends StatefulWidget {
  final GradebookStudent student;
  final int totalMarks;
  final int? obtained;
  final ValueChanged<String> onChanged;
  final VoidCallback? onOpenStudent;

  const MarkEntryRow({
    super.key,
    required this.student,
    required this.totalMarks,
    required this.obtained,
    required this.onChanged,
    this.onOpenStudent,
  });

  @override
  State<MarkEntryRow> createState() => _MarkEntryRowState();
}

class _MarkEntryRowState extends State<MarkEntryRow> {
  /// This row's own marks field — created with the row and disposed with it, so
  /// it can never be shared with another student's row or outlive the sheet.
  late final TextEditingController _controller =
      TextEditingController(text: _textFor(widget.obtained));

  static String _textFor(int? mark) => mark?.toString() ?? '';

  @override
  void didUpdateWidget(MarkEntryRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reflect marks that changed outside the field (a reload after saving),
    // while leaving what the teacher is currently typing untouched.
    if (widget.obtained != int.tryParse(_controller.text.trim())) {
      _controller.text = _textFor(widget.obtained);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  GradebookStudent get student => widget.student;
  int get totalMarks => widget.totalMarks;
  int? get obtained => widget.obtained;
  VoidCallback? get onOpenStudent => widget.onOpenStudent;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.stackSm),
          child: Column(
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: student.accent.withValues(alpha: 0.18),
                    child: Text(student.initials,
                        style: AppTypography.titleMd
                            .copyWith(color: student.accent)),
                  ),
                  const SizedBox(width: AppSpacing.stackSm),
                  Expanded(
                    child: GestureDetector(
                      onTap: onOpenStudent,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(student.name,
                              style: AppTypography.titleMd
                                  .copyWith(fontWeight: FontWeight.w700)),
                          Text('ID: ${student.id}',
                              style: AppTypography.bodySm),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.stackSm),
              Row(
                children: [
                  Expanded(child: Text('Obtained:', style: AppTypography.bodyLg)),
                  SizedBox(
                    width: 90,
                    child: TextField(
                      controller: _controller,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      style: AppTypography.titleMd,
                      onChanged: widget.onChanged,
                      decoration: InputDecoration(
                        isDense: true,
                        hintText: '--',
                        hintStyle: AppTypography.bodyLg
                            .copyWith(color: AppColors.outline),
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 10),
                        enabledBorder: _border(AppColors.outlineVariant),
                        focusedBorder: _border(AppColors.primary, width: 1.5),
                        border: _border(AppColors.outlineVariant),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.stackSm),
              Row(
                children: [
                  Expanded(child: Text('Total:', style: AppTypography.bodyLg)),
                  Text('$totalMarks',
                      style: AppTypography.titleMd
                          .copyWith(fontWeight: FontWeight.w700)),
                ],
              ),
              const SizedBox(height: AppSpacing.stackSm),
              Align(
                alignment: Alignment.centerRight,
                child: obtained != null
                    ? const Icon(AppIcons.checkCircleOutlineRounded,
                        size: 22, color: AppColors.tertiary)
                    : const Icon(AppIcons.moreHorizRounded,
                        size: 22, color: AppColors.outline),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: AppColors.outlineVariant),
      ],
    );
  }

  OutlineInputBorder _border(Color color, {double width = 1}) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        borderSide: BorderSide(color: color, width: width),
      );
}
