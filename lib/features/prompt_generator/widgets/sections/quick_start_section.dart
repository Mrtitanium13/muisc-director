import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:music_director/core/constants/genre_data.dart';
import 'package:music_director/core/theme/app_colors.dart';
import 'package:music_director/core/utils/haptic_utils.dart';
import 'package:music_director/features/prompt_generator/providers/prompt_form_providers.dart';
import 'package:music_director/presentation/providers/app_providers.dart';

class QuickStartSection extends ConsumerWidget {
  const QuickStartSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'QUICK START',
          style: GoogleFonts.inter(
            fontSize: 11,
            color: AppColors.textTertiary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 36,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: GenreData.quickPickRows.length,
            separatorBuilder: (context, index) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              final row = GenreData.quickPickRows[i];
              final label = row.$1;
              final value = row.$2;
              return ActionChip(
                label: Text(label, style: const TextStyle(fontSize: 12)),
                onPressed: () {
                  hapticLight();
                  ref.read(selectedPrimarySubProvider.notifier).state = value;
                  ref.read(promptFormProvider.notifier).setGenreSelection(value);
                },
                backgroundColor: AppColors.surfaceElevated,
              );
            },
          ),
        ),
      ],
    );
  }
}
