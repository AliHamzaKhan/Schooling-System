import 'package:flutter/material.dart';

import '../admin_theme.dart';
import 'admin_surface.dart';

/// Row with a section title on the left and an optional trailing action
/// (e.g. "View All") on the right.
class SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  /// Renders the title at page-section scale rather than card scale.
  final bool large;

  const SectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
    this.large = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Flexible(
          child: Text(
            title,
            style: large ? AdminType.sectionTitle : AdminType.cardTitle,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (actionLabel != null)
          AdminInlineAction(label: actionLabel!, onTap: onAction),
      ],
    );
  }
}
