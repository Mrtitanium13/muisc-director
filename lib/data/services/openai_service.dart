import 'dart:math';

import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/api_constants.dart';
import '../../core/constants/on_device_api_keys.dart';
import '../../core/network/dio_client.dart';
import '../../core/utils/api_connectivity.dart';
import '../../core/utils/chat_completion_helpers.dart';
import '../../core/constants/melody_style_data.dart';
import '../../core/constants/song_structure_data.dart';
import '../../core/constants/suno_system_prompt_v2_candidate.dart';
import '../../core/utils/suno_block2_opt_out.dart';
import '../../core/utils/suno_format_validation.dart';
import '../../core/utils/suno_internal_output_strip.dart';
import '../../core/utils/payload_optimization.dart';
import '../../core/utils/remix_payload_compiler.dart';
import '../../data/models/audio_analysis_model.dart';
import '../../data/models/audio_analysis_model.dart';
import '../../data/models/song_generation_type.dart';
import '../../core/utils/suno_lyric_phonetic_sanitize.dart';
import '../../core/utils/suno_output_qa.dart';
import '../../core/utils/suno_output_split.dart';
import '../../core/constants/suno_prompt_limits.dart';
import '../../core/constants/block1_mix_master_directive.dart';
import '../../core/utils/drum_matrix.dart';
import '../../core/utils/genre_hybridization_matrix.dart';
import '../../core/utils/live_instrument_matrix.dart';
import '../../core/utils/code_translation_matrix.dart';
import '../../core/constants/human_authenticity_config.dart';
import '../../core/constants/genre_lyrics_directives.dart';
import '../../core/constants/human_realism_config.dart';
import '../../core/constants/production_intensity_config.dart';
import '../../core/utils/suno_prompt_builder.dart';
import '../../core/constants/hitmaker_max_martin_directives.dart';
import '../../core/constants/suno_dj_mix_directives.dart';
import '../../core/constants/suno_polish_system_prompt.dart';
import '../../core/constants/suno_system_prompt.dart';
import '../../core/constants/humanization_pass.dart';
import '../../core/constants/suno_compression_pass.dart';
import '../../core/constants/theme_consistency_pass.dart';
import '../../core/constants/dialect_style_data.dart';
import '../../core/constants/audio_environment_data.dart';
import '../../core/constants/vocal_accent_data.dart';
import '../../core/utils/theme_consistency_split.dart';
import '../models/melody_variation_mode.dart';
import '../models/suno_field_output_mode.dart';
import '../models/track_duration_config.dart';
import '../models/user_input_model.dart';

class OpenAIService {
  OpenAIService(this._dio, this._prefs);

  final Dio _dio;
  final SharedPreferences _prefs;

  static const _melodyRotateIndexKey = 'md_melody_variation_rotate_index';

  final _rand = Random();

  ({String apiKey, bool useOpenRouter}) get _onDeviceCredentials =>
      OnDeviceApiKeys.resolveActive(_prefs);

  /// [appendToUserBlock] is appended to the model user message (strict retry, A/B tests).
  /// [temperatureOverride] when non-null replaces [ApiConstants.promptTemperatureFor] for this call.
  /// When both [continuationPriorOutput] and [continuationUserRequest] are non-empty, a revision
  /// block is inserted so the model can output a full new two-block prompt from prior + follow-up.
  Future<String> generateSunoPrompt(
    UserInputModel input, {
    bool preferLightweightModel = false,
    String? appendToUserBlock,
    double? temperatureOverride,
    int? maxCompletionTokensOverride,
    String? continuationPriorOutput,
    String? continuationUserRequest,
    bool skipThemeConsistencyPass = false,
  }) async {
    final sessionVar = _resolveMelodySessionVariation(input);
    final melodyBlock = MelodyStyleData.composeUserBlock(
      melodyStyleId: input.melodyStyleId,
      melodyCustomNotes: input.melodyCustomNotes,
      sessionVariationDirective: sessionVar,
    );

    final mdBase = ApiConstants.resolveMdApiBase(_prefs);
    if (mdBase != null && mdBase.isNotEmpty) {
      try {
        await assertMusicDirectorServerReachable(mdBase);
        final text = await _generateOnServer(
          mdBase,
          input,
          melodyBlock,
          userBlockSuffix: appendToUserBlock,
          continuationPriorOutput: continuationPriorOutput,
          continuationUserRequest: continuationUserRequest,
          preferLightweightModel: preferLightweightModel,
        );
        await _advanceMelodyRotationIfNeeded(input);
        return _finalizeSunoV2Output(text, input);
      } catch (e) {
        if (_shouldFallbackToOnDeviceAfterServerFailure(e) &&
            OnDeviceApiKeys.hasActiveKey(_prefs)) {
          final onDevice = await _generateOnDeviceSunoPrompt(
            input: input,
            melodyBlock: melodyBlock,
            appendToUserBlock: appendToUserBlock,
            continuationPriorOutput: continuationPriorOutput,
            continuationUserRequest: continuationUserRequest,
            preferLightweightModel: preferLightweightModel,
            temperatureOverride: temperatureOverride,
            maxCompletionTokensOverride: maxCompletionTokensOverride,
            skipThemeConsistencyPass: skipThemeConsistencyPass,
          );
          return onDevice;
        }
        rethrow;
      }
    }

    return _generateOnDeviceSunoPrompt(
      input: input,
      melodyBlock: melodyBlock,
      appendToUserBlock: appendToUserBlock,
      continuationPriorOutput: continuationPriorOutput,
      continuationUserRequest: continuationUserRequest,
      preferLightweightModel: preferLightweightModel,
      temperatureOverride: temperatureOverride,
      maxCompletionTokensOverride: maxCompletionTokensOverride,
      skipThemeConsistencyPass: skipThemeConsistencyPass,
    );
  }

  bool _shouldFallbackToOnDeviceAfterServerFailure(Object error) {
    if (isMusicDirectorServerConnectionFailure(error)) return true;
    if (error is! DioException) return false;
    final code = error.response?.statusCode;
    if (code == 503 || code == 502 || code == 401) {
      return true;
    }
    return false;
  }

