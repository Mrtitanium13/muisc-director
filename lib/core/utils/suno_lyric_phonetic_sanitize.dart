/// Post-process Suno output — phonetic apostrophes + instrumental staging leaks.

import '../constants/audio_environment_data.dart';
import 'suno_lyrics_audio_normalizer.dart';

const _verbPrefixes = [
  'features ',
  'feature ',
  'featured ',
  'playing a ',
  'playing ',
  'play a ',
  'play ',
  'letting the ',
  'let the ',
  'let ',
  'adding ',
  'add ',
  'introducing ',
  'introduce ',
];

String _stripVerbLead(String token) {
  var t = token.trim();
  while (t.isNotEmpty) {
    final lower = t.toLowerCase();
    var stripped = false;
    for (final prefix in _verbPrefixes) {
      if (lower.startsWith(prefix)) {
        t = t.substring(prefix.length).trimLeft();
        stripped = true;
        break;
      }
    }
    if (!stripped) break;
  }
  return t;
}

String _cleanInstrumentalBody(String body) {
  return body
      .split(',')
      .map(_stripVerbLead)
      .where((p) => p.isNotEmpty)
      .join(', ');
}

final _instrumentalBracket = RegExp(
  r'\[(Instrumental(?:\s+Break)?|Instrumental Interlude|Log Drum Break):\s*([^\]]+)\]',
  caseSensitive: false,
);

/// Strip verb-phrase leaks from instrumental-only staging brackets.
String sanitizeInstrumentalStagingTags(String text) {
  return text.replaceAllMapped(_instrumentalBracket, (m) {
    final label = m.group(1)!;
    final body = _cleanInstrumentalBody(m.group(2)!);
    return body.isEmpty ? '[$label]' : '[$label: $body]';
  });
}

final _gospelLane = RegExp(
  r'gospel|worship|praise(?:\s*(?:&|and)\s*worship)?|ccm|christian|southern\s+gospel|afro[- ]?gospel|afro[- ]?praise|contemporary\s+christian',
  caseSensitive: false,
);

final _gospelStagingReplacements = <(RegExp, String)>[
  (RegExp(r'\bsidechain\s+pump\b', caseSensitive: false),
      'Analog VCA glue, warm dynamic leveling'),
  (RegExp(r'\bheavier\s+sidechain\b', caseSensitive: false),
      'heavier sustained strings, warm dynamic leveling'),
  (RegExp(r'\bsidechain\s+slam\b', caseSensitive: false),
      'warm dynamic leveling, analog console glue'),
  (RegExp(r'\bsidechain\b', caseSensitive: false), 'warm dynamic leveling'),
  (RegExp(r'\bdj\s+intro\b', caseSensitive: false),
      'Dead-room isolation, pristine studio environment, close-mic vocal tracking'),
  (RegExp(r'\bdj\s+outro\b', caseSensitive: false),
      'Sustained studio band resolution, clean multi-track fade, trailing organ decay'),
  (RegExp(r'\bmix-out\s+groove\b', caseSensitive: false),
      'Sustained studio band resolution, clean multi-track fade, trailing organ decay'),
  (RegExp(r'\bfull\s+satb\s+choir\s+stack\b', caseSensitive: false),
      'Isolated multi-tracked vocal doubles, Tight double-tracked vocal stacks'),
  (RegExp(r'\bauthentic\s+congregational\s+width\b', caseSensitive: false),
      'Multi-tracked vocal overlays, Isolated multi-tracked vocal doubles'),
  (RegExp(r'\bcongregational\s+trailing\s+ad-libs\b', caseSensitive: false),
      'clean multi-track fade'),
  (RegExp(r'\blive\s+band\s+count-in\b', caseSensitive: false),
      'Dead-room isolation, close-mic vocal tracking'),
  (RegExp(r'\bfilter\s+sweep\b', caseSensitive: false), 'natural room decay'),
  (RegExp(r'\blow-pass\s+sweep\b', caseSensitive: false), 'warm dynamic dip'),
  (RegExp(r'\bsupersaw\b', caseSensitive: false), 'lush sustained live strings'),
];

bool _isGospelLane(String primary, String fusion) {
  final blob = '${primary.trim()} ${fusion.trim()}'.trim();
  if (blob.isEmpty) return false;
  return _gospelLane.hasMatch(blob);
}

String _sanitizeGospelBracketInner(String inner) {
  var out = inner;
  for (final (pattern, replacement) in _gospelStagingReplacements) {
    out = out.replaceAll(pattern, replacement);
  }
  return out;
}

final _sectionMark = RegExp(
  r'^\[(Intro|Verse\s*\d+|Chorus|Final\s+Chorus|Bridge|Outro|Pre-Chorus|Drop|Build)\]\s*$',
  caseSensitive: false,
);
final _sectionHeader = RegExp(r'^\[[^\]]+\]\s*$', multiLine: true);

