import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/models/suno_field_output_mode.dart';
import '../../data/models/user_input_model.dart';
import 'dialect_style_data.dart';
import '../utils/api_base_url_normalize.dart';
import '../utils/api_base_url_resolver.dart';
import '../utils/openai_key_validation.dart';
import '../utils/suno_block2_opt_out.dart';

/// API URLs, env keys, and **tiered chat model routing** for prompt generation.
///
/// **On-device chat** (when `MD_API_BASE_URL` is unset) uses the provider selected in
/// Settings — separate LaoZhang and OpenRouter keys ([OnDeviceApiKeys]).
///
/// **Server** (`/generate-prompt`, Gemini `/analyze`) defaults to LaoZhang when
/// `OPENAI_BASE_URL` is unset; set `OPENROUTER_ONLY=true` for OpenRouter on Railway.
///
/// ## Recommended production architecture (summary)
///
/// **Tier 1 — Primary generation (LaoZhang)**  
/// Hybrid default: Terra English draft / Astra multilingual → Claude lyrics polish → Astra/Claude humanization.  
/// Use: full prompts, lyrics + structure (Block 2), BEASTMODE, fusion/remix,
/// analyzer-heavy user blocks, DJ constraints, v5.0 / v5.5 tiers.
///
/// **Tier 2 — Fast lightweight**  
/// LaoZhang: [laozhangLightChatModel]. OpenRouter: [openRouterLightChatModel].  
/// Use: **Regenerate** re-runs, **Simple + explicit Block 2 opt-out** (`userRequestedBlock2OptOut`),
/// and legacy short-tier runs that meet the same narrow criteria.
///
/// **Tier 3 — Audio analysis**  
/// Server: Gemini 2.5 Flash/Pro via LaoZhang (`/analyze`); librosa fallback if Gemini fails.
///
/// **Tier 4 — Fallback**  
/// Provider-specific fallback model on 429 / 502 / 503.
///
/// ## Rough cost reference (indicative only)
///
/// Full v5.5 + lyrics on Tier 1 is typically a few cents per run; Tier 2 is
/// an order of magnitude cheaper. Exact spend depends on system prompt size and
/// completion length (see `SunoPromptLimits.maxCompletionTokensFor`).
class ApiConstants {
  ApiConstants._();

  // ── OpenAI (direct) ─────────────────────────────────────────────────
  static const String openAiApiBaseUrl = 'https://api.openai.com/v1';

  static const String openAiChatCompletions =
      'https://api.openai.com/v1/chat/completions';

  /// Reference: native OpenAI chat model id (not used by the Flutter client for prompts).
  static const String openAiPrimaryChatModel = 'gpt-4o';

  /// Reference: native OpenAI lightweight id (not used by the Flutter client for prompts).
  static const String openAiLightChatModel = 'gpt-4o-mini';

  // ── LaoZhang API (default on-device + server) ─────────────────────
  static const String laozhangApiBaseUrl = 'https://api.laozhang.ai/v1';

  static const String laozhangChatCompletions =
      '$laozhangApiBaseUrl/chat/completions';

  /// LaoZhang Gemini (server `/analyze` + lightweight prompt tier).
  static const String laozhangGeminiFlashModel = 'gemini-2.5-flash';

  /// LaoZhang primary Suno prompt model (large context for ~150k-char system prompt).
  static const String laozhangGeminiProModel = 'gemini-2.5-pro';

  // ── OpenRouter (OpenAI-compatible, optional) ───────────────────────
  static const String openRouterChatCompletions =
      'https://openrouter.ai/api/v1/chat/completions';

  /// OpenRouter generate / theme / compression (Qwen 3.7 Plus).
  static const String openRouterGenerateChatModel = 'qwen/qwen3.7-plus';

  /// OpenRouter humanization rewrite pass (Mistral Large).
  static const String openRouterHumanizationChatModel =
      'mistralai/mistral-large';

  /// Alias — primary generation uses Qwen 3.7 for all languages.
  static const String openRouterPrimaryChatModel = openRouterGenerateChatModel;

  /// Multilingual generation also uses Qwen 3.7 (Mistral is humanization-only).
  static const String openRouterMultilingualPrimaryChatModel =
      openRouterGenerateChatModel;

  static const String openRouterThemeConsistencyChatModel =
      openRouterGenerateChatModel;

  static const String openRouterCompressionChatModel =
      openRouterGenerateChatModel;

  static const String openRouterLightChatModel = 'openai/gpt-4o-mini';

