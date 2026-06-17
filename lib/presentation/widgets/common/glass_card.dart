import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.accentBorder = false,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final bool accentBorder;

  @override
  Widget build(BuildContext context) {
    final border = Border.all(
      color: accentBorder ? AppColors.accentPrimary.withValues(alpha: 0.55) : AppColors.border,
      width: accentBorder ? 1.5 : 1,
    );
    final content = ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(16),
            border: border,
            boxShadow: [
              if (accentBorder)
                BoxShadow(
                  color: AppColors.accentPrimary.withValues(alpha: 0.2),
                  blurRadius: 18,
                  spreadRadius: 0,
                ),
            ],
          ),
          child: child,
        ),
      ),
    );

    if (onTap == null) return content;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: content,
      ),
    );
  }
}
