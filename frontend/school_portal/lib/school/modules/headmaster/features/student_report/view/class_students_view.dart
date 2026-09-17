import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared/shared.dart';

import '../data/student_report_service.dart';
import 'section_students_view.dart';
import '../../../../../widgets/skeletons.dart';

/// Arguments for [ClassStudentsView]: which class to list and its label.
class ClassStudentsArgs {
  final String classId;
  final String title; // e.g. "Grade 5"
  const ClassStudentsArgs({required this.classId, required this.title});

  static ClassStudentsArgs fromRoute({
    required Map<String, String?> parameters,
    Object? arguments,
  }) {
    final classId = parameters['class_id']?.trim() ?? '';
    if (classId.isNotEmpty) {
      return ClassStudentsArgs(
        classId: classId,
        title: parameters['title']?.trim().isNotEmpty == true
            ? parameters['title']!.trim()
            : 'Class',
      );
    }
    return arguments is ClassStudentsArgs
        ? arguments
        : const ClassStudentsArgs(classId: '', title: 'Class');
  }
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
    _args = ClassStudentsArgs.fromRoute(
      parameters: Get.parameters,
      arguments: Get.arguments,
    );
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
      _groups.clear();
    });
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
      if (!students.success) {
        if (!mounted) return;
        setState(() {
          _loading = false;
          _error = students.error ?? 'Could not load section students.';
          _groups.clear();
        });
        return;
      }
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
          ? const SkeletonPage(withHeader: false, body: SkeletonRosterList())
          : _error != null
          ? AppStateView.error(
              title: 'Could not load class students',
              message: _error!,
              actionLabel: 'Try again',
              onAction: _load,
            )
          : _groups.isEmpty
          ? const AppStateView.empty(
              title: 'No sections yet',
              message: 'This class has no sections to show.',
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.containerPaddingMobile,
                AppSpacing.stackMd,
                AppSpacing.containerPaddingMobile,
                AppSpacing.stackXl,
              ),
              children: [
                for (final (section, students) in _groups) ...[
                  Text('Section ${section.name}', style: AppTypography.titleLg),
                  const SizedBox(height: AppSpacing.stackSm),
                  if (students.isEmpty)
                    GlassSurface(
                      padding: const EdgeInsets.all(AppSpacing.stackMd),
                      child: Text(
                        'No students enrolled.',
                        style: AppTypography.bodyMd,
                      ),
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
