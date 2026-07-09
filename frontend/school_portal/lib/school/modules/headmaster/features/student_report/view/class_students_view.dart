import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared/shared.dart';

import '../data/student_report_service.dart';
import 'section_students_view.dart';

/// Arguments for [ClassStudentsView]: which class to list and its label.
class ClassStudentsArgs {
  final String classId;
  final String title; // e.g. "Grade 5"
  const ClassStudentsArgs({required this.classId, required this.title});
}

/// All students of one class, grouped by section — the teacher's entry point
/// (a teacher teaches whole classes, so their roster is class-separated).
/// Tapping a student opens their 360° report.
class ClassStudentsView extends StatefulWidget {
  const ClassStudentsView({super.key});

  @override
  State<ClassStudentsView> createState() => _ClassStudentsViewState();
}

class _ClassStudentsViewState extends State<ClassStudentsView> {
  late final ClassStudentsArgs _args;
  bool _loading = true;
  String? _error;

  /// Section label → its students.
  final List<(RosterEntry, List<RosterEntry>)> _groups = [];

  @override
  void initState() {
    super.initState();
    final arg = Get.arguments;
    _args = arg is ClassStudentsArgs
        ? arg
        : const ClassStudentsArgs(classId: '', title: 'Students');
    _load();
  }

  Future<void> _load() async {
    if (_args.classId.isEmpty) {
      setState(() {
        _loading = false;
        _error = 'No class selected.';
      });
      return;
    }
    final service = StudentReportService();
    final secRes = await service.fetchClassSections(_args.classId);
    if (!secRes.success) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = secRes.error ?? 'Could not load sections.';
      });
      return;
    }
    for (final section in secRes.data ?? const <RosterEntry>[]) {
      final students = await service.fetchSectionStudents(section.id);
      _groups.add((section, students.data ?? const <RosterEntry>[]));
    }
    if (!mounted) return;
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(title: Text('${_args.title} — Students')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!, style: AppTypography.bodyLg))
              : _groups.isEmpty
                  ? Center(
                      child: Text('This class has no sections yet.',
                          style: AppTypography.bodyLg))
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(
                          AppSpacing.containerPaddingMobile,
                          AppSpacing.stackMd,
                          AppSpacing.containerPaddingMobile,
                          AppSpacing.stackXl),
                      children: [
                        for (final (section, students) in _groups) ...[
                          Text('Section ${section.name}',
                              style: AppTypography.titleLg),
                          const SizedBox(height: AppSpacing.stackSm),
                          if (students.isEmpty)
                            GlassSurface(
                              padding:
                                  const EdgeInsets.all(AppSpacing.stackMd),
                              child: Text('No students enrolled.',
                                  style: AppTypography.bodyMd),
                            )
                          else
                            for (final s in students) ...[
                              StudentRosterTile(student: s),
                              const SizedBox(height: AppSpacing.stackSm),
                            ],
                          const SizedBox(height: AppSpacing.stackMd),
                        ],
                      ],
                    ),
    );
  }
}
