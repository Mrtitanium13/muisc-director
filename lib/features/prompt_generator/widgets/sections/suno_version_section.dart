import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:music_director/core/theme/app_colors.dart';
import 'package:music_director/core/utils/haptic_utils.dart';
import 'package:music_director/features/prompt_generator/utils/prompt_form_constants.dart';
import 'package:music_director/features/prompt_generator/widgets/common/scrollable_chip_row.dart';
import 'package:music_director/presentation/providers/app_providers.dart';

class SunoVersionSection extends ConsumerWidget {
  const SunoVersionSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final form = ref.watch(promptFormProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'SUNO VERSION',
          style: GoogleFonts.inter(
            fontSize: 12,
            letterSpacing: 1.1,
            color: AppColors.accentTertiary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Controls bracket density & lyric depth — not Style field length '
          '(always ~130–150 words / ≤1000 chars).',
          style: GoogleFonts.inter(
            fontSize: 12,
            color: AppColors.textSecondary,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 8),
        ScrollableChipRow(
          children: [
            for (final v in PromptFormConstants.sunoVersions)
              Tooltip(
                message: PromptFormConstants.sunoVersionHints[v]!,
                child: ChoiceChip(
                  label: Text(v),
                  selected: form.sunoVersion == v,
                  onSelected: (_) {
                    hapticLight();
                    ref.read(promptFormProvider.notifier).setSunoVersion(v);
                  },
                  selectedColor: AppColors.chipSelectedFill,
                  side: BorderSide(
                    color: form.sunoVersion == v
                        ? AppColors.chipSelectedBorder
                        : AppColors.border,
                  ),
                  labelStyle: TextStyle(
                    fontWeight: form.sunoVersion == v
                        ? FontWeight.w700
                        : FontWeight.w500,
                    color: form.sunoVersion == v
                        ? AppColors.creodomeCyan
                        : AppColors.textSecondary,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          PromptFormConstants.sunoVersionHints[form.sunoVersion] ??
              PromptFormConstants.sunoVersionHints['v5.5']!,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: AppColors.textTertiary,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}
