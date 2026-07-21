import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared/shared.dart';

import '../../../../../config/headmaster_routes.dart';
import '../../../data/headmaster_repository.dart';
import '../models/teacher_attendance_day.dart';
import '../view/teacher_attendance_roster_view.dart';
import '../../../../../widgets/skeletons.dart';

/// Reports-section card: today's teacher attendance summary with drill-in
/// cards for absent / late-comers and a "Record Attendance" CTA.
class TeacherAttendanceReportCard extends StatefulWidget {
  const TeacherAttendanceReportCard({super.key});

  @override
  State<TeacherAttendanceReportCard> createState() =>
      _TeacherAttendanceReportCardState();
}

class _TeacherAttendanceReportCardState
    extends State<TeacherAttendanceReportCard> with WidgetsBindingObserver {
  final _repo = Get.find<HeadmasterRepository>();
  final _day = Rxn<TeacherAttendanceDay>();
  final _loading = true.obs;
  final _error = RxnString();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _fetch();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _fetch();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _fetch() async {
    _loading.value = true;
    _error.value = null;
    final res = await _repo.loadTeacherAttendance(date: DateTime.now());
    if (res.success && res.data != null) {
      _day.value = res.data;
    } else {
      _error.value = res.error ?? 'Could not load attendance';
    }
    _loading.value = false;
  }

  void _openRoster(TeacherAttendanceStatus status, String title) {
    Get.toNamed(
      HeadmasterRoutes.teacherAttendanceRoster,
      arguments: TeacherAttendanceRosterArgs(
        date: DateTime.now(),
        status: status,
        title: title,
      ),
    );
  }

  Future<void> _openMarking() async {
    await Get.toNamed(HeadmasterRoutes.teacherAttendance);
    await _fetch();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return GlassSurface(
        padding: const EdgeInsets.all(AppSpacing.stackLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.co_present_outlined,
                    size: 18, color: AppColors.primary),
                const SizedBox(width: 6),
                Text('Teacher Attendance', style: AppTypography.titleLg),
                const Spacer(),
                InkWell(
                  onTap: _openMarking,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.edit_calendar_outlined,
                            size: 14, color: AppColors.primary),
                        const SizedBox(width: 4),
                        Text('Record',
                            style: AppTypography.labelMd.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.stackMd),
            if (_loading.value)
              const Shimmer(child: SkeletonCardList(count: 2, height: 44))
            else if (_day.value == null)
              Text(_error.value ?? 'No data', style: AppTypography.bodyMd)
            else ...[
              _MetricsRow(day: _day.value!, onOpen: _openRoster),
              const SizedBox(height: AppSpacing.stackMd),
              GhostButton(
                label: 'Record Today\'s Attendance',
                leadingIcon: Icons.edit_calendar_outlined,
                trailingIcon: Icons.chevron_right_rounded,
                expanded: true,
                onPressed: _openMarking,
              ),
            ],
          ],
        ),
      );
    });
  }
}

class _MetricsRow extends StatelessWidget {
  final TeacherAttendanceDay day;
  final void Function(TeacherAttendanceStatus, String) onOpen;
  const _MetricsRow({required this.day, required this.onOpen});

  String get _rate {
    final pct = (day.presentRate * 100).round();
    return '$pct%';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _Tile(
                label: 'Present Rate',
                value: _rate,
                color: AppColors.tertiary,
                icon: Icons.trending_up_rounded,
              ),
            ),
            const SizedBox(width: AppSpacing.stackSm),
            Expanded(
              child: _Tile(
                label: 'Present',
                value: '${day.present}',
                color: AppColors.tertiary,
                icon: Icons.check_circle_outline,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.stackSm),
        Row(
          children: [
            Expanded(
              child: _Tile(
                label: 'Absent',
                value: '${day.absent}',
                color: AppColors.error,
                icon: Icons.person_off_outlined,
                onTap: day.absent == 0
                    ? null
                    : () => onOpen(
                        TeacherAttendanceStatus.absent, 'Absent Teachers'),
              ),
            ),
            const SizedBox(width: AppSpacing.stackSm),
            Expanded(
              child: _Tile(
                label: 'Late Comers',
                value: '${day.late}',
                color: const Color(0xFFF59E0B),
                icon: Icons.schedule_rounded,
                onTap: day.late == 0
                    ? null
                    : () => onOpen(
                        TeacherAttendanceStatus.late, 'Late Comers'),
              ),
            ),
          ],
        ),
        if (day.unmarked > 0) ...[
          const SizedBox(height: AppSpacing.stackSm),
          Text(
            '${day.unmarked} teachers not yet marked for today.',
            style: AppTypography.bodyMd
                .copyWith(color: AppColors.onSurfaceVariant),
          ),
        ],
      ],
    );
  }
}

class _Tile extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;
  final VoidCallback? onTap;
  const _Tile({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.button),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.stackMd),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(AppRadius.button),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(label,
                      style: AppTypography.labelMd.copyWith(color: color)),
                ),
                if (onTap != null)
                  Icon(Icons.chevron_right_rounded, size: 16, color: color),
              ],
            ),
            const SizedBox(height: 4),
            Text(value,
                style: AppTypography.headlineLg
                    .copyWith(color: color, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}
