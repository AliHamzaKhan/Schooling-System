import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

import '../models/gradebook_data.dart';

/// One student row in the gradebook: avatar + name + ID, Obtained input,
/// Total label, and a status dot (filled green check once a mark is entered).
class MarkEntryRow extends StatelessWidget {
  final GradebookStudent student;
  final int totalMarks;
  final int? obtained;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback? onOpenStudent;

  const MarkEntryRow({
    super.key,
    required this.student,
    required this.totalMarks,
    required this.controller,
    required this.obtained,
    required this.onChanged,
    this.onOpenStudent,
  });

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
                      controller: controller,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      style: AppTypography.titleMd,
                      onChanged: onChanged,
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
                    ? const Icon(Icons.check_circle_outline_rounded,
                        size: 22, color: AppColors.tertiary)
                    : const Icon(Icons.more_horiz_rounded,
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
