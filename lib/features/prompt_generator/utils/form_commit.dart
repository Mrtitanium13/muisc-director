import 'package:flutter_riverpod/flutter_riverpod.dart' show WidgetRef;

import 'package:music_director/core/constants/audio_environment_data.dart';
import 'package:music_director/core/constants/dialect_style_data.dart';
import 'package:music_director/core/constants/lyric_temperament_data.dart';
import 'package:music_director/config/melody_config.dart';
import 'package:music_director/core/constants/power_code_data.dart';
import 'package:music_director/core/constants/prompt_flow_data.dart';
import 'package:music_director/core/constants/vocal_accent_data.dart';
import 'package:music_director/core/utils/duration_format.dart';
import 'package:music_director/data/models/suno_field_output_mode.dart';
import 'package:music_director/data/models/track_duration_config.dart';
import 'package:music_director/features/prompt_generator/providers/prompt_form_providers.dart';
import 'package:music_director/presentation/providers/app_providers.dart';

/// Writes all transient UI state + controllers into [promptFormProvider].
class FormCommit {
  const FormCommit._();

  static void commitAll(WidgetRef ref) {
    _syncGenre(ref);
    final n = ref.read(promptFormProvider.notifier);
    final form = ref.read(promptFormProvider);

    final trackDuration = form.trackDuration;
    String? resolvedLabel;
    if (trackDuration == TrackDuration.custom) {
      final raw = ref.read(customDurationControllerProvider).text.trim();
      if (raw.isEmpty) {
        resolvedLabel = null;
      } else {
        final p = parseFlexibleDurationMinutes(raw);
        resolvedLabel = p != null ? formatMinutesToMmSs(p) : raw;
      }
    } else {
      resolvedLabel = trackDuration.label;
    }
    n.setTrackDurationLabel(resolvedLabel);

    n.setVibe(_composedVibe(ref));
    final bpmText = ref.read(bpmControllerProvider).text.trim();
    n.setBpm(bpmText.isEmpty ? null : bpmText);

    n.setKeyScale(
      root: ref.read(keyRootProvider),
      scale: ref.read(scaleProvider),
    );

    final tone = PromptFlowData.vocalToneForCommit(
      preset: ref.read(vocalTonePresetProvider),
      customText: ref.read(vocalToneControllerProvider).text,
    );
    final vocalChoice = ref.read(vocalChoiceProvider);
    n.setVocal(
      spec: vocalChoice,
      tone: tone.isEmpty ? null : tone,
    );

    final instrumental =
        vocalChoice == null || vocalChoice == 'Instrumental Only';
    final dialectId = ref.read(dialectStyleUiProvider) ??
        DialectStyleData.standardEnglishId;
    final pidginActive = DialectStyleData.isNigerianPidgin(dialectId);
    n.setVocalAccent(
      instrumental
          ? null
          : VocalAccentData.resolveEffectiveAccent(
              topLevel: ref.read(vocalAccentUiProvider),
              nigerianSub: ref.read(nigerianAccentSubUiProvider),
              useNigerianSubRegion:
                  pidginActive && ref.read(vocalAccentUiProvider) == 'nigerian',
            ),
    );
    n.setDialectStyleId(
      instrumental
          ? DialectStyleData.standardEnglishId
          : dialectId,
    );
    n.setDialectVariantId(
      instrumental || !pidginActive
          ? DialectStyleData.generalVariantId
          : (ref.read(dialectVariantUiProvider) ??
              DialectStyleData.generalVariantId),
    );
    n.setAudioEnvironmentModeId(
      instrumental
          ? AudioEnvironmentData.studioIsolatedId
          : (ref.read(audioEnvironmentUiProvider) ??
              AudioEnvironmentData.studioIsolatedId),
    );

    n.setReferenceArtists(
      ref.read(referenceArtistsControllerProvider).text.trim(),
    );
    n.setSonicTags(ref.read(sonicTagsUiProvider));
    n.setAvoid(ref.read(avoidControllerProvider).text.trim());
    n.setLanguage(
      PromptFlowData.languageForCommit(
        preset: ref.read(languagePresetProvider),
        customText: ref.read(languageControllerProvider).text,
      ),
    );
    n.setSongStructureCustom(
      ref.read(structureCustomControllerProvider).text.trim(),
    );
    n.setRealInstrumentals(
      ref.read(realInstrumentsControllerProvider).text.trim(),
    );

    final melodyStyle = ref.read(melodyStyleUiProvider) ?? MelodyConfig.autoId;
    n.setMelodyStyleId(melodyStyle);
    n.setMelodyCustomNotes(
      ref.read(melodyCustomNotesControllerProvider).text.trim(),
    );
    n.setMelodyEvolution(form.melodyEvolution);
    n.setChordProgression(
      ref.read(chordProgressionControllerProvider).text.trim(),
    );

    final resolved = resolveLyricsBox(
      simpleMode: form.sunoFieldOutputMode == SunoFieldOutputMode.simple,
      lyricsText: ref.read(lyricsControllerProvider).text,
      generateLyrics: ref.read(generateLyricsProvider),
      useVibeAsLyricSource: form.useVibeAsLyricSource,
    );
    n.setOptionalLyrics(resolved.optionalLyrics);
    n.setGenerateLyrics(resolved.generateLyrics);

    n.setLyricThemeNotes(ref.read(lyricThemeControllerProvider).text.trim());
    n.setActiveModifierCodes(_temperamentLine(ref));
    n.setHumanRealism(ref.read(humanRealismLevelProvider));
    n.setProductionIntensity(ref.read(productionIntensityLevelProvider));
    n.setGenreFxLaneId(ref.read(genreFxLaneIdProvider));
    n.setRemixOriginalSongTitle(
      ref.read(remixSongTitleControllerProvider).text.trim(),
    );
    n.setRemixOriginalArtist(
      ref.read(remixArtistControllerProvider).text.trim(),
    );
    n.setSongGenerationType(form.songGenerationType);
  }

