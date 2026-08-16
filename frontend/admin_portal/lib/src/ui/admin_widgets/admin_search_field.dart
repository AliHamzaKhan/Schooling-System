import 'package:flutter/material.dart';

import '../admin_theme.dart';

/// Rounded white search field used at the top of list screens. Optional
/// trailing [action] (e.g. a filter button) sits to the right, outside the box.
class AdminSearchField extends StatelessWidget {
  final String hint;
  final ValueChanged<String>? onChanged;
  final TextEditingController? controller;
  final Widget? action;

  const AdminSearchField({
    super.key,
    this.hint = 'Search…',
    this.onChanged,
    this.controller,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    // The TextField needs a Material ancestor of its own — the field is used on
    // plain-colored screens, not only inside cards.
    final field = Material(
      type: MaterialType.transparency,
      child: Container(
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: AdminPalette.card,
          borderRadius: AdminRadius.brTile,
          border: Border.all(color: AdminPalette.border),
          boxShadow: AdminPalette.cardShadow,
        ),
        child: Row(
          children: [
            const Icon(Icons.search_rounded,
                size: 20, color: AdminPalette.faint),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: controller,
                onChanged: onChanged,
                style:
                    AdminType.body.copyWith(color: AdminPalette.ink, fontSize: 15),
                cursorColor: AdminPalette.ink,
                decoration: InputDecoration(
                  hintText: hint,
                  hintStyle: AdminType.body
                      .copyWith(color: AdminPalette.faint, fontSize: 15),
                  isCollapsed: true,
                  filled: false,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (action == null) return field;
    return Row(
      children: [
        Expanded(child: field),
        const SizedBox(width: 10),
        action!,
      ],
    );
  }
}

/// Square icon button sized to match [AdminSearchField] (used for filter/tune).
class AdminIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const AdminIconButton({super.key, required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AdminPalette.card,
      borderRadius: AdminRadius.brTile,
      child: InkWell(
        onTap: onTap,
        borderRadius: AdminRadius.brTile,
        child: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            borderRadius: AdminRadius.brTile,
            border: Border.all(color: AdminPalette.border),
          ),
          child: Icon(icon, size: 20, color: AdminPalette.ink),
        ),
      ),
    );
  }
}
