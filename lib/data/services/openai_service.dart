import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/api_constants.dart';
import '../../core/constants/on_device_api_keys.dart';
import '../../core/network/dio_client.dart';
import '../../core/utils/api_connectivity.dart';
import '../../core/utils/chat_completion_helpers.dart';
import '../../core/ai/modules/genre_lyrics_emission.dart';
import '../../core/ai/modules/humanized_lyrics_qa.dart';
import '../../core/constants/song_structure_data.dart';
import '../../core/constants/structural_hierarchy_directive.dart';
import '../../core/constants/suno_system_prompt_v2_candidate.dart';
import '../../core/utils/suno_block2_opt_out.dart';
import '../../core/utils/suno_format_validation.dart';
import '../../core/utils/suno_internal_output_strip.dart';
import '../../core/utils/payload_optimization.dart';
import '../../core/utils/remix_payload_compiler.dart';
import '../../features/remix/application/remix_telemetry.dart';
import '../../data/models/song_generation_type.dart';
import '../../core/utils/suno_lyric_phonetic_sanitize.dart';
import '../../core/utils/suno_output_qa.dart';
import '../../core/utils/suno_output_split.dart';
import '../../core/utils/suno_path_a_lyrics.dart';
import '../../core/constants/suno_prompt_limits.dart';
import '../../core/constants/block1_mix_master_directive.dart';
import '../../services/narrative_brief_builder.dart';
import '../../core/suno_prompt_router.dart';
import '../../core/constants/big_room_fusion_progressive_engine.dart';
import '../../core/constants/big_room_hardstyle_cinematic_hybrid_engine.dart';
import '../../core/constants/thick_humanized_vocal_presence.dart';
import '../../core/utils/dynamic_structural_engine.dart';
import '../../core/utils/drum_matrix.dart';
import '../../core/routing/music_prompt_engine.dart';
import '../../core/routing/music_prompt_routing_monitor.dart';
import '../../core/utils/genre_hybridization_matrix.dart';
import '../../core/utils/live_instrument_matrix.dart';
import '../../core/utils/code_translation_matrix.dart';
import '../../core/constants/human_authenticity_config.dart';
import '../../core/constants/genre_data.dart';
import '../../songwriter/models/lyric_result.dart';
import '../../songwriter/models/song_brief.dart';
import '../../core/constants/prompt_flow_data.dart';
import '../../core/constants/genre_lyrics_directives.dart';
import '../../core/constants/master_country_lyric_engine.dart';
import '../../core/constants/master_edm_lyric_engine.dart';
import '../../core/constants/master_gospel_lyric_engine.dart';
import '../../core/constants/master_hardstyle_lyric_engine.dart';
import '../../core/constants/master_hiphop_lyric_engine.dart';
import '../../core/constants/master_pop_lyric_engine.dart';
import '../../core/constants/master_progressive_big_room_house_lyric_engine.dart';
import '../../core/constants/master_rnb_lyric_engine.dart';
import '../../core/constants/master_rock_lyric_engine.dart';
import '../../core/constants/lyric_craft_hierarchy_directive.dart';
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
import '../../core/constants/vocal_spec_tone_data.dart';
import '../../core/utils/theme_consistency_split.dart';
import '../models/suno_field_output_mode.dart';
import '../models/track_duration_config.dart';
import '../models/user_input_model.dart';

class OpenAIService {
  OpenAIService(this._dio, this._prefs);

  final Dio _dio;
  final SharedPreferences _prefs;

  ({String apiKey, bool useOpenRouter}) get _onDeviceCredentials =>
      OnDeviceApiKeys.resolveActive(_prefs);

