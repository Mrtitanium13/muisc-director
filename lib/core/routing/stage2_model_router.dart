import '../constants/api_constants.dart';
import '../ai/modules/genre_lyrics_emission.dart';
import '../ai/modules/k_human_voice_directive.dart';
import 'genre_scaffold_map.dart';
import 'music_prompt_routing.dart';

/// Stage 2 — maps [RoutingKey] → logical model + regional user-block overlay.
class Stage2ModelRouter {
  Stage2ModelRouter._();

  /// Calabar/Ibibio markers — must survive draft AND polish stages.
  static const ibibioVocabularyTokens = [
    'Abasi',
    'esie',
    'kpa',
    'edinen',
    'emi',
    'idaha',
    'nno',
    'fo',
    'mmo',
    'mi',
  ];

  static const ibibioVocabularyBlock =
      'IBIBIO VOCABULARY (preserve in lyrics — do NOT replace with Lagos/wahala/abeg): '
      'Abasi, esie, kpa, edinen, emi, idaha, nno, fo, mmo, mi';

  static const lagosPidginBannedInIbibio = [
    'wahala',
    'abeg',
    'na wa o',
    'sef',
    'oya',
  ];

  static const _routingToPrimaryModel = {
    RoutingKeys.genAfricanMainstream: ModelKeys.claudeSonnet,
    RoutingKeys.genAfricanPidgin: ModelKeys.claudeSonnet,
    RoutingKeys.genEastAsian: ModelKeys.glm,
    RoutingKeys.genEuropeanLingual: ModelKeys.mistral,
    RoutingKeys.hybridCultural: ModelKeys.gpt5,
    RoutingKeys.genLatin: ModelKeys.claudeSonnet,
    RoutingKeys.genWesternPop: ModelKeys.gpt5,
    RoutingKeys.genSea: ModelKeys.mistral,
    RoutingKeys.genMiddleEastern: ModelKeys.gpt5,
    RoutingKeys.hybridMultiGenre: ModelKeys.gpt5,
  };

  static ModelKey pickModelKey(Stage1Classification c) {
    if (c.routingKey == RoutingKeys.hybridMultiGenre) {
      return _pickModelForHybrid(c);
    }
    return _routingToPrimaryModel[c.routingKey] ?? ModelKeys.gpt5;
  }

  static ModelKey _pickModelForHybrid(Stage1Classification c) {
    final genres = [
      c.primarySlot.genre.toLowerCase(),
      ...c.secondarySlots.map((s) => s.genre.toLowerCase()),
    ];
    final langs = c.languagesDetected.map((l) => l.toLowerCase()).toList();
    final hasEastAsian = langs.any((l) => ['zh', 'yue', 'ja', 'ko', 'vi'].contains(l)) ||
        genres.any((g) => [
              'mandopop',
              'jpop',
              'kpop',
              'cantopop',
              'vpop',
              'vinahouse',
              'trot',
            ].any(g.contains));
    if (hasEastAsian) return ModelKeys.glm;
    final hasLatin = langs.any((l) => ['es', 'pt'].contains(l)) ||
        genres.any((g) => ['reggaeton', 'bachata', 'salsa', 'latin'].any(g.contains));
    if (hasLatin) return ModelKeys.claudeSonnet;
    return ModelKeys.gpt5;
  }

  /// Provider-specific API model slug for draft generation.
  static String resolveDraftModelSlug({
    required Stage1Classification classification,
    required bool useOpenRouter,
    required bool lightweight,
  }) {
    if (lightweight) {
      return useOpenRouter
          ? ApiConstants.openRouterLightChatModel
          : ApiConstants.laozhangLightChatModel;
    }
    return _slugForModelKey(
      pickModelKey(classification),
      useOpenRouter: useOpenRouter,
    );
  }

  static String resolvePolishModelSlug({
    required Stage1Classification classification,
    required bool useOpenRouter,
  }) {
    if (useOpenRouter) {
      return ApiConstants.polishModelForPromptWithProvider(
        useOpenRouter: true,
      );
    }
    final key = pickModelKey(classification);
    switch (key) {
      case ModelKeys.claudeSonnet:
        return ApiConstants.laozhangLyricsPrimaryChatModel;
      case ModelKeys.glm:
      case ModelKeys.mistral:
      case ModelKeys.gpt5:
        return ApiConstants.laozhangPromptChatModel;
      default:
        return ApiConstants.laozhangLyricsPrimaryChatModel;
    }
  }

  static String _slugForModelKey(ModelKey key, {required bool useOpenRouter}) {
    if (useOpenRouter) {
      switch (key) {
        case ModelKeys.claudeSonnet:
          return 'anthropic/claude-sonnet-4';
        case ModelKeys.gpt5:
          return ApiConstants.openRouterGenerateChatModel;
        case ModelKeys.glm:
          return 'zhipu/glm-4-plus';
        case ModelKeys.mistral:
          return ApiConstants.openRouterHumanizationChatModel;
        case ModelKeys.qwen:
          return ApiConstants.openRouterGenerateChatModel;
        default:
          return ApiConstants.openRouterGenerateChatModel;
      }
    }
    switch (key) {
      case ModelKeys.claudeSonnet:
        return ApiConstants.laozhangLyricsPrimaryChatModel;
      case ModelKeys.gpt5:
        return ApiConstants.laozhangPromptChatModel;
      case ModelKeys.glm:
      case ModelKeys.mistral:
        return ApiConstants.laozhangPromptChatModel;
      case ModelKeys.qwen:
        return ApiConstants.laozhangGeminiFlashModel;
      default:
        return ApiConstants.laozhangPromptChatModel;
    }
  }

