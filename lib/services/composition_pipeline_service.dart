import '../config/melody_config.dart';
import '../core/suno_prompt_router.dart';
import '../data/models/melody_evolution.dart';
import '../data/models/user_input_model.dart';
import 'melody_composer_service.dart';

/// Fully composed prompt assets ready for [AiRepository.generatePrompt].
class CompositionResult {
  const CompositionResult({
    required this.composedInput,
    this.genreKeys = const [],
    this.genreStyleTokens = const [],
    this.melodyStyleTokens = const [],
    this.userNotices = const [],
  });

  /// Lyrics and vibe with melody + genre DNA applied.
  final UserInputModel composedInput;

  /// Canonical genre keys resolved from primary + fusion.
  final List<String> genreKeys;

  /// Descriptive tags contributed by [SunoPromptRouterV2] genre DNA.
  final List<String> genreStyleTokens;

  /// Style-prompt tokens from melody composition (includes evolution plan).
  final List<String> melodyStyleTokens;

  /// Informational messages for the UI layer to display.
  final List<String> userNotices;

  /// Same composed lyrics and genre/melody tokens with a different base vibe.
  UserInputModel withVibe(String vibe) => composedInput.copyWith(
        vibe: SunoPromptRouterV2.composeStyleField(
          userVibe: vibe.trim(),
          genreKeys: genreKeys,
          additionalTokens: melodyStyleTokens,
          sunoVersion: composedInput.sunoVersion,
        ),
      );
}

/// Central composition step before any prompt generation path.
class CompositionPipelineService {
  CompositionPipelineService._();

  /// Runs genre DNA + melody composition into a single style field.
  ///
  /// [vibeOverride] replaces [userInput.vibe] before composition (A/B compare).
  static CompositionResult run({
    required UserInputModel userInput,
    String? vibeOverride,
  }) {
    final baseVibe = (vibeOverride ?? userInput.vibe).trim();
    final working = userInput.copyWith(vibe: baseVibe);

    final genreKeys = SunoPromptRouterV2.resolveGenreKeys(
      primaryGenre: working.primaryGenre,
      subGenreFusion: working.subGenreFusion,
    );
    final genreStyleTokens = SunoPromptRouterV2.getDnaTagsForGenres(genreKeys);

    final melodyResult = MelodyComposerService.compose(
      melodyDirectiveId: working.melodyStyleId,
      evolution: working.melodyEvolution,
      customMelodyNotes: working.melodyCustomNotes,
      originalLyrics: working.optionalLyrics,
      primaryGenre: working.primaryGenre,
      subGenreFusion: working.subGenreFusion,
    );

    final melodyInstruction = _buildMelodyInstruction(
      melodyToken: melodyResult.melodyStyleToken,
      evolution: working.melodyEvolution,
    );
    final melodyTokensForVibe =
        melodyInstruction.isEmpty ? <String>[] : [melodyInstruction];

    final composedVibe = SunoPromptRouterV2.composeStyleField(
      userVibe: baseVibe,
      genreKeys: genreKeys,
      additionalTokens: melodyTokensForVibe,
      sunoVersion: working.sunoVersion,
    );

    return CompositionResult(
      composedInput: working.copyWith(
        optionalLyrics: melodyResult.modifiedLyrics,
        vibe: composedVibe,
      ),
      genreKeys: genreKeys,
      genreStyleTokens: genreStyleTokens,
      melodyStyleTokens: melodyTokensForVibe,
      userNotices: melodyResult.userNotices,
    );
  }

  /// Combines the genre-aware style token with an explicit evolution plan.
  static String _buildMelodyInstruction({
    required String melodyToken,
    required MelodyEvolution evolution,
  }) {
    if (melodyToken.trim().isEmpty) {
      return MelodyConfig.buildMelodyEvolutionPlan(evolution);
    }
    return '$melodyToken. ${MelodyConfig.buildMelodyEvolutionPlan(evolution)}';
  }

  /// Legacy helper — prefer [SunoPromptRouterV2.composeStyleField].
  static String mergeVibeWithTokens(String vibe, List<String> tokens) {
    if (tokens.isEmpty) return vibe.trim();
    final tokenStr = tokens.join(', ');
    final trimmed = vibe.trim();
    if (trimmed.isEmpty) return tokenStr;
    return '$trimmed, $tokenStr';
  }
}
