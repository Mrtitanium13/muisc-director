import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:music_director/core/theme/app_colors.dart';

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.label,
    this.helperText,
  });

  final String label;
  final String? helperText;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: GoogleFonts.inter(
            fontSize: 12,
            letterSpacing: 1.1,
            color: AppColors.accentTertiary,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (helperText != null) ...[
          const SizedBox(height: 4),
          Text(
            helperText!,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppColors.textSecondary,
              height: 1.35,
            ),
          ),
        ],
      ],
    );
  }
}
