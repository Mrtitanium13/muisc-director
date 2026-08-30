import 'audio_environment_data.dart';

/// Human Authenticity Engine — runtime user-block (full engine in system prompt).
abstract final class HumanAuthenticityConfig {
  HumanAuthenticityConfig._();

  // ────────────────────────── Genre taxonomy ──────────────────────────

  static const List<String> _electronicLanes = [
    'uplifting trance',
    'trance',
    'big room',
    'festival edm',
    'progressive trance',
    'melodic techno',
    'progressive house',
    'big room techno',
    'techno',
    'edm',
    'house',
    'future bass',
    'electro',
  ];

  static const List<String> _festivalVocalLanes = [
    ..._electronicLanes,
    'k-pop',
    'dance pop',
    'electropop',
  ];

  static const List<String> _gospelLanes = [
    'gospel',
    'worship',
    'praise and worship',
    'praise & worship',
    'praise',
    'ccm',
    'christian',
    'southern gospel',
    'afro-gospel',
    'afro-praise',
    'contemporary christian',
  ];

  /// §3B Level 1–2 — mantra / hook-dominant; §17 situation-first story is waived.
  static const List<String> _mantraDominantLanes = [
    'hard techno',
    'industrial techno',
    'minimal techno',
    'schranz',
    'peak-time techno',
    'peak time techno',
    'acid techno',
    'big room',
    'festival edm',
    'tech house',
    'mainstage',
    'hardstyle',
    'phonk',
    'neurofunk',
    'dubstep',
  ];

  /// §3B Level 3–4 — full situation-first story lyrics (§17).
  static const List<String> _storyDominantLanes = [
    'hip hop',
    'hiphop',
    'boom bap',
    'lo-fi hip hop',
    'jazz rap',
    'trap',
    'drill',
    'country',
    'folk',
    'americana',
    'singer-songwriter',
    'singer songwriter',
    'indie folk',
    'outlaw country',
    'modern country',
    'bluegrass',
    'alt country',
    'afrobeat',
    'afrobeats',
    'afro-house',
    'afro house',
    'amapiano',
    'dancehall',
    'reggaeton',
    'commercial pop',
    'mainstream pop',
    'latin pop',
    'r&b',
    'rnb',
    'neo-soul',
    'neo soul',
    'soul',
    'contemporary r&b',
    'bedroom pop',
    'indie pop',
  ];

  /// Partial §17 — intimate breakdown/bridge storytelling; chorus stays hook-first.
  static const List<String> _partialStoryLanes = [
    'progressive house',
    'melodic techno',
    'melodic house',
    'uplifting trance',
    'progressive trance',
    'festival edm',
  ];

  // ─────────────────────── Genre matching engine ──────────────────────

