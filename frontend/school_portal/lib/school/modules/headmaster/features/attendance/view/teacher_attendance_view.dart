import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared/shared.dart';

import '../../../data/headmaster_repository.dart';
import '../models/teacher_attendance_day.dart';
import '../../../../../widgets/skeletons.dart';

/// Teacher Attendance — headmaster marks each teacher present / absent / late
/// (with arrival time) for the selected date, then saves in bulk.
class TeacherAttendanceView extends StatefulWidget {
  const TeacherAttendanceView({super.key});

  @override
  State<TeacherAttendanceView> createState() =>
      _TeacherAttendanceViewState();
}

class _TeacherAttendanceViewState extends State<TeacherAttendanceView> {
  final _repo = Get.find<HeadmasterRepository>();

  final _date = Rx<DateTime>(DateTime.now());
  final _day = Rxn<TeacherAttendanceDay>();
  final _draft = <String, TeacherAttendanceRow>{}.obs; // teacher_id → row
  final _loading = true.obs;
  final _saving = false.obs;
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
      _draft.value = {
        for (final r in res.data!.entries) r.teacherId: r,
      };
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

  Future<void> _pickArrival(TeacherAttendanceRow row) async {
    final now = TimeOfDay.now();
    final initial = row.arrivalTime == null
        ? now
        : _parseTime(row.arrivalTime!) ?? now;
    final picked =
        await showTimePicker(context: context, initialTime: initial);
    if (picked == null) return;
    _draft[row.teacherId] = row.copyWith(
      arrivalTime:
          '${picked.hour.toString().padLeft(2, "0")}:${picked.minute.toString().padLeft(2, "0")}',
    );
  }

  static TimeOfDay? _parseTime(String s) {
    final parts = s.split(':');
    if (parts.length < 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    return TimeOfDay(hour: h, minute: m);
  }

  void _setStatus(
      TeacherAttendanceRow row, TeacherAttendanceStatus status) {
    // Auto-fill "Present" with current time when moving out of unmarked
    // so headmasters don't have to open the picker for the common case.
    String? arrival = row.arrivalTime;
    if ((status == TeacherAttendanceStatus.present ||
            status == TeacherAttendanceStatus.late) &&
        arrival == null) {
      final now = TimeOfDay.now();
      arrival =
          '${now.hour.toString().padLeft(2, "0")}:${now.minute.toString().padLeft(2, "0")}';
    }
    _draft[row.teacherId] = row.copyWith(status: status, arrivalTime: arrival);
  }

  Future<void> _save() async {
    _saving.value = true;
    final entries = <Map<String, dynamic>>[];
    for (final row in _draft.values) {
      if (row.status == TeacherAttendanceStatus.unmarked) continue;
      entries.add({
        'teacher_id': row.teacherId,
        'status': row.status.wire,
        if (row.arrivalTime != null) 'arrival_time': row.arrivalTime,
      });
    }
    if (entries.isEmpty) {
      _saving.value = false;
      Get.snackbar(
        'Nothing to save',
        'Mark at least one teacher before saving.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    final res = await _repo.markTeacherAttendance(
      date: _date.value,
      entries: entries,
    );
    _saving.value = false;
    if (res.success) {
      Get.back();
      Get.snackbar('Attendance saved',
          'Marked ${entries.length} teachers for ${_fmt(_date.value)}',
          snackPosition: SnackPosition.BOTTOM);
    } else {
      Get.snackbar('Could not save',
          res.error ?? 'Please try again.',
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  String _fmt(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(
        title: const Text('Teacher Attendance'),
        backgroundColor: AppColors.surface,
      ),
      body: Obx(() {
        if (_loading.value && _day.value == null) {
          return const SkeletonPage(body: SkeletonRosterList());
        }
        if (_error.value != null && _day.value == null) {
          return Center(
              child: Text(_error.value!, style: AppTypography.bodyLg));
        }
        final day = _day.value;
        if (day == null || day.totalTeachers == 0) {
          return Center(
            child: Text('No teachers to mark.', style: AppTypography.bodyLg),
          );
        }
        final rows = _draft.values.toList();
        return Column(
          children: [
            _Header(
              date: _date.value,
              day: day,
              onPickDate: _pickDate,
              formatted: _fmt(_date.value),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.containerPaddingMobile,
                  AppSpacing.stackMd,
                  AppSpacing.containerPaddingMobile,
                  AppSpacing.stackXl,
                ),
                itemCount: rows.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: AppSpacing.stackSm),
                itemBuilder: (_, i) => _TeacherAttendanceTile(
                  row: rows[i],
                  onStatus: (s) => _setStatus(rows[i], s),
                  onPickArrival: () => _pickArrival(rows[i]),
                ),
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.containerPaddingMobile,
                  0,
                  AppSpacing.containerPaddingMobile,
                  AppSpacing.stackMd,
                ),
                child: Obx(() => PrimaryButton(
                      label: 'Save Attendance',
                      isLoading: _saving.value,
                      expanded: true,
                      onPressed: _saving.value ? null : _save,
                    )),
              ),
            ),
          ],
        );
      }),
    );
  }
}

