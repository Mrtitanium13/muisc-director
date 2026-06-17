import '../constants/suno_prompt_limits.dart';
import '../../data/models/suno_field_output_mode.dart';
import 'suno_block_headers.dart';
import 'suno_output_qa.dart';
import 'suno_output_split.dart';

/// Lightweight format QA for unified two-block output and legacy triple-header.
class FormatValidationResult {
  const FormatValidationResult({
    required this.hasBlock1Banner,
    required this.hasBlock2Banner,
    required this.hasEndTag,
    required this.hasBulletsInBlock1,
    required this.hasSuspiciousProseInBlock2,
    required this.followUpsPresent,
    required this.block1CharCount,
    required this.block1CharLimit,
    required this.block1WithinCharLimit,
    required this.block1WordCount,
    required this.block1ProbablyTruncated,
    required this.block2CharCount,
    required this.block2WithinCharLimit,
  });

  final bool hasBlock1Banner;
  final bool hasBlock2Banner;
  final bool hasEndTag;
  final bool hasBulletsInBlock1;
  final bool hasSuspiciousProseInBlock2;
  final bool followUpsPresent;

  final int block1CharCount;
  final int block1CharLimit;
  final bool block1WithinCharLimit;
  final int block1WordCount;
  final bool block1ProbablyTruncated;
  final int block2CharCount;
  final bool block2WithinCharLimit;

  /// 0.0–1.0. When [expectLyricsBlock] is false, Block 2 / [End] / follow-up
  /// checks are treated as N/A and scored as passing.
  static double qualityScore(
    FormatValidationResult r, {
    required bool expectLyricsBlock,
  }) {
    var score = 0;
    if (r.hasBlock1Banner) score += 22;
    if (!expectLyricsBlock || r.hasBlock2Banner) score += 22;
    if (!expectLyricsBlock || r.hasEndTag) score += 18;
    if (!r.hasBulletsInBlock1) score += 13;
    if (!r.hasSuspiciousProseInBlock2) score += 10;
    if (!expectLyricsBlock || r.followUpsPresent) score += 5;
    if (r.block1WithinCharLimit) score += 10;
    if (!expectLyricsBlock || r.block2WithinCharLimit) score += 10;
    return score / 110;
  }

  static FormatValidationResult validate(
    String rawOutput, {
    required bool expectLyricsBlock,
    SunoFieldOutputMode block1Mode = SunoFieldOutputMode.custom,
  }) {
    final parsed = parseSunoOutput(rawOutput);
    final hasB1 = _rawHasBlock1Signal(rawOutput, parsed);
    final hasB2 = !expectLyricsBlock
        ? true
        : _rawHasBlock2Signal(rawOutput, parsed);
    final end = expectLyricsBlock ? parsed.block2HasEndTag : true;
    final style = parsed.styleBody ?? '';
    final bullets = style.isNotEmpty && _detectBulletsInBlock1(style);
    final prose = _detectSuspiciousProseInBlock2(parsed.lyricsBody);
    final follow = expectLyricsBlock &&
        ((parsed.suggestionsBody?.trim().isNotEmpty ?? false) ||
            _detectFollowUpsHeuristic(rawOutput));

    final b1Cap = SunoPromptLimits.block1CharHardCapForMode(block1Mode);
    final b1Count = style.length;
    final b1Limit = b1Cap;
    final b1Ok = b1Count <= b1Cap;
    final b1Words = style.isEmpty
        ? 0
        : style.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
    final b1Short = b1Words > 0 && b1Words < block1IncompleteWordThreshold;

    final lyrics = (parsed.lyricsBody ?? '').trim();
    final b2Count = lyrics.length;
    final b2Ok = !expectLyricsBlock || b2Count <= SunoPromptLimits.lyricsCharLimit;

    return FormatValidationResult(
      hasBlock1Banner: hasB1,
      hasBlock2Banner: hasB2,
      hasEndTag: end,
      hasBulletsInBlock1: bullets,
      hasSuspiciousProseInBlock2: prose,
      followUpsPresent: !expectLyricsBlock ? true : follow,
      block1CharCount: b1Count,
      block1CharLimit: b1Limit,
      block1WithinCharLimit: b1Ok,
      block1WordCount: b1Words,
      block1ProbablyTruncated: b1Short,
      block2CharCount: b2Count,
      block2WithinCharLimit: b2Ok,
    );
  }

