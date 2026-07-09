import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared/shared.dart';

import '../../../../../config/headmaster_routes.dart';
import '../../../../../config/teacher_routes.dart';
import '../../../../headmaster/features/student_report/view/class_students_view.dart'
    show ClassStudentsArgs;
import '../../attendance/models/attendance_models.dart';
import '../models/teaching_class.dart';

/// Single-class detail reached from "View Class" (or the card menu). Shows the
/// class identity + roster size and the common per-class actions (take
/// attendance, open the gradebook, message the class).
class ClassDetailView extends StatelessWidget {
  const ClassDetailView({super.key});

  TeachingClass get _class {
    final arg = Get.arguments;
    return arg is TeachingClass ? arg : _fallback;
  }

  static const _fallback = TeachingClass(
    id: 'C-0',
    subject: 'Class',
    grade: '',
    description: '',
    students: 0,
    accent: AppColors.primary,
  );

  @override
  Widget build(BuildContext context) {
    final c = _class;
    return AppScaffold(
      appBar: AppBar(title: const Text('Class Details')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.containerPaddingMobile,
            AppSpacing.stackMd,
            AppSpacing.containerPaddingMobile,
            AppSpacing.stackXl),
        children: [
          Row(
            children: [
              Container(
                  width: 10,
                  height: 10,
                  decoration:
                      BoxDecoration(color: c.accent, shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Text(c.subject,
                  style: AppTypography.titleMd
                      .copyWith(color: c.accent, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: AppSpacing.stackSm),
          Text(c.grade.isEmpty ? c.subject : c.grade,
              style: AppTypography.displayLg.copyWith(fontSize: 30)),
          if (c.description.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(c.description, style: AppTypography.bodyLg),
          ],
          const SizedBox(height: AppSpacing.stackLg),
          GlassSurface(
            padding: const EdgeInsets.all(AppSpacing.stackLg),
            child: Row(
              children: [
                const Icon(Icons.people_alt_outlined,
                    color: AppColors.onSurfaceVariant),
                const SizedBox(width: AppSpacing.stackSm),
                Text('${c.students} Students',
                    style: AppTypography.titleMd
                        .copyWith(fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.stackLg),
          Text('Actions', style: AppTypography.titleLg),
          const SizedBox(height: AppSpacing.stackMd),
          PrimaryButton(
            label: 'Take Attendance',
            leadingIcon: Icons.fact_check_outlined,
            trailingIcon: null,
            expanded: true,
            onPressed: () => Get.toNamed(
              TeacherRoutes.attendanceMark,
              arguments: AttendanceClass(
                id: c.id,
                subject: c.subject,
                grade: c.grade,
                students: c.students,
                icon: Icons.class_outlined,
                color: c.accent,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.stackSm),
          GhostButton(
            label: 'View Students',
            leadingIcon: Icons.people_alt_outlined,
            expanded: true,
            // Shared staff drill-down (lives under the headmaster routes):
            // sections of this class → students → 360° student report.
            onPressed: () => Get.toNamed(
              HeadmasterRoutes.classStudents,
              arguments: ClassStudentsArgs(
                classId: c.id,
                title: c.subject.isEmpty ? 'Class' : c.subject,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.stackSm),
          GhostButton(
            label: 'Open Gradebook',
            expanded: true,
            onPressed: () => Get.toNamed(TeacherRoutes.gradebook),
          ),
          const SizedBox(height: AppSpacing.stackSm),
          GhostButton(
            label: 'Message Class',
            expanded: true,
            onPressed: () => Get.toNamed(TeacherRoutes.chat),
          ),
        ],
      ),
    );
  }
}
