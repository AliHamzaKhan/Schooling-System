import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../ui/tokens/app_colors.dart';
import '../../../../ui/tokens/app_radius.dart';
import '../../../../ui/tokens/app_typography.dart';

/// Segmented N-box code field with auto-advance + backspace handling.
/// Emits the concatenated code via [onChanged] and fires [onCompleted] when
/// all boxes are filled.
class OtpInput extends StatefulWidget {
  final int length;
  final ValueChanged<String> onChanged;
  final VoidCallback? onCompleted;

  const OtpInput({
    super.key,
    this.length = 6,
    required this.onChanged,
    this.onCompleted,
  });

  @override
  State<OtpInput> createState() => _OtpInputState();
}

class _OtpInputState extends State<OtpInput> {
  late final List<TextEditingController> _controllers;
  late final List<FocusNode> _nodes;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(widget.length, (_) => TextEditingController());
    _nodes = List.generate(widget.length, (_) => FocusNode());
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final n in _nodes) {
      n.dispose();
    }
    super.dispose();
  }

  String get _code => _controllers.map((c) => c.text).join();

  void _onChanged(int i, String v) {
    if (v.length > 1) {
      // Pasted / autofilled — distribute across boxes from index i.
      final chars = v.replaceAll(RegExp(r'\D'), '').split('');
      for (var j = 0; j < chars.length && i + j < widget.length; j++) {
        _controllers[i + j].text = chars[j];
      }
      final next = (i + chars.length).clamp(0, widget.length - 1);
      _nodes[next].requestFocus();
    } else if (v.isNotEmpty && i < widget.length - 1) {
      _nodes[i + 1].requestFocus();
    }
    _emit();
  }

  void _onKey(int i, KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace &&
        _controllers[i].text.isEmpty &&
        i > 0) {
      _nodes[i - 1].requestFocus();
      _controllers[i - 1].clear();
      _emit();
    }
  }

  void _emit() {
    final code = _code;
    widget.onChanged(code);
    if (code.length == widget.length) widget.onCompleted?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        for (var i = 0; i < widget.length; i++)
          Flexible(
            child: Padding(
              padding: EdgeInsets.only(right: i == widget.length - 1 ? 0 : 8),
              child: AspectRatio(
                aspectRatio: 0.82,
                child: KeyboardListener(
                  focusNode: FocusNode(skipTraversal: true),
                  onKeyEvent: (e) => _onKey(i, e),
                  child: TextField(
                    controller: _controllers[i],
                    focusNode: _nodes[i],
                    autofocus: i == 0,
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    maxLength: 1,
                    style: AppTypography.headlineLg,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      counterText: '',
                      filled: true,
                      fillColor: AppColors.surfaceContainerLow,
                      contentPadding: EdgeInsets.zero,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.defaultR),
                        borderSide: const BorderSide(color: AppColors.outlineVariant),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.defaultR),
                        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                      ),
                    ),
                    onChanged: (v) => _onChanged(i, v),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
