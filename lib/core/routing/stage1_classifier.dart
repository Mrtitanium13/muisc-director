import '../../data/models/user_input_model.dart';
import '../constants/dialect_style_data.dart';
import '../constants/vocal_accent_data.dart';
import '../utils/genre_hybridization_matrix.dart';
import 'music_prompt_routing.dart';

/// Stage 1 — heuristic classifier from app form fields (no extra LLM call).
class Stage1Classifier {
  Stage1Classifier._();

  static Stage1Classification classify(UserInputModel input, {String? textHint}) {
    final primary = input.primaryGenre.trim();
    final fusion = input.subGenreFusion.trim();
    final vibe = input.vibe.trim();
    final blob = '$primary $fusion $vibe ${textHint ?? ''}'.toLowerCase();
    final languages = _detectLanguages(input, blob);
    final bpm = _parseBpm(input.bpm) ?? _estimateBpm(blob);

    if (_isHybridCultural(input, blob, languages)) {
      return _buildClassification(
        routingKey: RoutingKeys.hybridCultural,
        isHybrid: true,
        primary: primary,
        fusion: fusion,
        bpm: bpm,
        languages: languages,
        mood: vibe.isEmpty ? 'neutral' : vibe,
        input: input,
      );
    }

    if (GenreHybridizationMatrix.fusionActive(fusion) ||
        _textSuggestsMultiFamilyHybrid(blob, primary, fusion)) {
      return _buildClassification(
        routingKey: RoutingKeys.hybridMultiGenre,
        isHybrid: true,
        primary: primary,
        fusion: fusion,
        bpm: bpm,
        languages: languages,
        mood: vibe.isEmpty ? 'neutral' : vibe,
        input: input,
      );
    }

    final pidgin = _resolvePidginSubVariant(input);
    if (pidgin != null ||
        DialectStyleData.isNigerianPidgin(input.dialectStyleId) ||
        _blobHasAny(blob, ['pidgin', 'wahala', 'abeg', 'dey go'])) {
      return _buildClassification(
        routingKey: RoutingKeys.genAfricanPidgin,
        isHybrid: false,
        primary: primary,
        fusion: fusion,
        bpm: bpm,
        languages: languages,
        mood: vibe.isEmpty ? 'neutral' : vibe,
        input: input,
        pidginSubVariant: pidgin ?? 'lagos_standard',
      );
    }

    if (_blobHasAny(blob, _eastAsianMarkers)) {
      return _buildClassification(
        routingKey: RoutingKeys.genEastAsian,
        isHybrid: false,
        primary: primary,
        fusion: fusion,
        bpm: bpm,
        languages: languages,
        mood: vibe.isEmpty ? 'neutral' : vibe,
        input: input,
        eastAsianSubVariant: _resolveEastAsianSubVariant(blob),
      );
    }

    if (_blobHasAny(blob, _latinMarkers)) {
      return _buildClassification(
        routingKey: RoutingKeys.genLatin,
        isHybrid: false,
        primary: primary,
        fusion: fusion,
        bpm: bpm,
        languages: languages,
        mood: vibe.isEmpty ? 'neutral' : vibe,
        input: input,
      );
    }

    if (_blobHasAny(blob, _europeanLingualMarkers)) {
      return _buildClassification(
        routingKey: RoutingKeys.genEuropeanLingual,
        isHybrid: false,
        primary: primary,
        fusion: fusion,
        bpm: bpm,
        languages: languages,
        mood: vibe.isEmpty ? 'neutral' : vibe,
        input: input,
      );
    }

    if (_blobHasAny(blob, _seaMarkers)) {
      return _buildClassification(
        routingKey: RoutingKeys.genSea,
        isHybrid: false,
        primary: primary,
        fusion: fusion,
        bpm: bpm,
        languages: languages,
        mood: vibe.isEmpty ? 'neutral' : vibe,
        input: input,
      );
    }

    if (_blobHasAny(blob, _middleEasternMarkers)) {
      return _buildClassification(
        routingKey: RoutingKeys.genMiddleEastern,
        isHybrid: false,
        primary: primary,
        fusion: fusion,
        bpm: bpm,
        languages: languages,
        mood: vibe.isEmpty ? 'neutral' : vibe,
        input: input,
      );
    }

    if (_blobHasAny(blob, _africanMainstreamMarkers)) {
      return _buildClassification(
        routingKey: RoutingKeys.genAfricanMainstream,
        isHybrid: false,
        primary: primary,
        fusion: fusion,
        bpm: bpm,
        languages: languages,
        mood: vibe.isEmpty ? 'neutral' : vibe,
        input: input,
      );
    }

    return _buildClassification(
      routingKey: RoutingKeys.genWesternPop,
      isHybrid: false,
      primary: primary,
      fusion: fusion,
      bpm: bpm,
      languages: languages,
      mood: vibe.isEmpty ? 'neutral' : vibe,
      input: input,
    );
  }

