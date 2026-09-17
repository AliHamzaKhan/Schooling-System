import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared/shared.dart';

import '../../../../../config/headmaster_routes.dart';
import '../../../../../widgets/portal_top_bar.dart';
import '../../../../../widgets/ring_chart.dart';
import '../../../data/headmaster_repository.dart';
import '../models/teacher_attendance_day.dart';
import '../../../../../widgets/skeletons.dart';

/// Attendance — teacher attendance for a chosen date, backed entirely by
/// `/hr/attendance`. Pick a date, see the split (present / absent / late /
/// leave / unmarked), drill into any group, or jump to the marking screen.
///
/// Student-side attendance analytics are not wired to the API yet, so this
/// screen deliberately shows only teacher data: every number here is real.
class AttendanceView extends StatefulWidget {
  final VoidCallback? onAnalytics;
  const AttendanceView({super.key, this.onAnalytics});

  @override
  State<AttendanceView> createState() => _AttendanceViewState();
}

class _AttendanceViewState extends State<AttendanceView> {
  final _repo = Get.find<HeadmasterRepository>();

  final _date = Rx<DateTime>(DateTime.now());
  final _day = Rxn<TeacherAttendanceDay>();
  final _loading = true.obs;
  final _error = RxnString();

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    _loading.value = true;
    _error.value = null;
    final res = await _repo.loadTeacherAttendance(date: _date.value);
    if (res.success && res.data != null) {
      _day.value = res.data;
    } else {
      _error.value = res.error ?? 'Could not load attendance';
    }
    _loading.value = false;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date.value,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null && picked != _date.value) {
      _date.value = picked;
      await _fetch();
    }
  }

  void _openRoster(TeacherAttendanceStatus status, String _) {
    Get.toNamed(
      HeadmasterRoutes.teacherAttendanceRoster,
      parameters: {
        'date': _date.value.toIso8601String().split('T').first,
        'status': status.wire,
      },
    );
  }

  Future<void> _openMarking() async {
    await Get.toNamed(HeadmasterRoutes.teacherAttendance);
    await _fetch();
  }

  String _fmtDate(DateTime d) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final today = DateTime.now();
    final isToday =
        d.year == today.year && d.month == today.month && d.day == today.day;
    final label = '${d.day} ${months[d.month - 1]} ${d.year}';
    return isToday ? 'Today, $label' : label;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PortalTopBar(showAvatar: true),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _fetch,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.containerPaddingMobile,
                0,
                AppSpacing.containerPaddingMobile,
                AppSpacing.stackXl,
              ),
              children: [
                Obx(
                  () => _DateSelector(
                    label: _fmtDate(_date.value),
                    onTap: _pickDate,
                  ),
                ),
                const SizedBox(height: AppSpacing.stackMd),
                Text('Teacher\nAttendance', style: AppTypography.headlineLg),
                const SizedBox(height: AppSpacing.stackLg),

                // Everything below depends on the fetched day. Scoping the Obx
                // here (rather than around the whole list) keeps the header and
                // date selector from flashing when the date changes.
                Obx(() {
                  if (_loading.value && _day.value == null) {
                    return const Shimmer(
                      child: SkeletonCardList(count: 3, height: 96),
                    );
                  }
                  final day = _day.value;
                  if (day == null) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 48),
                      child: Center(
                        child: Text(
                          _error.value ?? 'No data',
                          style: AppTypography.bodyLg,
                        ),
                      ),
                    );
                  }
                  if (day.totalTeachers == 0) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 48),
                      child: Center(
                        child: Text(
                          'No teachers on the roster yet.',
                          style: AppTypography.bodyLg,
                        ),
                      ),
                    );
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _StatusTiles(day: day, onOpen: _openRoster),
                      const SizedBox(height: AppSpacing.stackLg),
                      GlassSurface(
                        padding: const EdgeInsets.all(AppSpacing.stackLg),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Present Rate', style: AppTypography.titleLg),
                            const SizedBox(height: 2),
                            Text(
                              '${day.present} of ${day.totalTeachers} teachers present',
                              style: AppTypography.bodySm,
                            ),
                            const SizedBox(height: AppSpacing.stackLg),
                            Center(
                              child: RingChart(
                                progress: day.presentRate,
                                color: AppColors.tertiary,
                                value: '${(day.presentRate * 100).round()}%',
                                caption: 'Teachers',
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (day.unmarked > 0) ...[
                        const SizedBox(height: AppSpacing.stackMd),
                        _UnmarkedBanner(
                          count: day.unmarked,
                          onTap: () => _openRoster(
                            TeacherAttendanceStatus.unmarked,
                            'Not Marked',
                          ),
                        ),
                      ],
                      const SizedBox(height: AppSpacing.stackLg),
                      PrimaryButton(
                        label: 'Record Attendance',
                        leadingIcon: AppIcons.editCalendarOutlined,
                        trailingIcon: null,
                        expanded: true,
                        onPressed: _openMarking,
                      ),
                      const SizedBox(height: AppSpacing.stackMd),
                      GhostButton(
                        label: 'Open Reports & Analytics',
                        trailingIcon: AppIcons.arrowForward,
                        expanded: true,
                        onPressed: widget.onAnalytics,
                      ),
                    ],
                  );
                }),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _DateSelector extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _DateSelector({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.button),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(AppRadius.button),
            border: Border.all(color: AppColors.outlineVariant),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                AppIcons.calendarTodayOutlined,
                size: 14,
                color: AppColors.primary,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: AppTypography.labelMd.copyWith(color: AppColors.primary),
              ),
              const SizedBox(width: 4),
              const Icon(
                AppIcons.expandMoreRounded,
                size: 16,
                color: AppColors.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Present / Absent / Late / Leave tiles — each with its own icon and colour,
/// and each drilling into the matching roster.
class _StatusTiles extends StatelessWidget {
  final TeacherAttendanceDay day;
  final void Function(TeacherAttendanceStatus, String) onOpen;
  const _StatusTiles({required this.day, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _Tile(
                label: 'Present',
                value: day.present,
                color: AppColors.tertiary,
                icon: AppIcons.checkCircleOutline,
                onTap: day.present == 0
                    ? null
                    : () => onOpen(
                        TeacherAttendanceStatus.present,
                        'Present Teachers',
                      ),
              ),
            ),
            const SizedBox(width: AppSpacing.stackSm),
            Expanded(
              child: _Tile(
                label: 'Absent',
                value: day.absent,
                color: AppColors.error,
                icon: AppIcons.personOffOutlined,
                onTap: day.absent == 0
                    ? null
                    : () => onOpen(
                        TeacherAttendanceStatus.absent,
                        'Absent Teachers',
                      ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.stackSm),
        Row(
          children: [
            Expanded(
              child: _Tile(
                label: 'Late Comers',
                value: day.late,
                color: const Color(0xFFF59E0B),
                icon: AppIcons.scheduleRounded,
                onTap: day.late == 0
                    ? null
                    : () => onOpen(TeacherAttendanceStatus.late, 'Late Comers'),
              ),
            ),
            const SizedBox(width: AppSpacing.stackSm),
            Expanded(
              child: _Tile(
                label: 'On Leave',
                value: day.onLeave,
                color: AppColors.primary,
                icon: AppIcons.eventBusyOutlined,
                onTap: day.onLeave == 0
                    ? null
                    : () => onOpen(TeacherAttendanceStatus.onLeave, 'On Leave'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Tile extends StatelessWidget {
  final String label;
  final int value;
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
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.stackMd),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    label,
                    style: AppTypography.labelMd.copyWith(color: color),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (onTap != null)
                  Icon(AppIcons.chevronRightRounded, size: 16, color: color),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '$value',
              style: AppTypography.headlineLg.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UnmarkedBanner extends StatelessWidget {
  final int count;
  final VoidCallback onTap;
  const _UnmarkedBanner({required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.button),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.stackMd),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(AppRadius.button),
          border: Border.all(color: AppColors.outlineVariant),
        ),
        child: Row(
          children: [
            const Icon(
              AppIcons.helpOutlineRounded,
              size: 18,
              color: AppColors.onSurfaceVariant,
            ),
            const SizedBox(width: AppSpacing.stackSm),
            Expanded(
              child: Text(
                '$count teacher${count == 1 ? "" : "s"} not yet marked',
                style: AppTypography.bodyMd.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ),
            const Icon(
              AppIcons.chevronRightRounded,
              size: 18,
              color: AppColors.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}