final _studioVocalReplacements = <(RegExp, String)>[
  (RegExp(r'\bstudio\s+harmonic\s+overlays\b', caseSensitive: false),
      'Wider multi-tracked studio harmonies'),
  (RegExp(r'\bstudio\s+harmonic\s+backing\b', caseSensitive: false),
      'Isolated multi-tracked vocal doubles'),
  (RegExp(r'\bharmonic\s+overlays\b', caseSensitive: false),
      'Wider multi-tracked studio harmonies'),
  (RegExp(r'\bharmonic\s+backing\b', caseSensitive: false),
      'Isolated multi-tracked vocal doubles'),
];

final _introCrowdBans = <(RegExp, String)>[
  (RegExp(r'\bcongregational\b', caseSensitive: false),
      'Isolated multi-tracked vocal doubles'),
  (RegExp(r'\bsanctuary\b', caseSensitive: false), 'Pristine studio environment'),
  (RegExp(r'\bcommunal\b', caseSensitive: false), 'Multi-tracked vocal overlays'),
  (RegExp(r'\bchurch\b', caseSensitive: false), 'Warm studio room'),
  (RegExp(r'\bchoir\b', caseSensitive: false), 'Isolated multi-tracked vocal doubles'),
  (RegExp(r'\bcongregation\b', caseSensitive: false),
      'Tight double-tracked vocal stacks'),
  (RegExp(r'\bsatb\b', caseSensitive: false), 'Isolated multi-tracked vocal doubles'),
  (RegExp(r'\blive\b', caseSensitive: false), 'Studio'),
];

final _tapeNoiseBans = <(RegExp, String)>[
  (RegExp(r'\bsubtle\s+tape\s+hiss\b', caseSensitive: false), 'focused studio room'),
  (RegExp(r'\btape\s+hiss\b', caseSensitive: false), 'dry acoustic room'),
  (RegExp(r'\bvinyl\s+crackle\b', caseSensitive: false),
      'sparse fingerpicked acoustic guitar'),
  (RegExp(r'\broom\s+noise\b', caseSensitive: false), 'dead-room silence'),
];

bool _isStagingBracket(String header) {
  if (header.contains(':')) return false;
  if (RegExp(
    r'^(Intro|Verse\s*\d+|Chorus|Final\s+Chorus|Bridge|Outro|Pre-Chorus|Drop|Build)\s*$',
    caseSensitive: false,
  ).hasMatch(header)) {
    return false;
  }
  return header.contains(',');
}

String _sanitizeStudioBracketInner(
  String inner, {
  required bool gospel,
  required bool early,
  required bool outro,
}) {
  var out = gospel ? _sanitizeGospelBracketInner(inner) : inner;
  for (final (pattern, replacement) in _studioVocalReplacements) {
    out = out.replaceAll(pattern, replacement);
  }
  if (early) {
    for (final (pattern, replacement) in _introCrowdBans) {
      out = out.replaceAll(pattern, replacement);
    }
  }
  if (early || outro) {
    for (final (pattern, replacement) in _tapeNoiseBans) {
      out = out.replaceAll(pattern, replacement);
    }
  }
  return out;
}

/// Strip crowd, harmonic-backing, and tape-noise triggers in studio-isolation mode.
String sanitizeStudioIsolationTags(
  String text, {
  String primaryGenre = '',
  String subGenreFusion = '',
  String audioEnvironmentModeId = '',
}) {
  if (AudioEnvironmentData.isLivePerformance(audioEnvironmentModeId)) return text;
  if (text.isEmpty) return text;

  final gospel = _isGospelLane(primaryGenre, subGenreFusion);
  final lines = text.split('\n');
  final outLines = <String>[];
  var currentSection = '';

  for (final line in lines) {
    final stripped = line.trim();
    final sectionMatch = _sectionMark.firstMatch(stripped);
    if (sectionMatch != null) {
      currentSection = sectionMatch.group(1)!;
      outLines.add(line);
      continue;
    }
    if (stripped.startsWith('[') && _sectionHeader.hasMatch(stripped)) {
      final header = stripped.substring(1, stripped.lastIndexOf(']'));
      if (_isStagingBracket(header)) {
        final early = RegExp(r'^(Intro|Verse\s*1)\s*$', caseSensitive: false)
            .hasMatch(currentSection);
        final outro =
            RegExp(r'^Outro\s*$', caseSensitive: false).hasMatch(currentSection);
        outLines.add(
          '[${_sanitizeStudioBracketInner(header, gospel: gospel, early: early, outro: outro)}]',
        );
        continue;
      }
    }
    outLines.add(line);
  }

  return outLines.join('\n');
}

final _electronicDominant = RegExp(
  r'techno|edm|house|trance|amapiano|trap|dnb|drum\s+and\s+bass|hardstyle|dubstep|electro|future\s+bass|melodic\s+techno',
  caseSensitive: false,
);

final _liveAcoustic = RegExp(
  r'gospel|worship|praise|folk|country|acoustic|americana|bluegrass|singer-songwriter|ccm|christian|southern\s+gospel',
  caseSensitive: false,
);

