import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared/shared.dart';

import '../../../data/teacher_repository.dart';
import '../models/timetable_slot.dart';
import '../../../../../widgets/skeletons.dart';

/// Teacher schedule — a horizontally scrollable week strip on top, the selected
/// day's periods below.
///
/// Periods come from the real timetable (`/academic/me/timetable`), so the
/// "starts in N min" banner is computed against actual clock times, and a
/// period counts as finished once its attendance has been marked.
class CalendarView extends StatefulWidget {
  const CalendarView({super.key});

  @override
  State<CalendarView> createState() => _CalendarViewState();
}

class _CalendarViewState extends State<CalendarView> {
  static const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  static const _months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  /// How many weeks either side of today the strip can scroll.
  static const _weeksBack = 8;
  static const _weeksForward = 16;

  final TeacherRepository _repo = Get.find<TeacherRepository>();

  late DateTime _selected;
  late final DateTime _firstDay;
  late final ScrollController _strip;

  bool _loading = true;
  String? _error;
  List<TeacherSlot> _slots = const [];

  /// Drives the countdown text so "starts in 10 min" stays honest without a
  /// rebuild storm — one tick a minute is enough resolution for a timetable.
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selected = DateTime(now.year, now.month, now.day);
    _firstDay = _mondayOf(_selected).subtract(const Duration(days: 7 * _weeksBack));
    _strip = ScrollController(
      // Open on the current week rather than the first scrollable one.
      initialScrollOffset: _weeksBack * 7 * _dayExtent,
    );
    _load();
    _tick = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    _strip.dispose();
    super.dispose();
  }

  static const double _dayExtent = 60; // width + separator of one day chip

  static DateTime _mondayOf(DateTime d) =>
      DateTime(d.year, d.month, d.day).subtract(Duration(days: d.weekday - 1));

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final res = await _repo.loadMyTimetable(onDate: _selected);
    if (!mounted) return;
    setState(() {
      if (res.success) {
        _slots = res.data ?? const [];
      } else {
        _error = res.error ?? 'Could not load your timetable.';
      }
      _loading = false;
    });
  }

  void _selectDay(DateTime day) {
    if (_sameDay(day, _selected)) return;
    setState(() => _selected = day);
    // attendance_marked is per-date, so the day's periods must be re-fetched.
    _load();
  }

  /// The selected day's periods, in start order.
  List<TeacherSlot> get _daySlots {
    final wanted = _selected.weekday - 1; // DateTime: Mon=1 → backend Mon=0
    return _slots.where((s) => s.dayOfWeek == wanted).toList()
      ..sort((a, b) => a.start.compareTo(b.start));
  }

  /// The next period that has not started yet, on today only — the one the
  /// banner counts down to. Null on any other day, or once the day is over.
  TeacherSlot? get _upNext {
    final now = DateTime.now();
    if (!_sameDay(_selected, now)) return null;
    for (final s in _daySlots) {
      if (s.attendanceMarked) continue;
      if (s.endsOn(now).isAfter(now)) return s;
    }
    return null;
  }

  String get _selectedLabel =>
      '${_months[_selected.month - 1]} ${_selected.day}, ${_selected.year}';

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(title: const Text('Schedule')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _weekStrip(),
          const Divider(height: 1, color: AppColors.outlineVariant),
          Expanded(child: _dayBody()),
        ],
      ),
    );
  }

  // ------------------------------ week strip ------------------------------ //

  Widget _weekStrip() {
    final today = DateTime.now();
    const totalDays = (_weeksBack + _weeksForward) * 7;
    return SizedBox(
      height: 92,
      child: ListView.builder(
        controller: _strip,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.containerPaddingMobile,
            vertical: AppSpacing.stackSm),
        itemCount: totalDays,
        itemExtent: _dayExtent,
        itemBuilder: (context, i) {
          final day = _firstDay.add(Duration(days: i));
          return _DayChip(
            label: _weekdays[day.weekday - 1],
            dayNumber: day.day,
            selected: _sameDay(day, _selected),
            isToday: _sameDay(day, today),
            onTap: () => _selectDay(day),
          );
        },
      ),
    );
  }

  // ------------------------------- day body ------------------------------- //

  Widget _dayBody() {
    if (_loading) {
      return const Shimmer(
        child: Padding(
          padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.containerPaddingMobile),
          child: SkeletonCardList(count: 4, height: 88),
        ),
      );
    }
    if (_error != null) {
      return _Empty(icon: AppIcons.cloudOffRounded, message: _error!, onRetry: _load);
    }

    final slots = _daySlots;
    final next = _upNext;
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.containerPaddingMobile,
            AppSpacing.stackMd,
            AppSpacing.containerPaddingMobile,
            AppSpacing.stackXl),
        children: [
          Text(_selectedLabel,
              style: AppTypography.headlineLg.copyWith(fontSize: 22)),
          const SizedBox(height: 2),
          Text(
            slots.isEmpty
                ? 'No periods scheduled.'
                : '${slots.length} period${slots.length == 1 ? '' : 's'} scheduled.',
            style: AppTypography.bodyLg,
          ),
          if (next != null) ...[
            const SizedBox(height: AppSpacing.stackMd),
            _UpNextBanner(slot: next, day: _selected),
          ],
          const SizedBox(height: AppSpacing.stackLg),
          if (slots.isEmpty)
            const _Empty(
              icon: AppIcons.eventAvailableOutlined,
              message: 'Nothing on the timetable for this day.',
            )
          else
            for (final s in slots) ...[
              _PeriodCard(
                slot: s,
                onFinish: s.attendanceMarked ? null : () => _finish(s),
              ),
              const SizedBox(height: AppSpacing.stackMd),
            ],
        ],
      ),
    );
  }

  /// "Finishing" a period means recording its attendance — that is what makes
  /// the session real in the backend, and what flips [TeacherSlot.attendanceMarked].
  ///
  /// The existing attendance screen can't take that job yet: its controller
  /// reads [Get.arguments] as an `AttendanceClass` (so a period would silently
  /// mark the wrong class), and its roster and save still run off mock
  /// fixtures. Rather than route into it and appear to work, this states the
  /// gap until that flow is wired to `POST /schools/{id}/attendance`.
  Future<void> _finish(TeacherSlot slot) async {
    Get.snackbar(
      'Not wired up yet',
      'Marking a period needs the attendance screen connected to the backend. '
          'Periods still show as done once their attendance exists.',
      snackPosition: SnackPosition.BOTTOM,
    );
  }
}

