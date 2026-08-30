import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:music_director/core/constants/genres_config.dart';
import 'package:music_director/core/constants/human_realism_config.dart';
import 'package:music_director/core/constants/production_intensity_config.dart';
import 'package:music_director/core/constants/suno_structure_examples.dart';
import 'package:music_director/core/constants/vocal_accent_data.dart';
import 'package:music_director/presentation/providers/app_providers.dart';

// Section-scoped transient UI state (not persisted in [UserInputModel] alone).
final selectedCategoryProvider = StateProvider<String?>((ref) => null);
final selectedPrimarySubProvider = StateProvider<String?>((ref) => null);
final selectedFusionSubProvider = StateProvider<String?>((ref) => null);

final moodToneProvider = StateProvider<String?>((ref) => null);
final eraSceneProvider = StateProvider<String?>((ref) => null);
final grooveFeelProvider = StateProvider<String?>((ref) => null);

final bpmPresetProvider = StateProvider<String?>((ref) => null);
final vocalTonePresetProvider = StateProvider<String?>((ref) => null);
final languagePresetProvider = StateProvider<String?>((ref) => null);

/// null = auto by genre, '__all__' = every distinct chip.
final realInstrumentGenreFilterProvider = StateProvider<String?>((ref) => null);

final advancedExpandedProvider = StateProvider<bool>((ref) => false);

final generateLyricsProvider = StateProvider<bool>((ref) => false);
final temperamentPickProvider = StateProvider<Set<String>>((ref) => <String>{});

/// Opt-in multi-stage songwriter pipeline (server `SONGWRITER_PIPELINE=1`).
final songwriterPipelineEnabledProvider = StateProvider<bool>((ref) => false);

/// Output mode id from tools/songwriter/output_modes.json (e.g. full_song).
final songwriterOutputModeProvider =
    StateProvider<String>((ref) => 'full_song');

/// Generation depth: fast | balanced | premium | debug.
final songwriterQualityModeProvider =
    StateProvider<String>((ref) => 'balanced');

final humanRealismLevelProvider = StateProvider<int>(
  (ref) => HumanRealismConfig.defaultLevel,
);
final productionIntensityLevelProvider = StateProvider<int>(
  (ref) => ProductionIntensityConfig.defaultLevel,
);
final genreFxLaneIdProvider = StateProvider<String>(
  (ref) => GenresConfig.autoLaneId,
);

final customDurationLabelProvider = StateProvider<String>((ref) => '');

// Vocal / key / dialect UI (coerced into form on commit).
final vocalChoiceProvider = StateProvider<String?>((ref) => null);
final vocalAccentUiProvider = StateProvider<String?>((ref) => null);
final nigerianAccentSubUiProvider = StateProvider<String>(
  (ref) => VocalAccentData.defaultNigerianSubAccent,
);
final keyRootProvider = StateProvider<String?>((ref) => null);
final scaleProvider = StateProvider<String?>((ref) => null);
final dialectStyleUiProvider = StateProvider<String?>((ref) => null);
final dialectVariantUiProvider = StateProvider<String?>((ref) => null);
final audioEnvironmentUiProvider = StateProvider<String?>((ref) => null);
final melodyStyleUiProvider = StateProvider<String?>((ref) => null);

Provider<TextEditingController> _textController(String initial) {
  return Provider<TextEditingController>((ref) {
    final c = TextEditingController(text: initial);
    ref.onDispose(c.dispose);
    return c;
  });
}

final vibeControllerProvider = _textController('');
final bpmControllerProvider = _textController('');
final chordProgressionControllerProvider = _textController('');
final realInstrumentsControllerProvider = _textController('');
final melodyCustomNotesControllerProvider = _textController('');
final lyricsControllerProvider = _textController('');
/// Genre FX arrangement tags — separate from songwriter [lyricsControllerProvider].
final fxLayoutControllerProvider = _textController('');
final lyricThemeControllerProvider = _textController('');
final structureCustomControllerProvider = _textController('');
final referenceArtistsControllerProvider = _textController('');
final sonicTagsUiProvider = StateProvider<List<String>>((ref) => const []);
final avoidControllerProvider = _textController('');
final languageControllerProvider = _textController('English');
final vocalToneControllerProvider = _textController('');
final remixSongTitleControllerProvider = _textController('');
final remixArtistControllerProvider = _textController('');
final customDurationControllerProvider = _textController('');

/// Suno structure example auto-matched to genre + version (no duplicated strings).
final sunoStructureExampleProvider = Provider<String>((ref) {
  final form = ref.watch(promptFormProvider);
  return SunoStructureExamples.exampleForVersion(
    version: form.sunoVersion,
    familyKey: SunoStructureExamples.familyForGenre(form.primaryGenre),
  );
});
