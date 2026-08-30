import 'package:flutter_riverpod/flutter_riverpod.dart' show WidgetRef;

import 'package:music_director/core/constants/audio_environment_data.dart';
import 'package:music_director/core/constants/dialect_style_data.dart';
import 'package:music_director/core/constants/genre_data.dart';
import 'package:music_director/core/constants/genres_config.dart';
import 'package:music_director/config/melody_config.dart';
import 'package:music_director/core/constants/prompt_flow_data.dart';
import 'package:music_director/core/constants/vocal_accent_data.dart';
import 'package:music_director/core/utils/suno_prompt_builder.dart';
import 'package:music_director/data/models/suno_field_output_mode.dart';
import 'package:music_director/data/models/track_duration_config.dart';
import 'package:music_director/data/models/user_input_model.dart';
import 'package:music_director/features/prompt_generator/providers/prompt_form_providers.dart';
import 'package:music_director/presentation/providers/app_providers.dart';

class FormHydration {
  const FormHydration._();

  static void hydrateAll(WidgetRef ref) {
    final form = ref.read(promptFormProvider);
    _hydrateGenreState(ref, form);
    _hydrateVibeState(ref, form);
    _hydrateBpmState(ref, form);
    _hydrateVocalState(ref, form);
    _hydrateTextControllers(ref, form);
    _hydrateSlidersAndToggles(ref, form);
    _hydrateRemixFields(ref, form);
    _hydrateTrackDuration(ref, form);
    _hydrateMelodyState(ref, form);
  }

  /// Reload after external form replacement (e.g. templates).
  static void reloadAll(WidgetRef ref) {
    hydrateAll(ref);
  }

  static void _hydrateGenreState(WidgetRef ref, UserInputModel form) {
    if (form.primaryGenre.isNotEmpty) {
      ref.read(selectedPrimarySubProvider.notifier).state = form.primaryGenre;
      ref.read(selectedCategoryProvider.notifier).state =
          GenreData.categoryForSubGenre(form.primaryGenre);
    }
    if (form.subGenreFusion.isNotEmpty) {
      ref.read(selectedFusionSubProvider.notifier).state = form.subGenreFusion;
    }
  }

  static void _hydrateVibeState(WidgetRef ref, UserInputModel form) {
    final parsed = PromptFlowData.parseStoredVibe(form.vibe);
    final family = PromptFlowData.resolveVibeGenreFamily(
      primaryGenre: form.primaryGenre,
      fusionGenre: form.subGenreFusion,
    );
    ref.read(moodToneProvider.notifier).state = parsed.mood;
    ref.read(eraSceneProvider.notifier).state =
        PromptFlowData.coerceEraForGenre(parsed.era, family);
    ref.read(grooveFeelProvider.notifier).state =
        PromptFlowData.coerceGrooveForGenre(parsed.groove, family);
    ref.read(vibeControllerProvider).text = parsed.detail;
  }

  static void _hydrateBpmState(WidgetRef ref, UserInputModel form) {
    ref.read(bpmControllerProvider).text = form.bpm ?? '';
    final bpm = form.bpm?.trim() ?? '';
    if (bpm.isEmpty) {
      ref.read(bpmPresetProvider.notifier).state = null;
      return;
    }
    final primary = ref.read(selectedPrimarySubProvider);
    final category = ref.read(selectedCategoryProvider);
    final suggestions =
        PromptFlowData.bpmSuggestionsForGenre(primary ?? category);
    if (suggestions.any((n) => n.toString() == bpm)) {
      ref.read(bpmPresetProvider.notifier).state = bpm;
    } else {
      ref.read(bpmPresetProvider.notifier).state = PromptFlowData.customOption;
    }
  }

  static void _hydrateVocalState(WidgetRef ref, UserInputModel form) {
    ref.read(vocalChoiceProvider.notifier).state = form.vocalSpec;
    final split = VocalAccentData.splitForUi(form.vocalAccent);
    ref.read(vocalAccentUiProvider.notifier).state = split.topLevel;
    ref.read(nigerianAccentSubUiProvider.notifier).state =
        split.nigerianSub ?? VocalAccentData.defaultNigerianSubAccent;
    ref.read(keyRootProvider.notifier).state = form.keyRoot;
    ref.read(scaleProvider.notifier).state = form.scale;
    ref.read(dialectStyleUiProvider.notifier).state =
        DialectStyleData.coerceId(form.dialectStyleId);
    ref.read(dialectVariantUiProvider.notifier).state =
        DialectStyleData.coerceVariantId(form.dialectVariantId);
    ref.read(audioEnvironmentUiProvider.notifier).state =
        AudioEnvironmentData.coerceId(form.audioEnvironmentModeId);
  }

