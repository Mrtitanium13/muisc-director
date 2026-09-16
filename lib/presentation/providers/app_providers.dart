import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/api_constants.dart';
import '../../core/constants/suno_version.dart';
import '../../core/network/dio_client.dart';
import '../../data/models/audio_analysis_model.dart';
import '../../data/models/audio_session.dart';
import '../../data/models/melody_evolution.dart';
import '../../data/models/song_generation_type.dart';
import '../../data/models/suno_field_output_mode.dart';
import '../../data/models/track_duration_config.dart';
import '../../data/models/user_input_model.dart';
import '../../data/repositories/ai_repository.dart';
import '../../data/repositories/audio_repository.dart';
import '../../data/services/audio_analyzer_service.dart';
import '../../data/services/hive_storage_service.dart';
import '../../data/services/openai_service.dart';
import 'session_providers.dart';

final dioProvider = Provider((ref) => createDio());

final openAiServiceProvider = Provider(
  (ref) => OpenAIService(
    ref.watch(dioProvider),
    ref.watch(sharedPrefsProvider),
  ),
);

final audioAnalyzerServiceProvider = Provider(
  (ref) => AudioAnalyzerService(ref.watch(sharedPrefsProvider)),
);

final aiRepositoryProvider = Provider(
  (ref) => AiRepository(ref.watch(openAiServiceProvider)),
);

final audioRepositoryProvider = Provider(
  (ref) => AudioRepository(ref.watch(audioAnalyzerServiceProvider)),
);

final hiveStorageProvider = Provider((ref) => HiveStorageService());

/// Bumped in Settings after saving [ApiConstants.prefMdApiBaseUrl] so UI re-reads
/// [ApiConstants.resolveAnalyzeBase] (SharedPreferences is not reactive).
final mdApiBaseRevisionProvider = StateProvider<int>((ref) => 0);

/// Current `/analyze` base URL, or `null` when the app will use offline demo analysis.
final analyzeBaseUrlProvider = Provider<String?>((ref) {
  ref.watch(mdApiBaseRevisionProvider);
  return ApiConstants.resolveAnalyzeBase(ref.watch(sharedPrefsProvider));
});

/// Bumped when prompts are saved or deleted so “Recent prompts” refreshes.
final promptHistoryRevisionProvider = StateProvider<int>((ref) => 0);

/// Set to `true` from the output screen **Regenerate** control so the next
/// client-side generation uses Tier 2 lightweight model. Cleared after one read
/// when the user runs **Generate** again on the prompt screen.
final preferLightweightNextGenerationProvider = StateProvider<bool>((ref) => false);

/// [UserInputModel] used for the last **live** navigation to `/output` (prompt screen or remix).
/// Cleared when opening a saved prompt from history/recent so follow-up continuation does not
/// silently use the wrong settings. When null, [OutputScreen] falls back to [promptFormProvider].
final lastOutputGenerationInputProvider =
    StateProvider<UserInputModel?>((ref) => null);

/// Last analysis result for prompt screen + optional session path to audio.
final analysisResultProvider =
    StateProvider<AudioAnalysisModel?>((ref) => null);

/// Picked or recorded audio (path on IO, bytes on web).
final audioSessionProvider = StateProvider<AudioSession?>((ref) => null);

/// Duration of the loaded track (from player metadata), for prompts + UI.
final audioDurationProvider = StateProvider<Duration?>((ref) => null);

final promptFormProvider =
    NotifierProvider<PromptFormNotifier, UserInputModel>(PromptFormNotifier.new);

class PromptFormNotifier extends Notifier<UserInputModel> {
  @override
  UserInputModel build() => const UserInputModel();

  /// Replaces entire current form state safely.
  void replace(UserInputModel m) => state = m;

  /// Resets the form back to clean baseline parameters.
  void reset() => state = const UserInputModel();

  void setSunoVersion(String v) {
    final next = SunoVersion.migrateToUiValue(v);
    if (state.sunoVersion == next) return;
    state = state.copyWith(sunoVersion: next);
  }

  void setPrimaryGenre(String g) {
    if (state.primaryGenre == g) return;
    state = state.copyWith(primaryGenre: g);
  }

