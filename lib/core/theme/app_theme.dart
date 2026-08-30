import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

class AppTheme {
  static ThemeData dark() {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.accentPrimary,
        secondary: AppColors.accentTertiary,
        tertiary: AppColors.creodomeCyan,
        surface: AppColors.surface,
        error: AppColors.error,
        onPrimary: AppColors.textPrimary,
        onSecondary: Color(0xFF001018),
        onTertiary: Color(0xFF001018),
        onSurface: AppColors.textPrimary,
      ),
      dividerColor: AppColors.border,
      splashFactory: InkRipple.splashFactory,
    );

    final textTheme = GoogleFonts.interTextTheme(base.textTheme).apply(
      bodyColor: AppColors.textPrimary,
      displayColor: AppColors.textPrimary,
    );

    return base.copyWith(
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: GoogleFonts.inter(
          fontWeight: FontWeight.w600,
          fontSize: 18,
          color: AppColors.textPrimary,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.accentTertiary, width: 1.5),
        ),
        labelStyle: const TextStyle(color: AppColors.textSecondary),
        hintStyle: const TextStyle(color: AppColors.textTertiary),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceElevated,
        selectedColor: AppColors.chipSelectedFill,
        secondarySelectedColor: AppColors.chipSelectedFill,
        disabledColor: AppColors.surface,
        labelStyle: GoogleFonts.inter(
          fontSize: 13,
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w500,
        ),
        secondaryLabelStyle: GoogleFonts.inter(
          fontSize: 13,
          color: AppColors.creodomeCyan,
          fontWeight: FontWeight.w700,
        ),
        checkmarkColor: AppColors.creodomeCyan,
        side: const BorderSide(color: AppColors.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.symmetric(horizontal: 4),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.toggleActive;
          }
          return AppColors.textTertiary;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.accentTertiary.withValues(alpha: 0.45);
          }
          return AppColors.surfaceElevated;
        }),
        trackOutlineColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.accentTertiary;
          }
          return AppColors.border;
        }),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return AppColors.creodomeCyan;
            }
            return AppColors.textSecondary;
          }),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return AppColors.chipSelectedFill;
            }
            return AppColors.surface;
          }),
          side: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const BorderSide(color: AppColors.chipSelectedBorder);
            }
            return const BorderSide(color: AppColors.border);
          }),
          iconColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return AppColors.creodomeCyan;
            }
            return AppColors.textTertiary;
          }),
        ),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: AppColors.accentTertiary,
        inactiveTrackColor: AppColors.border,
        thumbColor: AppColors.creodomeCyan,
        overlayColor: AppColors.accentTertiary.withValues(alpha: 0.16),
        valueIndicatorColor: AppColors.accentTertiary,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.surfaceElevated,
        contentTextStyle: GoogleFonts.inter(color: AppColors.textPrimary),
      ),
    );
  }

  static TextStyle mono(BuildContext context, {double fontSize = 13}) {
    return GoogleFonts.jetBrainsMono(
      fontSize: fontSize,
      color: AppColors.textSecondary,
    );
  }
}