  /// Tier 4 — same HTTP shape as OpenAI; used only after retriable errors.
  static const String openRouterFallbackChatModel =
      'anthropic/claude-3.5-haiku';

  /// Default when docs mention OpenRouter without distinguishing tier / language.
  static const String openRouterModelDefault = openRouterPrimaryChatModel;

  /// LaoZhang GPT-6 Astra — multilingual draft + lyrics humanization (full capability).
  static const String laozhangGpt6AstraModel = 'gpt-6-astra';

  /// LaoZhang GPT-5.6 Sol — songwriter creative fallback.
  static const String laozhangGpt56SolModel = 'gpt-5.6-sol';

  /// LaoZhang GPT-5.6 Terra — English Suno structure draft.
  static const String laozhangGpt56TerraModel = 'gpt-5.6-terra';

  /// LaoZhang GPT-5.6 Luna — mechanical compression / light stages.
  static const String laozhangGpt56LunaModel = 'gpt-5.6-luna';

  /// LaoZhang lyrics + artistic expression (Claude Sonnet 4.5).
  static const String laozhangClaudeSonnet45Model = 'claude-sonnet-4-5';

  /// Multilingual / Pidgin prompt draft (Astra).
  static const String laozhangPromptChatModel = laozhangGpt6AstraModel;

  /// Alias — multilingual frontier draft model.
  static const String laozhangVisionChatModel = laozhangPromptChatModel;

  /// English production draft (Terra).
  static const String laozhangEnglishDraftChatModel = laozhangGpt56TerraModel;

  static const String laozhangLyricsPrimaryChatModel = laozhangClaudeSonnet45Model;

  static const String laozhangLyricsSecondaryChatModel = laozhangGeminiProModel;

  /// Style-only / Block 2 opt-out — Gemini Pro (large system prompt context).
  static const String laozhangStyleOnlyChatModel = laozhangGeminiProModel;

  static const String laozhangPrimaryChatModel = laozhangEnglishDraftChatModel;

  static const String laozhangMultilingualPrimaryChatModel =
      laozhangPromptChatModel;

  static const String laozhangLightChatModel = laozhangGeminiFlashModel;

  static const String laozhangFallbackChatModel = laozhangLyricsSecondaryChatModel;

  static const String laozhangPolishChatModel = laozhangLyricsPrimaryChatModel;

  /// Theme consistency post-pass — lyrics + expression editorial (Claude on LaoZhang).
  static const String laozhangThemeConsistencyChatModel =
      laozhangLyricsPrimaryChatModel;

  /// Multilingual / Pidgin humanization (Astra — must be humanized).
  static const String laozhangHumanizationMultilingualChatModel =
      laozhangGpt6AstraModel;

  /// English humanization (Claude).
  static const String laozhangHumanizationEnglishChatModel =
      laozhangLyricsPrimaryChatModel;

  /// Mechanical Suno compression (Luna).
  static const String laozhangCompressionChatModel = laozhangGpt56LunaModel;

  // ── Anthropic (reference — no direct client in app yet) ─────────────
  static const String anthropicMessagesBaseUrl =
      'https://api.anthropic.com/v1/messages';

  /// Haiku 3.5 class (not "4.5"); use with Anthropic API or OpenRouter slug above.
  static const String anthropicFallbackModelId = 'claude-3-5-haiku-latest';

  // ── Temperature (chat) ──────────────────────────────────────────────
  /// Default Path B / simpler instrumental prompts.
  static const double promptTemperatureDefault = 0.75;

  /// Path A / C or any generation that includes a lyrics block.
  static const double promptTemperatureLyricsPath = 0.85;

  /// When user includes /BEASTMODE (or similar) in vibe / modifiers.
  static const double promptTemperatureBeastmode = 0.80;

  // ── Legacy documentation caps (actual caps: [SunoPromptLimits]) ────
  static const int chatMaxTokensV45Hint = 400;
  static const int chatMaxTokensV50Hint = 350;
  static const int chatMaxTokensV55Hint = 500;
  static const int chatMaxTokensLyricsAddonHint = 650;

  static const String envOpenAiKey = 'OPENAI_API_KEY';
  static const String envAudioBaseUrl = 'AUDIO_ANALYSIS_BASE_URL';
  static const String envMdApiBaseUrl = 'MD_API_BASE_URL';

  /// When true, server uses OpenRouter instead of LaoZhang (Railway env).
  static const String envOpenRouterOnly = 'OPENROUTER_ONLY';

