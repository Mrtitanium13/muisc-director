import '../constants/genre_data.dart';
import '../constants/dialect_style_data.dart';
import '../constants/hitmaker_max_martin_directives.dart';
import 'duration_format.dart';
import '../../data/models/suno_field_output_mode.dart';
import '../../data/models/track_duration_config.dart';
import '../../data/models/user_input_model.dart';

/// Map a single free-text blob into [UserInputModel] fields using heuristics only (no LLM).
/// Full raw text is kept in [UserInputModel.vibe] for context. Merge onto an existing model
/// (e.g. [promptFormProvider]) to preserve Suno version, structure preset, and other fields.
class QuickDescribeMapResult {
  const QuickDescribeMapResult({
    required this.merged,
    required this.appliedHints,
  });

  final UserInputModel merged;
  final List<String> appliedHints;
}

const _powerCodes = {
  '/BEASTMODE',
  '/L99',
  '/UDA',
  '/WRITEIT',
};

const _temperamentCodes = {
  '/GRIT',
  '/TENDER',
  '/FURY',
  '/HAZE',
  '/SWAGGER',
  '/HYMN',
  '/WIRED',
};

/// Returns [base] with extracted BPM, genre, key, codes, and instrumental intent applied.
QuickDescribeMapResult mapQuickDescribeToUserInput(
  String raw,
  UserInputModel base,
) {
  final hints = <String>[];
  final text = raw.trim();
  if (text.isEmpty) {
    return QuickDescribeMapResult(merged: base, appliedHints: hints);
  }

  String? bpm;
  final bpmTail = RegExp(
    r'(?:^|[\s,])(\d{2,3})\s*bpm\b',
    caseSensitive: false,
  ).firstMatch(text);
  if (bpmTail != null) {
    bpm = bpmTail.group(1);
  }
  if (bpm == null) {
    final bpmPrefix = RegExp(
      r'\bbpm\s*[:=]?\s*(\d{2,3})\b',
      caseSensitive: false,
    ).firstMatch(text);
    if (bpmPrefix != null) bpm = bpmPrefix.group(1);
  }
  if (bpm != null) hints.add('BPM $bpm');

  final lower = text.toLowerCase();
  final subgenres = <String>[];
  for (final list in GenreData.subGenresByCategory.values) {
    subgenres.addAll(list);
  }
  subgenres.sort((a, b) => b.length.compareTo(a.length));
  String? genre;
  for (final g in subgenres) {
    if (_phraseAtWordBoundary(lower, g.toLowerCase())) {
      genre = g;
      hints.add('Genre $genre');
      break;
    }
  }

  if (lower.contains('max martin') ||
      RegExp(r'\b(hitmaker|melodic math)\b').hasMatch(lower)) {
    genre = hitmakerMaxMartinGenreLabel;
    hints.add('Hitmaker / Melodic Math lane');
  }

  SunoFieldOutputMode fieldMode = base.sunoFieldOutputMode;
  if (RegExp(
    r'\bsimple\s+field\b|\bsimple\s+mode\b|\bsuno\s+simple\b|\bdescription\s+only\b',
    caseSensitive: false,
  ).hasMatch(text)) {
    fieldMode = SunoFieldOutputMode.simple;
    hints.add('Simple field mode');
  }

  TrackDuration trackDur = base.trackDuration;
  String? trackLabel = base.trackDurationLabel;
  for (final m in RegExp(r'\b(\d{1,2}:\d{2})\b').allMatches(text)) {
    final g = m.group(1);
    if (g == null) continue;
    final p = parseFlexibleDurationMinutes(g);
    if (p != null && p > 0 && p <= 45) {
      trackDur = TrackDuration.custom;
      trackLabel = formatMinutesToMmSs(p);
      hints.add('Target length $trackLabel');
      break;
    }
  }

  final foundTokens = _extractKnownCodes(text);
  var generateLyrics = base.generateLyrics;
  final powerFound = <String>[];
  final temperFound = <String>[];
  for (final t in foundTokens) {
    final u = t.toUpperCase();
    if (u == '/WRITEIT') {
      generateLyrics = true;
      hints.add('/WRITEIT → generate lyrics');
      continue;
    }
    if (_powerCodes.contains(u)) {
      powerFound.add(u);
    } else if (_temperamentCodes.contains(u)) {
      temperFound.add(u);
    }
  }
  if (powerFound.isNotEmpty) {
    hints.add('Power: ${powerFound.join(' ')}');
  }
  if (temperFound.isNotEmpty) {
    hints.add('Temperament: ${temperFound.join(' ')}');
  }

  var lyricTemperamentCodes = _mergeCodeTokens(
    base.lyricTemperamentCodes,
    temperFound,
  );

  var vibe = text;
  final extraPower = powerFound.join(' ');
  if (extraPower.isNotEmpty) {
    vibe = '$vibe $extraPower'.trim();
  }

  var vocalSpec = base.vocalSpec;
  String? vocalAccent = base.vocalAccent;
  var dialectStyleId = base.dialectStyleId;
  var dialectVariantId = base.dialectVariantId;
  if (RegExp(
    r'\bnigerian\s+pidgin\b|\bpidgin\s+english\b|\bwrite\s+in\s+pidgin\b',
    caseSensitive: false,
  ).hasMatch(text)) {
    dialectStyleId = DialectStyleData.nigerianPidginId;
    hints.add('Nigerian Pidgin dialect');
  }
  if (RegExp(r'\bibibio\b', caseSensitive: false).hasMatch(text)) {
    dialectStyleId = DialectStyleData.nigerianPidginId;
    dialectVariantId = 'ibibio';
    hints.add('Ibibio-inflected Pidgin');
  } else if (RegExp(r'\befik\b', caseSensitive: false).hasMatch(text)) {
    dialectStyleId = DialectStyleData.nigerianPidginId;
    dialectVariantId = 'efik';
    hints.add('Efik-inflected Pidgin');
  } else if (RegExp(r'\byoruba\b', caseSensitive: false).hasMatch(text)) {
    dialectStyleId = DialectStyleData.nigerianPidginId;
    dialectVariantId = 'yoruba';
    hints.add('Yoruba-inflected Pidgin');
  } else if (RegExp(r'\bigbo\b', caseSensitive: false).hasMatch(text)) {
    dialectStyleId = DialectStyleData.nigerianPidginId;
    dialectVariantId = 'igbo';
    hints.add('Igbo-inflected Pidgin');
  } else if (RegExp(r'\bhausa\b', caseSensitive: false).hasMatch(text)) {
    dialectStyleId = DialectStyleData.nigerianPidginId;
    dialectVariantId = 'hausa';
    hints.add('Hausa-inflected Pidgin');
  }
  if (RegExp(
    r'\binstrumental\b|no\s+vocals?\b|beat\s+only\b|instrumentals?\s+only\b',
    caseSensitive: false,
  ).hasMatch(text)) {
    vocalSpec = 'Instrumental only';
    vocalAccent = null;
    dialectStyleId = DialectStyleData.standardEnglishId;
    dialectVariantId = DialectStyleData.generalVariantId;
    generateLyrics = false;
    hints.add('Instrumental');
  }

  String? keyRoot = base.keyRoot;
  String? scale = base.scale;
  final keyMatch = RegExp(
    r'\b(?:in\s+)?([A-G](?:#|b)?)\s*(major|minor|maj|min)\b',
    caseSensitive: false,
  ).firstMatch(text);
  if (keyMatch != null) {
    keyRoot = keyMatch.group(1);
    final mode = keyMatch.group(2)!.toLowerCase();
    scale = mode.startsWith('maj') ? 'Major' : 'Minor';
    hints.add('Key $keyRoot $scale');
  }

  var merged = base.copyWith(
    bpm: bpm ?? base.bpm,
    primaryGenre: genre ?? base.primaryGenre,
    vibe: vibe,
    lyricTemperamentCodes: lyricTemperamentCodes,
    generateLyrics: generateLyrics,
    vocalSpec: vocalSpec,
    vocalAccent: vocalAccent,
    dialectStyleId: dialectStyleId,
    dialectVariantId: dialectVariantId,
    keyRoot: keyRoot,
    scale: scale,
    sunoFieldOutputMode: fieldMode,
    trackDuration: trackDur,
    trackDurationLabel: trackLabel,
  );

  if (fieldMode == SunoFieldOutputMode.simple) {
    merged = merged.copyWith(optionalLyrics: '', generateLyrics: false);
  }

  return QuickDescribeMapResult(merged: merged, appliedHints: hints);
}

