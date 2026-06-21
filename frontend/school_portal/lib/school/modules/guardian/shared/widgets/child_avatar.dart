import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

import '../models/child.dart';

/// Circular avatar for a [Child] — network photo when available, initials on a
/// tinted disc otherwise.
class ChildAvatar extends StatelessWidget {
  final Child child;
  final double size;
  const ChildAvatar({super.key, required this.child, this.size = 44});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.primaryFixed,
        image: child.photoUrl != null
            ? DecorationImage(
                image: NetworkImage(child.photoUrl!), fit: BoxFit.cover)
            : null,
      ),
      child: child.photoUrl == null
          ? Text(
              child.initials,
              style: AppTypography.titleMd.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w800,
                fontSize: size * 0.34,
              ),
            )
          : null,
    );
  }
}
