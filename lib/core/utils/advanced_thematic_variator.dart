// Advanced thematic variator — Python/Dart runtime guardrails for genre lanes.

import '../constants/big_room_fusion_progressive_vocal_lyric_engine.dart';

const tokenBlacklist = [
  'neon',
  'cyber',
  'dancefloor',
  'coffee',
  'dashboard',
  'taillights',
  'phone screen',
  'taillight',
  'melancholy drive',
  'car ride',
  'highway tears',
  'club night',
  'hands up',
  'put your hands up',
];

const tactileAnchorTokens = [
  'chrome',
  'monochrome',
  'receipts',
  'poker face',
  'concrete',
  'fluorescent',
  'turnstile',
  'linoleum',
  'elevator mirror',
  'subway tile',
  'glass partition',
  'stainless steel',
];

const _songwritingArchetypes = {
  'psychological_subtext': (
    'Psychological Subtext',
    'Write beneath the surface: unspoken tension, withheld confession, '
        'body-language cues over exposition. One concrete object carries the emotional weight.',
  ),
  'architectural_realism': (
    'Architectural Realism',
    'Ground every image in built space: corridors, loading bays, service elevators, '
        'receipt printers, security glass. Industrial realism — no fantasy gloss.',
  ),
  'late_night_realist': (
    'Late Night Realist',
    'After-midnight pragmatism: fluorescent hum, empty lobbies, last trains, '
        'vending-machine light. Emotion through routine detail, not melodrama.',
  ),
};

const _futureHouseLanes = [
  'future house',
  'future-house',
  'future_house',
  'bass house',
  'uk house',
];

const _hardstyleLanes = [
  'hardstyle',
  'rawstyle',
  'euphoric hardstyle',
  'hard bounce',
  'edm bounce',
];

const _amapianoLanes = [
  'amapiano',
  'private school amapiano',
  'private school',
  'yanos',
  'piano amapiano',
  'organic amapiano',
  'afro house',
  'amapiano-vinahouse',
];

const _amapianoArchetypes = {
  'spatial_late_night': (
    'Spatial Late-Night Imagery',
    'Contemporary urban night scenes — veranda breeze, okada at the corner, plastic chair on the step, '
        'gold rings, late shifts. Emotion through spatial detail, not melodrama.',
  ),
  'log_drum_build': (
    'Log Drum Build Authority',
    'Rhythmic spacious repetition through intro and verse; reserve density for '
        'percussion breakdown and [Drop: Heavy Rolling Log Drum] chant triggers.',
  ),
  'private_school_groove': (
    'Private School Groove',
    'Atmospheric Rhodes/shaker intros, intimate close-mic English delivery, '
        'soulful chorus stacks, jazzy bridge isolation before the drop.',
  ),
};

const _amapianoPopClicheBan = [
  'vows',
  'committing sin',
  'forever and always',
  'meant to be',
  'she was nineteen',
  'i was seventeen',
  'she was seventeen',
];

String _genreBlob(String primary, String fusion) =>
    '${primary.trim()} ${fusion.trim()}'.toLowerCase();

bool isFutureHouseLane(String primary, [String fusion = '']) {
  final blob = _genreBlob(primary, fusion);
  return _futureHouseLanes.any(blob.contains);
}

bool isHardstyleLaneForVariator(String primary, [String fusion = '']) {
  final blob = _genreBlob(primary, fusion);
  return _hardstyleLanes.any(blob.contains);
}

String selectArchetype([String seed = '']) {
  final keys = _songwritingArchetypes.keys.toList();
  final s = seed.trim().toLowerCase();
  var hash = 0;
  for (final codeUnit in s.codeUnits) {
    hash = (hash * 31 + codeUnit) & 0xFFFFFFFF;
  }
  return keys[hash % keys.length];
}

bool isAmapianoLaneForVariator(String primary, [String fusion = '']) {
  final blob = _genreBlob(primary, fusion);
  return _amapianoLanes.any(blob.contains);
}

String selectAmapianoArchetype([String seed = '']) {
  final keys = _amapianoArchetypes.keys.toList();
  final s = seed.trim().toLowerCase();
  var hash = 0;
  for (final codeUnit in s.codeUnits) {
    hash = (hash * 31 + codeUnit) & 0xFFFFFFFF;
  }
  return keys[hash % keys.length];
}

