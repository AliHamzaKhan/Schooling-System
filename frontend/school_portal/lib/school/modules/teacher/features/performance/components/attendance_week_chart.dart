import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

import '../models/performance_data.dart';

/// Compact 5-bar weekday chart: Present marks render as full-height amber
/// bars; Absent marks leave the column empty. "Present" / "Absent" labels sit
/// on the left axis.
class AttendanceWeekChart extends StatelessWidget {
  final List<WeekDay> week;
  const AttendanceWeekChart({super.key, required this.week});

  static const _color = Color(0xFFE8A317);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 170,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 56,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text('Present', style: AppTypography.labelCaps),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 22),
                  child: Text('Absent', style: AppTypography.labelCaps),
                ),
              ],
            ),
          ),
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      for (final d in week) ...[
                        Expanded(
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 8),
                            decoration: BoxDecoration(
                              color: d.mark == DayMark.present
                                  ? _color
                                  : Colors.transparent,
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(AppRadius.sm)),
                            ),
                            height: d.mark == DayMark.present ? double.infinity : 0,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    for (final d in week)
                      Expanded(
                        child: Text(d.label,
                            textAlign: TextAlign.center,
                            style: AppTypography.bodySm),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