class _Header extends StatelessWidget {
  final DateTime date;
  final TeacherAttendanceDay day;
  final VoidCallback onPickDate;
  final String formatted;
  const _Header({
    required this.date,
    required this.day,
    required this.onPickDate,
    required this.formatted,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.containerPaddingMobile,
        AppSpacing.stackMd,
        AppSpacing.containerPaddingMobile,
        AppSpacing.stackSm,
      ),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.stackMd),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(color: AppColors.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: onPickDate,
              borderRadius: BorderRadius.circular(AppRadius.button),
              child: Row(
                children: [
                  const Icon(AppIcons.calendarTodayOutlined,
                      size: 18, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(formatted, style: AppTypography.titleMd),
                  const Spacer(),
                  Text('Change',
                      style: AppTypography.labelMd
                          .copyWith(color: AppColors.primary)),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.stackSm),
            Row(
              children: [
                _CountChip(label: 'Present', value: day.present,
                    color: AppColors.tertiary),
                const SizedBox(width: 6),
                _CountChip(label: 'Late', value: day.late,
                    color: const Color(0xFFF59E0B)),
                const SizedBox(width: 6),
                _CountChip(label: 'Absent', value: day.absent,
                    color: AppColors.error),
                const SizedBox(width: 6),
                _CountChip(label: 'Unmarked', value: day.unmarked,
                    color: AppColors.onSurfaceVariant),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CountChip extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  const _CountChip(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(AppRadius.button),
        ),
        child: Column(
          children: [
            Text('$value',
                style: AppTypography.titleLg
                    .copyWith(color: color, fontWeight: FontWeight.w700)),
            Text(label,
                style:
                    AppTypography.labelMd.copyWith(color: color)),
          ],
        ),
      ),
    );
  }
}

class _TeacherAttendanceTile extends StatelessWidget {
  final TeacherAttendanceRow row;
  final ValueChanged<TeacherAttendanceStatus> onStatus;
  final VoidCallback onPickArrival;
  const _TeacherAttendanceTile({
    required this.row,
    required this.onStatus,
    required this.onPickArrival,
  });

  static const _options = [
    TeacherAttendanceStatus.present,
    TeacherAttendanceStatus.late,
    TeacherAttendanceStatus.absent,
    TeacherAttendanceStatus.onLeave,
  ];

  static Color _color(TeacherAttendanceStatus s) => switch (s) {
        TeacherAttendanceStatus.present => AppColors.tertiary,
        TeacherAttendanceStatus.late => const Color(0xFFF59E0B),
        TeacherAttendanceStatus.absent => AppColors.error,
        TeacherAttendanceStatus.onLeave => AppColors.primary,
        TeacherAttendanceStatus.unmarked => AppColors.onSurfaceVariant,
      };

  @override
  Widget build(BuildContext context) {
    final needsArrival = row.status == TeacherAttendanceStatus.present ||
        row.status == TeacherAttendanceStatus.late;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.stackMd),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor:
                    AppColors.primary.withValues(alpha: 0.12),
                child: Text(
                  row.teacherName.isNotEmpty
                      ? row.teacherName[0].toUpperCase()
                      : '?',
                  style: AppTypography.titleMd
                      .copyWith(color: AppColors.primary),
                ),
              ),
              const SizedBox(width: AppSpacing.stackSm),
              Expanded(
                child: Text(row.teacherName, style: AppTypography.bodyLg),
              ),
              if (needsArrival)
                InkWell(
                  onTap: onPickArrival,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(AppRadius.full),
                      border: Border.all(color: AppColors.outlineVariant),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(AppIcons.scheduleRounded,
                            size: 14, color: AppColors.primary),
                        const SizedBox(width: 4),
                        Text(
                          row.arrivalTime == null
                              ? 'Set arrival'
                              : row.arrivalTime!.substring(0,
                                  row.arrivalTime!.length.clamp(0, 5)),
                          style: AppTypography.labelMd,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.stackSm),
          Row(
            children: [
              for (final s in _options) ...[
                Expanded(
                  child: _StatusPill(
                    status: s,
                    selected: row.status == s,
                    onTap: () => onStatus(s),
                  ),
                ),
                if (s != _options.last) const SizedBox(width: 6),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final TeacherAttendanceStatus status;
  final bool selected;
  final VoidCallback onTap;
  const _StatusPill({
    required this.status,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = _TeacherAttendanceTile._color(status);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.button),
      child: Container(
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.16) : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.button),
          border: Border.all(
            color: selected ? color : AppColors.outlineVariant,
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Text(status.label,
            style: AppTypography.labelMd.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            )),
      ),
    );
  }
}