bool _phraseAtWordBoundary(String haystack, String phrase) {
  if (phrase.isEmpty) return false;
  var from = 0;
  while (from <= haystack.length) {
    final idx = haystack.indexOf(phrase, from);
    if (idx < 0) return false;
    final before = idx == 0 ? ' ' : haystack[idx - 1];
    final afterIdx = idx + phrase.length;
    final after = afterIdx >= haystack.length ? ' ' : haystack[afterIdx];
    final beforeOk = !_isWordChar(before);
    final afterOk = !_isWordChar(after);
    if (beforeOk && afterOk) return true;
    from = idx + 1;
  }
  return false;
}

bool _isWordChar(String ch) {
  if (ch.isEmpty) return false;
  return RegExp(r'[a-z0-9]', caseSensitive: false).hasMatch(ch);
}

List<String> _extractKnownCodes(String text) {
  final known = [..._powerCodes, ..._temperamentCodes];
  final found = <String>[];
  final seen = <String>{};
  final upper = text.toUpperCase();
  for (final code in known) {
    final needle = code.toUpperCase();
    var start = 0;
    while (true) {
      final i = upper.indexOf(needle, start);
      if (i < 0) break;
      final before = i == 0 ? ' ' : text[i - 1];
      final afterEnd = i + needle.length;
      final after = afterEnd >= text.length ? ' ' : text[afterEnd];
      if (!_isWordChar(before) &&
          (after == '/' || !_isWordChar(after))) {
        if (seen.add(needle)) found.add(needle);
      }
      start = i + 1;
    }
  }
  return found;
}

String _mergeCodeTokens(String existing, List<String> upperTokens) {
  final out = <String>[];
  final seen = <String>{};
  void add(String raw) {
    final u = raw.toUpperCase();
    if (u.isEmpty) return;
    if (seen.add(u)) out.add(u);
  }

  for (final s in existing.split(RegExp(r'\s+'))) {
    add(s);
  }
  for (final t in upperTokens) {
    add(t);
  }
  return out.join(' ');
}
