import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:music_director/core/constants/power_code_data.dart';
import 'package:music_director/core/constants/prompt_flow_data.dart';
import 'package:music_director/core/theme/app_colors.dart';
import 'package:music_director/core/utils/haptic_utils.dart';
import 'package:music_director/features/prompt_generator/providers/prompt_form_providers.dart';
import 'package:music_director/features/prompt_generator/utils/temperament_toggle.dart';
import 'package:music_director/features/prompt_generator/widgets/common/scrollable_chip_row.dart';
import 'package:music_director/presentation/providers/app_providers.dart';
import 'package:music_director/presentation/widgets/common/md_text_field.dart';

class MoodVibeSection extends ConsumerWidget {
  const MoodVibeSection({super.key, this.compact = false});

  final bool compact;

  void _syncDropdownsForGenre(WidgetRef ref, String genreFamily) {
    final era = ref.read(eraSceneProvider);
    final groove = ref.read(grooveFeelProvider);
    final nextEra = PromptFlowData.coerceEraForGenre(era, genreFamily);
    final nextGroove = PromptFlowData.coerceGrooveForGenre(groove, genreFamily);
    if (nextEra != era) {
      ref.read(eraSceneProvider.notifier).state = nextEra;
    }
    if (nextGroove != groove) {
      ref.read(grooveFeelProvider.notifier).state = nextGroove;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final form = ref.watch(promptFormProvider);
    final moodTone = ref.watch(moodToneProvider);
    final eraScene = ref.watch(eraSceneProvider);
    final grooveFeel = ref.watch(grooveFeelProvider);
    final temperamentPick = ref.watch(temperamentPickProvider);
    final vibeCtrl = ref.watch(vibeControllerProvider);

    final genreFamily = PromptFlowData.resolveVibeGenreFamily(
      primaryGenre: form.primaryGenre,
      fusionGenre: form.subGenreFusion,
    );
    final eraOptions = PromptFlowData.getEraScenesForGenre(genreFamily);
    final grooveOptions = PromptFlowData.getGrooveFeelsForGenre(genreFamily);

    ref.listen<String>(
      promptFormProvider.select((f) => f.primaryGenre),
      (prev, next) {
      final family = PromptFlowData.resolveVibeGenreFamily(
        primaryGenre: next,
        fusionGenre: ref.read(promptFormProvider).subGenreFusion,
      );
      _syncDropdownsForGenre(ref, family);
    },
    );
    ref.listen<String>(
      promptFormProvider.select((f) => f.subGenreFusion),
      (prev, next) {
      final family = PromptFlowData.resolveVibeGenreFamily(
        primaryGenre: ref.read(promptFormProvider).primaryGenre,
        fusionGenre: next,
      );
      _syncDropdownsForGenre(ref, family);
    },
    );

    final validEra = PromptFlowData.coerceEraForGenre(eraScene, genreFamily);
    final validGroove =
        PromptFlowData.coerceGrooveForGenre(grooveFeel, genreFamily);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!compact) ...[
          Text(
            'MOOD & VIBE',
            style: GoogleFonts.inter(
              fontSize: 11,
              letterSpacing: 1.2,
              color: AppColors.textTertiary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Pick tone anchors from the menus, then add scene or story detail below.',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppColors.textSecondary,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 10),
        ],
        Text(
          'POWER CODES (OPTIONAL)',
          style: GoogleFonts.inter(
            fontSize: 11,
            color: AppColors.textTertiary,
          ),
        ),
        const SizedBox(height: 6),
        ScrollableChipRow(
          height: 42,
          spacing: 6,
          children: [
            for (final c in PowerCodeData.codes)
              FilterChip(
                label: Text(
                  PowerCodeData.labelFor(c),
                  style: GoogleFonts.inter(fontSize: 11),
                ),
                tooltip: PowerCodeData.hintFor(c),
                selected: temperamentPick.contains(c),
                onSelected: (_) => toggleTemperament(ref, c),
                selectedColor: AppColors.chipSelectedFill,
                checkmarkColor: AppColors.creodomeCyan,
                side: BorderSide(
                  color: temperamentPick.contains(c)
                      ? AppColors.chipSelectedBorder
                      : AppColors.border,
                ),
                labelStyle: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: temperamentPick.contains(c)
                      ? FontWeight.w700
                      : FontWeight.w500,
                  color: temperamentPick.contains(c)
                      ? AppColors.creodomeCyan
                      : AppColors.textSecondary,
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: DropdownButtonFormField<String?>(
                // ignore: deprecated_member_use
                value: moodTone,
                decoration: const InputDecoration(
                  labelText: 'Mood / emotional tone',
                ),
                isExpanded: true,
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('Not set'),
                  ),
                  for (final m in PromptFlowData.moodTones)
                    DropdownMenuItem<String?>(
                      value: m,
                      child: Text(m),
                    ),
                ],
                onChanged: (v) {
                  hapticLight();
                  ref.read(moodToneProvider.notifier).state = v;
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<String?>(
                // ignore: deprecated_member_use
                value: validEra,
                decoration: const InputDecoration(
                  labelText: 'Era / scene (optional)',
                ),
                isExpanded: true,
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('Not set'),
                  ),
                  for (final e in eraOptions)
                    DropdownMenuItem<String?>(
                      value: e,
                      child: Text(e, overflow: TextOverflow.ellipsis),
                    ),
                ],
                onChanged: (v) {
                  hapticLight();
                  ref.read(eraSceneProvider.notifier).state = v;
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        DropdownButtonFormField<String?>(
          // ignore: deprecated_member_use
          value: validGroove,
          decoration: const InputDecoration(
            labelText: 'Groove feel (optional)',
          ),
          isExpanded: true,
          items: [
            const DropdownMenuItem<String?>(
              value: null,
              child: Text('Not set'),
            ),
            for (final g in grooveOptions)
              DropdownMenuItem<String?>(
                value: g,
                child: Text(g),
              ),
          ],
          onChanged: (v) {
            hapticLight();
            ref.read(grooveFeelProvider.notifier).state = v;
          },
        ),
        const SizedBox(height: 10),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(
            'Use vibe/idea text as source material for lyrics',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          subtitle: Text(
            form.useVibeAsLyricSource
                ? 'Paste a long story, scene, or verse — up to 8,000 characters.'
                : 'Turns your story, text, or verse into a song.',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          value: form.useVibeAsLyricSource,
          onChanged: (value) {
            hapticLight();
            ref.read(promptFormProvider.notifier).setUseVibeAsLyricSource(value);
            if (value) {
              ref.read(generateLyricsProvider.notifier).state = true;
            }
          },
          dense: true,
        ),
        MdTextField(
          controller: vibeCtrl,
          label: form.useVibeAsLyricSource
              ? 'SOURCE TEXT (story, scene, verse)'
              : 'VIBE / IDEA (scene, story, concept)',
          hint: form.useVibeAsLyricSource
              ? 'Paste the full story, chat, poem, or scene you want turned into lyrics…'
              : 'e.g. late-night drive after the show, rooftop summer, breakup voicemail…',
          maxLines: form.useVibeAsLyricSource ? 12 : 4,
          maxLength: form.useVibeAsLyricSource ? 8000 : 500,
        ),
      ],
    );
  }
}