String? resolveThematicProfile(String primary, [String fusion = '']) {
  if (isHardstyleLaneForVariator(primary, fusion)) return 'hardstyle';
  if (isAmapianoLaneForVariator(primary, fusion)) return 'amapiano';
  if (BigRoomFusionProgressiveVocalLyricEngine.isBigRoomFusionLane(
    primaryGenre: primary,
    subGenreFusion: fusion,
  )) {
    return 'big_room_fusion';
  }
  if (isFutureHouseLane(primary, fusion)) return 'future_house';
  return null;
}

String buildThematicGuardrails(
  String profile, {
  String primary = '',
  String fusion = '',
  String vibe = '',
}) {
  if (profile == 'big_room_fusion' ||
      BigRoomFusionProgressiveVocalLyricEngine.isBigRoomFusionLane(
        primaryGenre: primary,
        subGenreFusion: fusion,
      )) {
    return '''
ADVANCED THEMATIC GUARDRAILS — BIG ROOM FUSION / PROGRESSIVE HOUSE (runtime constraint):
1. VERSE: internal conversational realism — short blunt lines, intimate psychological state; no forced scene/time backdrops unless user supplied.
2. BUILD: ascending repetitive hook fragments and vowel extension — chop-ready cells, not travelogue narration.
3. PRE-DROP: ONE sharp 2–5 syllable command or emotionally heavy phrase before supersaw impact.
4. DROP: anthem mantra/chop loops only — no flowing narrative sentences.
5. BAN DJ-callout filler (${tokenBlacklist.where((t) => t.contains('hands')).join(', ')}, feel the beat, we're going higher, infinite skies) and sci-fi/rave metaphors.''';
  }

  if (profile == 'future_house' || isFutureHouseLane(primary, fusion)) {
    final archetype = selectArchetype('$primary|$fusion|$vibe');
    final arch = _songwritingArchetypes[archetype]!;
    final anchors = tactileAnchorTokens.take(4).join(', ');
    return '''
ADVANCED THEMATIC GUARDRAILS — FUTURE HOUSE (runtime constraint):
1. BLACKLIST (zero tolerance): ${tokenBlacklist.join(', ')}.
2. BAN generic AI buzzwords, car-melancholy loops, and club-hands-up filler.
3. ARCHETYPE (mandatory): ${arch.$1} — ${arch.$2}
4. TACTILE TOKENS: weave at least two of: $anchors (plus chrome, monochrome, receipts, poker face).
5. STYLE: high-tier pop-house songwriting — industrial realism, punchy pre-drop cues, controlled delivery.''';
  }

  if (profile == 'hardstyle' || isHardstyleLaneForVariator(primary, fusion)) {
    return '''
ADVANCED THEMATIC GUARDRAILS — HARDSTYLE (runtime constraint):
1. DYNAMIC SHIFT: [Breakdown] = vulnerable spoken confession; [Build-up] = cold defiant survival/determination.
2. PRE-DROP: ONE yelled/screamed command word only (e.g. BREATHE, NEVER, GO) — allowed here even if delivery elsewhere is controlled.
3. BAN melodramatic clichés: we own the night, ghosts pulling near, strobe light flash, destroy the grid, hollows out my chest cavity.
4. BAN sci-fi/rave metaphors and forced scene/time backdrops.
5. Drop sections: chop/mantra cells only — no flowing poetic sentences.''';
  }

  if (profile == 'amapiano' || isAmapianoLaneForVariator(primary, fusion)) {
    final archetype = selectAmapianoArchetype('$primary|$fusion|$vibe');
    final arch = _amapianoArchetypes[archetype]!;
    return '''
ADVANCED THEMATIC GUARDRAILS — AMAPIANO / PRIVATE SCHOOL (runtime constraint):
1. POP CLICHÉ BAN: ${_amapianoPopClicheBan.join(', ')}.
2. English-dominant canvas; cadence/structure from amapianoDataset.json only — never copy hooks.
3. ARCHETYPE (mandatory): ${arch.$1} — ${arch.$2}
4. LOG DRUM IS KING: soulful keys → [Percussion Breakdown] → [Drop: Heavy Rolling Log Drum].
5. Keep builds spacious and repetitive; do not overcrowd bars before the drop.
6. COMMERCIAL ORDER: Intro → V1 → Chorus → V2 → Chorus → Bridge → Breakdown → Drop → Final Chorus → Outro (Verse 2 BEFORE second Chorus).''';
  }

  return '';
}

String advancedThematicVariatorBlock({
  String primary = '',
  String fusion = '',
  String vibe = '',
}) {
  final profile = resolveThematicProfile(primary, fusion);
  if (profile == null) return '';
  return buildThematicGuardrails(
    profile,
    primary: primary,
    fusion: fusion,
    vibe: vibe,
  );
}
