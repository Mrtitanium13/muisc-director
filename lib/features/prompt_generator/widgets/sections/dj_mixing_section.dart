import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:music_director/core/constants/suno_dj_mix_directives.dart';
import 'package:music_director/core/theme/app_colors.dart';
import 'package:music_director/core/utils/structural_family_resolver.dart';
import 'package:music_director/features/prompt_generator/providers/prompt_form_providers.dart';
import 'package:music_director/presentation/providers/app_providers.dart';

class DjMixingSection extends ConsumerWidget {
  const DjMixingSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final form = ref.watch(promptFormProvider);
    final primarySub = ref.watch(selectedPrimarySubProvider);
    final genreFxLaneId = ref.watch(genreFxLaneIdProvider);

    final family = StructuralFamilyResolver.resolve(
      primaryGenre: form.primaryGenre.isNotEmpty
          ? form.primaryGenre
          : (primarySub ?? ''),
      fusionGenre: form.subGenreFusion,
      commercialLane: genreFxLaneId.isEmpty ? null : genreFxLaneId,
    );
    final djAllowed = djMixAllowedForFamily(family);
    final bars = djBarConfigFor(family);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'DJ MIXING (SUNO PROMPT)',
          style: GoogleFonts.inter(
            fontSize: 11,
            letterSpacing: 1.2,
            color: AppColors.textTertiary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          djAllowed
              ? 'Optional DJ-friendly intro/outro for club/radio lanes '
                  '(${bars.introBars}-bar intro · ${bars.outroBars}-bar outro for this genre).'
              : 'DJ mix-in/out not available for ${StructuralFamilyResolver.laneHintFor(family)} — '
                  'use EDM, Hip-Hop, Trap, Amapiano, or Pop lanes.',
          style: GoogleFonts.inter(
            fontSize: 12,
            color: AppColors.textSecondary,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 8),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('DJ intro (mix-in)'),
          subtitle: Text(
            djAllowed
                ? 'Long blend-friendly intro (previous → this track)'
                : 'Disabled for this genre family',
            style: GoogleFonts.inter(
              fontSize: 11,
              color: AppColors.textTertiary,
            ),
          ),
          value: djAllowed && form.djIntroMixIn,
          onChanged: djAllowed
              ? (v) =>
                  ref.read(promptFormProvider.notifier).setDjIntroMixIn(v)
              : null,
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('DJ outro (mix-out)'),
          subtitle: Text(
            djAllowed
                ? 'Long blend-friendly outro (this track → next)'
                : 'Disabled for this genre family',
            style: GoogleFonts.inter(
              fontSize: 11,
              color: AppColors.textTertiary,
            ),
          ),
          value: djAllowed && form.djOutroMixOut,
          onChanged: djAllowed
              ? (v) =>
                  ref.read(promptFormProvider.notifier).setDjOutroMixOut(v)
              : null,
        ),
      ],
    );
  }
}
