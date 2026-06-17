import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';

class MdTextField extends StatelessWidget {
  const MdTextField({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.maxLines = 1,
    this.maxLength,
    this.readOnly = false,
    this.onTap,
    this.keyboardType,
    this.onChanged,
  });

  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final int maxLines;
  final int? maxLength;
  final bool readOnly;
  final VoidCallback? onTap;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              label!,
              style: GoogleFonts.inter(
                fontSize: 11,
                letterSpacing: 1.2,
                fontWeight: FontWeight.w600,
                color: AppColors.textTertiary,
              ),
            ),
          ),
        TextField(
          controller: controller,
          maxLines: maxLines,
          maxLength: maxLength,
          readOnly: readOnly,
          onTap: onTap,
          keyboardType: keyboardType,
          onChanged: onChanged,
          style: GoogleFonts.inter(color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            counterStyle: const TextStyle(color: AppColors.textTertiary, fontSize: 11),
          ),
        ),
      ],
    );
  }
}
