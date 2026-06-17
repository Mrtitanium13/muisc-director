import 'audio_environment_data.dart';

/// Human Authenticity Engine — runtime user-block (full engine in system prompt).
class HumanAuthenticityConfig {
  HumanAuthenticityConfig._();

  static const _electronicLanes = [
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

  static const _festivalVocalLanes = [
    ..._electronicLanes,
    'k-pop',
    'dance pop',
    'electropop',
  ];

  static const _gospelLanes = [
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
  static const _mantraDominantLanes = [
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
  static const _storyDominantLanes = [
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
  static const _partialStoryLanes = [
    'progressive house',
    'melodic techno',
    'melodic house',
    'uplifting trance',
    'progressive trance',
    'festival edm',
  ];

  static bool _blobContainsAny(String blob, List<String> needles) =>
      needles.any(blob.contains);

  static String _genreBlob(String primary, String fusion) =>
      '${primary.trim()} ${fusion.trim()}'.toLowerCase();

  static bool isElectronicLane(String primary, String fusion) {
    final blob = _genreBlob(primary, fusion);
    return _blobContainsAny(blob, _electronicLanes);
  }

  static bool isMantraDominantLane(String primary, String fusion) {
    final blob = _genreBlob(primary, fusion);
    return _blobContainsAny(blob, _mantraDominantLanes);
  }

  static bool isFestivalVocalLane(String primary, String fusion) {
    final blob = _genreBlob(primary, fusion);
    return _blobContainsAny(blob, _festivalVocalLanes);
  }

  static bool isGospelLane(String primary, String fusion) {
    final blob = _genreBlob(primary, fusion);
    return _blobContainsAny(blob, _gospelLanes);
  }

  /// Full §17 situation-first story format (Level 3–4 lyric lanes).
  static bool isSituationFirstStoryLane(String primary, String fusion) {
    if (isMantraDominantLane(primary, fusion)) return false;
    final blob = _genreBlob(primary, fusion);
    return _blobContainsAny(blob, _storyDominantLanes) ||
        isGospelLane(primary, fusion);
  }

  /// Breakdown/bridge situation triggers only (§17 partial).
  static bool isPartialSituationStoryLane(String primary, String fusion) {
    if (isMantraDominantLane(primary, fusion)) return false;
    if (isSituationFirstStoryLane(primary, fusion)) return false;
    final blob = _genreBlob(primary, fusion);
    return _blobContainsAny(blob, _partialStoryLanes);
  }

  static String userBlockDirective({
    String primaryGenre = '',
    String subGenreFusion = '',
    bool djOutro = false,
    String audioEnvironmentModeId = AudioEnvironmentData.studioIsolatedId,
  }) {
    final lines = <String>[
      'HUMAN AUTHENTICITY ENGINE (Block 2 + polish — mandatory):',
      '- Replace generic emotion with concrete images (mug, kettle, keys, unread text).',
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
      lines.add(
        '- Critical Reconciliation Rule (final cleanse): no stacked acoustic+EDM tags; '
        'purge sidechain pump, drum loop, 16-bar DJ, mix-out groove from all brackets.',
      );
      lines.add(
        '- Traditional Gospel Architecture: ban EDM/club staging in brackets '
        '(sidechain pump, filter sweep, DJ mix-out, supersaw, loop grids).',
      );
      if (AudioEnvironmentData.isLivePerformance(audioEnvironmentModeId)) {
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
        if (AudioEnvironmentData.isLivePerformance(audioEnvironmentModeId)) {
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
    } else if (isFestivalVocalLane(primaryGenre, subGenreFusion)) {
      lines.add(
        '- Festival/melodic electronic: simple singable choruses; breakdown = intimate '
        '(whispered/double-track optional); hook repetition OK.',
      );
      lines.add(
        '- Melodic impact allowed in Block 1: chorus lift, octave jump, sustained peak note.',
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
}