  Future<String> _generateOnDeviceSunoPrompt({
    required UserInputModel input,
    required String? melodyBlock,
    String? appendToUserBlock,
    String? continuationPriorOutput,
    String? continuationUserRequest,
    bool preferLightweightModel = false,
    double? temperatureOverride,
    int? maxCompletionTokensOverride,
    bool skipThemeConsistencyPass = false,
  }) async {
    final creds = _onDeviceCredentials;
    final key = creds.apiKey;
    var userBlock = _buildUserContent(_withGenreFxApplied(input), melodyUserBlock: melodyBlock);
    final cont = _continuationAppend(
      continuationPriorOutput,
      continuationUserRequest,
    );
    if (cont != null) {
      userBlock = '$userBlock\n\n$cont';
    }
    final suf = appendToUserBlock?.trim();
    if (suf != null && suf.isNotEmpty) {
      userBlock = '$userBlock\n\n$suf';
    }

    if (key.isEmpty) {
      throw ApiConnectivityException(
        creds.useOpenRouter
            ? 'No OpenRouter API key. Settings → OpenRouter API key (sk-or-v1-…).'
            : 'No LaoZhang API key. Settings → LaoZhang API key (api.laozhang.ai/token), '
                'then select LaoZhang as the on-device provider. '
                'OpenRouter can run on-device without a local server; LaoZhang needs your key here '
                'or a reachable PC server with OPENAI_API_KEY set.',
      );
    }

    final useOpenRouter = creds.useOpenRouter;
    final endpoint = useOpenRouter
        ? ApiConstants.openRouterChatCompletions
        : ApiConstants.laozhangChatCompletions;
    final lightweight = ApiConstants.shouldUseLightweightChatModel(
      input,
      preferLightweightForRegenerate: preferLightweightModel,
    );
    final headers = <String, String>{
      'Authorization': 'Bearer $key',
      'Content-Type': 'application/json',
      if (useOpenRouter) ...{
        'HTTP-Referer': 'https://music-director.app',
        'X-Title': 'Music Director',
      },
    };

    final lyricsTrim = input.optionalLyrics.trim();
    final hasLyrics = lyricsTrim.isNotEmpty;
    final simple = input.sunoFieldOutputMode == SunoFieldOutputMode.simple;
    final pathC = !simple && input.generateLyrics && !hasLyrics;
    final block2OptOut = userRequestedBlock2OptOut(input);
    final lyricsTask = _lyricsTaskFor(input);
    final lyricsWords = hasLyrics
        ? lyricsTrim
            .split(RegExp(r'\s+'))
            .where((w) => w.isNotEmpty)
            .length
        : 0;
    final maxTok = maxCompletionTokensOverride ??
        SunoPromptLimits.maxCompletionTokensFor(
          input.sunoVersion,
          hasUserLyrics: hasLyrics,
          userLyricsWordCount: lyricsWords,
          generateLyrics: pathC,
          useV2FormatLawStyle: ApiConstants.useSunoPromptV2Candidate(),
          sunoFieldOutputMode: input.sunoFieldOutputMode,
          block2OptOut: block2OptOut,
        );

    final temperature =
        temperatureOverride ?? ApiConstants.promptTemperatureFor(input);

    final hybridLaozhang = !useOpenRouter &&
        ApiConstants.useHybridPromptPipelineForProvider(
          lightweight: lightweight,
          useOpenRouter: false,
        ) &&
        lyricsTask;
    final effectiveMaxTok = hybridLaozhang && maxTok < 4200 ? 4200 : maxTok;

    try {
      final text = await _generateOnDevice(
        endpoint: endpoint,
        headers: headers,
        useOpenRouter: useOpenRouter,
        language: input.language,
        lightweight: lightweight,
        userBlock: userBlock,
        temperature: temperature,
        maxTok: effectiveMaxTok,
        lyricsTask: lyricsTask,
      );
      await _advanceMelodyRotationIfNeeded(input);
      return _deliverSunoOutput(
        text,
        input,
        applyThemePass: !skipThemeConsistencyPass,
      );
    } on DioException catch (e) {
      if (ApiConstants.shouldRetryWithLlmFallback(e)) {
        final text = await _completeChatCompletion(
          endpoint: endpoint,
          headers: headers,
          model: ApiConstants.fallbackModelForProvider(
            useOpenRouter: useOpenRouter,
            lyricsTask: lyricsTask,
          ),
          systemContent: _systemPromptForProvider(useOpenRouter),
          userBlock: userBlock,
          temperature: temperature,
          maxTok: maxTok,
          applyLaozhangHygiene: !useOpenRouter,
        );
        await _advanceMelodyRotationIfNeeded(input);
        return _deliverSunoOutput(
          text,
          input,
          applyThemePass: !skipThemeConsistencyPass,
        );
      }
      rethrow;
    }
  }

  /// Runs [generateSunoPrompt], then **one** stricter pass if [FormatValidationResult]
  /// QA fails (suffix + lower temperature). Works for **client-side** OpenRouter and
  /// **server** `/generate-prompt` (suffix sent as `user_block_suffix`).
  Future<String> generateSunoPromptWithFormatRetry(
    UserInputModel input, {
    bool preferLightweightModel = false,
    String? continuationPriorOutput,
    String? continuationUserRequest,
  }) async {
    final mdBase = ApiConstants.resolveMdApiBase(_prefs);
    final serverMode = mdBase != null && mdBase.isNotEmpty;

    var text = await generateSunoPrompt(
      input,
      preferLightweightModel: preferLightweightModel,
      continuationPriorOutput: continuationPriorOutput,
      continuationUserRequest: continuationUserRequest,
      skipThemeConsistencyPass: true,
    );
    if (!ApiConstants.useSunoPromptV2Candidate()) return text;

    for (var attempt = 0; attempt < 2; attempt++) {
      final finalized = _finalizeSunoV2Output(text, input);
      if (!_needsFormatRetry(finalized, input)) {
        return _deliverSunoOutput(
          text,
          input,
          applyThemePass: !serverMode,
        );
      }

      final expectLyrics = !userRequestedBlock2OptOut(input);
      final parsed = parseSunoOutput(finalized);
      final qa = FormatValidationResult.validate(
        finalized,
        expectLyricsBlock: expectLyrics,
        block1Mode: input.sunoFieldOutputMode,
      );
      final suffix = FormatValidationResult.buildFormatRetrySuffix(
        qa,
        expectLyricsBlock: expectLyrics,
      );
      final retryMaxTok = (_baseMaxCompletionTokens(input) * (1.25 + attempt * 0.25))
          .ceil()
          .clamp(1400, 8192);
      final retryText = await generateSunoPrompt(
        input,
        preferLightweightModel: preferLightweightModel,
        appendToUserBlock: suffix,
        temperatureOverride: 0.35,
        maxCompletionTokensOverride: retryMaxTok,
        continuationPriorOutput: continuationPriorOutput,
        continuationUserRequest: continuationUserRequest,
        skipThemeConsistencyPass: true,
      );
      final retryFinalized = _finalizeSunoV2Output(retryText, input);
      if (!_needsFormatRetry(retryFinalized, input) ||
          isBetterSunoOutput(retryText, text)) {
        text = retryText;
      }
    }

    final finalized = _finalizeSunoV2Output(text, input);
    if (!_needsFormatRetry(finalized, input)) {
      return _deliverSunoOutput(text, input, applyThemePass: !serverMode);
    }

    // Server runs its own completion pass; on-device LaoZhang needs it here.
    if ((mdBase == null || mdBase.isEmpty) &&
        !_onDeviceCredentials.useOpenRouter) {
      final completed = await _laozhangOnDeviceCompletion(
        input,
        partial: finalized,
        preferLightweightModel: preferLightweightModel,
        continuationPriorOutput: continuationPriorOutput,
        continuationUserRequest: continuationUserRequest,
      );
      if (isBetterSunoOutput(completed, text)) {
        text = completed;
      }
    }

    return _deliverSunoOutput(text, input, applyThemePass: !serverMode);
  }

  int _baseMaxCompletionTokens(UserInputModel input) {
    final lyricsTrim = input.optionalLyrics.trim();
    final hasLyrics = lyricsTrim.isNotEmpty;
    final pathC = input.sunoFieldOutputMode != SunoFieldOutputMode.simple &&
        input.generateLyrics &&
        !hasLyrics;
    final lyricsWords = hasLyrics
        ? lyricsTrim.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length
        : 0;
    return SunoPromptLimits.maxCompletionTokensFor(
      input.sunoVersion,
      hasUserLyrics: hasLyrics,
      userLyricsWordCount: lyricsWords,
      generateLyrics: pathC,
      useV2FormatLawStyle: ApiConstants.useSunoPromptV2Candidate(),
      sunoFieldOutputMode: input.sunoFieldOutputMode,
      block2OptOut: userRequestedBlock2OptOut(input),
    );
  }

