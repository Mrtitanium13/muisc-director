import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_icons/phosphor_icons.dart';

import 'package:music_director/core/theme/app_colors.dart';
import 'package:music_director/core/utils/haptic_utils.dart';
import 'package:music_director/data/models/suno_field_output_mode.dart';
import 'package:music_director/features/prompt_generator/providers/prompt_form_providers.dart';
import 'package:music_director/presentation/providers/app_providers.dart';

class SunoFieldModeSection extends ConsumerWidget {
  const SunoFieldModeSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final form = ref.watch(promptFormProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'SUNO FIELD MODE',
          style: GoogleFonts.inter(
            fontSize: 12,
            letterSpacing: 1.1,
            color: AppColors.accentTertiary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        SegmentedButton<SunoFieldOutputMode>(
          segments: const [
            ButtonSegment<SunoFieldOutputMode>(
              value: SunoFieldOutputMode.custom,
              label: Text('Custom'),
              icon: Icon(PhosphorIconsRegular.slidersHorizontal),
            ),
            ButtonSegment<SunoFieldOutputMode>(
              value: SunoFieldOutputMode.simple,
              label: Text('Simple'),
              icon: Icon(PhosphorIconsRegular.article),
            ),
          ],
          selected: {form.sunoFieldOutputMode},
          onSelectionChanged: (s) {
            final m = s.first;
            hapticLight();
            ref.read(promptFormProvider.notifier).setSunoFieldOutputMode(m);
            if (m == SunoFieldOutputMode.simple) {
              ref.read(generateLyricsProvider.notifier).state = false;
              ref.read(lyricsControllerProvider).clear();
              ref.read(promptFormProvider.notifier)
                ..setGenerateLyrics(false)
                ..setOptionalLyrics('');
            }
          },
        ),
        const SizedBox(height: 6),
        Text(
          form.sunoFieldOutputMode == SunoFieldOutputMode.custom
              ? 'Custom: Style — producer prose (130–150 words, ≤1000 chars) + optional Lyrics (≤2500 chars).'
              : 'Simple: Description — same prose budget (130–150 words, ≤1000 chars; no lyrics block).',
          style: GoogleFonts.inter(
            fontSize: 12,
            color: AppColors.textSecondary,
            height: 1.35,
          ),
        ),
      ],
    );
  }
}
