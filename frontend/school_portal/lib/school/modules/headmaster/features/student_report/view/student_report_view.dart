import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared/shared.dart';

import '../../../../../config/headmaster_routes.dart';
import '../../../../../widgets/section_header.dart';
import '../controller/student_report_controller.dart';
import '../models/student_report.dart';
import 'message_history_view.dart' show MessageHistoryArgs;
import '../../../../../widgets/skeletons.dart';

/// Student Report — a 360-degree view of one student (attendance, exams,
/// assignments, quizzes, total points) plus guardian actions.
class StudentReportView extends GetView<StudentReportController> {
  const StudentReportView({super.key});

  static String _fmt(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toString();

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(
        title: Obx(() =>
            Text(controller.report.value?.studentName ?? 'Student Report')),
      ),
      body: Obx(() {
        if (controller.loading.value) {
          return const SkeletonPage(body: Column(children: [SkeletonStatGrid(count: 4), SizedBox(height: AppSpacing.stackLg), SkeletonCardList(count: 3)]));
        }
        if (controller.error.value != null) {
          return Center(
              child: Text(controller.error.value!, style: AppTypography.bodyLg));
        }
        final r = controller.report.value;
        if (r == null) return const SizedBox.shrink();
        return ListView(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.containerPaddingMobile,
              AppSpacing.stackMd,
              AppSpacing.containerPaddingMobile,
              AppSpacing.stackXl),
          children: [
            // Headline stats.
            Row(
              children: [
                Expanded(
                  child: _Stat(
                    label: 'Attendance',
                    value: '${r.attendance.percentage.toStringAsFixed(0)}%',
                    accent: AppColors.tertiary,
                  ),
                ),
                const SizedBox(width: AppSpacing.stackMd),
                Expanded(
                  child: _Stat(
                    label: 'Exam Avg',
                    value: '${r.examAverage.toStringAsFixed(0)}%',
                    accent: AppColors.primary,
                  ),
                ),
                const SizedBox(width: AppSpacing.stackMd),
                Expanded(
                  child: _Stat(
                    label: 'Points',
                    value: _fmt(r.totalPoints),
                    accent: const Color(0xFFE8A317),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.stackLg),

            // Attendance breakdown.
            const SectionHeader(title: 'Attendance'),
            const SizedBox(height: AppSpacing.stackSm),
            GlassSurface(
              padding: const EdgeInsets.all(AppSpacing.stackMd),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _Mini(label: 'Present', value: '${r.attendance.present}'),
                  _Mini(label: 'Late', value: '${r.attendance.late}'),
                  _Mini(label: 'Absent', value: '${r.attendance.absent}'),
                  _Mini(label: 'Total', value: '${r.attendance.total}'),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.stackLg),

            // Exams.
            SectionHeader(title: 'Exams (avg ${r.examAverage.toStringAsFixed(0)}%)'),
            const SizedBox(height: AppSpacing.stackSm),
            if (r.exams.isEmpty)
              _empty('No published exam results.')
            else
              for (final e in r.exams) ...[
                _ExamRow(exam: e),
                const SizedBox(height: AppSpacing.stackSm),
              ],
            const SizedBox(height: AppSpacing.stackMd),

            // Assignments.
            const SectionHeader(title: 'Assignments'),
            const SizedBox(height: AppSpacing.stackSm),
            GlassSurface(
              padding: const EdgeInsets.all(AppSpacing.stackMd),
              child: Row(
                children: [
                  const Icon(Icons.assignment_outlined,
                      color: AppColors.primary),
                  const SizedBox(width: AppSpacing.stackMd),
                  Expanded(
                    child: Text(
                      '${r.assignmentsSubmitted} of ${r.assignmentsTotal} submitted',
                      style: AppTypography.titleMd,
                    ),
                  ),
                  Text(
                    r.assignmentsTotal == 0
                        ? '—'
                        : '${(r.assignmentsSubmitted * 100 / r.assignmentsTotal).round()}%',
                    style: AppTypography.titleMd.copyWith(
                        fontWeight: FontWeight.w800, color: AppColors.primary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.stackLg),

            // Quizzes.
            SectionHeader(
              title: r.quizAverage == null
                  ? 'Quizzes'
                  : 'Quizzes (avg ${_fmt(r.quizAverage!)})',
            ),
            const SizedBox(height: AppSpacing.stackSm),
            if (r.quizzes.isEmpty)
              _empty('No quiz attempts yet.')
            else
              for (final q in r.quizzes) ...[
                GlassSurface(
                  padding: const EdgeInsets.all(AppSpacing.stackMd),
                  child: Row(
                    children: [
                      const Icon(Icons.quiz_outlined, color: AppColors.primary),
                      const SizedBox(width: AppSpacing.stackMd),
                      Expanded(
                          child: Text(q.title, style: AppTypography.titleMd)),
                      Text(q.score == null ? '—' : _fmt(q.score!),
                          style: AppTypography.titleMd.copyWith(
                              fontWeight: FontWeight.w800,
                              color: AppColors.tertiary)),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.stackSm),
              ],
            const SizedBox(height: AppSpacing.stackMd),

            // Guardian + actions.
            _GuardianActions(controller: controller, report: r),
          ],
        );
      }),
    );
  }

  Widget _empty(String text) => GlassSurface(
        padding: const EdgeInsets.all(AppSpacing.stackMd),
        child: Text(text, style: AppTypography.bodyMd),
      );
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final Color accent;
  const _Stat({required this.label, required this.value, required this.accent});

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      padding: const EdgeInsets.all(AppSpacing.stackMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value,
              style: AppTypography.headlineLg
                  .copyWith(fontSize: 24, color: accent)),
          Text(label,
              style: AppTypography.bodySm
                  .copyWith(color: AppColors.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class _Mini extends StatelessWidget {
  final String label;
  final String value;
  const _Mini({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style:
                AppTypography.titleLg.copyWith(fontWeight: FontWeight.w800)),
        Text(label,
            style: AppTypography.bodySm
                .copyWith(color: AppColors.onSurfaceVariant)),
      ],
    );
  }
}

class _ExamRow extends StatelessWidget {
  final ReportExam exam;
  const _ExamRow({required this.exam});

  @override
  Widget build(BuildContext context) {
    final passed = exam.status.toLowerCase() == 'pass';
    final color = passed ? AppColors.tertiary : AppColors.error;
    return GlassSurface(
      padding: const EdgeInsets.all(AppSpacing.stackMd),
      child: Row(
        children: [
          Expanded(child: Text(exam.examName, style: AppTypography.titleMd)),
          Text('${exam.percentage.toStringAsFixed(0)}%',
              style: AppTypography.titleMd
                  .copyWith(fontWeight: FontWeight.w800, color: color)),
          const SizedBox(width: AppSpacing.stackSm),
          Text(exam.grade.isEmpty ? (passed ? 'P' : 'F') : exam.grade,
              style: AppTypography.labelMd.copyWith(color: color)),
        ],
      ),
    );
  }
}

class _GuardianActions extends StatelessWidget {
  final StudentReportController controller;
  final StudentReport report;
  const _GuardianActions({required this.controller, required this.report});

  Future<void> _requestMeeting(BuildContext context) async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 90)),
    );
    if (date == null || !context.mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 10, minute: 0),
    );
    if (time == null) return;
    await controller.createMeeting(
        DateTime(date.year, date.month, date.day, time.hour, time.minute));
  }

  @override
  Widget build(BuildContext context) {
    final guardian =
        report.guardians.isEmpty ? null : report.guardians.first.name;
    return GlassSurface(
      padding: const EdgeInsets.all(AppSpacing.stackLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.escalator_warning_rounded,
                  color: AppColors.primary),
              const SizedBox(width: AppSpacing.stackSm),
              Expanded(
                child: Text(
                  guardian == null ? 'No guardian linked' : 'Guardian: $guardian',
                  style: AppTypography.titleMd,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.stackMd),
          Obx(() => PrimaryButton(
                label: 'Request Meeting',
                leadingIcon: Icons.event_available_rounded,
                trailingIcon: null,
                expanded: true,
                isLoading: controller.actionBusy.value,
                onPressed: () => _requestMeeting(context),
              )),
          const SizedBox(height: AppSpacing.stackSm),
          GhostButton(
            label: 'Message Guardian',
            leadingIcon: Icons.chat_bubble_outline_rounded,
            trailingIcon: null,
            expanded: true,
            onPressed: controller.hasGuardian ? controller.messageGuardian : null,
          ),
          const SizedBox(height: AppSpacing.stackSm),
          GhostButton(
            label: 'Raise a Concern',
            leadingIcon: Icons.report_gmailerrorred_rounded,
            trailingIcon: null,
            expanded: true,
            onPressed: controller.sendComplaint,
          ),
          const SizedBox(height: AppSpacing.stackSm),
          GhostButton(
            label: 'View Message History',
            leadingIcon: Icons.history_rounded,
            trailingIcon: Icons.chevron_right_rounded,
            expanded: true,
            onPressed: () => Get.toNamed(
              HeadmasterRoutes.messageHistory,
              arguments: MessageHistoryArgs(
                studentId: report.studentId,
                studentName: report.studentName,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