  /// When `false` / `0` / `no` / `off`, use legacy [kSunoDirectorSystemPrompt] (word-budget v1).
  /// When unset or `true` / `1` / `yes`, use [kSunoDirectorSystemPromptV2Candidate] (Path A/B/C + genre appendix).
  static const String envUseSunoPromptV2 = 'USE_SUNO_PROMPT_V2';
  static const String envThemeConsistencyPass = 'THEME_CONSISTENCY_PASS';

  static const String prefMdApiBaseUrl = 'md_api_base_url';

  /// Unified backend (same origin as `server/` FastAPI). Overrides `.env` when set in Settings.
  static String? resolveMdApiBase(SharedPreferences prefs) {
    final fromPrefs = prefs.getString(prefMdApiBaseUrl)?.trim();
    if (fromPrefs != null && fromPrefs.isNotEmpty) {
      return resolveDeviceApiBaseUrl(_normalizedAndRepairPrefs(prefs, fromPrefs));
    }
    final fromEnv = dotenv.env[envMdApiBaseUrl]?.trim();
    if (fromEnv != null && fromEnv.isNotEmpty) {
      return resolveDeviceApiBaseUrl(normalizeApiBaseUrl(fromEnv));
    }
    return null;
  }

  /// Fixes https→http on LAN and persists so older saved URLs keep working.
  static String _normalizedAndRepairPrefs(SharedPreferences prefs, String raw) {
    final normalized = normalizeApiBaseUrl(raw);
    if (normalized != raw) {
      prefs.setString(prefMdApiBaseUrl, normalized);
    }
    return normalized;
  }

  /// Analysis only (legacy). Used when [resolveMdApiBase] is null.
  static String? resolveLegacyAudioBase() {
    final v = dotenv.env[envAudioBaseUrl]?.trim();
    if (v != null && v.isNotEmpty) {
      return resolveDeviceApiBaseUrl(v);
    }
    return null;
  }

  /// Base URL for `/analyze` and `/generate-prompt` (no trailing slash).
  static String? resolveAnalyzeBase(SharedPreferences prefs) {
    return resolveMdApiBase(prefs) ?? resolveLegacyAudioBase();
  }

  static bool useServerPrompt(SharedPreferences prefs) =>
      resolveMdApiBase(prefs) != null;

  /// V2 master prompt is **on by default** (Path A/B/C, Human Songwriter Engine, genre reference appendix).
  /// Set `USE_SUNO_PROMPT_V2=false` in `.env` to use the legacy word-budget system prompt.
  static bool useSunoPromptV2Candidate() {
    final v = dotenv.env[envUseSunoPromptV2]?.trim().toLowerCase();
    if (v == null || v.isEmpty) return true;
    if (v == 'false' || v == '0' || v == 'no' || v == 'off') return false;
    return true;
  }

  /// Post-processing theme consistency on Block 2 (on by default). Set `THEME_CONSISTENCY_PASS=false` to disable.
  static bool themeConsistencyEnabled() {
    final v = dotenv.env[envThemeConsistencyPass]?.trim().toLowerCase();
    if (v == null || v.isEmpty) return true;
    if (v == 'false' || v == '0' || v == 'no' || v == 'off') return false;
    return true;
  }

  // ── Model routing ───────────────────────────────────────────────────

  /// On-device: OpenRouter when the saved key looks like OpenRouter; else LaoZhang.
  static bool useOpenRouterForOnDeviceKey(String apiKey) =>
      looksLikeOpenRouterKey(apiKey);

  /// Gemini 2.5 Flash draft → Flash polish (skipped for Regenerate / lightweight tier).
  static bool useHybridPromptPipeline({
    required bool lightweight,
    required String apiKey,
  }) =>
      useHybridPromptPipelineForProvider(
        lightweight: lightweight,
        useOpenRouter: useOpenRouterForOnDeviceKey(apiKey),
      );

  static bool useHybridPromptPipelineForProvider({
    required bool lightweight,
    required bool useOpenRouter,
  }) {
    if (lightweight) return false;
    if (!useOpenRouter) return true;
    return false;
  }

  static String draftModelForPrompt({
    required String language,
    required bool lightweight,
    required String apiKey,
  }) =>
      draftModelForPromptWithProvider(
        language: language,
        lightweight: lightweight,
        useOpenRouter: useOpenRouterForOnDeviceKey(apiKey),
      );

