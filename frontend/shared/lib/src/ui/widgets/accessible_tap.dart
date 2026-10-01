import 'package:flutter/material.dart';

import 'focus_ring.dart';

/// A custom tap target that is also a real control: announced as a button,
/// reachable with Tab, activated with Enter/Space and showing a focus ring.
///
/// Use instead of a bare [GestureDetector] for anything a user can act on.
class AccessibleTap extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final HitTestBehavior? behavior;
  final bool? selected;
  final BorderRadius borderRadius;

  const AccessibleTap({
    super.key,
    required this.child,
    this.onTap,
    this.behavior,
    this.selected,
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Semantics(
      container: true,
      button: true,
      enabled: enabled,
      selected: selected,
      child: FocusRing(
        borderRadius: borderRadius,
        child: FocusableActionDetector(
          enabled: enabled,
          mouseCursor: enabled ? SystemMouseCursors.click : MouseCursor.defer,
          actions: {
            ActivateIntent: CallbackAction<ActivateIntent>(
              onInvoke: (_) {
                onTap?.call();
                return null;
              },
            ),
          },
          child: GestureDetector(behavior: behavior, onTap: onTap, child: child),
        ),
      ),
    );
  }
}
