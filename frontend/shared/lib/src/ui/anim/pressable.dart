import 'package:flutter/material.dart';

import '../widgets/focus_ring.dart';
import 'app_motion.dart';

/// A tap target that scales down slightly while pressed — gives buttons and
/// cards a tactile, responsive feel.
class Pressable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scale;
  final BorderRadius? borderRadius;

  const Pressable({
    super.key,
    required this.child,
    this.onTap,
    this.scale = 0.97,
    this.borderRadius,
  });

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;

  void _set(bool v) {
    if (widget.onTap == null) return;
    if (_down != v) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    // Announced as a button, focusable, and activated by Enter/Space.
    return Semantics(
      container: true,
      button: true,
      enabled: enabled,
      child: FocusRing(
        borderRadius: widget.borderRadius ?? BorderRadius.circular(8),
        child: FocusableActionDetector(
          enabled: enabled,
          mouseCursor: enabled ? SystemMouseCursors.click : MouseCursor.defer,
          actions: {
            ActivateIntent: CallbackAction<ActivateIntent>(
              onInvoke: (_) {
                widget.onTap?.call();
                return null;
              },
            ),
          },
          child: GestureDetector(
            onTapDown: (_) => _set(true),
            onTapUp: (_) => _set(false),
            onTapCancel: () => _set(false),
            onTap: widget.onTap,
            child: AnimatedScale(
              scale: _down ? widget.scale : 1.0,
              duration: AppMotion.fast,
              curve: AppMotion.standard,
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}