  /// Normalizes primary + fusion into a single lower-case phrase where
  /// hyphens and slashes become spaces so "singer-songwriter" matches
  /// "singer songwriter".
  static String _genreBlob(String primary, String fusion) {
    final raw = '${primary.trim()} ${fusion.trim()}'.toLowerCase();
    return raw
        .replaceAll(RegExp(r'[-/]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  /// Same hyphen/slash fold as [_genreBlob] so needles stay aligned with the blob.
  static String _normalizeNeedle(String needle) => needle
      .toLowerCase()
      .replaceAll(RegExp(r'[-/]+'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  static final Map<String, RegExp> _needlePatterns = {};

  static RegExp _patternFor(String needle) {
    final key = _normalizeNeedle(needle);
    return _needlePatterns.putIfAbsent(
      key,
      () => RegExp(r'\b' + RegExp.escape(key) + r'\b'),
    );
  }

  static bool _matchesAny(String blob, List<String> needles) =>
      needles.any((needle) => _patternFor(needle).hasMatch(blob));

  static bool isElectronicLane(String primary, String fusion) =>
      _matchesAny(_genreBlob(primary, fusion), _electronicLanes);

  static bool isMantraDominantLane(String primary, String fusion) =>
      _matchesAny(_genreBlob(primary, fusion), _mantraDominantLanes);

  static bool isFestivalVocalLane(String primary, String fusion) =>
      _matchesAny(_genreBlob(primary, fusion), _festivalVocalLanes);

  static bool isGospelLane(String primary, String fusion) =>
      _matchesAny(_genreBlob(primary, fusion), _gospelLanes);

  /// Full §17 situation-first story format (Level 3–4 lyric lanes).
  static bool isSituationFirstStoryLane(String primary, String fusion) {
    if (isMantraDominantLane(primary, fusion)) return false;
    final blob = _genreBlob(primary, fusion);
    return _matchesAny(blob, _storyDominantLanes) || isGospelLane(primary, fusion);
  }

  /// Breakdown/bridge situation triggers only (§17 partial).
  static bool isPartialSituationStoryLane(String primary, String fusion) {
    if (isMantraDominantLane(primary, fusion)) return false;
    if (isSituationFirstStoryLane(primary, fusion)) return false;
    return _matchesAny(_genreBlob(primary, fusion), _partialStoryLanes);
  }

  // ─────────────────────────── Directive builder ──────────────────────

  static String userBlockDirective({
    String primaryGenre = '',
    String subGenreFusion = '',
    bool djOutro = false,
    String audioEnvironmentModeId = AudioEnvironmentData.studioIsolatedId,
  }) {
    final lines = [
      'HUMAN AUTHENTICITY ENGINE (Block 2 + polish — mandatory):',
      '- Replace generic emotion with concrete images invented for THIS song — never kettle/receipt/bleach/"3 AM on cold tile" stock kits.',
      '- Specificity pass: rewrite interchangeable lines (holding on, broken heart, lost in the dark).',
      '- Chorus: one hook + one emotional line; repeatable; no verbatim verse phrases.',
      '- NEVER output artist/producer/song names — translate to sonic character only.',
      '- Final internal QA: human authenticity, chorus memory, genre fit, Suno caps, zero names.',
    ];

    if (isMantraDominantLane(primaryGenre, subGenreFusion)) {
      lines.add(
        '- §17 WAIVED (mantra/hook-dominant lane): no verse situation arcs — '
        'repetition, commands, physical sensation per §3A Level 1–2 only.',
      );
    } else if (isSituationFirstStoryLane(primaryGenre, subGenreFusion)) {
      lines.add(
        '- §17 SITUATION-FIRST STORY (active): build verses from observable events '
        'and lived situations before naming emotions; Life-Moment Test before finalize.',
      );
    } else if (isPartialSituationStoryLane(primaryGenre, subGenreFusion)) {
      lines.add(
        '- §17 PARTIAL (progressive/melodic lane): situation triggers in breakdown/bridge '
        'only — chorus stays hook-first; no full verse story arcs.',
      );
    }

    if (isGospelLane(primaryGenre, subGenreFusion)) {
      _addGospelLines(lines, audioEnvironmentModeId, djOutro);
    } else if (isFestivalVocalLane(primaryGenre, subGenreFusion)) {
      lines.add(
        '- Festival/melodic electronic: simple singable choruses; breakdown = intimate '
        '(whispered/double-track optional); hook repetition OK.',
      );
      lines.add(
        '- Melodic impact allowed in Block 1: chorus lift, octave jump, sustained peak note.',
      );
      lines.add(
        '- Electronic: breakdown intimacy vs drop energy; optional whispered/stripped breakdown vocals.',
      );
    } else if (isElectronicLane(primaryGenre, subGenreFusion)) {
      lines.add(
        '- Electronic: breakdown intimacy vs drop energy; optional whispered/stripped breakdown vocals.',
      );
    }

    if (!isGospelLane(primaryGenre, subGenreFusion) &&
        (djOutro || isElectronicLane(primaryGenre, subGenreFusion))) {
      lines.add(
        '- DJ-friendly: 16-bar outro, loopable groove, filtered mix-out, delay tails when outro flag or club lane.',
      );
    }

    lines.add(
      '- Block 1 near word cap: compress phrasing (shorthand bars/gear) without losing arrangement intent.',
    );

    return lines.join('\n');
  }

  static void _addGospelLines(
    List<String> lines,
    String audioEnvironmentModeId,
    bool djOutro,
  ) {
    lines.add(
      '- Critical Reconciliation Rule (final cleanse): no stacked acoustic+EDM tags; '
      'purge sidechain pump, drum loop, 16-bar DJ, mix-out groove from all brackets.',
    );
    lines.add(
      '- Traditional Gospel Architecture: ban EDM/club staging in brackets '
      '(sidechain pump, filter sweep, DJ mix-out, supersaw, loop grids).',
    );

    final isLive = AudioEnvironmentData.isLivePerformance(audioEnvironmentModeId);

    if (isLive) {
      lines.add(
        '- Live Performance Arena Mode: Intro = stadium crowd ambience, thunderous '
        'cheering, large outdoor stage reverb; Chorus = crowd singing along loudly; '
        'Bridge = audience handclaps; Outro = standing ovation and long applause.',
      );
    } else {
      lines.add(
        '- Studio-Isolation Directive: Intro/early tags ban Congregational, Live, '
        'Church, Sanctuary, Communal, SATB Choir Stack; mandate dead-room isolation '
        'and close-mic vocal tracking.',
      );
      lines.add(
        '- Use studio-clean worship tokens: Isolated multi-tracked vocal doubles, Tight '
        'Double-Tracked Vocal Stacks, Hammond B3 swell, Analog VCA glue, trailing '
        'organ decay — never crowd/congregation ambience.',
      );
    }

    if (djOutro) {
      if (isLive) {
        lines.add(
          '- Outro: sustained live band resolution, loud crowd screaming, '
          'standing ovation, natural stadium decay — never DJ mix-out groove.',
        );
      } else {
        lines.add(
          '- Outro: sustained studio band resolution, clean multi-track fade, '
          'trailing organ decay — never DJ mix-out groove.',
        );
      }
    }
  }
}
