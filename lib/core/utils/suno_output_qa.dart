import '../constants/suno_prompt_limits.dart';
import 'suno_output_split.dart';

/// Block 1 body below this word count is probably truncated (server parity).
const int block1IncompleteWordThreshold = 80;

int block1BodyWordCount(String raw) {
  final style = parseSunoOutput(raw).styleBody?.trim() ?? '';
  if (style.isEmpty) return 0;
  return style.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
}

bool unifiedBlock2MissingOutput(String raw) =>
    parseSunoOutput(raw).unifiedBlock2Missing;

bool block1ProbablyTruncated(String raw) {
  final wc = block1BodyWordCount(raw);
  return wc > 0 && wc < block1IncompleteWordThreshold;
}

bool sunoOutputIncomplete(String raw) =>
    unifiedBlock2MissingOutput(raw) || block1ProbablyTruncated(raw);

bool isBetterSunoOutput(String candidate, String current) {
  final candBad = sunoOutputIncomplete(candidate);
  final curBad = sunoOutputIncomplete(current);
  if (candBad != curBad) return !candBad;
  if (unifiedBlock2MissingOutput(current) &&
      !unifiedBlock2MissingOutput(candidate)) {
    return true;
  }
  return candidate.length > current.length;
}

bool shouldFormatRetryOutput(
  String raw, {
  required bool useV2,
  required bool block2OptOut,
}) {
  if (!useV2 || block2OptOut) return false;
  return sunoOutputIncomplete(raw);
}

String buildIncompleteOutputRetrySuffix({
  required bool block2Missing,
  required bool block1Short,
}) {
  final lines = <String>[
    'STRICT COMPLIANCE — Output the **complete** two-block reply again. Fix:',
  ];
  if (block1Short) {
    final w = SunoPromptLimits.block1StyleWordRangeFor('v5.5');
    lines.add(
      '- Block 1 producer prose must be **${w.min}–${w.max} words** (you returned far too few).',
    );
  }
  if (block2Missing) {
    lines.add(
      '- Include BLOCK 2 — PASTE INTO SUNO: LYRICS with section metatags through [End].',
    );
  }
  lines.add('- No markdown fences. No meta-commentary before the banners.');
  return lines.join('\n');
}
