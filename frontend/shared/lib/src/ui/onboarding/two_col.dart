import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

/// Two-column row that collapses to a single column on narrow widths.
class TwoCol extends StatelessWidget {
  final Widget left;
  final Widget right;
  final double gap;

  const TwoCol({super.key, required this.left, required this.right, this.gap = AppSpacing.stackLg});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 560) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [left, SizedBox(height: gap), right],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: left),
            SizedBox(width: gap),
            Expanded(child: right),
          ],
        );
      },
    );
  }
}