  static String buildRegionalUserBlockAppend(Stage1Classification c) {
    final buf = StringBuffer()
      ..writeln('MUSIC PROMPT ROUTER (Stage 1 classification — internal):')
      ..writeln('routing_key=${c.routingKey}')
      ..writeln('is_hybrid=${c.isHybrid}')
      ..writeln('estimated_bpm=${c.estimatedBpm}')
      ..writeln('dominant_language=${c.dominantLanguage}')
      ..writeln('languages_detected=${c.languagesDetected.join(", ")}');

    if (c.pidginSubVariant != null) {
      buf.writeln('pidgin_sub_variant=${c.pidginSubVariant}');
      buf.writeln(_pidginOverlay(c.pidginSubVariant!));
    }
    if (c.eastAsianSubVariant != null) {
      buf.writeln('east_asian_sub_variant=${c.eastAsianSubVariant}');
      buf.writeln(_eastAsianOverlay(c.eastAsianSubVariant!));
    }
    if (c.isHybrid && c.hybridResolution != null) {
      buf.writeln('tempo_strategy=${c.hybridResolution!.tempoStrategy}');
      buf.writeln(_hybridOverlay(c));
    }
    if (_isWestAfricanLane(c)) {
      buf.writeln(_westAfricanImageryOverlay());
    }
    buf.writeln(
      GenreScaffoldMap.buildIntroOutroInstructionForClassification(
        c,
        vibeHint: c.dominantMood,
      ),
    );
    buf.writeln(
      'Apply kStagingAndAccentRules Section D blacklist on all staging brackets before emission.',
    );
    if (GenreLyricsEmission.emitsLyrics(c.primarySlot.genre)) {
      buf.writeln(kHumanVoiceDirective);
    }
    return buf.toString().trim();
  }

  /// Whether [genre] should receive human-voice directive + lyric QA.
  static bool genreEmitsLyrics(String genre) =>
      GenreLyricsEmission.emitsLyrics(genre);

  static bool _isWestAfricanLane(Stage1Classification c) {
    return c.routingKey == RoutingKeys.genAfricanMainstream ||
        c.routingKey == RoutingKeys.genAfricanPidgin;
  }

  static String _westAfricanImageryOverlay() => '''
PART 2 ANTI-REPETITION (West African lanes):
- Do not reuse the same physical object/noise across sections.
- Banned tokens → swap per Regional Daily Life matrix: Zinc → veranda/compound/plastic chair; Generator Hum → akara/okada/broom/radio; Tea/Coffee → akara/pap/well water/sachet water; Kitchen Counter → veranda/doorstep/compound gate.
- BANNED STOCK FORMULAS: "At 3 AM on cold tile in Lagos", bleach/scrubbing floors, bent receipt by the kettle, "Mama said… count grace before receipts". Invent scene details from THIS brief — Lagos only if the user set Nigeria / Lagos.''';

  static String _hybridOverlay(Stage1Classification c) {
    final h = c.hybridResolution!;
    final sec = h.secondary.map((s) => s.genre).join(' + ');
    final domBpm = h.dominant.bpm ?? c.estimatedBpm;
    var maxDelta = 0;
    for (final s in h.secondary) {
      final d = ((s.bpm ?? domBpm) - domBpm).abs();
      if (d > maxDelta) maxDelta = d;
    }
    final tempoDirective = switch (h.tempoStrategy) {
      'dominant_lock' =>
        'TEMPO_STRATEGY=dominant_lock — lock to $domBpm BPM; secondary rhythmic texture adapts.',
      'midpoint' => () {
        final secBpm = h.secondary.isNotEmpty
            ? (h.secondary.first.bpm ?? domBpm)
            : domBpm;
        final mid = ((domBpm + secBpm) / 2).round();
        return 'TEMPO_STRATEGY=midpoint — use ~$mid BPM (primary $domBpm, secondary $secBpm).';
      }(),
      _ =>
        'TEMPO_STRATEGY=dual_section — BPM gap $maxDelta (>20); use distinct tempo sections per genre.',
    };
    return '''
HYBRID MULTI-GENRE DISPATCH:
- DOMINANT: ${h.dominant.genre} @ ${domBpm}BPM — owns structure.
- SECONDARY: $sec — texture/vocabulary in Intro/Verse 1/Breakdown only.
- $tempoDirective
- structure_strategy=${h.structureStrategy}
- Single subordinate accent in Intro OR Verse 1; sidechain/filter at Drop/Chorus.''';
  }

  static String _pidginOverlay(String v) {
    switch (v) {
      case 'ibibio':
        return '$ibibioVocabularyBlock\n'
            'PIDGIN SUB-VARIANT: Ibibio/Calabar — triplet-feel, open vowel phrasing, '
            'Abasi gospel anchor when worship-toned. BANNED Lagos markers: wahala, abeg, na wa o, sef, oya.';
      case 'igbo':
        return 'PIDGIN SUB-VARIANT: Igbo — tonal percussive, una/nnam/kedu/gini vocabulary.';
      case 'rivers_state':
        return 'PIDGIN SUB-VARIANT: Rivers/Harbour — hard consonants, yu/de/wi pronouns, clipped delivery.';
      default:
        return 'PIDGIN SUB-VARIANT: Lagos Standard — wahala/abeg/na so/oya vocabulary.';
    }
  }

  static String _eastAsianOverlay(String v) {
    return 'EAST ASIAN SUB-VARIANT: $v — use native structure + idiomatic language for performable lines.';
  }
}