  bool _needsFormatRetry(String finalized, UserInputModel input) {
    if (userRequestedBlock2OptOut(input)) return false;
    final expectLyrics = !userRequestedBlock2OptOut(input);
    final parsed = parseSunoOutput(finalized);
    final qa = FormatValidationResult.validate(
      finalized,
      expectLyricsBlock: expectLyrics,
      block1Mode: input.sunoFieldOutputMode,
    );
    return FormatValidationResult.shouldRetryAfterValidation(
      qa,
      expectLyricsBlock: expectLyrics,
      unifiedBlock2Missing: parsed.unifiedBlock2Missing,
    );
  }

  Future<String> _laozhangOnDeviceCompletion(
    UserInputModel input, {
    required String partial,
    required bool preferLightweightModel,
    String? continuationPriorOutput,
    String? continuationUserRequest,
  }) async {
    final creds = _onDeviceCredentials;
    final key = creds.apiKey;
    if (key.isEmpty) return partial;

    final sessionVar = _resolveMelodySessionVariation(input);
    final melodyBlock = MelodyStyleData.composeUserBlock(
      melodyStyleId: input.melodyStyleId,
      melodyCustomNotes: input.melodyCustomNotes,
      sessionVariationDirective: sessionVar,
    );
    var userBlock = _buildUserContent(_withGenreFxApplied(input), melodyUserBlock: melodyBlock);
    final cont = _continuationAppend(
      continuationPriorOutput,
      continuationUserRequest,
    );
    if (cont != null) userBlock = '$userBlock\n\n$cont';

    final headers = <String, String>{
      'Authorization': 'Bearer $key',
      'Content-Type': 'application/json',
    };

    return _completeLaozhangTruncatedOutput(
      endpoint: ApiConstants.laozhangChatCompletions,
      headers: headers,
      systemContent: _systemPromptForProvider(false),
      userBlock: userBlock,
      partial: partial,
      maxTok: _baseMaxCompletionTokens(input),
    );
  }

  static bool _lyricsTaskFor(UserInputModel input) =>
      !userRequestedBlock2OptOut(input);

  static String? _continuationAppend(String? prior, String? followUp) {
    final p = prior == null ? '' : truncateContinuationPrior(prior);
    final f = followUp?.trim();
    if (p.isEmpty || f == null || f.isEmpty) return null;
    return '''
PRIOR OUTPUT (revise to one full Suno reply; keep intent unless follow-up contradicts):
---
$p
---

FOLLOW-UP:
$f
'''.trim();
  }

  String _finalizeSunoV2Output(String text, UserInputModel input) {
    var out = stripInternalCognitionBlocks(text);
    if (!ApiConstants.useSunoPromptV2Candidate()) return out;
    out = sanitizeSunoPostOutput(
      out,
      primaryGenre: input.primaryGenre,
      subGenreFusion: input.subGenreFusion,
      audioEnvironmentModeId: input.audioEnvironmentModeId,
    );
    out = applyRemixGenerationTypeOutput(input, out);
    return enforceUnifiedBlock1CharLimit(out, input.sunoFieldOutputMode);
  }

  Future<String> _deliverSunoOutput(
    String text,
    UserInputModel input, {
    required bool applyThemePass,
  }) async {
    var out = text;
    if (applyThemePass) {
      final creds = _onDeviceCredentials;
      if (creds.useOpenRouter && ApiConstants.openRouterPostProcessEnabled()) {
        out = await _applyOpenRouterPostProcess(out, input);
      } else {
        out = await _applyLaozhangPostProcess(out, input);
      }
    }
    return _finalizeSunoV2Output(out, input);
  }

  Future<String> _applyOpenRouterPostProcess(
    String text,
    UserInputModel input,
  ) async {
    if (!ApiConstants.useSunoPromptV2Candidate()) return text;
    if (userRequestedBlock2OptOut(input)) return text;
    if (!_lyricsTaskFor(input)) return text;

    final remixInstrumental = remixEngineActive(input) &&
        input.songGenerationType == SongGenerationType.instrumental;

    var out = text;
    if (ApiConstants.themeConsistencyEnabled() && !remixInstrumental) {
      out = await _applyThemeConsistencyPass(out, input);
    }
    if (!remixInstrumental) {
      out = await _applyHumanizationPass(out, input, useOpenRouter: true);
    }
    out = await _applySunoCompressionPass(out, input, useOpenRouter: true);
    return out;
  }

  Future<({String endpoint, Map<String, String> headers})?> _postProcessEndpoint() async {
    final creds = _onDeviceCredentials;
    final key = creds.apiKey;
    if (key.isEmpty) return null;
    final useOpenRouter = creds.useOpenRouter;
    return (
      endpoint: useOpenRouter
          ? ApiConstants.openRouterChatCompletions
          : ApiConstants.laozhangChatCompletions,
      headers: <String, String>{
        'Authorization': 'Bearer $key',
        'Content-Type': 'application/json',
        if (useOpenRouter) ...{
          'HTTP-Referer': 'https://music-director.app',
          'X-Title': 'Music Director',
        },
      },
    );
  }

  Future<String> _applyBlock2PostPass({
    required String text,
    required UserInputModel input,
    required String systemPrompt,
    required String Function(String block2Body) buildUserMessage,
    required String model,
    String? fallbackModel,
    double temperature = 0.4,
  }) async {
    final parsed = parseSunoOutput(text);
    if (parsed.unifiedBlock2Missing) return text;
    final parts = splitBlock2Parts(text);
    if (parts == null) return text;

    final ep = await _postProcessEndpoint();
    if (ep == null) return text;

    String? rawOut;
    for (final attemptModel in [
      model,
      if (fallbackModel != null && fallbackModel != model) fallbackModel,
    ]) {
      try {
        rawOut = await _completeChatCompletion(
          endpoint: ep.endpoint,
          headers: ep.headers,
          model: attemptModel,
          systemContent: systemPrompt,
          userBlock: buildUserMessage(parts.block2Body),
          temperature: temperature,
          maxTok: 4096,
        );
        break;
      } catch (_) {
        if (attemptModel == fallbackModel) return text;
      }
    }
    if (rawOut == null) return text;

    final candidate = sanitizeThemeConsistencyOutput(rawOut);
    if (!block2ThemeOutputValid(candidate) || candidate == parts.block2Body) {
      return text;
    }
    final merged = mergeBlock2Parts(
      prefix: parts.prefix,
      block2Body: candidate,
      suffix: parts.suffix,
    );
    final check = parseSunoOutput(merged);
    if (check.unifiedBlock2Missing) return text;
    return merged;
  }

  Future<String> _applyThemeConsistencyPass(
    String text,
    UserInputModel input,
  ) async {
    if (!ApiConstants.useSunoPromptV2Candidate()) return text;
    if (!ApiConstants.themeConsistencyEnabled()) return text;
    if (userRequestedBlock2OptOut(input)) return text;
    if (!_lyricsTaskFor(input)) return text;
    if (remixEngineActive(input) &&
        input.songGenerationType == SongGenerationType.instrumental) {
      return text;
    }

    final useOpenRouter = _onDeviceCredentials.useOpenRouter;
    return _applyBlock2PostPass(
      text: text,
      input: input,
      systemPrompt: kThemeConsistencySystemPrompt,
      buildUserMessage: (body) => buildThemeConsistencyUserMessage(
        block2Body: body,
        primaryGenre: input.primaryGenre,
        subGenreFusion: input.subGenreFusion,
        vibe: input.vibe,
        lyricThemeNotes: input.lyricThemeNotes,
        language: input.language,
        vocalAccent: input.vocalAccent,
        dialectStyleId: input.dialectStyleId,
        dialectVariantId: input.dialectVariantId,
        audioEnvironmentModeId: input.audioEnvironmentModeId,
        remixOriginalSongTitle: input.remixOriginalSongTitle,
        remixOriginalArtist: input.remixOriginalArtist,
        songGenerationType: input.songGenerationType,
      ),
      model: ApiConstants.themeConsistencyModelForPromptWithProvider(
        useOpenRouter: useOpenRouter,
      ),
      fallbackModel: useOpenRouter
          ? null
          : ApiConstants.fallbackModelForProvider(
              useOpenRouter: false,
              lyricsTask: true,
            ),
    );
  }

