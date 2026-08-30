import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:music_director/core/theme/app_colors.dart';

/// Numbered step label — high-contrast badge + title for workflow order.
class WorkflowStepLabel extends StatelessWidget {
  const WorkflowStepLabel({
    super.key,
    required this.step,
    required this.title,
    this.subtitle,
  });

  final int step;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                AppColors.accentTertiary,
                AppColors.creodomeCyan,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: AppColors.creodomeCyan.withValues(alpha: 0.35),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            '$step',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: AppColors.background,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title.toUpperCase(),
                style: GoogleFonts.inter(
                  fontSize: 13,
                  letterSpacing: 1.0,
                  fontWeight: FontWeight.w800,
                  color: AppColors.accentTertiary,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle!,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    height: 1.35,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
