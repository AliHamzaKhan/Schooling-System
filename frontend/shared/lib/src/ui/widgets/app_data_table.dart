import 'package:flutter/material.dart';

import '../tokens/app_colors.dart';
import '../tokens/app_radius.dart';

/// Bordered, horizontally scrollable shell for Material data tables.
///
/// Horizontal scrolling is intentional: columns remain readable at 200% text
/// instead of compressing, clipping, or forcing an entire screen to overflow.
class AppDataTable extends StatelessWidget {
  final List<DataColumn> columns;
  final List<DataRow> rows;
  final String semanticLabel;
  final ScrollController? controller;

  const AppDataTable({
    super.key,
    required this.columns,
    required this.rows,
    required this.semanticLabel,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: semanticLabel,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            border: Border.all(color: AppColors.cardBorder),
            borderRadius: BorderRadius.circular(AppRadius.card),
          ),
          child: SingleChildScrollView(
            controller: controller,
            scrollDirection: Axis.horizontal,
            child: DataTable(columns: columns, rows: rows),
          ),
        ),
      ),
    );
  }
}