  Future<String> _applyLaozhangPostProcess(
    String text,
    UserInputModel input,
  ) async {
    if (!ApiConstants.useSunoPromptV2Candidate()) return text;
    if (userRequestedBlock2OptOut(input)) return text;
    if (!_lyricsTaskFor(input)) return text;
    if (remixEngineActive(input) &&
        input.songGenerationType == SongGenerationType.instrumental) {
      return text;
    }

    var out = text;
    if (ApiConstants.themeConsistencyEnabled()) {
      out = await _applyThemeConsistencyPass(out, input);
    }
    out = await _applyHumanizationPass(out, input, useOpenRouter: false);
    out = await _applySunoCompressionPass(out, input, useOpenRouter: false);
    return out;
  }

  Future<String> _applyHumanizationPass(
    String text,
    UserInputModel input, {
    required bool useOpenRouter,
  }) async {
    if (!ApiConstants.humanizationPassEnabled()) return text;
    if (userRequestedBlock2OptOut(input)) return text;
    if (!_lyricsTaskFor(input)) return text;

    return _applyBlock2PostPass(
      text: text,
      input: input,
      systemPrompt: kHumanizationSystemPrompt,
      buildUserMessage: (body) => buildHumanizationUserMessage(
        block2Body: body,
        primaryGenre: input.primaryGenre,
        subGenreFusion: input.subGenreFusion,
        vibe: input.vibe,
        lyricThemeNotes: input.lyricThemeNotes,
        language: input.language,
        vocalAccent: input.vocalAccent,
        dialectStyleId: input.dialectStyleId,
        dialectVariantId: input.dialectVariantId,
        audioEnvironmentModeId: input.audioEnvironmentModeId,
      ),
      model: ApiConstants.humanizationModelForPrompt(
        useOpenRouter: useOpenRouter,
        language: input.language,
        dialectStyleId: input.dialectStyleId,
      ),
      fallbackModel: useOpenRouter
          ? null
          : (ApiConstants.laozhangMultilingualHumanization(
                language: input.language,
                dialectStyleId: input.dialectStyleId,
              )
              ? ApiConstants.laozhangLyricsPrimaryChatModel
              : ApiConstants.laozhangPromptChatModel),
      temperature: 0.45,
    );
  }

  Future<String> _applySunoCompressionPass(
    String text,
    UserInputModel input, {
    required bool useOpenRouter,
  }) async {
    if (!ApiConstants.sunoCompressionPassEnabled()) return text;

    final ep = await _postProcessEndpoint();
    if (ep == null) return text;
    if (parseSunoOutput(text).unifiedBlock2Missing &&
        _lyricsTaskFor(input)) {
      return text;
    }

    final userBlock = buildSunoCompressionUserMessage(
      fullOutput: text,
      primaryGenre: input.primaryGenre,
      subGenreFusion: input.subGenreFusion,
      vibe: input.vibe,
      lyricThemeNotes: input.lyricThemeNotes,
      language: input.language,
      vocalAccent: input.vocalAccent,
      dialectStyleId: input.dialectStyleId,
      dialectVariantId: input.dialectVariantId,
      audioEnvironmentModeId: input.audioEnvironmentModeId,
      fieldMode: input.sunoFieldOutputMode.name,
    );
    final models = <String>[
      ApiConstants.compressionModelForProvider(useOpenRouter: useOpenRouter),
      if (!useOpenRouter) ApiConstants.laozhangLyricsSecondaryChatModel,
    ];

    for (final model in models) {
      try {
        final raw = await _completeChatCompletion(
          endpoint: ep.endpoint,
          headers: ep.headers,
          model: model,
          systemContent: kSunoCompressionSystemPrompt,
          userBlock: userBlock,
          temperature: 0.35,
          maxTok: 8192,
          applyLaozhangHygiene: !useOpenRouter,
        );
        final candidate = raw.trim();
        if (candidate.isEmpty) continue;
        final check = parseSunoOutput(candidate);
        if (check.unifiedBlock2Missing && _lyricsTaskFor(input)) continue;
        if (!candidate.toUpperCase().contains('BLOCK 1')) continue;
        if (sunoOutputIncomplete(candidate) && !sunoOutputIncomplete(text)) {
          continue;
        }
        if (isBetterSunoOutput(candidate, text) ||
            !sunoOutputIncomplete(candidate)) {
          return candidate;
        }
      } catch (_) {}
    }
    return text;
  }

  String get _directorSystemPrompt => ApiConstants.useSunoPromptV2Candidate()
      ? kSunoDirectorSystemPromptV2Candidate
      : kSunoDirectorSystemPrompt;

  String _systemPromptForProvider(bool useOpenRouter) => useOpenRouter
      ? _directorSystemPrompt
      : appendLaozhangArchitectureBoundary(_directorSystemPrompt);

  Future<String> _generateOnDevice({
    required String endpoint,
    required Map<String, String> headers,
    required bool useOpenRouter,
    required String language,
    required bool lightweight,
    required String userBlock,
    required double temperature,
    required int maxTok,
    required bool lyricsTask,
  }) async {
    final draftModel = ApiConstants.draftModelForPromptWithProvider(
      language: language,
      lightweight: lightweight,
      useOpenRouter: useOpenRouter,
      lyricsTask: lyricsTask,
    );

    final systemContent = _systemPromptForProvider(useOpenRouter);
    final hygiene = !useOpenRouter;

    if (!ApiConstants.useHybridPromptPipelineForProvider(
      lightweight: lightweight,
      useOpenRouter: useOpenRouter,
    )) {
      if (!useOpenRouter) {
        final single = await _completeLaozhangChatWithFallback(
          endpoint: endpoint,
          headers: headers,
          systemContent: systemContent,
          userBlock: userBlock,
          temperature: temperature,
          maxTok: maxTok,
          primaryModel: draftModel,
        );
        if (!lyricsTask || !sunoOutputIncomplete(single)) return single;
        final completed = await _completeLaozhangTruncatedOutput(
          endpoint: endpoint,
          headers: headers,
          systemContent: systemContent,
          userBlock: userBlock,
          partial: single,
          maxTok: maxTok,
        );
        return isBetterSunoOutput(completed, single) ? completed : single;
      }
      return _completeChatCompletion(
        endpoint: endpoint,
        headers: headers,
        model: draftModel,
        systemContent: systemContent,
        userBlock: userBlock,
        temperature: temperature,
        maxTok: maxTok,
        applyLaozhangHygiene: hygiene,
      );
    }

    final draft = !useOpenRouter
        ? await _completeLaozhangChatWithFallback(
            endpoint: endpoint,
            headers: headers,
            systemContent: systemContent,
            userBlock: userBlock,
            temperature: temperature,
            maxTok: maxTok,
            primaryModel: draftModel,
          )
        : await _completeChatCompletion(
            endpoint: endpoint,
            headers: headers,
            model: draftModel,
            systemContent: systemContent,
            userBlock: userBlock,
            temperature: temperature,
            maxTok: maxTok,
            applyLaozhangHygiene: hygiene,
          );

    if (useOpenRouter) {
      final polishMaxTok = maxTok.clamp(3200, 8192);
      try {
        return await _completeChatCompletion(
          endpoint: endpoint,
          headers: headers,
          model: ApiConstants.polishModelForPromptWithProvider(
            useOpenRouter: useOpenRouter,
          ),
          systemContent: kSunoPolishSystemPrompt,
          userBlock: buildSunoPolishUserMessage(
            draft: draft,
            originalUserBlock: userBlock,
          ),
          temperature: 0.4,
          maxTok: polishMaxTok,
          applyLaozhangHygiene: hygiene,
        );
      } catch (_) {
        return draft;
      }
    }

    var result = await _polishLaozhangDraftWithFallback(
      endpoint: endpoint,
      headers: headers,
      draft: draft,
      userBlock: userBlock,
      maxTok: maxTok,
    );
    if (lyricsTask && sunoOutputIncomplete(result)) {
      final completed = await _completeLaozhangTruncatedOutput(
        endpoint: endpoint,
        headers: headers,
        systemContent: systemContent,
        userBlock: userBlock,
        partial: result,
        maxTok: maxTok,
      );
      if (isBetterSunoOutput(completed, result)) {
        result = completed;
      }
    }
    return result;
  }

