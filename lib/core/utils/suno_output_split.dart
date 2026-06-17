import 'package:flutter/foundation.dart';

import '../../data/models/suno_field_output_mode.dart';
import '../constants/suno_prompt_limits.dart';
import 'suno_block_headers.dart';
import 'suno_block1_trim.dart' show smartTrimBlock1Prose;
import 'suno_internal_output_strip.dart';

/// Parses AI output: unified **Block 1 + Block 2** (V2), optional legacy Producer Brief
/// (merged into Block 1 for display), or `SUNO STRUCTURE` / `SUNO STYLE` / `SUNO LYRICS`.
typedef SunoParsed = ({
  String full,
  String? structureBody,
  String? styleBody,
  String? lyricsBody,
  bool unifiedTwoBlockFormat,
  String? suggestionsBody,
  bool block2HasEndTag,
  String? producerBriefBody,
  bool unifiedThreeSectionFormat,

  /// Unified V2 layout detected but no Lyrics body through `[End]` (incomplete generation).
  bool unifiedBlock2Missing,
});

/// True when [line] is a model “intro” before bullet suggestions — not useful as its own chip.
bool isFollowUpPreambleLine(String line) {
  final t = line.trim();
  if (t.isEmpty) return true;
  if (RegExp(r'^[\-=━─▔]{3,}$').hasMatch(t)) return true;
  final lower = t.toLowerCase();
  final normalized = lower.replaceAll(RegExp(r'\s+'), ' ').trim();

  // Stock phrase only (often followed on the next line by “→ …” suggestions).
  const preambleOnly = <String>{
    'if you want, i can also:',
    'if you want, i can also',
    "if you'd like, i can also:",
    "if you'd like, i can also",
    'if you would like, i can also:',
    'if you would like, i can also',
    'optional follow-ups:',
    'follow-up suggestions:',
    'here are some options:',
    'here are a few ideas:',
    'next steps:',
    'next steps',
  };
  if (preambleOnly.contains(normalized)) return true;

  if (normalized.startsWith('optional follow-up')) return true;
  if (normalized.startsWith('follow-up suggestions')) return true;
  if (normalized.startsWith('here are some')) return true;

  // “If you want, I can also” with **no** actionable tail (no arrow, line stays short).
  if (normalized.startsWith('if you want, i can also') &&
      !t.contains('→') &&
      normalized.length <= 40) {
    return true;
  }
  if (normalized.startsWith("if you'd like, i can also") &&
      !t.contains('→') &&
      normalized.length <= 42) {
    return true;
  }
  return false;
}

/// Lines from [SunoParsed.suggestionsBody] (text after `[End]`) for UI chips / paste.
List<String> suggestionLinesFromBody(String? suggestionsBody) {
  if (suggestionsBody == null || suggestionsBody.trim().isEmpty) {
    return const [];
  }
  return suggestionsBody
      .split('\n')
      .map((l) => l.trim())
      .where((l) => l.isNotEmpty)
      .where((l) => !isFollowUpPreambleLine(l))
      .toList();
}

SunoParsed parseSunoOutput(String raw) {
  final t = stripInternalCognitionBlocks(raw).trim();
  if (t.isEmpty) {
    return (
      full: raw,
      structureBody: null,
      styleBody: null,
      lyricsBody: null,
      unifiedTwoBlockFormat: false,
      suggestionsBody: null,
      block2HasEndTag: false,
      producerBriefBody: null,
      unifiedThreeSectionFormat: false,
      unifiedBlock2Missing: false,
    );
  }

  final unified = _tryParseUnifiedBlocks(raw);
  if (unified != null) return unified;

  final parts = t.split(RegExp(r'\r?\nSUNO LYRICS\r?\n', caseSensitive: false));
  final beforeLyrics = parts[0].trim();
  String? lyricsBody;
  if (parts.length >= 2) {
    lyricsBody = parts.sublist(1).join('\n\nSUNO LYRICS\n\n').trim();
    if (lyricsBody.isEmpty) lyricsBody = null;
  }

  String? structureBody;
  String? styleBody;

  if (beforeLyrics.toUpperCase().startsWith('SUNO STRUCTURE')) {
    final nl = beforeLyrics.indexOf('\n');
    final afterStructureHeader =
        nl >= 0 ? beforeLyrics.substring(nl + 1) : '';
    final styleParts = afterStructureHeader.split(
      RegExp(r'\r?\nSUNO STYLE\s*\r?\n', caseSensitive: false),
    );
    if (styleParts.length >= 2) {
      structureBody = styleParts.first.trim();
      styleBody = styleParts.sublist(1).join('\nSUNO STYLE\n').trim();
    } else {
      structureBody = afterStructureHeader.trim();
    }
  } else {
    var block = beforeLyrics;
    if (block.toUpperCase().startsWith('SUNO STYLE')) {
      final i = block.indexOf('\n');
      block = i >= 0 ? block.substring(i + 1).trim() : '';
    }
    styleBody = block.isEmpty ? null : block;
  }

  final end = lyricsBody != null && _bodyHasEndTagLine(lyricsBody);

  return (
    full: raw,
    structureBody: structureBody,
    styleBody: styleBody,
    lyricsBody: lyricsBody,
    unifiedTwoBlockFormat: false,
    suggestionsBody: null,
    block2HasEndTag: end,
    producerBriefBody: null,
    unifiedThreeSectionFormat: false,
    unifiedBlock2Missing: false,
  );
}

