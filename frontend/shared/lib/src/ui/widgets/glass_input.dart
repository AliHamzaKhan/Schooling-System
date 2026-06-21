import 'package:flutter/material.dart';

import '../tokens/app_colors.dart';
import '../tokens/app_elevation.dart';
import '../tokens/app_radius.dart';
import '../tokens/app_typography.dart';

/// Minimalist input field — only a bottom border at rest, expands to a full
/// glass container on focus (per DESIGN.md component spec).
class GlassInput extends StatefulWidget {
  final String? label;
  final String? hint;
  final TextEditingController? controller;
  final TextInputType keyboardType;
  final bool obscureText;
  final bool autofocus;
  final IconData? prefixIcon;
  final Widget? suffix;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final FocusNode? focusNode;
  final String? errorText;

  const GlassInput({
    super.key,
    this.label,
    this.hint,
    this.controller,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.autofocus = false,
    this.prefixIcon,
    this.suffix,
    this.onChanged,
    this.onSubmitted,
    this.focusNode,
    this.errorText,
  });

  @override
  State<GlassInput> createState() => _GlassInputState();
}

class _GlassInputState extends State<GlassInput> {
  late final FocusNode _focusNode;
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_handleFocus);
  }

  void _handleFocus() => setState(() => _focused = _focusNode.hasFocus);

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocus);
    if (widget.focusNode == null) _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasError = widget.errorText != null;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      padding: EdgeInsets.symmetric(horizontal: _focused ? 5 : 0, vertical: _focused ? 4 : 0),
      decoration: BoxDecoration(
        color: _focused ? AppElevation.l1Fill : Colors.transparent,
        borderRadius: BorderRadius.circular(
          _focused ? AppRadius.button : 0,
        ),
        border: Border.all(
          color: _focused
              ? AppColors.glassBorder
              : Colors.transparent,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.label != null) ...[
            Text(widget.label!.toUpperCase(),
                style: AppTypography.labelCaps.copyWith(color: AppColors.onSurfaceVariant)),
            const SizedBox(height: 4),
          ],
          Row(
            children: [
              if (widget.prefixIcon != null) ...[
                Icon(widget.prefixIcon, size: 18, color: AppColors.onSurfaceVariant),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: TextField(
                  controller: widget.controller,
                  focusNode: _focusNode,
                  autofocus: widget.autofocus,
                  keyboardType: widget.keyboardType,
                  obscureText: widget.obscureText,
                  onChanged: widget.onChanged,
                  onSubmitted: widget.onSubmitted,
                  style: AppTypography.bodyLg.copyWith(color: AppColors.onSurface),
                  decoration: InputDecoration(
                    hintText: widget.hint,
                    hintStyle: AppTypography.bodyLg.copyWith(color: AppColors.outline),
                    isCollapsed: true,
                    // GlassInput draws its own container — keep the inner field
                    // fully borderless/unfilled regardless of the global theme.
                    filled: false,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    focusedErrorBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
              if (widget.suffix != null) widget.suffix!,
            ],
          ),
          if (hasError) ...[
            const SizedBox(height: 4),
            Text(widget.errorText!, style: AppTypography.bodySm.copyWith(color: AppColors.error)),
          ],
        ],
      ),
    );
  }
}