  int _laozhangPolishMaxTokens(int maxTok) =>
      maxTok < 3200 ? 3200 : maxTok.clamp(3200, 8192);

  int _laozhangCompletionMaxTokens(int maxTok) =>
      (maxTok * 1.5).ceil().clamp(4200, 8192);

  Future<String> _polishLaozhangDraftWithFallback({
    required String endpoint,
    required Map<String, String> headers,
    required String draft,
    required String userBlock,
    required int maxTok,
  }) async {
    final polishUser = buildSunoPolishUserMessage(
      draft: draft,
      originalUserBlock: userBlock,
    );
    final polishMaxTok = _laozhangPolishMaxTokens(maxTok);
    final models = <String>{
      ApiConstants.polishModelForPromptWithProvider(useOpenRouter: false),
      ApiConstants.laozhangLyricsSecondaryChatModel,
      ApiConstants.laozhangLyricsPrimaryChatModel,
    }.toList();

    String? best;
    for (final model in models) {
      try {
        final out = await _completeChatCompletion(
          endpoint: endpoint,
          headers: headers,
          model: model,
          systemContent: kSunoPolishSystemPrompt,
          userBlock: polishUser,
          temperature: 0.4,
          maxTok: polishMaxTok,
          applyLaozhangHygiene: true,
        );
        if (!sunoOutputIncomplete(out)) return out;
        if (best == null || isBetterSunoOutput(out, best)) best = out;
      } catch (_) {}
    }
    return best ?? draft;
  }

  Future<String> _completeLaozhangTruncatedOutput({
    required String endpoint,
    required Map<String, String> headers,
    required String systemContent,
    required String userBlock,
    required String partial,
    required int maxTok,
  }) async {
    final completionMaxTok = _laozhangCompletionMaxTokens(maxTok);
    final models = <String>[
      ApiConstants.laozhangPromptChatModel,
      ApiConstants.laozhangLyricsSecondaryChatModel,
      ApiConstants.laozhangLyricsPrimaryChatModel,
    ];

    String? best;
    for (final model in models) {
      try {
        final out = await _completeChatContinuation(
          endpoint: endpoint,
          headers: headers,
          model: model,
          systemContent: systemContent,
          userBlock: userBlock,
          partialAssistant: partial,
          continuationUser: _laozhangCompletionUser(partial, userBlock),
          temperature: 0.35,
          maxTok: completionMaxTok,
          applyLaozhangHygiene: true,
        );
        if (!sunoOutputIncomplete(out)) return out;
        if (best == null || isBetterSunoOutput(out, best)) best = out;
      } catch (_) {}
    }
    return best ?? partial;
  }

  Future<String> _completeLaozhangChatWithFallback({
    required String endpoint,
    required Map<String, String> headers,
    required String systemContent,
    required String userBlock,
    required double temperature,
    required int maxTok,
    required String primaryModel,
  }) async {
    final models = <String>{
      primaryModel,
      ApiConstants.laozhangLyricsSecondaryChatModel,
      ApiConstants.laozhangLyricsPrimaryChatModel,
    }.toList();
    Object? lastError;
    for (final model in models) {
      try {
        return await _completeChatCompletion(
          endpoint: endpoint,
          headers: headers,
          model: model,
          systemContent: systemContent,
          userBlock: userBlock,
          temperature: temperature,
          maxTok: maxTok,
          applyLaozhangHygiene: true,
        );
      } catch (e) {
        lastError = e;
      }
    }
    if (lastError is DioException) throw lastError;
    throw DioException(
      requestOptions: RequestOptions(path: endpoint),
      error: lastError ?? 'LaoZhang generation failed',
    );
  }

  Future<String> _completeChatCompletion({
    required String endpoint,
    required Map<String, String> headers,
    required String model,
    required String systemContent,
    required String userBlock,
    required double temperature,
    required int maxTok,
    bool applyLaozhangHygiene = false,
  }) async {
    final payload = <String, dynamic>{
      'model': model,
      'messages': [
        {'role': 'system', 'content': systemContent},
        {'role': 'user', 'content': userBlock},
      ],
      'temperature': temperature,
      'max_tokens': maxTok,
    };
    applyChatTokenLimits(payload, model, maxTok);
    final res = await _dio.post<Map<String, dynamic>>(
      endpoint,
      data: payload,
      options: promptGenerationRequestOptions().copyWith(
        headers: headers,
      ),
    );

    final choices = res.data?['choices'] as List<dynamic>?;
    final choice = choices?.isNotEmpty == true ? choices!.first : null;
    final message = choice is Map ? choice['message'] : null;
    final text = extractChatMessageContent(message);
    if (text == null || text.trim().isEmpty) {
      final finish = choice is Map ? choice['finish_reason']?.toString() : null;
      final refusal = message is Map ? message['refusal'] : null;
      throw DioException(
        requestOptions: res.requestOptions,
        error: describeEmptyChatResponse(
          model: model,
          finishReason: finish,
          refusal: refusal,
        ),
      );
    }
    var out = text.trim();
    if (applyLaozhangHygiene) {
      out = cleanLaoZhangOnDevicePayload(out);
    }
    return out;
  }

  Future<String> _completeChatContinuation({
    required String endpoint,
    required Map<String, String> headers,
    required String model,
    required String systemContent,
    required String userBlock,
    required String partialAssistant,
    required String continuationUser,
    required double temperature,
    required int maxTok,
    bool applyLaozhangHygiene = false,
  }) async {
    final payload = <String, dynamic>{
      'model': model,
      'messages': [
        {'role': 'system', 'content': systemContent},
        {'role': 'user', 'content': userBlock},
        {'role': 'assistant', 'content': partialAssistant},
        {'role': 'user', 'content': continuationUser},
      ],
      'temperature': temperature,
      'max_tokens': maxTok,
    };
    applyChatTokenLimits(payload, model, maxTok);
    final res = await _dio.post<Map<String, dynamic>>(
      endpoint,
      data: payload,
      options: promptGenerationRequestOptions().copyWith(
        headers: headers,
      ),
    );
    final choices = res.data?['choices'] as List<dynamic>?;
    final choice = choices?.isNotEmpty == true ? choices!.first : null;
    final message = choice is Map ? choice['message'] : null;
    final text = extractChatMessageContent(message);
    if (text == null || text.trim().isEmpty) {
      final finish = choice is Map ? choice['finish_reason']?.toString() : null;
      throw DioException(
        requestOptions: res.requestOptions,
        error: describeEmptyChatResponse(
          model: model,
          finishReason: finish,
        ),
      );
    }
    var out = text.trim();
    if (applyLaozhangHygiene) {
      out = cleanLaoZhangOnDevicePayload(out);
    }
    return out;
  }

