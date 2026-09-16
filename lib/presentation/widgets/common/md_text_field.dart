import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';

class MdTextField extends StatelessWidget {
  const MdTextField({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.minLines,
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
  final int? minLines;
  final int maxLines;
  final int? maxLength;
  final bool readOnly;
  final VoidCallback? onTap;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    final lines = () {
      var n = maxLines < 1 ? 1 : maxLines;
      if (minLines != null && n < minLines!) n = minLines!;
      return n;
    }();
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
          minLines: minLines,
          maxLines: lines,
          maxLength: maxLength,
          readOnly: readOnly,
          onTap: onTap,
          keyboardType: keyboardType,
          textAlignVertical:
              lines > 1 ? TextAlignVertical.top : TextAlignVertical.center,
          onChanged: onChanged,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
          ),
          decoration: InputDecoration(
            hintText: hint,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            counterStyle: const TextStyle(
              color: AppColors.textTertiary,
              fontSize: 11,
            ),
          ),
        ),
      ],
    );
  }
}
