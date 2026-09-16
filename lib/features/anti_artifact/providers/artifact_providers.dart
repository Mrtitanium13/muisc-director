import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/engine_config.dart';
import '../../../services/duration_budgeter.dart';
import '../../../services/lyric_linter.dart';
import '../../../services/prompt_assembler.dart';
import '../../../services/reroll_coach.dart';

class ArtifactFormState {
  const ArtifactFormState({
    this.modelVersion = EngineConfig.preferredModelKey,
    this.genres = const ['electronic'],
    this.tempo = 'mid',
    this.vocal = 'female',
    this.mood,
    this.customTokens = const [],
    this.lyrics = '',
    this.failCount = 0,
    this.dismissedWarnings = const {},
  });

  final String modelVersion;
  final List<String> genres;
  final String tempo;
  final String vocal;
  final String? mood;
  final List<String> customTokens;
  final String lyrics;
  final int failCount;
  final Set<String> dismissedWarnings;

  AssemblerInput get input => AssemblerInput(
        modelVersion: modelVersion,
        genres: genres,
        tempo: tempo,
        vocal: vocal,
        mood: mood,
        customTokens: customTokens,
      );

  ArtifactFormState copyWith({
    String? modelVersion,
    List<String>? genres,
    String? tempo,
    String? vocal,
    String? Function()? mood,
    List<String>? customTokens,
    String? lyrics,
    int? failCount,
    Set<String>? dismissedWarnings,
  }) =>
      ArtifactFormState(
        modelVersion: modelVersion ?? this.modelVersion,
        genres: genres ?? this.genres,
        tempo: tempo ?? this.tempo,
        vocal: vocal ?? this.vocal,
        mood: mood != null ? mood() : this.mood,
        customTokens: customTokens ?? this.customTokens,
        lyrics: lyrics ?? this.lyrics,
        failCount: failCount ?? this.failCount,
        dismissedWarnings: dismissedWarnings ?? this.dismissedWarnings,
      );
}

class ArtifactFormNotifier extends StateNotifier<ArtifactFormState> {
  ArtifactFormNotifier() : super(const ArtifactFormState());

  void setModelVersion(String v) =>
      state = state.copyWith(modelVersion: EngineConfig.migrateModelKey(v));

  void toggleGenre(String key) {
    final resolved = EngineConfig.migrateModelKey(state.modelVersion);
    final maxGenres = EngineConfig.maxGenresByModel[resolved] ??
        EngineConfig.maxGenreTokens;
    final current = List<String>.from(state.genres);
    if (current.contains(key)) {
      current.remove(key);
    } else if (current.length < maxGenres) {
      current.add(key);
    }
    if (current.isEmpty) return;
    state = state.copyWith(genres: current);
  }

  void addCustomToken(String token) {
    if (state.customTokens.contains(token)) return;
    state = state.copyWith(
      customTokens: [...state.customTokens, token],
    );
  }

  void setTempo(String v) => state = state.copyWith(tempo: v);
  void setVocal(String v) => state = state.copyWith(vocal: v);

  void setMood(String? v) => state = state.copyWith(mood: () => v);

  void setLyrics(String v) => state = state.copyWith(lyrics: v);

  void incrementFailCount() =>
      state = state.copyWith(failCount: state.failCount + 1);

  void resetFailCount() => state = state.copyWith(failCount: 0);

  void dismissWarning(String w) {
    state = state.copyWith(
      dismissedWarnings: {...state.dismissedWarnings, w},
    );
  }
}

final artifactFormProvider =
    StateNotifierProvider<ArtifactFormNotifier, ArtifactFormState>(
  (ref) => ArtifactFormNotifier(),
);

final assemblerOutputProvider = Provider<AssemblerOutput>((ref) {
  final form = ref.watch(artifactFormProvider);
  return PromptAssembler.assemble(form.input);
});

final lintIssuesProvider = Provider<List<LintIssue>>((ref) {
  final form = ref.watch(artifactFormProvider);
  final output = ref.watch(assemblerOutputProvider);
  if (form.lyrics.trim().isEmpty) return [];
  return LyricLinter.lint(form.lyrics, syllableCap: output.syllableCap);
});

final durationResultProvider = Provider<DurationResult>((ref) {
  final form = ref.watch(artifactFormProvider);
  return DurationBudgeter.estimate(
    lyrics: form.lyrics,
    tempo: form.tempo,
    modelVersion: form.modelVersion,
  );
});

final verifiedPromptsProvider =
    FutureProvider<List<VerifiedPrompt>>((ref) async {
  return RerollCoach.loadVerifiedPrompts();
});