  static String _laozhangCompletionUser(String partial, String originalUser) =>
      '''
Your previous Suno reply was **incomplete** (Block 1 stopped early and/or Block 2 is missing).

Rewrite the **complete** two-block output from scratch in **one** reply:
- **BLOCK 1 — PASTE INTO SUNO: STYLE** → 130–150 words of finished producer prose.
- **BLOCK 2 — PASTE INTO SUNO: LYRICS** → full bracket structure through **[End]**.

ORIGINAL USER REQUEST:
---
${originalUser.trim()}
---

INCOMPLETE DRAFT:
---
${partial.trim()}
---

Output ONLY the final complete two-block Suno reply.''';

  Future<String> _generateOnServer(
    String base,
    UserInputModel input,
    String? melodyUserBlock, {
    String? userBlockSuffix,
    String? continuationPriorOutput,
    String? continuationUserRequest,
    bool preferLightweightModel = false,
  }) async {
    final fxInput = _withGenreFxApplied(input);
    final lyricsTrim = fxInput.optionalLyrics.trim();
    final hasLyrics = lyricsTrim.isNotEmpty;
    final simple = input.sunoFieldOutputMode == SunoFieldOutputMode.simple;
    final pathC = !simple && input.generateLyrics && !hasLyrics;
    final api = createMusicDirectorApiDio(base);
    final res = await api.post<Map<String, dynamic>>(
      ApiPaths.generatePrompt,
      options: promptGenerationRequestOptions(),
      data: {
        ...OnDeviceApiKeys.serverRequestFields(_prefs),
        'suno_version': input.sunoVersion,
        'primary_genre': input.primaryGenre,
        'sub_genre_fusion': input.subGenreFusion,
        'vibe': fxInput.vibe,
        'bpm': input.bpm,
        'key_root': input.keyRoot,
        'scale': input.scale,
        'vocal_spec': input.vocalSpec,
        'vocal_tone': input.vocalTone,
        'vocal_accent': input.vocalAccent,
        'dialect_style_id': input.dialectStyleId,
        'dialect_variant_id': input.dialectVariantId,
        'audio_environment_mode': input.audioEnvironmentModeId,
        'reference_artists': input.referenceArtists,
        'avoid': input.avoid,
        'language': input.language,
        'include_analyzer_data': input.includeAnalyzerData,
        'analyzer_summary': input.analyzerSummary,
        'track_duration_label': input.trackDurationLabel,
        'dj_intro_mix_in': input.djIntroMixIn,
        'dj_outro_mix_out': input.djOutroMixOut,
        'song_structure_directive': SongStructureData.userBlockDirective(
          presetId: input.songStructurePresetId,
          customNotes: input.songStructureCustom,
        ),
        'optional_lyrics': fxInput.optionalLyrics,
        'remix_from_analyzer': input.remixFromAnalyzer,
        'remix_original_song_title': input.remixOriginalSongTitle,
        'remix_original_artist': input.remixOriginalArtist,
        'song_generation_type': input.songGenerationType.apiValue,
        'real_instrumentals': input.realInstrumentals,
        if (input.chordProgression.trim().isNotEmpty)
          'chord_progression': input.chordProgression.trim(),
        'field_output_mode': input.sunoFieldOutputMode.name,
        'generate_lyrics': pathC,
        'lyric_theme_notes': input.lyricThemeNotes,
        'lyric_temperament_codes': input.lyricTemperamentCodes,
        'human_realism': input.humanRealism,
        'production_intensity': input.productionIntensity,
        'genre_fx_lane': input.genreFxLaneId,
        'duration_user_block': TrackDurationConfig.fromUserInput(
          duration: input.trackDuration,
          trackDurationLabel: input.trackDurationLabel,
          djIntro: input.djIntroMixIn,
          djOutro: input.djOutroMixOut,
          bpmRaw: input.bpm,
        ).toPromptContext(),
        if (melodyUserBlock != null && melodyUserBlock.trim().isNotEmpty)
          'melody_user_block': melodyUserBlock.trim(),
        if (userBlockSuffix != null && userBlockSuffix.trim().isNotEmpty)
          'user_block_suffix': userBlockSuffix.trim(),
        if (continuationPriorOutput != null &&
            continuationPriorOutput.trim().isNotEmpty &&
            continuationUserRequest != null &&
            continuationUserRequest.trim().isNotEmpty) ...{
          'continuation_prior_output': continuationPriorOutput.trim(),
          'continuation_user_request': continuationUserRequest.trim(),
        },
        'prefer_lightweight_model': preferLightweightModel,
      },
    );
    final text = res.data?['prompt'] as String?;
    if (text == null || text.isEmpty) {
      throw DioException(
        requestOptions: res.requestOptions,
        error: 'Empty server prompt response',
      );
    }
    return text.trim();
  }

  String? _resolveMelodySessionVariation(UserInputModel input) {
    if (kMelodySessionVariationDirectives.isEmpty) return null;
    switch (input.melodyVariationMode) {
      case MelodyVariationMode.none:
        return null;
      case MelodyVariationMode.random:
        return kMelodySessionVariationDirectives[
            _rand.nextInt(kMelodySessionVariationDirectives.length)];
      case MelodyVariationMode.rotate:
        final i = _prefs.getInt(_melodyRotateIndexKey) ?? 0;
        return kMelodySessionVariationDirectives[
            i % kMelodySessionVariationDirectives.length];
    }
  }

  Future<void> _advanceMelodyRotationIfNeeded(UserInputModel input) async {
    if (input.melodyVariationMode != MelodyVariationMode.rotate) return;
    final next = (_prefs.getInt(_melodyRotateIndexKey) ?? 0) + 1;
    await _prefs.setInt(_melodyRotateIndexKey, next);
  }

  static String _resolvedAnalyzerConstraints(UserInputModel i) {
    final summary = i.analyzerSummary.trim();
    if (summary.isEmpty) {
      return AudioAnalysisModel.fallbackAnalyzerSummary;
    }
    for (final line in summary.split('\n')) {
      final t = line.trim();
      if (t.isEmpty ||
          t.startsWith('TARGET AUDIO PROFILE') ||
          t.contains(':') && t.indexOf(',') > t.indexOf(':')) {
        continue;
      }
      if (t.contains(',')) {
        return AudioAnalysisModel.sanitizeProfile(t);
      }
    }
    final lines = summary.split('\n').map((l) => l.trim()).toList();
    final targetIdx = lines.indexWhere((l) => l.startsWith('TARGET AUDIO PROFILE'));
    if (targetIdx >= 0 && targetIdx + 1 < lines.length) {
      return AudioAnalysisModel.sanitizeProfile(lines[targetIdx + 1]);
    }
    return AudioAnalysisModel.fallbackAnalyzerSummary;
  }

  String _vocalUserBlockLine(UserInputModel i) {
    final spec = (i.vocalSpec ?? '').trim();
    final tone = (i.vocalTone ?? '').trim();
    final accent = (i.vocalAccent ?? '').trim();
    final parts = <String>[
      if (spec.isNotEmpty) spec,
      if (tone.isNotEmpty) tone,
      if (accent.isNotEmpty)
        'accent/delivery (style-only, not impersonation or voice cloning): '
            '$accent',
    ];
    if (parts.isEmpty) return 'Vocal:';
    return 'Vocal: ${parts.join(' — ')}';
  }