  static void _hydrateTextControllers(WidgetRef ref, UserInputModel form) {
    ref.read(referenceArtistsControllerProvider).text = form.referenceArtists;
    ref.read(sonicTagsUiProvider.notifier).state =
        List<String>.from(form.sonicTags);
    ref.read(avoidControllerProvider).text = form.avoid;

    final langCtrl = ref.read(languageControllerProvider);
    final coercedLang = PromptFlowData.coerceLanguage(form.language);
    if (coercedLang == PromptFlowData.customOption) {
      ref.read(languagePresetProvider.notifier).state =
          PromptFlowData.customOption;
      langCtrl.text = form.language;
    } else {
      ref.read(languagePresetProvider.notifier).state = coercedLang;
      langCtrl.text = coercedLang ?? 'English';
    }

    final vocalToneCtrl = ref.read(vocalToneControllerProvider);
    final coercedTone = PromptFlowData.coerceVocalTone(form.vocalTone);
    if (coercedTone == PromptFlowData.customOption) {
      ref.read(vocalTonePresetProvider.notifier).state =
          PromptFlowData.customOption;
      vocalToneCtrl.text = form.vocalTone ?? '';
    } else if (coercedTone != null) {
      ref.read(vocalTonePresetProvider.notifier).state = coercedTone;
      vocalToneCtrl.text = '';
    } else {
      ref.read(vocalTonePresetProvider.notifier).state = null;
      vocalToneCtrl.text = '';
    }

    ref.read(realInstrumentsControllerProvider).text = form.realInstrumentals;
    ref.read(chordProgressionControllerProvider).text = form.chordProgression;
    ref.read(melodyCustomNotesControllerProvider).text = form.melodyCustomNotes;
    ref.read(structureCustomControllerProvider).text = form.songStructureCustom;
    final mixedLyrics = form.optionalLyrics;
    final coreLyrics = SunoPromptBuilder.stripFxLayout(mixedLyrics);
    final fxLayout = SunoPromptBuilder.extractFxLayout(mixedLyrics);
    ref.read(lyricsControllerProvider).text = coreLyrics;
    ref.read(fxLayoutControllerProvider).text = fxLayout;
    if (coreLyrics != mixedLyrics) {
      ref.read(promptFormProvider.notifier).setOptionalLyrics(coreLyrics);
    }
    ref.read(lyricThemeControllerProvider).text = form.lyricThemeNotes;
  }

  static void _hydrateSlidersAndToggles(WidgetRef ref, UserInputModel form) {
    ref.read(humanRealismLevelProvider.notifier).state = form.humanRealism;
    ref.read(productionIntensityLevelProvider.notifier).state =
        form.productionIntensity;
    ref.read(genreFxLaneIdProvider.notifier).state =
        form.genreFxLaneId.isEmpty
            ? GenresConfig.autoLaneId
            : form.genreFxLaneId;
    ref.read(generateLyricsProvider.notifier).state = form.generateLyrics;

    final picks = <String>{};
    for (final p in form.activeModifierCodes.split(RegExp(r'\s+'))) {
      if (p.startsWith('/')) picks.add(p);
    }
    ref.read(temperamentPickProvider.notifier).state = picks;

    if (form.sunoFieldOutputMode == SunoFieldOutputMode.simple) {
      ref.read(generateLyricsProvider.notifier).state = false;
      ref.read(lyricsControllerProvider).clear();
      ref.read(fxLayoutControllerProvider).clear();
    }
  }

  static void _hydrateRemixFields(WidgetRef ref, UserInputModel form) {
    ref.read(remixSongTitleControllerProvider).text =
        form.remixOriginalSongTitle;
    ref.read(remixArtistControllerProvider).text = form.remixOriginalArtist;
  }

  static void _hydrateTrackDuration(WidgetRef ref, UserInputModel form) {
    if (form.trackDuration == TrackDuration.custom) {
      ref.read(customDurationControllerProvider).text =
          form.trackDurationLabel ?? '';
    } else {
      ref.read(customDurationControllerProvider).text = '';
    }
  }

  static void _hydrateMelodyState(WidgetRef ref, UserInputModel form) {
    ref.read(melodyStyleUiProvider.notifier).state = form.melodyStyleId.isEmpty
        ? MelodyConfig.autoId
        : form.melodyStyleId;
  }
}