/// Back-compat: older call sites only need style + lyrics.
({String full, String? styleBody, String? lyricsBody}) parseSunoDualOutput(
  String raw,
) {
  final p = parseSunoOutput(raw);
  return (
    full: p.full,
    styleBody: p.styleBody,
    lyricsBody: p.lyricsBody,
  );
}

/// Collapse Block 1 to one paragraph and hard-cap: **≤150 words**, **≤** mode char max.
String enforceUnifiedBlock1CharLimit(String raw, SunoFieldOutputMode mode) {
  final limit = mode == SunoFieldOutputMode.simple
      ? SunoPromptLimits.block1SimpleModeCharMax
      : SunoPromptLimits.block1CustomModeCharMax;
  final normalized = raw.replaceAll('\r\n', '\n');
  final lines = normalized.split('\n');
  var iBlock1 = -1;
  var iBlock2 = -1;
  for (var i = 0; i < lines.length; i++) {
    if (lineIsBlock2LyricsHeader(lines[i])) {
      if (iBlock2 < 0) iBlock2 = i;
    } else if (lineIsBlock1StyleHeader(lines[i])) {
      if (iBlock1 < 0) iBlock1 = i;
    }
  }
  if (iBlock1 < 0) return raw;

  final endExclusive = iBlock2 >= 0 ? iBlock2 : lines.length;
  if (iBlock1 + 1 >= endExclusive) return raw;

  final bodyChunk = lines.sublist(iBlock1 + 1, endExclusive).join('\n');
  final strippedChunk = _stripDecorativeLines(bodyChunk).trim();
  if (strippedChunk.isEmpty) return raw;

  final flat = strippedChunk
      .replaceAll(RegExp(r'[\r\n]+'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  final trimmed = smartTrimBlock1Prose(
    flat,
    maxWords: SunoPromptLimits.block1StyleWordHardMax,
    maxChars: limit,
  );

  if (trimmed == flat && flat.length <= limit) {
    final wc = flat.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
    if (wc <= SunoPromptLimits.block1StyleWordHardMax) return raw;
  }

  return [
    ...lines.sublist(0, iBlock1 + 1),
    trimmed,
    ...lines.sublist(endExclusive),
  ].join('\n');
}

SunoParsed? _tryParseUnifiedBlocks(String raw) {
  final lines = raw.replaceAll('\r\n', '\n').split('\n');
  var iProducerBrief = -1;
  var iBlock1 = -1;
  var iBlock2 = -1;
  for (var i = 0; i < lines.length; i++) {
    if (lineIsProducerBriefHeader(lines[i]) && iProducerBrief < 0) {
      iProducerBrief = i;
    }
    if (lineIsBlock2LyricsHeader(lines[i]) && iBlock2 < 0) {
      iBlock2 = i;
    }
    if (lineIsBlock1StyleHeader(lines[i]) && iBlock1 < 0) {
      iBlock1 = i;
    }
  }
  if (iBlock1 < 0) return null;

  final hasOrderedBrief =
      iProducerBrief >= 0 && iProducerBrief < iBlock1;
  String? legacyBrief;
  if (hasOrderedBrief) {
    final briefChunk = lines.sublist(iProducerBrief + 1, iBlock1).join('\n');
    legacyBrief = _stripDecorativeLines(briefChunk).trim();
    if (legacyBrief.isEmpty) legacyBrief = null;
  }

  if (iBlock2 < 0) {
    final proseLines = lines.sublist(iBlock1 + 1);
    var prose = _stripDecorativeLines(proseLines.join('\n')).trim();
    if (legacyBrief != null && legacyBrief.isNotEmpty) {
      prose = prose.isEmpty
          ? legacyBrief
          : '$legacyBrief\n\n$prose';
    }
    _logIncompleteUnifiedBlock2(
      hasBlock2Banner: false,
      hasLyricsBody: false,
      rawLength: raw.length,
    );
    return (
      full: raw,
      structureBody: null,
      styleBody: prose.isEmpty ? null : prose,
      lyricsBody: null,
      unifiedTwoBlockFormat: true,
      suggestionsBody: null,
      block2HasEndTag: false,
      producerBriefBody: null,
      unifiedThreeSectionFormat: false,
      unifiedBlock2Missing: true,
    );
  }

  var styleChunk = lines.sublist(iBlock1 + 1, iBlock2).join('\n');
  var styleBody = _stripDecorativeLines(styleChunk).trim();
  if (legacyBrief != null && legacyBrief.isNotEmpty) {
    styleBody = styleBody.isEmpty
        ? legacyBrief
        : '$legacyBrief\n\n$styleBody';
  }
  final lyricSectionRaw = lines.sublist(iBlock2 + 1).join('\n').trim();
  final strippedLyric = _stripDecorativeLines(lyricSectionRaw).trim();
  final split = _splitLyricsAndSuggestions(strippedLyric);
  final lyricsRaw = split.$1;
  final suggestions = split.$2;
  final hasEnd = lyricsRaw.isNotEmpty && _bodyHasEndTagLine(lyricsRaw);
  final missingB2 = lyricsRaw.trim().isEmpty;
  if (missingB2) {
    _logIncompleteUnifiedBlock2(
      hasBlock2Banner: true,
      hasLyricsBody: false,
      rawLength: raw.length,
    );
  }

  return (
    full: raw,
    structureBody: null,
    styleBody: styleBody.isEmpty ? null : styleBody,
    lyricsBody: lyricsRaw.isEmpty ? null : lyricsRaw,
    unifiedTwoBlockFormat: true,
    suggestionsBody: suggestions,
    block2HasEndTag: hasEnd,
    producerBriefBody: null,
    unifiedThreeSectionFormat: false,
    unifiedBlock2Missing: missingB2,
  );
}

void _logIncompleteUnifiedBlock2({
  required bool hasBlock2Banner,
  required bool hasLyricsBody,
  required int rawLength,
}) {
  if (kDebugMode) {
    debugPrint(
      '[SunoOutputSplit] incomplete unified output — '
      'Block2Banner: $hasBlock2Banner · lyricsBody: $hasLyricsBody · '
      'rawLen: $rawLength',
    );
  }
}

/// Returns `(lyricsThroughEnd, suggestionsAfterEnd)`.
(String, String?) _splitLyricsAndSuggestions(String afterBlock2Banner) {
  final lines = afterBlock2Banner.split('\n');
  var endIdx = -1;
  for (var i = 0; i < lines.length; i++) {
    if (lines[i].trim() == '[End]') endIdx = i;
  }
  if (endIdx >= 0) {
    final lyrics =
        lines.sublist(0, endIdx + 1).join('\n').trimRight();
    final rest = lines.sublist(endIdx + 1).join('\n').trim();
    return (lyrics, rest.isEmpty ? null : rest);
  }
  return (afterBlock2Banner.trim(), null);
}

bool _bodyHasEndTagLine(String body) {
  for (final line in body.split('\n')) {
    if (line.trim() == '[End]') return true;
  }
  return false;
}

String _stripDecorativeLines(String text) {
  return text
      .split('\n')
      .where((l) {
        final t = l.trim();
        if (t.isEmpty) return true;
        if (RegExp(r'^[\-=]{3,}$').hasMatch(t)) return false;
        return !_isSeparatorOrBannerOnlyLine(t);
      })
      .join('\n');
}

bool _isSeparatorOrBannerOnlyLine(String t) {
  if (t.isEmpty) return false;
  const sep = '━═─▔▁‐-–—';
  for (final r in t.runes) {
    final ch = String.fromCharCode(r);
    if (ch == ' ' || ch == '\t') continue;
    if (sep.contains(ch)) continue;
    if (ch == '📋' || ch == '⚡' || ch == '🎛️') continue;
    return false;
  }
  return true;
}
