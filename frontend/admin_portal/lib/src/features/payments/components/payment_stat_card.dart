import 'package:flutter/material.dart';

import '../../../ui/admin_theme.dart';
import '../../../ui/admin_widgets/admin_surface.dart';
import '../models/payments_data.dart';
import 'package:shared/shared.dart';

/// Compact billing KPI tile sized for a two-column grid: a small icon and an
/// uppercase label on top, the value below, and an optional caption line.
class PaymentStatCard extends StatelessWidget {
  final PaymentStat stat;
  const PaymentStatCard({super.key, required this.stat});

  @override
  Widget build(BuildContext context) {
    return AdminCard(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(stat.icon, size: 15, color: AdminPalette.faint),
              const SizedBox(width: 7),
              Expanded(
                child: Text(stat.label.toUpperCase(),
                    style: AdminType.overline,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
          const SizedBox(height: 12),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(stat.value, style: AdminType.metric),
          ),
          if (stat.caption != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(AppIcons.trendingUpRounded,
                    size: 13, color: stat.captionColor ?? AdminPalette.muted),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    stat.caption!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AdminType.meta.copyWith(
                      fontSize: 12,
                      color: stat.captionColor ?? AdminPalette.muted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