  /// Multi-stage lyric pipeline via server `POST /generate-lyrics`.
  /// Requires [ApiConstants.resolveMdApiBase] / MD_API_BASE_URL.
  Future<LyricResult> generateSongwriterLyrics(SongBrief brief) async {
    final mdBase = ApiConstants.resolveMdApiBase(_prefs);
    if (mdBase == null || mdBase.isEmpty) {
      throw StateError(
        'Songwriter pipeline requires MD_API_BASE_URL (Music Director server).',
      );
    }
    await assertMusicDirectorServerReachable(mdBase);
    final api = createMusicDirectorApiDio(mdBase);
    final res = await api.post<Map<String, dynamic>>(
      ApiPaths.generateLyrics,
      options: songwriterRequestOptions(),
      data: {
        ...brief.toJson(),
        ...OnDeviceApiKeys.serverRequestFields(_prefs),
      },
    );
    final body = res.data;
    if (body == null) {
      throw StateError('Empty /generate-lyrics response');
    }
    return LyricResult.fromJson(body);
  }

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
    final mdBase = ApiConstants.resolveMdApiBase(_prefs);
    if (mdBase != null && mdBase.isNotEmpty) {
      try {
        await assertMusicDirectorServerReachable(mdBase);
        final text = await _generateOnServer(
          mdBase,
          input,
          userBlockSuffix: appendToUserBlock,
          continuationPriorOutput: continuationPriorOutput,
          continuationUserRequest: continuationUserRequest,
          preferLightweightModel: preferLightweightModel,
        );
        return _finalizeSunoV2Output(text, input);
      } catch (e) {
        if (_shouldFallbackToOnDeviceAfterServerFailure(e) &&
            OnDeviceApiKeys.hasActiveKey(_prefs)) {
          final onDevice = await _generateOnDeviceSunoPrompt(
            input: input,
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
    var userBlock = _buildUserContent(_withGenreFxApplied(input));
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
    final lightweight = ApiConstants.shouldUseLightweightChatModel(
      input,
      preferLightweightForRegenerate: preferLightweightModel,
    );

    String? routedDraftModel;
    String? routedPolishModel;
    String? pidginSubVariant;
    MusicPromptRoutingMonitor.recordRoutingGateCheck();
    if (ApiConstants.useSunoPromptV2Candidate()) {
      final plan = MusicPromptEngine.prepare(
        input: input,
        useOpenRouter: useOpenRouter,
        lightweight: lightweight,
        textHint: input.vibe,
      );
      userBlock = '${userBlock.trim()}\n\n${plan.userBlockAppend}';
      pidginSubVariant = plan.classification.pidginSubVariant;
      if (!lightweight) {
        routedDraftModel = MusicPromptEngine.draftModelForPlan(
          plan: plan,
          useOpenRouter: useOpenRouter,
          lightweight: false,
        );
        routedPolishModel = MusicPromptEngine.polishModelForPlan(
          plan: plan,
          useOpenRouter: useOpenRouter,
        );
      }
    } else if (VocalAccentData.coerceStored(input.vocalAccent ?? '') ==
            'nigerian_ibibio' ||
        input.dialectVariantId == 'ibibio') {
      MusicPromptRoutingMonitor.warnIbibioV1Fallback();
      pidginSubVariant = 'ibibio';
    }

    final endpoint = useOpenRouter
        ? ApiConstants.openRouterChatCompletions
        : ApiConstants.laozhangChatCompletions;
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
    final pathC = !simple &&
        (input.generateLyrics || input.useVibeAsLyricSource) &&
        !hasLyrics;
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

    final fewShotPrefix = MasterGospelLyricEngine.shouldInjectFewShot(
          primaryGenre: input.primaryGenre,
          subGenreFusion: input.subGenreFusion,
          vibe: input.vibe,
          lyricThemeNotes: input.lyricThemeNotes,
          lyricsTask: lyricsTask,
        )
        ? MasterGospelLyricEngine.fewShotPrefixMessages(
            primaryGenre: input.primaryGenre,
            subGenreFusion: input.subGenreFusion,
            vibe: input.vibe,
            lyricThemeNotes: input.lyricThemeNotes,
          )
        : MasterHardstyleLyricEngine.shouldInjectFewShot(
            primaryGenre: input.primaryGenre,
            subGenreFusion: input.subGenreFusion,
            vibe: input.vibe,
            lyricThemeNotes: input.lyricThemeNotes,
            lyricsTask: lyricsTask,
          )
        ? MasterHardstyleLyricEngine.fewShotPrefixMessages(
            primaryGenre: input.primaryGenre,
            subGenreFusion: input.subGenreFusion,
            vibe: input.vibe,
            lyricThemeNotes: input.lyricThemeNotes,
          )
        : MasterProgressiveBigRoomHouseLyricEngine.shouldInjectFewShot(
            primaryGenre: input.primaryGenre,
            subGenreFusion: input.subGenreFusion,
            vibe: input.vibe,
            lyricThemeNotes: input.lyricThemeNotes,
            lyricsTask: lyricsTask,
          )
        ? MasterProgressiveBigRoomHouseLyricEngine.fewShotPrefixMessages(
            primaryGenre: input.primaryGenre,
            subGenreFusion: input.subGenreFusion,
            vibe: input.vibe,
            lyricThemeNotes: input.lyricThemeNotes,
          )
        : MasterEdmLyricEngine.shouldInjectFewShot(
            primaryGenre: input.primaryGenre,
            subGenreFusion: input.subGenreFusion,
            vibe: input.vibe,
            lyricThemeNotes: input.lyricThemeNotes,
            lyricsTask: lyricsTask,
          )
        ? MasterEdmLyricEngine.fewShotPrefixMessages(
            primaryGenre: input.primaryGenre,
            subGenreFusion: input.subGenreFusion,
            vibe: input.vibe,
            lyricThemeNotes: input.lyricThemeNotes,
          )
        : MasterRnbLyricEngine.shouldInjectFewShot(
            primaryGenre: input.primaryGenre,
            subGenreFusion: input.subGenreFusion,
            vibe: input.vibe,
            lyricThemeNotes: input.lyricThemeNotes,
            lyricsTask: lyricsTask,
          )
        ? MasterRnbLyricEngine.fewShotPrefixMessages(
            primaryGenre: input.primaryGenre,
            subGenreFusion: input.subGenreFusion,
            vibe: input.vibe,
            lyricThemeNotes: input.lyricThemeNotes,
          )
        : MasterHipHopLyricEngine.shouldInjectFewShot(
            primaryGenre: input.primaryGenre,
            subGenreFusion: input.subGenreFusion,
            vibe: input.vibe,
            lyricThemeNotes: input.lyricThemeNotes,
            lyricsTask: lyricsTask,
          )
        ? MasterHipHopLyricEngine.fewShotPrefixMessages(
            primaryGenre: input.primaryGenre,
            subGenreFusion: input.subGenreFusion,
            vibe: input.vibe,
            lyricThemeNotes: input.lyricThemeNotes,
          )
        : MasterCountryLyricEngine.shouldInjectFewShot(
            primaryGenre: input.primaryGenre,
            subGenreFusion: input.subGenreFusion,
            vibe: input.vibe,
            lyricThemeNotes: input.lyricThemeNotes,
            lyricsTask: lyricsTask,
          )
        ? MasterCountryLyricEngine.fewShotPrefixMessages(
            primaryGenre: input.primaryGenre,
            subGenreFusion: input.subGenreFusion,
            vibe: input.vibe,
            lyricThemeNotes: input.lyricThemeNotes,
          )
        : MasterRockLyricEngine.shouldInjectFewShot(
            primaryGenre: input.primaryGenre,
            subGenreFusion: input.subGenreFusion,
            vibe: input.vibe,
            lyricThemeNotes: input.lyricThemeNotes,
            lyricsTask: lyricsTask,
          )
        ? MasterRockLyricEngine.fewShotPrefixMessages(
            primaryGenre: input.primaryGenre,
            subGenreFusion: input.subGenreFusion,
            vibe: input.vibe,
            lyricThemeNotes: input.lyricThemeNotes,
          )
        : MasterPopLyricEngine.shouldInjectFewShot(
            primaryGenre: input.primaryGenre,
            subGenreFusion: input.subGenreFusion,
            vibe: input.vibe,
            lyricThemeNotes: input.lyricThemeNotes,
            lyricsTask: lyricsTask,
          )
        ? MasterPopLyricEngine.fewShotPrefixMessages(
            primaryGenre: input.primaryGenre,
            subGenreFusion: input.subGenreFusion,
            vibe: input.vibe,
            lyricThemeNotes: input.lyricThemeNotes,
          )
        : null;

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
        draftModelOverride: routedDraftModel,
        polishModelOverride: routedPolishModel,
        pidginSubVariant: pidginSubVariant,
        chatPrefixTurns: fewShotPrefix,
      );
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
          chatPrefixTurns: fewShotPrefix,
        );
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
        return _deliverWithLyricQualityGate(
          text,
          input,
          applyThemePass: !serverMode,
          preferLightweightModel: preferLightweightModel,
          continuationPriorOutput: continuationPriorOutput,
          continuationUserRequest: continuationUserRequest,
        );
      }

      final expectLyrics = !userRequestedBlock2OptOut(input);
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
      return _deliverWithLyricQualityGate(
        text,
        input,
        applyThemePass: !serverMode,
        preferLightweightModel: preferLightweightModel,
        continuationPriorOutput: continuationPriorOutput,
        continuationUserRequest: continuationUserRequest,
      );
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

    return _deliverWithLyricQualityGate(
      text,
      input,
      applyThemePass: !serverMode,
      preferLightweightModel: preferLightweightModel,
      continuationPriorOutput: continuationPriorOutput,
      continuationUserRequest: continuationUserRequest,
    );
  }