  /// Whether a second generation pass is worth trying (client-side QA).
  static bool shouldRetryAfterValidation(
    FormatValidationResult r, {
    required bool expectLyricsBlock,
    required bool unifiedBlock2Missing,
  }) {
    if (unifiedBlock2Missing && expectLyricsBlock) return true;
    if (r.block1ProbablyTruncated) return true;
    final score = qualityScore(r, expectLyricsBlock: expectLyricsBlock);
    if (score < 0.82) return true;
    if (expectLyricsBlock && (!r.hasBlock2Banner || !r.hasEndTag)) {
      return true;
    }
    return false;
  }

  /// Appended to the user block on a single strict retry.
  static String buildFormatRetrySuffix(
    FormatValidationResult r, {
    required bool expectLyricsBlock,
  }) {
    final lines = <String>[
      'STRICT COMPLIANCE — Output the full two-block reply again. Fix:',
    ];
    if (!r.hasBlock1Banner) {
      lines.add(
        '- Include the exact line: BLOCK 1 — PASTE INTO SUNO: STYLE (or Simple Description banner).',
      );
    }
    if (expectLyricsBlock) {
      if (!r.hasBlock2Banner) {
        lines.add(
          '- Include BLOCK 2 — PASTE INTO SUNO: LYRICS with section metatags.',
        );
      }
      if (!r.hasEndTag) {
        lines.add('- End Block 2 with [End] on its own line.');
      }
      if (!r.block2WithinCharLimit) {
        lines.add(
          '- Block 2 must be ≤ ${SunoPromptLimits.lyricsCharLimit} characters.',
        );
      }
    }
    if (r.block1ProbablyTruncated) {
      final w = SunoPromptLimits.block1StyleWordRangeFor('v5.5');
      lines.add(
        '- Block 1 producer prose must be **${w.min}–${w.max} words** (output was only ${r.block1WordCount} words).',
      );
    }
    if (!r.block1WithinCharLimit) {
      lines.add(
        '- Block 1 prose body must be ≤ ${r.block1CharLimit} characters (one paragraph).',
      );
    }
    if (r.hasBulletsInBlock1) {
      lines.add('- Block 1: flowing producer prose only — no bullet or numbered lists.');
    }
    lines.add('- No markdown fences. No meta-commentary before the banners.');
    return lines.join('\n');
  }
}

bool _rawHasBlock1Signal(String raw, SunoParsed parsed) {
  for (final line in raw.replaceAll('\r\n', '\n').split('\n')) {
    if (lineIsBlock1StyleHeader(line)) return true;
  }
  final head = raw.trim().toUpperCase();
  if (head.startsWith('SUNO STRUCTURE')) return true;
  if (head.startsWith('SUNO STYLE')) return true;
  if (parsed.styleBody != null && parsed.styleBody!.trim().isNotEmpty) {
    return true;
  }
  return false;
}

bool _rawHasBlock2Signal(String raw, SunoParsed parsed) {
  for (final line in raw.replaceAll('\r\n', '\n').split('\n')) {
    if (lineIsBlock2LyricsHeader(line)) return true;
  }
  if (rawContainsLegacySunoLyricsHeader(raw)) return true;
  return parsed.lyricsBody != null && parsed.lyricsBody!.trim().isNotEmpty;
}

bool _detectFollowUpsHeuristic(String raw) {
  final u = raw.toUpperCase();
  return u.contains('IF YOU WANT') ||
      u.contains('IF YOU WANT, I CAN') ||
      raw.contains('→');
}

bool _detectBulletsInBlock1(String styleBody) {
  for (final line in styleBody.split('\n')) {
    final t = line.trimLeft();
    if (t.startsWith('- ') ||
        t.startsWith('• ') ||
        t.startsWith('* ') ||
        RegExp(r'^\d+\.\s').hasMatch(t)) {
      return true;
    }
  }
  return false;
}

/// Flags a single line in Block 2 that looks like a prose paragraph (model put
/// style description in Lyrics). Normal lyric lines rarely exceed this density.
bool _detectSuspiciousProseInBlock2(String? lyricsBody) {
  if (lyricsBody == null || lyricsBody.trim().isEmpty) return false;
  for (final line in lyricsBody.split('\n')) {
    final t = line.trim();
    if (t.isEmpty) continue;
    if (t.startsWith('[')) continue;
    final words = t.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
    if (words > 28) return true;
  }
  return false;
}
