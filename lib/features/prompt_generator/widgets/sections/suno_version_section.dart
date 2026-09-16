import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:music_director/core/constants/suno_version.dart';
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
    final uiVersion = SunoVersion.migrateToUiValue(form.sunoVersion);
    if (uiVersion != form.sunoVersion) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(promptFormProvider.notifier).setSunoVersion(uiVersion);
      });
    }

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
          'Controls bracket density, lyric depth, and model intent — not Style '
          'field length (always ~130–150 words / ≤1000 chars).',
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
                  selected: uiVersion == v,
                  onSelected: (_) {
                    hapticLight();
                    ref.read(promptFormProvider.notifier).setSunoVersion(v);
                  },
                  selectedColor: AppColors.accentPrimary.withValues(alpha: 0.25),
                  labelStyle: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: uiVersion == v
                        ? FontWeight.w700
                        : FontWeight.w500,
                    color: uiVersion == v
                        ? AppColors.accentPrimary
                        : AppColors.textSecondary,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          PromptFormConstants.sunoVersionHints[uiVersion] ??
              PromptFormConstants.sunoVersionHints['v6']!,
          style: GoogleFonts.inter(
            fontSize: 11,
            color: AppColors.textSecondary,
            height: 1.35,
          ),
        ),
      ],
    );
  }
}