// ------------------------------- components ------------------------------- //

class _DayChip extends StatelessWidget {
  final String label;
  final int dayNumber;
  final bool selected;
  final bool isToday;
  final VoidCallback onTap;

  const _DayChip({
    required this.label,
    required this.dayNumber,
    required this.selected,
    required this.isToday,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final fg = selected ? AppColors.onPrimary : AppColors.onSurface;
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.stackSm),
      child: Material(
        color: selected ? AppColors.primary : AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.sm),
              border: Border.all(
                color: isToday && !selected
                    ? AppColors.primary
                    : AppColors.outlineVariant,
                width: isToday && !selected ? 1.5 : 1,
              ),
            ),
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(label,
                    style: AppTypography.labelMd.copyWith(
                      color: selected ? AppColors.onPrimary : AppColors.onSurfaceVariant,
                    )),
                const SizedBox(height: 2),
                Text('$dayNumber',
                    style: AppTypography.titleMd
                        .copyWith(color: fg, fontWeight: FontWeight.w800)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The "starts in N min" / "in progress" banner for the next period today.
class _UpNextBanner extends StatelessWidget {
  final TeacherSlot slot;
  final DateTime day;
  const _UpNextBanner({required this.slot, required this.day});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final start = slot.startsOn(day);
    final live = !start.isAfter(now);
    final until = start.difference(now);

    final (label, accent, icon) = live
        ? ('In progress now', AppColors.tertiary, AppIcons.playCircleOutline)
        : (
            'Starts in ${_humanise(until)}',
            until.inMinutes <= 15 ? AppColors.error : AppColors.primary,
            AppIcons.scheduleRounded,
          );

    return GlassSurface(
      padding: const EdgeInsets.all(AppSpacing.stackMd),
      fill: accent.withValues(alpha: 0.08),
      child: Row(
        children: [
          Icon(icon, color: accent),
          const SizedBox(width: AppSpacing.stackMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: AppTypography.labelCaps.copyWith(
                        color: accent, fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                Text(slot.title,
                    style: AppTypography.titleMd
                        .copyWith(fontWeight: FontWeight.w700)),
                Text('${slot.timeRange}${slot.room == null ? '' : ' · ${slot.room}'}',
                    style: AppTypography.bodySm),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// "45 min" / "2 h 10 min" — hours only appear when they matter.
  static String _humanise(Duration d) {
    if (d.inMinutes < 1) return 'less than a minute';
    if (d.inMinutes < 60) return '${d.inMinutes} min';
    final h = d.inHours;
    final m = d.inMinutes % 60;
    return m == 0 ? '$h h' : '$h h $m min';
  }
}

class _PeriodCard extends StatelessWidget {
  final TeacherSlot slot;

  /// Null once the period is finished, which disables the action.
  final VoidCallback? onFinish;

  const _PeriodCard({
    required this.slot,
    this.onFinish,
  });

  @override
  Widget build(BuildContext context) {
    final done = slot.attendanceMarked;

    return GlassSurface(
      padding: const EdgeInsets.all(AppSpacing.stackMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(slot.timeRange,
                  style: AppTypography.titleMd
                      .copyWith(fontWeight: FontWeight.w800)),
              const Spacer(),
              if (done)
                const _Pill(
                  label: 'Done',
                  color: AppColors.tertiary,
                  icon: AppIcons.checkCircleRounded,
                )
              else if (slot.isClassTeacher)
                const _Pill(
                  label: 'Class teacher',
                  color: AppColors.primary,
                  icon: AppIcons.starRounded,
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(slot.title,
              style: AppTypography.titleMd
                  .copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Wrap(
            spacing: AppSpacing.stackMd,
            runSpacing: 4,
            children: [
              if (slot.room != null)
                _Meta(icon: AppIcons.locationOnOutlined, text: slot.room!),
              if (slot.studentCount > 0)
                _Meta(
                  icon: AppIcons.peopleAltOutlined,
                  text: '${slot.studentCount} students',
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.stackMd),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onFinish,
              icon: Icon(done
                  ? AppIcons.checkCircleOutline
                  : AppIcons.factCheckOutlined),
              label: Text(done
                  ? 'Attendance recorded'
                  : 'Mark attendance & finish'),
              style: OutlinedButton.styleFrom(
                foregroundColor:
                    done ? AppColors.tertiary : AppColors.primary,
                side: BorderSide(
                  color: done
                      ? AppColors.tertiary
                      : AppColors.outlineVariant,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.button),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;
  const _Pill({required this.label, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(label,
              style: AppTypography.labelMd
                  .copyWith(color: color, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  final IconData icon;
  final String text;
  const _Meta({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: AppColors.onSurfaceVariant),
        const SizedBox(width: 4),
        Text(text, style: AppTypography.bodySm),
      ],
    );
  }
}

class _Empty extends StatelessWidget {
  final IconData icon;
  final String message;
  final VoidCallback? onRetry;
  const _Empty({required this.icon, required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.stackXl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 40, color: AppColors.outline),
          const SizedBox(height: AppSpacing.stackMd),
          Text(message, style: AppTypography.bodyLg, textAlign: TextAlign.center),
          if (onRetry != null) ...[
            const SizedBox(height: AppSpacing.stackMd),
            TextButton(onPressed: onRetry, child: const Text('Try again')),
          ],
        ],
      ),
    );
  }
}