  /// Lyrics box → Path A when the user pasted/wrote lyrics; otherwise Path B/C.
  static ({String optionalLyrics, bool generateLyrics}) resolveLyricsBox({
    required bool simpleMode,
    required String lyricsText,
    required bool generateLyrics,
    required bool useVibeAsLyricSource,
  }) {
    if (simpleMode) {
      return (optionalLyrics: '', generateLyrics: false);
    }
    final lyricsTrim = lyricsText.trim();
    var genLyrics = generateLyrics;
    if (useVibeAsLyricSource) genLyrics = true;
    if (lyricsTrim.isNotEmpty) genLyrics = false;
    if (genLyrics) {
      return (optionalLyrics: '', generateLyrics: true);
    }
    return (optionalLyrics: lyricsTrim, generateLyrics: false);
  }

  static void _syncGenre(WidgetRef ref) {
    final primary = ref.read(selectedPrimarySubProvider) ?? '';
    final fusion = ref.read(selectedFusionSubProvider) ?? '';
    ref.read(promptFormProvider.notifier).setGenreSelection(
          primary,
          fusion: fusion,
        );
  }

  static String _composedVibe(WidgetRef ref) => PromptFlowData.composeVibe(
        mood: ref.read(moodToneProvider),
        era: ref.read(eraSceneProvider),
        groove: ref.read(grooveFeelProvider),
        detail: ref.read(vibeControllerProvider).text,
      );

  static String _temperamentLine(WidgetRef ref) {
    final picks = ref.read(temperamentPickProvider);
    final ordered = [
      for (final c in PowerCodeData.codes)
        if (picks.contains(c)) c,
      for (final c in LyricTemperamentData.codes)
        if (picks.contains(c)) c,
    ];
    return ordered.join(' ');
  }
}