  static const _maxLyricQualityRetries = 1;

  bool _shouldRunLyricQualityGate(UserInputModel input) {
    if (!ApiConstants.useSunoPromptV2Candidate()) return false;
    if (userRequestedBlock2OptOut(input)) return false;
    if (!_lyricsTaskFor(input)) return false;
    if (input.optionalLyrics.trim().isNotEmpty) return false;
    if (remixEngineActive(input) &&
        input.songGenerationType == SongGenerationType.instrumental) {
      return false;
    }
    return GenreLyricsEmission.emitsLyrics(_genreLabelForLyricQa(input));
  }

  String _genreLabelForLyricQa(UserInputModel input) {
    final fusion = input.subGenreFusion.trim();
    if (fusion.isNotEmpty) return fusion;
    final primary = input.primaryGenre.trim();
    return primary.isEmpty ? 'Pop' : primary;
  }

  HumanizedLyricsQaResult? _lyricQaOnDelivered(
    String delivered,
    UserInputModel input, {
    bool recordSession = true,
  }) {
    if (!_shouldRunLyricQualityGate(input)) return null;
    final parsed = parseSunoOutput(_finalizeSunoV2Output(delivered, input));
    final lyrics = parsed.lyricsBody?.trim() ?? '';
    if (lyrics.isEmpty) return null;
    return HumanizedLyricsQa.enforceHumanizedLyrics(
      lyrics,
      _genreLabelForLyricQa(input),
      recordSession: recordSession,
      regenerateOnClicheHits: true,
    );
  }

