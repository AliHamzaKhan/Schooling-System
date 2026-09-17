import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared/shared.dart';

import '../../../../../config/headmaster_routes.dart';
import '../data/student_report_service.dart';
import '../../../../../widgets/skeletons.dart';

/// Arguments for [SectionStudentsView]: which section to list and its label.
class SectionStudentsArgs {
  final String sectionId;
  final String title; // e.g. "Grade 5 · A"
  const SectionStudentsArgs({required this.sectionId, required this.title});

  static SectionStudentsArgs fromRoute({
    required Map<String, String?> parameters,
    Object? arguments,
  }) {
    final sectionId = parameters['section_id']?.trim() ?? '';
    if (sectionId.isNotEmpty) {
      return SectionStudentsArgs(
        sectionId: sectionId,
        title: parameters['title']?.trim().isNotEmpty == true
            ? parameters['title']!.trim()
            : 'Students',
      );
    }
    return arguments is SectionStudentsArgs
        ? arguments
        : const SectionStudentsArgs(sectionId: '', title: 'Students');
  }
}

/// Students enrolled in one section; tapping a student opens their 360° report.
/// Shared by the Headmaster (classes → section → students) and Teacher drill-ins.
class SectionStudentsView extends StatefulWidget {
  final String studentReportRoute;
  const SectionStudentsView({
    super.key,
    this.studentReportRoute = HeadmasterRoutes.studentReport,
  });

  @override
  State<SectionStudentsView> createState() => _SectionStudentsViewState();
}

class _SectionStudentsViewState extends State<SectionStudentsView> {
  late final SectionStudentsArgs _args;
  bool _loading = true;
  String? _error;
  List<RosterEntry> _students = const [];

  @override
  void initState() {
    super.initState();
    _args = SectionStudentsArgs.fromRoute(
      parameters: Get.parameters,
      arguments: Get.arguments,
    );
    _load();
  }

  Future<void> _load() async {
    if (_args.sectionId.isEmpty) {
      setState(() {
        _loading = false;
        _error = 'No section selected.';
      });
      return;
    }
    final res = await StudentReportService().fetchSectionStudents(
      _args.sectionId,
    );
    if (!mounted) return;
    setState(() {
      if (res.success) {
        _students = res.data ?? const [];
      } else {
        _error = res.error ?? 'Could not load students.';
      }
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(title: Text(_args.title)),
      body: _loading
          ? const SkeletonPage(withHeader: false, body: SkeletonRosterList())
          : _error != null
          ? Center(child: Text(_error!, style: AppTypography.bodyLg))
          : _students.isEmpty
          ? Center(
              child: Text(
                'No students enrolled in this section.',
                style: AppTypography.bodyLg,
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.containerPaddingMobile,
                AppSpacing.stackMd,
                AppSpacing.containerPaddingMobile,
                AppSpacing.stackXl,
              ),
              itemCount: _students.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(height: AppSpacing.stackSm),
              itemBuilder: (context, i) => StudentRosterTile(
                student: _students[i],
                reportRoute: widget.studentReportRoute,
              ),
            ),
    );
  }
}

/// One tappable student row → opens the student's report.
class StudentRosterTile extends StatelessWidget {
  final RosterEntry student;
  final String reportRoute;
  const StudentRosterTile({
    super.key,
    required this.student,
    this.reportRoute = HeadmasterRoutes.studentReport,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Get.toNamed(
        '$reportRoute?student_id=${Uri.encodeComponent(student.id)}',
        arguments: student.id,
      ),
      child: GlassSurface(
        padding: const EdgeInsets.all(AppSpacing.stackMd),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.primary.withValues(alpha: 0.14),
              child: Text(
                student.name.isEmpty
                    ? '?'
                    : student.name.characters.first.toUpperCase(),
                style: AppTypography.titleMd.copyWith(color: AppColors.primary),
              ),
            ),
            const SizedBox(width: AppSpacing.stackMd),
            Expanded(
              child: Text(
                student.name.isEmpty ? 'Student' : student.name,
                style: AppTypography.titleMd.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const Icon(
              AppIcons.chevronRightRounded,
              color: AppColors.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}
