import 'package:flutter/material.dart';

import '../../../data/models/dashboard_stats.dart';
import '../../../ui/admin_theme.dart';
import '../../../ui/admin_widgets/admin_surface.dart';

/// One row in the Recent Alerts feed — leading severity chip, title + body,
/// and a time stamp. Severity drives the chip color only; the row itself stays
/// on the flat card surface.
class AlertTile extends StatelessWidget {
  final AdminAlert alert;
  const AlertTile({super.key, required this.alert});

  @override
  Widget build(BuildContext context) {
    final (fg, bg, icon) = switch (alert.severity) {
      AlertSeverity.critical => (
          AdminPalette.danger,
          AdminPalette.dangerSoft,
          Icons.warning_amber_rounded,
        ),
      AlertSeverity.warning => (
          AdminPalette.warning,
          AdminPalette.warningSoft,
          Icons.schedule_rounded,
        ),
      AlertSeverity.info => (
          AdminPalette.ink,
          AdminPalette.tint,
          Icons.group_add_rounded,
        ),
    };

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AdminIconTile(icon: icon, size: 38, background: bg, foreground: fg),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: Text(alert.title, style: AdminType.rowTitle)),
                  const SizedBox(width: 8),
                  Text(alert.timeAgo,
                      style: AdminType.meta.copyWith(
                          fontSize: 12, color: AdminPalette.faint)),
                ],
              ),
              const SizedBox(height: 3),
              Text(alert.body, style: AdminType.meta),
            ],
          ),
        ),
      ],
    );
  }
}