  static const _africanMainstreamMarkers = [
    'afrobeats',
    'afrobeat',
    'amapiano',
    'highlife',
    'gqom',
    'afropop',
    'afro house',
    'afro-house',
    'fuji',
  ];

  static const _eastAsianMarkers = [
    'k-pop',
    'kpop',
    'j-pop',
    'jpop',
    'c-pop',
    'cpop',
    'mandopop',
    'cantopop',
    'vinahouse',
    'v-pop',
    'vpop',
    'trot',
    'city pop',
    'bollywood',
    'bhangra',
  ];

  static const _latinMarkers = [
    'reggaeton',
    'bachata',
    'salsa',
    'cumbia',
    'bossa nova',
    'dembow',
    'latin pop',
    'sertanejo',
    'forró',
    'forro',
  ];

  static const _europeanLingualMarkers = [
    'french chanson',
    'chanson',
    'schlager',
    'italian pop',
    'german pop',
    'dutch pop',
    'nordic pop',
  ];

  static const _seaMarkers = [
    'thai pop',
    'dangdut',
    'indonesian',
    'filipino',
    'opm',
    'pinoy',
  ];

  static const _middleEasternMarkers = [
    'arabic pop',
    'turkish pop',
    'persian',
    'hebrew pop',
    'middle eastern',
  ];

  static bool _blobHasAny(String blob, List<String> needles) {
    for (final n in needles) {
      if (blob.contains(n)) return true;
    }
    return false;
  }

  static bool _isHybridCultural(
    UserInputModel input,
    String blob,
    List<String> languages,
  ) {
    if (_blobHasAny(blob, [
      'bilingual',
      'code-switch',
      'code switch',
      'english verse',
      'korean chorus',
      'spanish chorus',
      'spanglish',
      'english hook',
      'pidgin verse',
    ])) {
      return true;
    }
    final lang = input.language.toLowerCase();
    if (lang.contains('pidgin') && lang.contains('english')) return true;
    if (lang.contains('+') || lang.contains('&')) return true;
    // Two non-English lyric languages (not UI language + genre hint).
    final nonEnglish = languages
        .where((l) => l != 'english' && l != 'en' && l.isNotEmpty)
        .toList();
    if (nonEnglish.length >= 2) return true;
    return false;
  }

  static bool _textSuggestsMultiFamilyHybrid(
    String blob,
    String primary,
    String fusion,
  ) {
    if (primary.isEmpty || fusion.isEmpty) {
      return _blobHasAny(blob, [' hybrid', '+', ' crossover', ' x ']);
    }
    final pFamily = _genreFamily(primary);
    final fFamily = _genreFamily(fusion);
    return pFamily.isNotEmpty && fFamily.isNotEmpty && pFamily != fFamily;
  }