  void setGenreSelection(String primary, {String fusion = ''}) {
    if (state.primaryGenre == primary && state.subGenreFusion == fusion) return;
    state = state.copyWith(primaryGenre: primary, subGenreFusion: fusion);
  }

  void setSubGenreFusion(String s) {
    if (state.subGenreFusion == s) return;
    state = state.copyWith(subGenreFusion: s);
  }

  void setVibe(String v) {
    if (state.vibe == v) return;
    state = state.copyWith(vibe: v);
  }

  void setBpm(String? b) {
    if (state.bpm == b) return;
    state = state.copyWith(bpm: b);
  }

  void setKeyScale({String? root, String? scale}) {
    if (state.keyRoot == root && state.scale == scale) return;
    state = state.copyWith(keyRoot: root, scale: scale);
  }

  void setVocal({String? spec, String? tone}) {
    if (state.vocalSpec == spec && state.vocalTone == tone) return;
    state = state.copyWith(vocalSpec: spec, vocalTone: tone);
  }

  void setVocalAccent(String? accent) {
    if (state.vocalAccent == accent) return;
    state = state.copyWith(vocalAccent: accent);
  }

  void setDialectStyleId(String id) {
    if (state.dialectStyleId == id) return;
    state = state.copyWith(dialectStyleId: id);
  }

  void setDialectVariantId(String id) {
    if (state.dialectVariantId == id) return;
    state = state.copyWith(dialectVariantId: id);
  }

  void setAudioEnvironmentModeId(String id) {
    if (state.audioEnvironmentModeId == id) return;
    state = state.copyWith(audioEnvironmentModeId: id);
  }

  void setReferenceArtists(String s) {
    if (state.referenceArtists == s) return;
    state = state.copyWith(referenceArtists: s);
  }

  void setSonicTags(List<String> tags) {
    if (_listEquals(state.sonicTags, tags)) return;
    state = state.copyWith(sonicTags: List<String>.from(tags));
  }

  void setAvoid(String s) {
    if (state.avoid == s) return;
    state = state.copyWith(avoid: s);
  }

  void setLanguage(String s) {
    if (state.language == s) return;
    state = state.copyWith(language: s);
  }

  void setIncludeAnalyzer(bool v) {
    if (state.includeAnalyzerData == v) return;
    state = state.copyWith(includeAnalyzerData: v);
  }

  void setAnalyzerSummary(String s) {
    if (state.analyzerSummary == s) return;
    state = state.copyWith(analyzerSummary: s);
  }

  void setTrackDurationLabel(String? label) {
    if (state.trackDurationLabel == label) return;
    state = state.copyWith(trackDurationLabel: label);
  }

  void setTrackDuration(TrackDuration d) {
    if (state.trackDuration == d) return;
    state = state.copyWith(trackDuration: d);
  }

  void setDjIntroMixIn(bool v) {
    if (state.djIntroMixIn == v) return;
    state = state.copyWith(djIntroMixIn: v);
  }

  void setDjOutroMixOut(bool v) {
    if (state.djOutroMixOut == v) return;
    state = state.copyWith(djOutroMixOut: v);
  }

  void setSongStructurePreset(String id) {
    if (state.songStructurePresetId == id) return;
    state = state.copyWith(songStructurePresetId: id);
  }

  void setSongStructureCustom(String notes) {
    if (state.songStructureCustom == notes) return;
    state = state.copyWith(songStructureCustom: notes);
  }

  void setOptionalLyrics(String lyrics) {
    if (state.optionalLyrics == lyrics) return;
    state = state.copyWith(optionalLyrics: lyrics);
  }

  void setRemixOriginalSongTitle(String s) {
    if (state.remixOriginalSongTitle == s) return;
    // Editing interpolation source clears analyzer genre-flip (mutual exclusion).
    state = state.copyWith(
      remixOriginalSongTitle: s,
      remixFromAnalyzer: false,
    );
  }

  void setRemixOriginalArtist(String s) {
    if (state.remixOriginalArtist == s) return;
    state = state.copyWith(
      remixOriginalArtist: s,
      remixFromAnalyzer: false,
    );
  }

  void setSongGenerationType(SongGenerationType t) {
    if (state.songGenerationType == t) return;
    state = state.copyWith(songGenerationType: t);
  }

  void setRealInstrumentals(String s) {
    if (state.realInstrumentals == s) return;
    state = state.copyWith(realInstrumentals: s);
  }

