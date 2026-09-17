import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared/shared.dart';

import '../../../data/headmaster_repository.dart';
import '../models/teacher_attendance_day.dart';
import '../../../../../widgets/skeletons.dart';

/// Read-only roster for a given date + status filter (Absent / Late / …).
/// The date and status live in the URL query so a browser refresh reconstructs
/// the same canonical backend read. Typed arguments remain a compatibility
/// fallback for older in-memory callers.
class TeacherAttendanceRosterArgs {
  final DateTime date;
  final TeacherAttendanceStatus status;
  final String title;
  const TeacherAttendanceRosterArgs({
    required this.date,
    required this.status,
    required this.title,
  });

  static TeacherAttendanceRosterArgs? fromRoute({
    required Map<String, String?> parameters,
    Object? arguments,
  }) {
    final date = DateTime.tryParse(parameters['date'] ?? '');
    final statusRaw = parameters['status'];
    final validStatus = const {
      'present',
      'absent',
      'late',
      'on_leave',
      'unmarked',
    }.contains(statusRaw);
    if (date != null && validStatus) {
      final status = TeacherAttendanceStatusX.fromWire(statusRaw);
      return TeacherAttendanceRosterArgs(
        date: date,
        status: status,
        title: switch (status) {
          TeacherAttendanceStatus.present => 'Present Teachers',
          TeacherAttendanceStatus.absent => 'Absent Teachers',
          TeacherAttendanceStatus.late => 'Late Comers',
          TeacherAttendanceStatus.onLeave => 'On Leave',
          TeacherAttendanceStatus.unmarked => 'Attendance Not Marked',
        },
      );
    }
    return arguments is TeacherAttendanceRosterArgs ? arguments : null;
  }
}

class TeacherAttendanceRosterView extends StatefulWidget {
  const TeacherAttendanceRosterView({super.key});

  @override
  State<TeacherAttendanceRosterView> createState() =>
      _TeacherAttendanceRosterViewState();
}

class _TeacherAttendanceRosterViewState
    extends State<TeacherAttendanceRosterView> {
  final _repo = Get.find<HeadmasterRepository>();
  final _rows = <TeacherAttendanceRow>[].obs;
  final _loading = true.obs;
  final _error = RxnString();

  TeacherAttendanceRosterArgs? args;

  @override
  void initState() {
    super.initState();
    args = TeacherAttendanceRosterArgs.fromRoute(
      parameters: Get.parameters,
      arguments: Get.arguments,
    );
    if (args == null) {
      _error.value = 'A valid attendance date and status are required.';
      _loading.value = false;
      return;
    }
    _fetch();
  }

  Future<void> _fetch() async {
    _loading.value = true;
    _error.value = null;
    final res = await _repo.loadTeacherAttendance(
      date: args!.date,
      status: args!.status.wire,
    );
    if (res.success && res.data != null) {
      _rows.assignAll(res.data!.entries);
    } else {
      _error.value = res.error ?? 'Could not load attendance';
    }
    _loading.value = false;
  }

  Color get _accent => switch (args!.status) {
    TeacherAttendanceStatus.present => AppColors.tertiary,
    TeacherAttendanceStatus.late => const Color(0xFFF59E0B),
    TeacherAttendanceStatus.absent => AppColors.error,
    TeacherAttendanceStatus.onLeave => AppColors.primary,
    TeacherAttendanceStatus.unmarked => AppColors.onSurfaceVariant,
  };

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(
        title: Text(args?.title ?? 'Teacher Attendance'),
        backgroundColor: AppColors.surface,
      ),
      body: Obx(() {
        if (_loading.value) {
          return const SkeletonPage(body: SkeletonRosterList());
        }
        if (_error.value != null) {
          return AppStateView.error(
            title: 'Could not load attendance roster',
            message: _error.value!,
            actionLabel: args == null ? null : 'Try again',
            onAction: args == null ? null : _fetch,
          );
        }
        if (_rows.isEmpty) {
          return const AppStateView.empty(
            title: 'No teachers in this group',
            message:
                'Attendance entries matching this filter will appear here.',
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.containerPaddingMobile,
            AppSpacing.stackLg,
            AppSpacing.containerPaddingMobile,
            AppSpacing.stackXl,
          ),
          itemCount: _rows.length,
          separatorBuilder: (_, _) =>
              const SizedBox(height: AppSpacing.stackSm),
          itemBuilder: (_, i) {
            final r = _rows[i];
            return Container(
              padding: const EdgeInsets.all(AppSpacing.stackMd),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(AppRadius.card),
                border: Border.all(color: AppColors.outlineVariant),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: _accent.withValues(alpha: 0.14),
                    child: Text(
                      r.teacherName.isNotEmpty
                          ? r.teacherName[0].toUpperCase()
                          : '?',
                      style: AppTypography.titleMd.copyWith(color: _accent),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.stackMd),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(r.teacherName, style: AppTypography.bodyLg),
                        if (r.arrivalTime != null)
                          Text(
                            'Arrived ${r.arrivalTime!.substring(0, r.arrivalTime!.length.clamp(0, 5))}',
                            style: AppTypography.bodyMd.copyWith(
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        if (r.remarks != null && r.remarks!.isNotEmpty)
                          Text(
                            r.remarks!,
                            style: AppTypography.bodyMd.copyWith(
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Text(
                    r.status.label,
                    style: AppTypography.labelMd.copyWith(
                      color: _accent,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      }),
    );
  }
}