  static String draftModelForPromptWithProvider({
    required String language,
    required bool lightweight,
    required bool useOpenRouter,
    bool lyricsTask = true,
  }) =>
      chatModelForPromptWithProvider(
        language: language,
        lightweight: lightweight,
        useOpenRouter: useOpenRouter,
        lyricsTask: lyricsTask,
      );

  static String polishModelForPrompt({required String apiKey}) =>
      polishModelForPromptWithProvider(
        useOpenRouter: useOpenRouterForOnDeviceKey(apiKey),
      );

  static String polishModelForPromptWithProvider({required bool useOpenRouter}) =>
      useOpenRouter ? openRouterGenerateChatModel : laozhangPolishChatModel;

  /// Theme consistency: Qwen 3.7 (OpenRouter) · Claude Sonnet 4.5 (LaoZhang).
  static String themeConsistencyModelForPromptWithProvider({
    required bool useOpenRouter,
  }) =>
      useOpenRouter
          ? openRouterThemeConsistencyChatModel
          : laozhangThemeConsistencyChatModel;

  /// Humanization: Mistral (OpenRouter) · Claude English · GPT-6 Astra multilingual/Pidgin (LaoZhang).
  static bool laozhangMultilingualHumanization({
    required String language,
    String? dialectStyleId,
  }) {
    if (DialectStyleData.isNigerianPidgin(dialectStyleId)) return true;
    return preferMultilingualPrimaryModelForLanguage(language);
  }

  static String humanizationModelForProvider({required bool useOpenRouter}) =>
      useOpenRouter
          ? openRouterHumanizationChatModel
          : laozhangHumanizationEnglishChatModel;

  static String humanizationModelForPrompt({
    required bool useOpenRouter,
    required String language,
    String? dialectStyleId,
  }) {
    if (useOpenRouter) return openRouterHumanizationChatModel;
    if (laozhangMultilingualHumanization(
      language: language,
      dialectStyleId: dialectStyleId,
    )) {
      return laozhangHumanizationMultilingualChatModel;
    }
    return laozhangHumanizationEnglishChatModel;
  }

  /// OpenRouter: Qwen 3.7 Plus. LaoZhang: Luna (mechanical Suno caps).
  static String compressionModelForProvider({required bool useOpenRouter}) =>
      useOpenRouter
          ? openRouterCompressionChatModel
          : laozhangCompressionChatModel;

  static bool openRouterPostProcessEnabled() {
    final v = dotenv.env['OPENROUTER_POST_PROCESS']?.trim().toLowerCase();
    if (v == null || v.isEmpty) return true;
    if (v == 'false' || v == '0' || v == 'no' || v == 'off') return false;
    return true;
  }

  static bool humanizationPassEnabled() =>
      _envFlagDefaultTrue('HUMANIZATION_PASS');

  static bool sunoCompressionPassEnabled() =>
      _envFlagDefaultTrue('SUNO_COMPRESSION_PASS');

  static bool _envFlagDefaultTrue(String key) {
    final v = dotenv.env[key]?.trim().toLowerCase();
    if (v == null || v.isEmpty) return true;
    if (v == 'false' || v == '0' || v == 'no' || v == 'off') return false;
    return true;
  }

  /// Chat completions URL for on-device generation from [apiKey] shape.
  static String onDeviceChatCompletionsUrl(String apiKey) =>
      useOpenRouterForOnDeviceKey(apiKey)
          ? openRouterChatCompletions
          : laozhangChatCompletions;

  /// Tiered model id for on-device prompt generation.
  static String chatModelForPrompt({
    required String language,
    required bool lightweight,
    required String apiKey,
  }) =>
      chatModelForPromptWithProvider(
        language: language,
        lightweight: lightweight,
        useOpenRouter: useOpenRouterForOnDeviceKey(apiKey),
      );

  static String chatModelForPromptWithProvider({
    required String language,
    required bool lightweight,
    required bool useOpenRouter,
    bool lyricsTask = true,
  }) {
    if (useOpenRouter) {
      return openRouterChatModelForPrompt(
        language: language,
        lightweight: lightweight,
      );
    }
    return laozhangChatModelForPrompt(
      language: language,
      lightweight: lightweight,
      lyricsTask: lyricsTask,
    );
  }

  static String fallbackModelForKey(String apiKey) =>
      fallbackModelForProvider(
        useOpenRouter: useOpenRouterForOnDeviceKey(apiKey),
      );

  static String fallbackModelForProvider({
    required bool useOpenRouter,
    bool lyricsTask = true,
  }) =>
      useOpenRouter
          ? openRouterFallbackChatModel
          : (lyricsTask
              ? laozhangLyricsSecondaryChatModel
              : laozhangStyleOnlyChatModel);