  /// Post-process delivery, then optionally one lyric-quality regenerate pass.
  Future<String> _deliverWithLyricQualityGate(
    String text,
    UserInputModel input, {
    required bool applyThemePass,
    required bool preferLightweightModel,
    String? continuationPriorOutput,
    String? continuationUserRequest,
  }) async {
    if (!_shouldRunLyricQualityGate(input)) {
      return _deliverSunoOutput(text, input, applyThemePass: applyThemePass);
    }

    var bestDelivered = await _deliverSunoOutput(
      text,
      input,
      applyThemePass: applyThemePass,
    );
    var bestQa = _lyricQaOnDelivered(bestDelivered, input);
    if (bestQa == null || !bestQa.shouldRegenerate) {
      return bestDelivered;
    }
    var activeQa = bestQa;

    for (var attempt = 0; attempt < _maxLyricQualityRetries; attempt++) {
      final suffix = HumanizedLyricsQa.buildRegenerateSuffix(activeQa);
      final retryMaxTok = (_baseMaxCompletionTokens(input) * 1.2).ceil().clamp(
            1400,
            8192,
          );
      final retryRaw = await generateSunoPrompt(
        input,
        preferLightweightModel: preferLightweightModel,
        appendToUserBlock: suffix,
        temperatureOverride: 0.42,
        maxCompletionTokensOverride: retryMaxTok,
        continuationPriorOutput: continuationPriorOutput,
        continuationUserRequest: continuationUserRequest,
        skipThemeConsistencyPass: true,
      );

      final retryFinalized = _finalizeSunoV2Output(retryRaw, input);
      if (_needsFormatRetry(retryFinalized, input)) continue;

      final retryDelivered = await _deliverSunoOutput(
        retryRaw,
        input,
        applyThemePass: applyThemePass,
      );
      final retryQa = _lyricQaOnDelivered(
        retryDelivered,
        input,
        recordSession: false,
      );
      if (retryQa == null) continue;

      if (HumanizedLyricsQa.isBetterResult(retryQa, activeQa)) {
        bestDelivered = retryDelivered;
        activeQa = retryQa;
      }
      if (!retryQa.shouldRegenerate) break;
    }

    return bestDelivered;
  }