  UserInputModel _withGenreFxApplied(UserInputModel input) {
    final fx = SunoPromptBuilder.applyGenreFxToInputs(
      vibe: input.vibe,
      optionalLyrics: input.optionalLyrics,
      genreFxLaneId: input.genreFxLaneId,
      primaryGenre: input.primaryGenre,
      fusionGenre: input.subGenreFusion,
      intensity: input.productionIntensity,
    );
    return input.copyWith(vibe: fx.vibe, optionalLyrics: fx.optionalLyrics);
  }

  String _buildUserContent(UserInputModel i, {String? melodyUserBlock}) {
    final hasLyrics = i.optionalLyrics.trim().isNotEmpty;
    final useV2 = ApiConstants.useSunoPromptV2Candidate();
    final simple = i.sunoFieldOutputMode == SunoFieldOutputMode.simple;
    final pathC = !simple && i.generateLyrics && !hasLyrics;
    final block2OptOut = userRequestedBlock2OptOut(i);
    final buf = StringBuffer();
    if (useV2) {
      buf.writeln(
        SunoPromptLimits.v2FieldBudgetUserLine(
          i.sunoVersion,
          hasPastedLyrics: hasLyrics,
          generateLyrics: pathC,
          fieldMode: i.sunoFieldOutputMode,
          block2OptOut: block2OptOut,
        ),
      );
    } else {
      buf.writeln(
        SunoPromptLimits.wordBudgetUserLine(
          i.sunoVersion,
          hasUserLyrics: hasLyrics,
        ),
      );
    }
    if (i.remixFromAnalyzer) {
      buf.writeln(
        useV2
            ? SunoPromptLimits.remixFromAnalyzerUserBlockSupplementV2(i.sunoVersion)
            : SunoPromptLimits.remixFromAnalyzerUserBlockSupplement(i.sunoVersion),
      );
    }
    if (remixEngineActive(i)) {
      buf.writeln(
        remixStyleFlipUserBlockSupplement(
          originalSongTitle: i.remixOriginalSongTitle,
          originalArtist: i.remixOriginalArtist,
          targetGenre: i.primaryGenre,
          generationType: i.songGenerationType,
        ),
      );
    }
    buf
      ..writeln('Suno version: ${i.sunoVersion}')
      ..writeln('Primary genre: ${i.primaryGenre}')
      ..writeln('Fusion / sub-genre: ${i.subGenreFusion}')
      ..writeln('Vibe / idea: ${i.vibe}');
    if (useV2) {
      final hybridBlock = GenreHybridizationMatrix.userBlockDirective(
        primaryGenre: i.primaryGenre,
        subGenreFusion: i.subGenreFusion,
      );
      if (hybridBlock.isNotEmpty) buf.writeln(hybridBlock);
    }
    buf
      ..writeln('BPM: ${i.bpm ?? 'unspecified'}')
      ..writeln('Key: ${i.keyRoot ?? ''} ${i.scale ?? ''}'.trim())
      ..writeln(_vocalUserBlockLine(i));
    final accentBlock = VocalAccentData.userBlockDirective(
      accent: i.vocalAccent,
      vocalSpec: i.vocalSpec ?? '',
      language: i.language,
      dialectStyleId: i.dialectStyleId,
    );
    if (accentBlock.isNotEmpty) {
      buf.writeln(accentBlock);
    }
    final dialectBlock =
        DialectStyleData.userBlockDirective(
          i.dialectStyleId,
          dialectVariantId: i.dialectVariantId,
        );
    if (dialectBlock.isNotEmpty) {
      buf.writeln(dialectBlock);
    }
    buf.writeln(
      AudioEnvironmentData.userBlockDirective(i.audioEnvironmentModeId),
    );
    buf
      ..writeln(
        'Reference influences (artist/producer/DJ/song/album names OK — '
        'ARTIST REFERENCE PROCESSING: hidden_internal_only DNA; merge multiples; '
        'never output names, song titles, or albums): ${i.referenceArtists}',
      )
      ..writeln('Avoid: ${i.avoid}')
      ..writeln('Language: ${i.language}');
    if (useV2) {
      final codeBlock = CodeTranslationMatrix.userBlockDirective(
        primaryGenre: i.primaryGenre,
        subGenreFusion: i.subGenreFusion,
        codesBlob: i.lyricTemperamentCodes,
        sunoVersion: i.sunoVersion,
        vibe: i.vibe,
      );
      if (codeBlock.isNotEmpty) buf.writeln(codeBlock);
    }
    if (userRequestedHitmakerMode(i)) {
      buf.writeln(
        buildHitmakerModeUserBlock(v2UnifiedOutput: useV2),
      );
    }
    final cp = i.chordProgression.trim();
    if (cp.isNotEmpty) {
      buf.writeln(
        useV2
            ? 'CHORD PROGRESSION (user specified — integrate into Block 1 producer prose within 130–150 words / ≤1000 characters; mirror harmony changes in Block 2 section flow; align with Key/scale when both are set): $cp'
            : 'CHORD PROGRESSION (user specified — integrate into SUNO STRUCTURE: parenthetical harmony per section where chords change; echo briefly as chord/pad/guitar voicing language in SUNO STYLE; align with Key/scale when both are set): $cp',
      );
    }
    final mb = melodyUserBlock?.trim();
    if (mb != null && mb.isNotEmpty) {
      buf.writeln(mb);
    }
    final realInst = i.realInstrumentals.trim();
    if (realInst.isNotEmpty) {
      buf.writeln(
        useV2
            ? LiveInstrumentMatrix.userBlockDirective(
                primaryGenre: i.primaryGenre,
                subGenreFusion: i.subGenreFusion,
                selectionRaw: realInst,
                sunoVersion: i.sunoVersion,
                powerCodes: i.lyricTemperamentCodes,
              )
            : 'Real / acoustic instruments (live or mic’d — foreground in SUNO STYLE, not as lyrics): $realInst',
      );
    }
    buf.writeln(
      TrackDurationConfig.fromUserInput(
        duration: i.trackDuration,
        trackDurationLabel: i.trackDurationLabel,
        djIntro: i.djIntroMixIn,
        djOutro: i.djOutroMixOut,
        bpmRaw: i.bpm,
      ).toPromptContext(),
    );
    buf.writeln(
      buildDjMixUserBlock(
        djIntroMixIn: i.djIntroMixIn,
        djOutroMixOut: i.djOutroMixOut,
        v2UnifiedOutput: useV2,
      ),
    );
    if (useV2) {
      buf.writeln(
        Block1MixMasterDirective.userBlockDirective(
          primaryGenre: i.primaryGenre,
          subGenreFusion: i.subGenreFusion,
          djIntro: i.djIntroMixIn,
          djOutro: i.djOutroMixOut,
        ),
      );
    }
    buf.writeln(
      SongStructureData.userBlockDirective(
        presetId: i.songStructurePresetId,
        customNotes: i.songStructureCustom,
      ),
    );
    if (simple) {
      buf.writeln('USER LYRICS (not provided)');
    } else if (hasLyrics) {
      buf.writeln('USER LYRICS (provided)');
      buf.writeln(i.optionalLyrics.trim());
    } else {
      buf.writeln('USER LYRICS (not provided)');
      if (pathC) {
        buf.writeln('GENERATE LYRICS');
        buf.writeln('/WRITEIT');
        final tn = i.lyricThemeNotes.trim();
        if (tn.isNotEmpty) {
          buf.writeln('Lyric theme / subject / POV / keywords: $tn');
        }
        final tc = i.lyricTemperamentCodes.trim();
        if (tc.isNotEmpty) {
          buf.writeln('TEMPERAMENT CODES: $tc');
        }
      }
    }
    if (useV2) {
      buf.writeln(
        ProductionIntensityConfig.userBlockDirective(i.productionIntensity),
      );
      buf.writeln(
        SunoPromptBuilder.genreFxPreservationDirective(
          genreFxLaneId: i.genreFxLaneId,
          primaryGenre: i.primaryGenre,
          subGenreFusion: i.subGenreFusion,
          intensity: i.productionIntensity,
        ),
      );
    }
    if (!block2OptOut) {
      if (useV2) {
        buf.writeln(
          DrumMatrix.userBlockDirective(
            primaryGenre: i.primaryGenre,
            subGenreFusion: i.subGenreFusion,
            sunoVersion: i.sunoVersion,
          ),
        );
      }
      buf.writeln(HumanRealismConfig.userBlockDirective(i.humanRealism));
      buf.writeln(
        HumanAuthenticityConfig.userBlockDirective(
          primaryGenre: i.primaryGenre,
          subGenreFusion: i.subGenreFusion,
          djOutro: i.djOutroMixOut,
          audioEnvironmentModeId: i.audioEnvironmentModeId,
        ),
      );
    }
    if (i.includeAnalyzerData) {
      final detail = i.analyzerSummary.trim();
      buf.writeln(
        'TARGET AUDIO PROFILE (foundational layout constraints — anchor vocal tags, '
        'mix styles, arrangement pacing):',
      );
      buf.writeln(_resolvedAnalyzerConstraints(i));
      if (detail.isNotEmpty) {
        buf.writeln('\nAudio analysis detail:\n$detail');
      }
    }
    return buf.toString();
  }