  /// LaoZhang: Terra English draft · Astra multilingual · Claude polish · Luna compression · Flash light.
  static String laozhangChatModelForPrompt({
    required String language,
    required bool lightweight,
    bool lyricsTask = true,
  }) {
    if (lightweight) return laozhangLightChatModel;
    if (!lyricsTask) return laozhangStyleOnlyChatModel;
    if (preferMultilingualPrimaryModelForLanguage(language)) {
      return laozhangMultilingualPrimaryChatModel;
    }
    return laozhangEnglishDraftChatModel;
  }

  /// True when [language] requests non-English lyric/instruction output (form: Language field).
  static bool preferMultilingualPrimaryModelForLanguage(String language) {
    final t = language.trim().toLowerCase();
    if (t.isEmpty) return false;
    if (t == 'english') return false;
    if (t.startsWith('english ') ||
        t.startsWith('english(') ||
        t.startsWith('english,')) {
      return false;
    }
    return true;
  }

  /// OpenRouter: Qwen 3.7 generate (all languages); GPT-mini when lightweight.
  static String openRouterChatModelForPrompt({
    required String language,
    required bool lightweight,
  }) {
    if (lightweight) return openRouterLightChatModel;
    return openRouterGenerateChatModel;
  }

  /// Tier 2 when `true`, Tier 1 when `false` (OpenRouter slugs vs OpenAI ids).
  ///
  /// For OpenRouter prompt generation prefer [openRouterChatModelForPrompt] so language
  /// can select Mistral Large; this method stays for tests and non-prompt callers.
  static String chatModelForTier({
    required bool useOpenRouter,
    required bool lightweight,
  }) {
    if (useOpenRouter) {
      return lightweight
          ? openRouterLightChatModel
          : openRouterPrimaryChatModel;
    }
    return lightweight ? openAiLightChatModel : openAiPrimaryChatModel;
  }

  /// Prefer **Tier 2** when [preferLightweightForRegenerate] is set, or for narrow
  /// short-tier + Block-2-opt-out cases (see implementation).
  static bool shouldUseLightweightChatModel(
    UserInputModel input, {
    bool preferLightweightForRegenerate = false,
  }) {
    if (preferLightweightForRegenerate) return true;
    if (input.sunoFieldOutputMode == SunoFieldOutputMode.simple) {
      return userRequestedBlock2OptOut(input);
    }

    final v = input.sunoVersion.trim();
    final shortTier = v == 'v4.5' || v == 'v3' || v == 'v4';
    if (!shortTier) return false;

    final hasLyrics = input.optionalLyrics.trim().isNotEmpty;
    if (hasLyrics) return false;
    if (input.generateLyrics) return false;
    if (input.remixFromAnalyzer) return false;
    if (input.djIntroMixIn || input.djOutroMixOut) return false;
    if (input.includeAnalyzerData && input.analyzerSummary.trim().isNotEmpty) {
      return false;
    }
    if (!userRequestedBlock2OptOut(input)) return false;
    return true;
  }

  static bool userRequestedBeastmode(UserInputModel input) {
    final blob =
        '${input.vibe} ${input.activeModifierCodes} ${input.avoid}'
            .toUpperCase();
    return blob.contains('/BEASTMODE') ||
        blob.contains('BEAST MODE') ||
        blob.contains('BEASTMODE');
  }

  /// Chat temperature: BEASTMODE slightly lower than default lyrics path.
  static double promptTemperatureFor(UserInputModel input) {
    if (userRequestedBeastmode(input)) return promptTemperatureBeastmode;
    final hasLyrics = input.optionalLyrics.trim().isNotEmpty;
    final simple = input.sunoFieldOutputMode == SunoFieldOutputMode.simple;
    final pathC = !simple && input.generateLyrics && !hasLyrics;
    if (hasLyrics || pathC) return promptTemperatureLyricsPath;
    if (useSunoPromptV2Candidate() && !userRequestedBlock2OptOut(input)) {
      return promptTemperatureLyricsPath;
    }
    return promptTemperatureDefault;
  }

  static bool shouldRetryWithLlmFallback(DioException e) {
    final code = e.response?.statusCode;
    return code == 429 || code == 502 || code == 503;
  }

  @Deprecated('Use shouldRetryWithLlmFallback')
  static bool shouldRetryWithOpenRouterFallback(DioException e) =>
      shouldRetryWithLlmFallback(e);
}