const _electronicLeakPhrases = [
  'sidechain pump',
  'sidechain slam',
  'sidechain',
  'drum loop',
  '16-bar dj',
  'dj intro',
  'dj outro',
  'mix-out groove',
  'mix out groove',
  'filter sweep',
  'low-pass sweep',
  'supersaw',
  'sub bloom',
  'hat rolls',
  '808 bloom',
  'riser',
];

final _acousticMarker = RegExp(
  r'acoustic|live drum|hammond|choir|satb|organic|folk|strings|piano|guitar|congregational',
  caseSensitive: false,
);

bool _fusionActive(String fusion) {
  final f = fusion.trim().toLowerCase();
  if (f.isEmpty) return false;
  return f != 'none' && f != 'n/a' && f != 'na' && f != '-' && f != '—';
}

bool _hybridSplitDnaActive(String primary, String fusion) {
  return _fusionActive(fusion) && _electronicDominant.hasMatch(primary);
}

bool _strictReconciliationLane(String primary, String fusion) {
  if (_hybridSplitDnaActive(primary, fusion)) return false;
  final blob = '${primary.trim()} ${fusion.trim()}'.trim();
  if (blob.isEmpty) return false;
  return _liveAcoustic.hasMatch(blob) || _isGospelLane(primary, fusion);
}

bool _tokenHasElectronicLeak(String token) {
  final low = token.toLowerCase();
  return _electronicLeakPhrases.any(low.contains);
}

String _reconcileBracketInner(
  String inner, {
  required bool strict,
  required bool hybrid,
  required bool gospel,
}) {
  final parts = inner.split(',').map((p) => p.trim()).where((p) => p.isNotEmpty);
  if (strict || gospel) {
    final innerWork = gospel ? _sanitizeGospelBracketInner(inner) : inner;
    final kept = innerWork
        .split(',')
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .where((p) => !_tokenHasElectronicLeak(p));
    return kept.join(', ');
  }
  if (hybrid && _acousticMarker.hasMatch(inner)) {
    final kept = parts.where((p) => !_tokenHasElectronicLeak(p));
    return kept.join(', ');
  }
  return inner;
}

/// SUNO V4 §3 Critical Reconciliation — strip EDM leaks from live/gospel staging.
String applyCriticalReconciliation(
  String text, {
  String primaryGenre = '',
  String subGenreFusion = '',
}) {
  if (text.isEmpty) return text;
  final strict = _strictReconciliationLane(primaryGenre, subGenreFusion);
  final hybrid = _hybridSplitDnaActive(primaryGenre, subGenreFusion);
  final gospel = _isGospelLane(primaryGenre, subGenreFusion);
  if (!strict && !hybrid) return text;

  return text.replaceAllMapped(RegExp(r'\[([^\]]+)\]'), (m) {
    final inner = _reconcileBracketInner(
      m.group(1)!,
      strict: strict,
      hybrid: hybrid,
      gospel: gospel,
    );
    return inner.isEmpty ? '[]' : '[$inner]';
  });
}

/// Swap club/EDM staging leaks for sanctuary tokens when genre is gospel/worship.
String sanitizeGospelStagingTags(
  String text, {
  String primaryGenre = '',
  String subGenreFusion = '',
}) {
  return applyCriticalReconciliation(
    text,
    primaryGenre: primaryGenre,
    subGenreFusion: subGenreFusion,
  );
}

/// Full V2 post-output hygiene (phonetics + instrumental + reconciliation).
String sanitizeSunoPostOutput(
  String text, {
  String primaryGenre = '',
  String subGenreFusion = '',
  String audioEnvironmentModeId = '',
}) {
  final phonetic = sanitizeSunoLyricPhonetics(text);
  final instrumental = sanitizeInstrumentalStagingTags(phonetic);
  final isolated = sanitizeStudioIsolationTags(
    instrumental,
    primaryGenre: primaryGenre,
    subGenreFusion: subGenreFusion,
    audioEnvironmentModeId: audioEnvironmentModeId,
  );
  final reconciled = applyCriticalReconciliation(
    isolated,
    primaryGenre: primaryGenre,
    subGenreFusion: subGenreFusion,
  );
  return applyAudioEngineNormalizationToSunoOutput(reconciled);
}

/// Strip trailing apostrophes that glitch Suno TTS.
String sanitizeSunoLyricPhonetics(String text) {
  if (text.isEmpty) return text;

  var out = text;
  const leading = <String, String>{
    "'round": 'around',
    "'bout": 'bout',
    "'cause": 'cause',
    "'em": 'em',
    "'til": 'til',
    '\u2019round': 'around',
    '\u2019bout': 'bout',
    '\u2019cause': 'cause',
    '\u2019em': 'em',
    '\u2019til': 'til',
  };
  for (final e in leading.entries) {
    out = out.replaceAll(e.key, e.value);
  }

  out = out.replaceAllMapped(
    RegExp(r"\b([A-Za-z]+)['\u2018\u2019](?![A-Za-z])"),
    (m) => m.group(1)!,
  );
  return out;
}