  String _mockPrompt(UserInputModel i) {
    final useV2 = ApiConstants.useSunoPromptV2Candidate();
    final hasLyrics = i.optionalLyrics.trim().isNotEmpty;
    final simple = i.sunoFieldOutputMode == SunoFieldOutputMode.simple;
    final preset = SongStructureData.presetById(i.songStructurePresetId);
    final order = preset?.sectionOrder ?? '';
    String structureLine;
    if (order.isNotEmpty) {
      structureLine =
          '[Intro]\n(long DJ-friendly entry — offline preview)\n[Body]\n(Roadmap: $order)\n[Outro]\n(tail / resolve)';
    } else if (i.songStructurePresetId == SongStructureData.customId &&
        i.songStructureCustom.trim().isNotEmpty) {
      structureLine =
          '[Intro]\n(setup)\n[Custom sections]\n(${i.songStructureCustom.trim()})\n[Outro]\n(fade)';
    } else {
      structureLine =
          '[Intro]\n(arc opens)\n[Body]\n(development — offline preview)\n[Outro]\n(resolve)';
    }
    final djBits = <String>[];
    if (i.djIntroMixIn) {
      djBits.add(
        'DJ mix-in intro; long filtered kick/hat buildup; 24+ bars before main groove; crossfade-friendly.',
      );
    }
    if (i.djOutroMixOut) {
      djBits.add(
        'DJ mix-out; long tail; gradual filter; no hard stop; blend to next track.',
      );
    }
    final djSuffix = djBits.isEmpty ? '' : ' ${djBits.join(' ')}';
    final ri = i.realInstrumentals.trim();
    final riBit = ri.isEmpty
        ? ''
        : ' Real / acoustic instrumentation: $ri (mic’d, room-aware).';
    final chordBit = i.chordProgression.trim().isEmpty
        ? ''
        : ' Harmony roadmap: ${i.chordProgression.trim()}.';
    const proProduction =
        'Pro studio production: large-diaphragm condenser vocal chain, plate + short room, controlled de-ess; '
        'tuned live drums, amp/DI guitars where fit, wide analog synths; glue bus compression, mono-safe sub, '
        'streaming-ready master polish.';
    final hitmakerBit = userRequestedHitmakerMode(i)
        ? ' Hitmaker / Melodic Math: center-stack vocals (1176-style punch), sidechained pulsing bass, ~−8 LUFS, ear candy every ~8s.'
        : '';
    final styleBody = '''
${i.primaryGenre.isNotEmpty ? i.primaryGenre : 'Electronic'} — ${i.vibe.isNotEmpty ? i.vibe : 'cinematic tension'}. ${i.bpm != null ? '${i.bpm} BPM.' : ''} ${i.keyRoot != null && i.scale != null ? '${i.keyRoot} ${i.scale}.' : ''}$chordBit ${i.vocalSpec ?? 'Vocals TBD'}. ${i.avoid.isNotEmpty ? 'Avoid: ${i.avoid}.' : ''}$riBit$djSuffix $proProduction$hitmakerBit''';
    if (useV2) {
      if (simple) {
        final genre = i.primaryGenre.isNotEmpty ? i.primaryGenre : 'electronic';
        final oneLine =
            'A $genre track${i.bpm != null ? ' at ${i.bpm} BPM' : ''}${i.keyRoot != null && i.scale != null ? ' in ${i.keyRoot} ${i.scale}' : ''}, ${i.vibe.isNotEmpty ? i.vibe : 'cinematic tension'} — offline Simple Mode preview (connect API for full generation).';
        return '''
BLOCK 1 — PASTE INTO SUNO: STYLE

$oneLine

(${i.sunoVersion} — Simple Mode / Description field; offline preview.)
'''.trim();
      }
      if (hasLyrics) {
        return '''
BLOCK 1 — PASTE INTO SUNO: STYLE

$styleBody
Arrangement arc (offline): $structureLine

BLOCK 2 — PASTE INTO SUNO: LYRICS

[Verse]
${i.optionalLyrics.trim()}

[End]

(${i.sunoVersion} — offline preview: connect API for full generation)
'''.trim();
      }
      if (i.generateLyrics) {
        return '''
BLOCK 1 — PASTE INTO SUNO: STYLE

$styleBody
Arrangement arc (offline): $structureLine

BLOCK 2 — PASTE INTO SUNO: LYRICS

[Verse]
(offline Path C — connect API for original lyric generation)

[End]

(${i.sunoVersion} — Human Songwriter Engine requires live model)
'''.trim();
      }
      return '''
BLOCK 1 — PASTE INTO SUNO: STYLE

$styleBody
Arrangement arc (offline): $structureLine

(${i.sunoVersion} — offline preview — no lyrics block. Set MD_API_BASE_URL or add an API key for live generation.)
'''.trim();
    }
    if (hasLyrics) {
      return '''
SUNO STRUCTURE
$structureLine

SUNO STYLE
$styleBody

SUNO LYRICS
[Verse]
${i.optionalLyrics.trim()}

[${i.sunoVersion} — offline preview: connect API for full generation]
'''.trim();
    }
    if (i.generateLyrics) {
      return '''
SUNO STRUCTURE
$structureLine

SUNO STYLE
$styleBody

SUNO LYRICS
[Verse]
(offline Path C — connect API for original lyric generation)

[${i.sunoVersion} — Human Songwriter Engine requires live model]
'''.trim();
    }
    return '''
SUNO STRUCTURE
$structureLine

SUNO STYLE
$styleBody

[${i.sunoVersion} — offline preview — no lyrics block]

(Set MD_API_BASE_URL or add an API key for live generation.)
'''.trim();
  }
}
