import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:music_director/core/constants/genre_data.dart';
import 'package:music_director/core/theme/app_colors.dart';
import 'package:music_director/core/utils/haptic_utils.dart';
import 'package:music_director/features/prompt_generator/providers/prompt_form_providers.dart';

class GenreSelectionSection extends ConsumerWidget {
  const GenreSelectionSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final category = ref.watch(selectedCategoryProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'PRIMARY GENRE',
          style: GoogleFonts.inter(
            fontSize: 12,
            letterSpacing: 1.1,
            color: AppColors.accentTertiary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final c in GenreData.categories)
              ChoiceChip(
                label: Text(c),
                selected: category == c,
                onSelected: (_) {
                  hapticSelection();
                  ref.read(selectedCategoryProvider.notifier).state = c;
                  ref.read(selectedPrimarySubProvider.notifier).state = null;
                  ref.read(selectedFusionSubProvider.notifier).state = null;
                },
                selectedColor: AppColors.chipSelectedFill,
                side: BorderSide(
                  color: category == c
                      ? AppColors.chipSelectedBorder
                      : AppColors.border,
                ),
                labelStyle: TextStyle(
                  fontWeight:
                      category == c ? FontWeight.w700 : FontWeight.w500,
                  color: category == c
                      ? AppColors.creodomeCyan
                      : AppColors.textSecondary,
                ),
              ),
          ],
        ),
      ],
    );
  }
}
