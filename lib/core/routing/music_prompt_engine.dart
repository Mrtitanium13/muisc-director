import '../../data/models/user_input_model.dart';
import '../constants/api_constants.dart';
import '../constants/vocal_accent_data.dart';
import '../utils/suno_output_split.dart';
import 'music_prompt_routing.dart';
import 'music_prompt_routing_monitor.dart';
import 'prompt_engine_qa.dart';
import 'stage1_classifier.dart';
import 'stage2_model_router.dart';

/// Top-level orchestrator: Stage 1 classify → Stage 2 model + user-block append.
class MusicPromptEngine {
  MusicPromptEngine._();

  static Stage2RoutingPlan prepare({
    required UserInputModel input,
    required bool useOpenRouter,
    required bool lightweight,
    String? textHint,
  }) {
    MusicPromptRoutingMonitor.recordRoutingGateCheck();
    _warnIbibioV1Fallback(input);
    final classification = Stage1Classifier.classify(input, textHint: textHint);
    final append = Stage2ModelRouter.buildRegionalUserBlockAppend(classification);
    final modelKey = Stage2ModelRouter.pickModelKey(classification);
    return Stage2RoutingPlan(
      classification: classification,
      primaryModelKey: modelKey,
      userBlockAppend: append,
    );
  }

  static String draftModelForPlan({
    required Stage2RoutingPlan plan,
    required bool useOpenRouter,
    required bool lightweight,
  }) =>
      Stage2ModelRouter.resolveDraftModelSlug(
        classification: plan.classification,
        useOpenRouter: useOpenRouter,
        lightweight: lightweight,
      );

  static String polishModelForPlan({
    required Stage2RoutingPlan plan,
    required bool useOpenRouter,
  }) =>
      Stage2ModelRouter.resolvePolishModelSlug(
        classification: plan.classification,
        useOpenRouter: useOpenRouter,
      );

  /// Fallback to legacy language-based routing when routing is disabled.
  static String legacyDraftModel({
    required String language,
    required bool useOpenRouter,
    required bool lightweight,
    required bool lyricsTask,
  }) =>
      ApiConstants.draftModelForPromptWithProvider(
        language: language,
        lightweight: lightweight,
        useOpenRouter: useOpenRouter,
        lyricsTask: lyricsTask,
      );

  static List<String> qaWarningsForOutput(String text, {String? genre}) {
    final issues = PromptEngineQa.qaCheckSunoOutput(text);
    issues.addAll(PromptEngineQa.qaCheckStylePromptFromSunoOutput(text));
    if (genre != null && genre.trim().isNotEmpty) {
      final parsed = parseSunoOutput(text);
      final lyrics = parsed.lyricsBody?.trim();
      if (lyrics != null && lyrics.isNotEmpty) {
        issues.addAll(PromptEngineQa.qaCheckHumanizedLyrics(lyrics, genre));
      }
    }
    return issues;
  }

  static void _warnIbibioV1Fallback(UserInputModel input) {
    final accent = VocalAccentData.coerceStored(input.vocalAccent ?? '');
    if (accent != 'nigerian_ibibio') return;
    if (_isV2RoutingEnabled()) return;
    MusicPromptRoutingMonitor.warnIbibioV1Fallback();
  }

  static bool _isV2RoutingEnabled() {
    try {
      return ApiConstants.useSunoPromptV2Candidate();
    } on Object {
      return true;
    }
  }
}