  int _baseMaxCompletionTokens(UserInputModel input) {
    final lyricsTrim = input.optionalLyrics.trim();
    final hasLyrics = lyricsTrim.isNotEmpty;
    final pathC = input.sunoFieldOutputMode != SunoFieldOutputMode.simple &&
        (input.generateLyrics || input.useVibeAsLyricSource) &&
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

    var userBlock = _buildUserContent(_withGenreFxApplied(input));
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
    out = enforceUnifiedBlock1CharLimit(out, input.sunoFieldOutputMode);
    if (remixEngineActive(input) &&
        input.songGenerationType == SongGenerationType.instrumental) {
      return out;
    }
    return pinUserLyricsToBlock2(out, input.optionalLyrics);
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
    final hasUserLyrics = input.optionalLyrics.trim().isNotEmpty;
    if (ApiConstants.themeConsistencyEnabled() &&
        !remixInstrumental &&
        !hasUserLyrics) {
      out = await _applyThemeConsistencyPass(out, input);
    }
    if (!remixInstrumental && !hasUserLyrics) {
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
    final hasUserLyrics = input.optionalLyrics.trim().isNotEmpty;
    if (ApiConstants.themeConsistencyEnabled() && !hasUserLyrics) {
      out = await _applyThemeConsistencyPass(out, input);
    }
    if (!hasUserLyrics) {
      out = await _applyHumanizationPass(out, input, useOpenRouter: false);
    }
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
    String? draftModelOverride,
    String? polishModelOverride,
    String? pidginSubVariant,
    List<Map<String, String>>? chatPrefixTurns,
  }) async {
    final draftModel = draftModelOverride ??
        ApiConstants.draftModelForPromptWithProvider(
          language: language,
          lightweight: lightweight,
          useOpenRouter: useOpenRouter,
          lyricsTask: lyricsTask,
        );
    final polishModel = polishModelOverride ??
        ApiConstants.polishModelForPromptWithProvider(
          useOpenRouter: useOpenRouter,
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
          chatPrefixTurns: chatPrefixTurns,
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
        chatPrefixTurns: chatPrefixTurns,
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
            chatPrefixTurns: chatPrefixTurns,
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
            chatPrefixTurns: chatPrefixTurns,
          );

    if (useOpenRouter) {
      final polishMaxTok = maxTok.clamp(3200, 8192);
      try {
        final polishUser = buildSunoPolishUserMessage(
          draft: draft,
          originalUserBlock: userBlock,
          pidginSubVariant: pidginSubVariant,
        );
        _assertIbibioPolishGuard(polishUser, pidginSubVariant);
        return await _completeChatCompletion(
          endpoint: endpoint,
          headers: headers,
          model: polishModel,
          systemContent: kSunoPolishSystemPrompt,
          userBlock: polishUser,
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
      pidginSubVariant: pidginSubVariant,
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

  void _assertIbibioPolishGuard(String polishUserBlock, String? pidginSubVariant) {
    if (pidginSubVariant != 'ibibio') return;
    assert(
      polishUserBlock.contains('Abasi'),
      'Ibibio vocabulary missing from polish stage — '
      'final lyrics will lose cultural markers',
    );
  }

  int _laozhangCompletionMaxTokens(int maxTok) =>
      (maxTok * 1.5).ceil().clamp(4200, 8192);

  Future<String> _polishLaozhangDraftWithFallback({
    required String endpoint,
    required Map<String, String> headers,
    required String draft,
    required String userBlock,
    required int maxTok,
    String? pidginSubVariant,
  }) async {
    final polishUser = buildSunoPolishUserMessage(
      draft: draft,
      originalUserBlock: userBlock,
      pidginSubVariant: pidginSubVariant,
    );
    _assertIbibioPolishGuard(polishUser, pidginSubVariant);
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
    List<Map<String, String>>? chatPrefixTurns,
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
          chatPrefixTurns: chatPrefixTurns,
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

  List<Map<String, String>> _buildChatMessages({
    required String systemContent,
    required String userBlock,
    List<Map<String, String>>? chatPrefixTurns,
  }) {
    final messages = <Map<String, String>>[
      {'role': 'system', 'content': systemContent},
    ];
    if (chatPrefixTurns != null) {
      messages.addAll(chatPrefixTurns);
    }
    messages.add({'role': 'user', 'content': userBlock});
    return messages;
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
    List<Map<String, String>>? chatPrefixTurns,
  }) async {
    final payload = <String, dynamic>{
      'model': model,
      'messages': _buildChatMessages(
        systemContent: systemContent,
        userBlock: userBlock,
        chatPrefixTurns: chatPrefixTurns,
      ),
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
    UserInputModel input, {
    String? userBlockSuffix,
    String? continuationPriorOutput,
    String? continuationUserRequest,
    bool preferLightweightModel = false,
  }) async {
    final fxInput = _withGenreFxApplied(input);
    final lyricsTrim = fxInput.optionalLyrics.trim();
    final hasLyrics = lyricsTrim.isNotEmpty;
    final simple = input.sunoFieldOutputMode == SunoFieldOutputMode.simple;
    final pathC = !simple &&
        (input.generateLyrics || input.useVibeAsLyricSource) &&
        !hasLyrics;
    final family = StructuralFamilyResolver.resolve(
      primaryGenre: input.primaryGenre,
      fusionGenre: input.subGenreFusion,
      commercialLane: input.genreFxLaneId.isEmpty ? null : input.genreFxLaneId,
    );
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
        'sonic_tags': input.sonicTags,
        'avoid': input.avoid,
        'language': input.language,
        'include_analyzer_data': input.includeAnalyzerData,
        'analyzer_summary': input.analyzerSummary,
        'track_duration_label': input.trackDurationLabel,
        'dj_intro_mix_in': input.djIntroMixIn,
        'dj_outro_mix_out': input.djOutroMixOut,
        'song_structure_directive': _structureUserBlock(
          input,
          useV2: ApiConstants.useSunoPromptV2Candidate(),
          block2OptOut: userRequestedBlock2OptOut(input),
          family: family,
        ),
        'song_structure_preset_id': input.songStructurePresetId,
        'song_structure_custom': input.songStructureCustom,
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
        'use_vibe_as_lyric_source': input.useVibeAsLyricSource,
        'lyric_theme_notes': input.lyricThemeNotes,
        'active_modifier_codes': input.activeModifierCodes,
        'melody_style_id': input.melodyStyleId,
        'melody_custom_notes': input.melodyCustomNotes,
        'bpm_hint': GenreData.bpmHintForLabel(input.primaryGenre) ?? '',
        'human_realism': input.humanRealism,
        'production_intensity': input.productionIntensity,
        'genre_fx_lane': input.genreFxLaneId,
        'duration_user_block': TrackDurationConfig.fromUserInput(
          duration: input.trackDuration,
          trackDurationLabel: input.trackDurationLabel,
          djIntro: input.djIntroMixIn,
          djOutro: input.djOutroMixOut,
          bpmRaw: input.bpm,
          family: family,
        ).toPromptContext(),
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

  String _vocalUserBlockLine(UserInputModel i) {
    return VocalSpecToneData.userBlockLine(
      vocalSpec: i.vocalSpec,
      vocalTone: i.vocalTone,
    );
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

  String _structureUserBlock(
    UserInputModel i, {
    required bool useV2,
    required bool block2OptOut,
    required StructuralFamily family,
  }) {
    final hybridLane = BigRoomHardstyleCinematicHybridEngine.matchesLane(
      primaryGenre: i.primaryGenre,
      subGenreFusion: i.subGenreFusion,
    );
    final djOk = djMixAllowedForFamily(family);
    final lock = SongStructureData.userBlockDirective(
      presetId: i.songStructurePresetId,
      customNotes: i.songStructureCustom,
      sunoVersion: i.sunoVersion,
      primaryGenre: i.primaryGenre,
      subGenreFusion: i.subGenreFusion,
      commercialLane: i.genreFxLaneId.isEmpty ? null : i.genreFxLaneId,
      includeDjIntro: hybridLane ? djOk : i.djIntroMixIn && djOk,
      includeDjOutro: hybridLane ? djOk : i.djOutroMixOut && djOk,
    );
    if (hybridLane) {
      return [
        lock,
        BigRoomHardstyleCinematicHybridEngine.composeStructuralConstraintsBlock(),
      ].join('\n\n');
    }
    if (!useV2 || block2OptOut) return lock;
    final custom = i.songStructureCustom.trim();
    if (RegExp(r'\[[^\]]+\]').hasMatch(custom)) return lock;
    return lock;
  }

  String _buildUserContent(UserInputModel i) {
    final hasLyrics = i.optionalLyrics.trim().isNotEmpty;
    final useV2 = ApiConstants.useSunoPromptV2Candidate();
    final simple = i.sunoFieldOutputMode == SunoFieldOutputMode.simple;
    final pathC = !simple &&
        (i.generateLyrics || i.useVibeAsLyricSource) &&
        !hasLyrics;
    final block2OptOut = userRequestedBlock2OptOut(i);
    final family = StructuralFamilyResolver.resolve(
      primaryGenre: i.primaryGenre,
      fusionGenre: i.subGenreFusion,
      commercialLane: i.genreFxLaneId.isEmpty ? null : i.genreFxLaneId,
    );
    final hybridLane = BigRoomHardstyleCinematicHybridEngine.matchesLane(
      primaryGenre: i.primaryGenre,
      subGenreFusion: i.subGenreFusion,
    );
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
    final remixRes = remixResolutionFor(i);
    final existingBuf = buf.toString();
    if (remixRes.mode == RemixMode.analyzerGenreFlip) {
      final before = buf.toString();
      if (!before.contains(remixAnalyzerBlockMarker)) {
        buf.writeln(
          useV2
              ? SunoPromptLimits.remixFromAnalyzerUserBlockSupplementV2(
                  i.sunoVersion,
                )
              : SunoPromptLimits.remixFromAnalyzerUserBlockSupplement(
                  i.sunoVersion,
                ),
        );
      }
      RemixTelemetry.activation(
        mode: remixRes.mode,
        nearActivation: remixRes.nearActivation,
        genre: i.primaryGenre,
        songGenerationType: i.songGenerationType.apiValue,
        blockInjected: !before.contains(remixAnalyzerBlockMarker),
      );
    } else if (remixRes.mode == RemixMode.interpolation) {
      final block = remixStyleFlipUserBlockSupplement(
        originalSongTitle: i.remixOriginalSongTitle,
        originalArtist: i.remixOriginalArtist,
        targetGenre: i.primaryGenre,
        generationType: i.songGenerationType,
        bpm: i.bpm ?? '',
        keyRoot: i.keyRoot ?? '',
        scale: i.scale ?? '',
        vibe: i.vibe,
        existingUserBlock: existingBuf,
      );
      if (block.isNotEmpty) buf.writeln(block);
      RemixTelemetry.activation(
        mode: remixRes.mode,
        nearActivation: remixRes.nearActivation,
        genre: i.primaryGenre,
        songGenerationType: i.songGenerationType.apiValue,
        title: i.remixOriginalSongTitle,
        artist: i.remixOriginalArtist,
        blockInjected: block.isNotEmpty,
      );
    } else if (remixRes.nearActivation) {
      RemixTelemetry.activation(
        mode: remixRes.mode,
        nearActivation: true,
        genre: i.primaryGenre,
        songGenerationType: i.songGenerationType.apiValue,
        title: i.remixOriginalSongTitle,
        artist: i.remixOriginalArtist,
        blockInjected: false,
      );
    }
    buf
      ..writeln('Suno version: ${i.sunoVersion}')
      ..writeln(
        'Primary genre: ${primaryGenreWithDjToolModifier(
          primaryGenre: i.primaryGenre,
          djIntroMixIn: hybridLane ? true : i.djIntroMixIn,
          djOutroMixOut: hybridLane ? true : i.djOutroMixOut,
          family: family,
        )}',
      )
      ..writeln('Fusion / sub-genre: ${i.subGenreFusion}');
    for (final line in PromptFlowData.buildVibeUserBlockLines(
      vibe: i.vibe,
      useVibeAsLyricSource: i.useVibeAsLyricSource,
    )) {
      buf.writeln(line);
    }
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
    final specToneBlock = VocalSpecToneData.userBlockDirective(
      vocalSpec: i.vocalSpec,
      vocalTone: i.vocalTone,
    );
    if (specToneBlock.isNotEmpty) {
      buf.writeln(specToneBlock);
    }
    final thickVocal = ThickHumanizedVocalPresence.composeUserBlock(
      primaryGenre: i.primaryGenre,
      subGenreFusion: i.subGenreFusion,
      vocalSpec: i.vocalSpec,
    );
    if (thickVocal.isNotEmpty) {
      buf.writeln(thickVocal);
    }
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
    if (i.includeAnalyzerData) {
      final analyzerSummary = i.analyzerSummary.trim();
      if (analyzerSummary.isNotEmpty) {
        buf.writeln(analyzerSummary);
      }
    }
    final refArtists = i.referenceArtists.trim();
    if (refArtists.isNotEmpty) {
      buf.writeln(
        '[ARTIST DNA REFERENCES] (ROLE: Music DNA Translator. TASK: Analyze the following references. Extract their core musical characteristics (timbre, harmony, rhythm, structure). Synthesize these traits into descriptive prose for the music model. STRICTLY FORBIDDEN: Do NOT mention the original artist, song, or album names in your output.): $refArtists',
      );
    }
    if (i.sonicTags.isNotEmpty) {
      buf.writeln(
        '[SONIC CHARACTERISTICS] (REQUIREMENTS: These are MANDATORY production instructions. Apply them LITERALLY to the final music prompt. DO NOT interpret, translate, or dilute these instructions in any way.): ${i.sonicTags.join(', ')}',
      );
    }
    buf
      ..writeln(
        'Avoid: ${LiveInstrumentMatrix.augmentAvoidClause(avoid: i.avoid, realInstrumentals: i.realInstrumentals)}',
      )
      ..writeln('Language: ${i.language}');
    if (useV2) {
      final codeBlock = CodeTranslationMatrix.userBlockDirective(
        primaryGenre: i.primaryGenre,
        subGenreFusion: i.subGenreFusion,
        codesBlob: i.activeModifierCodes,
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
    final realInst = i.realInstrumentals.trim();
    if (realInst.isNotEmpty) {
      buf.writeln(
        useV2
            ? LiveInstrumentMatrix.userBlockDirective(
                primaryGenre: i.primaryGenre,
                subGenreFusion: i.subGenreFusion,
                selectionRaw: realInst,
                sunoVersion: i.sunoVersion,
                powerCodes: i.activeModifierCodes,
              )
            : 'Real / acoustic instruments (live or mic’d — foreground in SUNO STYLE, not as lyrics): $realInst',
      );
    }
    buf.writeln(
      TrackDurationConfig.fromUserInput(
        duration: i.trackDuration,
        trackDurationLabel: i.trackDurationLabel,
        djIntro: hybridLane ? true : i.djIntroMixIn,
        djOutro: hybridLane ? true : i.djOutroMixOut,
        bpmRaw: i.bpm,
        family: family,
        primaryGenre: i.primaryGenre,
        fusionGenre: i.subGenreFusion,
      ).toPromptContext(),
    );
    if (hybridLane) {
      buf.writeln(
        BigRoomHardstyleCinematicHybridEngine.composeDjMixEnforcementBlock(),
      );
    } else {
      buf.writeln(
        buildDjMixUserBlock(
          djIntroMixIn: i.djIntroMixIn,
          djOutroMixOut: i.djOutroMixOut,
          sunoVersion: i.sunoVersion,
          family: family,
          v2UnifiedOutput: useV2,
        ),
      );
    }
    if (useV2) {
      buf.writeln(
        Block1MixMasterDirective.userBlockDirective(
          primaryGenre: i.primaryGenre,
          subGenreFusion: i.subGenreFusion,
          sunoVersion: i.sunoVersion,
        ),
      );
      buf.writeln(
        SunoPromptRouterV2.userBlockDirective(
          primaryGenre: i.primaryGenre,
          subGenreFusion: i.subGenreFusion,
          sunoVersion: i.sunoVersion,
        ),
      );
    }
    final eliteHybrid = BigRoomHardstyleCinematicHybridEngine.userBlockAppendFor(
      primaryGenre: i.primaryGenre,
      subGenreFusion: i.subGenreFusion,
    );
    if (eliteHybrid.isNotEmpty) {
      buf.writeln(eliteHybrid);
    } else {
      final eliteBr = BigRoomFusionProgressiveEngine.userBlockAppendFor(
        primaryGenre: i.primaryGenre,
        subGenreFusion: i.subGenreFusion,
      );
      if (eliteBr.isNotEmpty) {
        buf.writeln(eliteBr);
      }
    }
    final structuralHierarchy =
        StructuralHierarchyDirective.userBlockDirective(i);
    if (structuralHierarchy != null) {
      buf.writeln(structuralHierarchy);
    }
    buf.writeln(
      _structureUserBlock(
        i,
        useV2: useV2,
        block2OptOut: block2OptOut,
        family: family,
      ),
    );
    if (simple) {
      buf.writeln('USER LYRICS (not provided)');
    } else if (hasLyrics) {
      buf.writeln(
        'USER LYRICS (provided) — PATH A: copy these sung lines into BLOCK 2 verbatim. '
        'Do not rewrite, paraphrase, or replace them.',
      );
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
        final narrativeBrief = NarrativeBriefBuilder.build(
          primaryGenre: i.primaryGenre,
          subGenreFusion: i.subGenreFusion,
          mood: i.vibe.trim().isNotEmpty ? i.vibe.trim() : 'unspecified',
          themes: NarrativeBriefBuilder.themesFromNotes(i.lyricThemeNotes),
        );
        buf.writeln('NARRATIVE BRIEF: $narrativeBrief');
        final tc = i.activeModifierCodes.trim();
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
          DynamicStructuralEngine.userBlockDirective(
            primaryGenre: i.primaryGenre,
            subGenreFusion: i.subGenreFusion,
            sunoVersion: i.sunoVersion,
          ),
        );
        buf.writeln(
          DrumMatrix.userBlockDirective(
            primaryGenre: i.primaryGenre,
            subGenreFusion: i.subGenreFusion,
            sunoVersion: i.sunoVersion,
          ),
        );
      }
      final lyricHierarchy = LyricCraftHierarchyDirective.userBlockDirective(i);
      if (lyricHierarchy != null) {
        buf.writeln(lyricHierarchy);
      }
      buf.writeln(
        HumanRealismConfig.userBlockDirective(
          i.humanRealism,
          dialectStyleId: i.dialectStyleId,
        ),
      );
      buf.writeln(
        HumanAuthenticityConfig.userBlockDirective(
          primaryGenre: i.primaryGenre,
          subGenreFusion: i.subGenreFusion,
          djOutro: i.djOutroMixOut,
          audioEnvironmentModeId: i.audioEnvironmentModeId,
        ),
      );
      final genreLyrics = GenreLyricsDirectives.userBlockDirective(
        primaryGenre: i.primaryGenre,
        subGenreFusion: i.subGenreFusion,
        vibe: i.vibe,
        lyricThemeNotes: i.lyricThemeNotes,
        vocalSpec: i.vocalSpec,
        vocalTone: i.vocalTone,
        melodyStyleId: i.melodyStyleId,
        melodyCustomNotes: i.melodyCustomNotes,
        bpmHint: GenreData.bpmHintForLabel(i.primaryGenre),
        genreFxLaneId: i.genreFxLaneId,
      );
      if (genreLyrics.isNotEmpty) {
        buf.writeln(genreLyrics);
      }
    }
    return buf.toString();
  }
}
