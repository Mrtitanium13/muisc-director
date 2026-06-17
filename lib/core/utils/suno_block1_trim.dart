/// Smart-truncate Block 1 text to [limit], preferring a clean break at the last comma.
String smartTrimBlock1AtLimit(String text, int limit) {
  if (text.length <= limit) return text;
  final sub = text.substring(0, limit);
  final lastComma = sub.lastIndexOf(',');
  if (lastComma > 0) return text.substring(0, lastComma).trimRight();
  return sub.trimRight();
}

/// Block 1 producer prose: cap words then characters (word boundary).
String smartTrimBlock1Prose(
  String text, {
  required int maxWords,
  required int maxChars,
}) {
  var s = text
      .replaceAll(RegExp(r'[\r\n]+'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  if (s.isEmpty) return s;
  final words = s.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
  if (words.length > maxWords) {
    s = words.take(maxWords).join(' ');
  }
  if (s.length <= maxChars) return s;
  return smartTrimSimpleDescription(s, maxChars);
}

/// Simple Mode description: trim on a word boundary when possible.
String smartTrimSimpleDescription(String text, int limit) {
  if (text.length <= limit) return text;
  final sub = text.substring(0, limit);
  final lastSpace = sub.lastIndexOf(' ');
  if (lastSpace > limit - 40) return sub.substring(0, lastSpace).trimRight();
  return sub.trimRight();
}