  void setMelodyStyleId(String id) {
    if (state.melodyStyleId == id) return;
    state = state.copyWith(melodyStyleId: id);
  }

  void setMelodyCustomNotes(String s) {
    if (state.melodyCustomNotes == s) return;
    state = state.copyWith(melodyCustomNotes: s);
  }

  void setMelodyEvolution(MelodyEvolution mode) {
    if (state.melodyEvolution == mode) return;
    state = state.copyWith(melodyEvolution: mode);
  }

  void setChordProgression(String s) {
    if (state.chordProgression == s) return;
    state = state.copyWith(chordProgression: s);
  }

  void setGenerateLyrics(bool v) {
    if (state.generateLyrics == v) return;
    state = state.copyWith(generateLyrics: v);
  }

  void setUseVibeAsLyricSource(bool value) {
    if (state.useVibeAsLyricSource == value) return;
    state = state.copyWith(
      useVibeAsLyricSource: value,
      generateLyrics: value ? true : state.generateLyrics,
    );
  }

  void setLyricThemeNotes(String s) {
    if (state.lyricThemeNotes == s) return;
    state = state.copyWith(lyricThemeNotes: s);
  }

  void setActiveModifierCodes(String s) {
    if (state.activeModifierCodes == s) return;
    state = state.copyWith(activeModifierCodes: s);
  }

  void setHumanRealism(int level) {
    if (state.humanRealism == level) return;
    state = state.copyWith(humanRealism: level);
  }

  void setProductionIntensity(int level) {
    if (state.productionIntensity == level) return;
    state = state.copyWith(productionIntensity: level);
  }

  void setGenreFxLaneId(String laneId) {
    if (state.genreFxLaneId == laneId) return;
    state = state.copyWith(genreFxLaneId: laneId);
  }

  void setSunoFieldOutputMode(SunoFieldOutputMode m) {
    if (state.sunoFieldOutputMode == m) return;
    state = state.copyWith(sunoFieldOutputMode: m);
  }

  void applyAnalysis(AudioAnalysisModel m, {String? trackDurationLabel}) {
    state = state.copyWith(
      analyzerSummary: m.toPromptSummary(),
      bpm: m.bpm?.toStringAsFixed(0),
      includeAnalyzerData: true,
      trackDurationLabel: trackDurationLabel ?? state.trackDurationLabel,
      remixFromAnalyzer: false,
    );
  }

  /// Fills the form for a **genre remix**: Suno prompt that flips analyzed audio into [targetGenre].
  /// Preserves [UserInputModel.sunoVersion] and other unmapped fields via [UserInputModel.copyWith].
  void applyRemixFromAnalysis({
    required AudioAnalysisModel analysis,
    required String targetGenre,
    String? trackDurationLabel,
    bool djIntroMixIn = false,
    bool djOutroMixOut = false,
  }) {
    final source = analysis.genre ?? 'uploaded audio';
    final computedVibe = '''
Genre remix / flip for Suno — target: $targetGenre

Re-imagine the source material as a convincing $targetGenre track. Keep rhythmic energy and emotional intent where they fit the new genre, but replace drum patterns, bass role, harmonic language, and mix aesthetic with idiomatic $targetGenre production (not a thin stylistic filter).

Source estimate: $source → destination: $targetGenre. In SUNO STYLE, briefly describe how drums, low-end, chords/pads, and leads change — stay within the model word budget (do not pad with repetition).
'''.trim();

    state = state.copyWith(
      primaryGenre: targetGenre,
      subGenreFusion: 'Remix · cross-genre',
      vibe: computedVibe,
      bpm: analysis.bpm?.toStringAsFixed(0),
      includeAnalyzerData: true,
      analyzerSummary:
          '${analysis.toPromptSummary()}\n\n[Remix target: $targetGenre]',
      trackDurationLabel: trackDurationLabel ?? state.trackDurationLabel,
      djIntroMixIn: djIntroMixIn,
      djOutroMixOut: djOutroMixOut,
      generateLyrics: false,
      remixFromAnalyzer: true,
      remixOriginalSongTitle: '',
      remixOriginalArtist: '',
      sunoFieldOutputMode: SunoFieldOutputMode.custom,
    );
  }
}

bool _listEquals(List<String> a, List<String> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