  static String _genreFamily(String genre) {
    final g = genre.toLowerCase();
    if (_blobHasAny(g, _africanMainstreamMarkers)) return 'african';
    if (_blobHasAny(g, _eastAsianMarkers)) return 'east_asian';
    if (_blobHasAny(g, _latinMarkers)) return 'latin';
    if (_blobHasAny(g, ['edm', 'house', 'techno', 'trance', 'dubstep'])) {
      return 'edm';
    }
    if (_blobHasAny(g, ['hip hop', 'hip-hop', 'trap', 'drill', 'boom bap'])) {
      return 'hiphop';
    }
    if (_blobHasAny(g, ['rock', 'metal', 'punk', 'emo'])) return 'rock';
    if (_blobHasAny(g, ['country', 'folk', 'americana'])) return 'country';
    if (_blobHasAny(g, ['gospel', 'worship', 'ccm'])) return 'gospel';
    if (_blobHasAny(g, ['pop', 'r&b', 'rnb', 'soul'])) return 'pop';
    return g;
  }

  static List<String> _detectLanguages(UserInputModel input, String blob) {
    final out = <String>{input.language.trim().toLowerCase()};
    if (_blobHasAny(blob, ['korean', 'k-pop', 'kpop'])) out.add('ko');
    if (_blobHasAny(blob, ['japanese', 'j-pop', 'jpop'])) out.add('ja');
    if (_blobHasAny(blob, ['mandarin', 'chinese', 'c-pop'])) out.add('zh');
    if (_blobHasAny(blob, ['vietnamese', 'vinahouse', 'v-pop'])) out.add('vi');
    if (_blobHasAny(blob, ['spanish', 'reggaeton', 'bachata'])) out.add('es');
    if (_blobHasAny(blob, ['portuguese', 'brazilian'])) out.add('pt');
    if (_blobHasAny(blob, ['french'])) out.add('fr');
    if (_blobHasAny(blob, ['arabic'])) out.add('ar');
    if (DialectStyleData.isNigerianPidgin(input.dialectStyleId)) {
      out.add('nigerian_pidgin');
    }
    out.removeWhere((e) => e.isEmpty);
    return out.toList();
  }

  static AfricanPidginSubVariant? _resolvePidginSubVariant(UserInputModel input) {
    final accent = VocalAccentData.coerceStored(input.vocalAccent ?? '');
    if (accent == 'nigerian_ibibio' || input.dialectVariantId == 'ibibio') {
      return 'ibibio';
    }
    if (accent == 'nigerian_igbo' || input.dialectVariantId == 'igbo') {
      return 'igbo';
    }
    if (accent == 'nigerian_rivers_state' ||
        input.dialectVariantId == 'rivers') {
      return 'rivers_state';
    }
    if (accent == 'nigerian' ||
        DialectStyleData.isNigerianPidgin(input.dialectStyleId)) {
      return 'lagos_standard';
    }
    return null;
  }

  static EastAsianSubVariant? _resolveEastAsianSubVariant(String blob) {
    if (blob.contains('mandopop') || blob.contains('c-pop')) return 'mandopop';
    if (blob.contains('j-pop') || blob.contains('jpop')) return 'jpop';
    if (blob.contains('k-pop') || blob.contains('kpop')) return 'kpop';
    if (blob.contains('cantopop')) return 'cantopop';
    if (blob.contains('vinahouse') || blob.contains('v-pop')) {
      return 'vpop_vinahouse';
    }
    if (blob.contains('trot')) return 'trot';
    return null;
  }

  static int? _parseBpm(String? raw) {
    final n = int.tryParse((raw ?? '').trim());
    if (n == null || n < 40 || n > 250) return null;
    return n;
  }

  static int _estimateBpm(String blob) {
    if (_blobHasAny(blob, ['hardstyle', 'drum and bass', 'dnb', 'gabber'])) {
      return 150;
    }
    if (_blobHasAny(blob, ['amapiano', 'afrobeats'])) return 112;
    if (_blobHasAny(blob, ['vinahouse', 'reggaeton'])) return 128;
    if (_blobHasAny(blob, ['house', 'techno', 'trance'])) return 128;
    if (_blobHasAny(blob, ['hip hop', 'trap', 'drill'])) return 140;
    return 100;
  }

