import 'package:flutter/material.dart';

import '../tokens/app_colors.dart';

/// Visible keyboard-focus indicator for custom controls (WCAG 2.4.7).
///
/// Gradient and glass fills hide the default ink focus highlight, so a 2 px
/// outline is drawn outside [child] while any descendant holds keyboard focus.
/// Pointer focus does not show the ring.
class FocusRing extends StatefulWidget {
  final Widget child;
  final BorderRadius borderRadius;

  const FocusRing({super.key, required this.child, required this.borderRadius});

  @override
  State<FocusRing> createState() => _FocusRingState();
}

class _FocusRingState extends State<FocusRing> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final visible =
        _focused &&
        FocusManager.instance.highlightMode == FocusHighlightMode.traditional;
    return Focus(
      canRequestFocus: false,
      skipTraversal: true,
      onFocusChange: (focused) => setState(() => _focused = focused),
      child: DecoratedBox(
        position: DecorationPosition.foreground,
        decoration: BoxDecoration(
          borderRadius: widget.borderRadius.add(BorderRadius.circular(3)),
          border: Border.all(
            color: visible ? AppColors.onSurface : Colors.transparent,
            width: 2,
            strokeAlign: BorderSide.strokeAlignOutside,
          ),
        ),
        child: widget.child,
      ),
    );
  }
}
