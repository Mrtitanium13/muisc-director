import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:music_director/config/melody_config.dart';
import 'package:music_director/core/theme/app_colors.dart';
import 'package:music_director/core/utils/haptic_utils.dart';
import 'package:music_director/data/models/melody_evolution.dart';
import 'package:music_director/features/prompt_generator/providers/prompt_form_providers.dart';
import 'package:music_director/presentation/providers/app_providers.dart';
import 'package:music_director/presentation/widgets/common/md_text_field.dart';

class MelodySection extends ConsumerWidget {
  const MelodySection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final form = ref.watch(promptFormProvider);
    final melodyStyleId = MelodyConfig.normalizeDirectiveId(
      ref.watch(melodyStyleUiProvider) ?? form.melodyStyleId,
    );
    final selected = MelodyConfig.getDirectiveById(melodyStyleId);
    final isCustom = selected.id == MelodyConfig.customId;
    final melodyCustomCtrl = ref.watch(melodyCustomNotesControllerProvider);
    final primary = ref.watch(selectedPrimarySubProvider);
    final fusion = ref.watch(selectedFusionSubProvider);
    final recommendedEvolution = MelodyConfig.recommendedEvolutionForGenre(
      primaryGenre: primary,
      fusionGenre: fusion,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'MELODY (OPTIONAL)',
          style: GoogleFonts.inter(
            fontSize: 11,
            letterSpacing: 1.2,
            color: AppColors.textTertiary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Steers style-prompt melody tokens and optional lyric structure hints. '
          'Evolution controls how motifs change section-to-section.',
          style: GoogleFonts.inter(
            fontSize: 12,
            color: AppColors.textSecondary,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(
          // ignore: deprecated_member_use
          value: selected.id,
          decoration: const InputDecoration(
            labelText: 'Melody style',
          ),
          isExpanded: true,
          items: [
            for (final d in MelodyConfig.directives)
              DropdownMenuItem<String>(
                value: d.id,
                child: Text(
                  d.label,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
          onChanged: (v) {
            if (v == null) return;
            hapticLight();
            final id = MelodyConfig.normalizeDirectiveId(v);
            ref.read(melodyStyleUiProvider.notifier).state = id;
            ref.read(promptFormProvider.notifier).setMelodyStyleId(id);
          },
        ),
        if (selected.description.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            selected.description,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppColors.textTertiary,
              height: 1.35,
            ),
          ),
        ],
        if (isCustom) ...[
          const SizedBox(height: 10),
          MdTextField(
            controller: melodyCustomCtrl,
            label: 'CUSTOM MELODY NOTES',
            hint:
                'e.g. Narrow range verses, octave leap on hook, staccato chant…',
            maxLines: 3,
            maxLength: 400,
            onChanged: (t) =>
                ref.read(promptFormProvider.notifier).setMelodyCustomNotes(t),
          ),
        ],
        const SizedBox(height: 10),
        DropdownButtonFormField<MelodyEvolution>(
          // ignore: deprecated_member_use
          value: form.melodyEvolution,
          decoration: const InputDecoration(
            labelText: 'Melody evolution (within one song)',
          ),
          isExpanded: true,
          items: MelodyEvolution.values
              .map(
                (mode) => DropdownMenuItem(
                  value: mode,
                  child: Text(
                    mode.label,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              )
              .toList(),
          onChanged: (v) {
            if (v == null) return;
            hapticLight();
            ref.read(promptFormProvider.notifier).setMelodyEvolution(v);
          },
        ),
        const SizedBox(height: 8),
        Text(
          MelodyConfig.evolutionDescriptions[form.melodyEvolution]!,
          style: GoogleFonts.inter(
            fontSize: 11,
            color: AppColors.textTertiary,
            height: 1.35,
          ),
        ),
        if (primary != null && primary.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            'Genre tip: $primary often works well with '
            '${recommendedEvolution.label}.',
            style: GoogleFonts.inter(
              fontSize: 11,
              color: AppColors.textSecondary,
              height: 1.35,
            ),
          ),
        ],
      ],
    );
  }
}