  /// Per-genre BPM anchor for hybrid tempo_strategy gap computation.
  static int _estimateBpmForGenre(String genre) {
    final g = genre.trim().toLowerCase();
    if (g.isEmpty) return 100;
    if (_blobHasAny(g, ['hardstyle', 'drum and bass', 'dnb'])) return 150;
    if (g.contains('amapiano') || g.contains('afrobeat')) return 112;
    if (_blobHasAny(g, ['vinahouse', 'v-pop', 'vpop'])) return 140;
    if (_blobHasAny(g, ['house', 'techno', 'reggaeton', 'trance'])) return 128;
    if (_blobHasAny(g, ['hip hop', 'hip-hop', 'trap', 'drill'])) return 140;
    if (_blobHasAny(g, ['dubstep', 'garage', 'ukg'])) return 130;
    return 100;
  }

  static HybridResolution? _resolveHybrid(GenreSlot primary, List<GenreSlot> secondaries) {
    if (secondaries.isEmpty) return null;
    final primaryBpm = primary.bpm ?? 100;
    var maxDelta = 0;
    for (final s in secondaries) {
      final d = ((s.bpm ?? primaryBpm) - primaryBpm).abs();
      if (d > maxDelta) maxDelta = d;
    }
    final tempoStrategy = maxDelta <= 8
        ? 'dominant_lock'
        : maxDelta <= 20
            ? 'midpoint'
            : 'dual_section';
    final sum = primary.weight + secondaries.fold(0.0, (a, s) => a + s.weight);
    final structureStrategy =
        primary.weight / sum < 0.5 ? 'alternating_sections' : 'dominant_only';
    return HybridResolution(
      dominant: primary,
      secondary: secondaries,
      tempoStrategy: tempoStrategy,
      structureStrategy: structureStrategy,
      vocabularyMerge: 'blended',
    );
  }

  static Stage1Classification _buildClassification({
    required RoutingKey routingKey,
    required bool isHybrid,
    required String primary,
    required String fusion,
    required int bpm,
    required List<String> languages,
    required String mood,
    required UserInputModel input,
    AfricanPidginSubVariant? pidginSubVariant,
    EastAsianSubVariant? eastAsianSubVariant,
  }) {
    final userBpm = _parseBpm(input.bpm);
    final primaryBpm =
        userBpm ?? _estimateBpmForGenre(primary.isEmpty ? 'Pop' : primary);
    final primarySlot = GenreSlot(
      genre: primary.isEmpty ? 'Pop' : primary,
      weight: isHybrid ? 0.6 : 1.0,
      bpm: primaryBpm,
      key: input.keyRoot,
      mood: mood,
      language: languages.isNotEmpty ? languages.first : input.language,
    );
    final secondarySlots = <GenreSlot>[];
    if (GenreHybridizationMatrix.fusionActive(fusion)) {
      secondarySlots.add(
        GenreSlot(
          genre: fusion,
          weight: 0.4,
          bpm: userBpm ?? _estimateBpmForGenre(fusion),
          language: languages.length > 1 ? languages[1] : input.language,
        ),
      );
    }
    return Stage1Classification(
      routingKey: routingKey,
      isHybrid: isHybrid,
      primarySlot: primarySlot,
      secondarySlots: secondarySlots,
      dominantMood: mood,
      estimatedBpm: userBpm ?? primaryBpm,
      dominantLanguage: languages.isNotEmpty ? languages.first : input.language,
      languagesDetected: languages,
      hybridResolution: isHybrid
          ? _resolveHybrid(primarySlot, secondarySlots)
          : null,
      pidginSubVariant: pidginSubVariant,
      eastAsianSubVariant: eastAsianSubVariant,
      structuralTemplateHint: _structuralHint(routingKey, primary),
    );
  }

  static String? _structuralHint(RoutingKey key, String primary) {
    final g = primary.toLowerCase();
    if (key == RoutingKeys.hybridMultiGenre) return 'hybrid_merged';
    if (g.contains('amapiano')) return 'amapiano_log';
    if (g.contains('gospel') || g.contains('worship')) return 'gospel_worship';
    if (g.contains('edm') || g.contains('house')) return 'edm_drop';
    if (g.contains('hip hop') || g.contains('trap')) return 'hiphop';
    return 'pop';
  }
}
