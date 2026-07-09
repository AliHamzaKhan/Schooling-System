import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared/shared.dart';

import '../../../data/teacher_repository.dart';
import '../../dashboard/models/dashboard_data.dart';

/// Lightweight schedule calendar reached from the dashboard's "View Calendar".
/// A month picker on top, the selected day's class blocks below (sourced from
/// the same schedule the dashboard shows).
class CalendarView extends StatefulWidget {
  const CalendarView({super.key});

  @override
  State<CalendarView> createState() => _CalendarViewState();
}

class _CalendarViewState extends State<CalendarView> {
  final TeacherRepository _repo = Get.find<TeacherRepository>();

  DateTime _selected = DateTime.now();
  bool _loading = true;
  List<ScheduleItem> _schedule = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final res = await _repo.loadDashboard();
    if (!mounted) return;
    setState(() {
      _schedule = res.data?.schedule ?? const [];
      _loading = false;
    });
  }

  String get _selectedLabel {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return '${months[_selected.month - 1]} ${_selected.day}, ${_selected.year}';
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return AppScaffold(
      appBar: AppBar(title: const Text('Calendar')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.containerPaddingMobile,
                  AppSpacing.stackMd,
                  AppSpacing.containerPaddingMobile,
                  AppSpacing.stackXl),
              children: [
                GlassSurface(
                  padding: const EdgeInsets.all(AppSpacing.stackSm),
                  child: CalendarDatePicker(
                    initialDate: _selected,
                    firstDate: DateTime(now.year - 1),
                    lastDate: DateTime(now.year + 2),
                    onDateChanged: (d) => setState(() => _selected = d),
                  ),
                ),
                const SizedBox(height: AppSpacing.stackLg),
                Text(_selectedLabel, style: AppTypography.headlineLg.copyWith(fontSize: 22)),
                const SizedBox(height: AppSpacing.stackSm),
                Text('Scheduled blocks for this day.', style: AppTypography.bodyLg),
                const SizedBox(height: AppSpacing.stackMd),
                if (_schedule.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.stackXl),
                    child: Center(
                      child: Text('Nothing scheduled.', style: AppTypography.bodyLg),
                    ),
                  )
                else
                  for (final s in _schedule) ...[
                    _CalendarScheduleRow(item: s),
                    const SizedBox(height: AppSpacing.stackSm),
                  ],
              ],
            ),
    );
  }
}

class _CalendarScheduleRow extends StatelessWidget {
  final ScheduleItem item;
  const _CalendarScheduleRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      padding: EdgeInsets.zero,
      fill: item.isPlanning ? AppColors.surfaceContainerLow : null,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 5,
              decoration: BoxDecoration(
                color: item.railColor,
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(AppRadius.card),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.stackMd),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.time,
                      style: AppTypography.titleLg
                          .copyWith(fontWeight: FontWeight.w800)),
                  Text(item.period,
                      style: AppTypography.labelCaps
                          .copyWith(color: AppColors.onSurfaceVariant)),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    vertical: AppSpacing.stackMd, horizontal: AppSpacing.stackSm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(item.title,
                        style: AppTypography.titleMd
                            .copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined,
                            size: 13, color: AppColors.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Text(item.location, style: AppTypography.bodySm),
                        if (item.students > 0) ...[
                          const SizedBox(width: AppSpacing.stackMd),
                          const Icon(Icons.people_alt_outlined,
                              size: 13, color: AppColors.onSurfaceVariant),
                          const SizedBox(width: 4),
                          Text('${item.students} Students',
                              style: AppTypography.bodySm),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
