import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

/// One "Island Pulse" KPI shown on the School Overview.
class PulseMetric {
  final String label;
  final String value;
  final IconData icon;
  final Color accent;

  /// Trend caption such as "+2.4%", "98%", or "Stable". Renders as a small pill
  /// in the top-right corner.
  final String? trendLabel;
  final Color? trendColor;
  final IconData? trendIcon;

  const PulseMetric({
    required this.label,
    required this.value,
    required this.icon,
    required this.accent,
    this.trendLabel,
    this.trendColor,
    this.trendIcon,
  });

  factory PulseMetric.fromJson(Map<String, dynamic> json) => PulseMetric(
        label: json['label'] as String? ?? '',
        value: '${json['value'] ?? ''}',
        // icon/accent are presentation only — defaulted, not from the API.
        icon: Icons.insights_rounded,
        accent: AppColors.primary,
        trendLabel: json['trend_label'] as String?,
      );
}

/// One event in the Upcoming Events horizontal carousel.
class UpcomingEvent {
  final String id;
  final String title;
  final String time;
  final String location;
  final String month; // "OCT"
  final String day;   // "12"
  final Color tint;
  final IconData icon;
  const UpcomingEvent({
    required this.id,
    required this.title,
    required this.time,
    required this.location,
    required this.month,
    required this.day,
    required this.tint,
    required this.icon,
  });

  factory UpcomingEvent.fromJson(Map<String, dynamic> json) => UpcomingEvent(
        id: '${json['id']}',
        title: json['title'] as String? ?? '',
        time: json['time'] as String? ?? '',
        location: json['location'] as String? ?? '',
        month: json['month'] as String? ?? '',
        day: '${json['day'] ?? ''}',
        // tint/icon are presentation only — defaulted, not from the API.
        tint: AppColors.primary,
        icon: Icons.event_rounded,
      );
}

/// Identity card on the top of the screen.
class SchoolIdentity {
  final String name;
  final String address;
  final String principal;
  const SchoolIdentity({
    required this.name,
    required this.address,
    required this.principal,
  });

  factory SchoolIdentity.fromJson(Map<String, dynamic> json) => SchoolIdentity(
        name: json['name'] as String? ?? '',
        address: json['address'] as String? ?? '',
        principal: json['principal'] as String? ?? '',
      );
}

class OverviewData {
  final SchoolIdentity school;
  final List<PulseMetric> pulse;
  final List<UpcomingEvent> events;
  const OverviewData({required this.school, required this.pulse, required this.events});

  factory OverviewData.fromJson(Map<String, dynamic> json) => OverviewData(
        school: SchoolIdentity.fromJson(
            (json['school'] as Map<String, dynamic>?) ?? const {}),
        pulse: ((json['pulse'] as List?) ?? [])
            .map((e) => PulseMetric.fromJson(e as Map<String, dynamic>))
            .toList(),
        events: ((json['events'] as List?) ?? [])
            .map((e) => UpcomingEvent.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
