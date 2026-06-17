/// Token-efficient payload shaping for on-device LLM requests.

const int kDefaultContinuationMaxChars = 6000;
const int kContinuationHeadChars = 1400;
const int kContinuationTailChars = 4200;

String compactPayloadText(String text) {
  if (text.isEmpty) return text;
  var out = text.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
  out = out.replaceAll(RegExp(r'[ \t]+\n'), '\n');
  out = out.replaceAll(RegExp(r'\n{3,}'), '\n\n');
  return out.trim();
}

String truncateContinuationPrior(
  String text, {
  int maxChars = kDefaultContinuationMaxChars,
}) {
  final t = compactPayloadText(text);
  if (t.length <= maxChars) return t;

  final headBudget = kContinuationHeadChars < maxChars ~/ 4
      ? maxChars ~/ 4
      : kContinuationHeadChars;
  var tailBudget = maxChars - headBudget - 48;
  if (tailBudget < 800) tailBudget = 800;

  const marker = '\n...[prior output truncated for token budget]...\n';
  if (headBudget + tailBudget + marker.length >= t.length) {
    return t.substring(0, maxChars);
  }

  return '${t.substring(0, headBudget).trimRight()}'
      '$marker'
      '${t.substring(t.length - tailBudget).trimLeft()}';
}

/// Appended to the director system prompt for on-device LaoZhang GPT-5.5 prompt-generation pass.
const String kLaozhangArchitectureBoundary = '''
[LAOZHANG ARCHITECTURE BOUNDARY]
You are the GPT-5.5 multilingual prompt-generation pass (LaoZhang). Claude follows to refine lyrics and artistic expression.
- Multilingual understanding: honor the user Language field, African languages, and Nigerian Pidgin (`dialect_style_id=nigerian_pidgin`) — never flatten Pidgin or African lyric intent to textbook English.
- Generate the complete Suno two-block reply (Block 1 STYLE + Block 2 LYRICS when applicable).
- Wrap all music instructions for a single section inside a single, comma-separated bracket.
- If the track environment is Studio, use cold engineering tokens: "Dead-room isolation, Zero audience noise".
- Keep lyric lines instrument-free; Claude will elevate hooks, storytelling, vocal personality, and poetic expression in the polish pass.''';

/// Inline Stage-5-style hygiene for LaoZhang on-device responses (Path 1).
String cleanLaoZhangOnDevicePayload(String rawOutputText) {
  var cleaned = rawOutputText;

  final stackedBracketRegex = RegExp(r'(\[[^\]]+\]\s*){2,}');
  cleaned = cleaned.split('\n').map((line) {
    return line.replaceAllMapped(stackedBracketRegex, (match) {
      final tags = RegExp(r'\[(.*?)\]')
          .allMatches(match.group(0)!)
          .map((m) => m.group(1)!.trim())
          .where((t) => t.isNotEmpty);
      return '[${tags.join(', ')}]';
    });
  }).join('\n');

  cleaned = cleaned
      .replaceAll('SATB Choir', 'Isolated multi-tracked vocal doubles')
      .replaceAll('SATB Studio Choir', 'Isolated multi-tracked vocal doubles')
      .replaceAll('Studio Harmonic Backing', 'Isolated multi-tracked vocal doubles')
      .replaceAll('Harmonic Backing', 'Isolated multi-tracked vocal doubles')
      .replaceAll('Congregational', 'Multi-tracked vocal doubles');

  cleaned = cleaned.replaceAll(RegExp(r'\n{3,}'), '\n\n');
  return cleaned.trim();
}

String appendLaozhangArchitectureBoundary(String systemPrompt) =>
    '$systemPrompt\n\n$kLaozhangArchitectureBoundary';

String compactGenreContextHeader({
  required String primaryGenre,
  required String subGenreFusion,
  required String vibe,
  required String lyricThemeNotes,
  required String language,
  List<String> extraLines = const [],
}) {
  final theme =
      lyricThemeNotes.trim().isEmpty ? 'infer' : lyricThemeNotes.trim();
  final g = primaryGenre.trim().isEmpty ? 'unspecified' : primaryGenre.trim();
  final f = subGenreFusion.trim().isEmpty ? 'none' : subGenreFusion.trim();
  final v = vibe.trim().isEmpty ? 'unspecified' : vibe.trim();
  final lang = language.trim().isEmpty ? 'English' : language.trim();
  final base = 'G:$g|F:$f|V:$v|L:$lang|T:$theme';
  final extras = extraLines.where((e) => e.trim().isNotEmpty).toList();
  if (extras.isEmpty) return base;
  return '$base\n${extras.join('\n')}';
}
