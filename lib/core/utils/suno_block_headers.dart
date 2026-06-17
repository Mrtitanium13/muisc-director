/// Shared detection for unified **Producer Brief** / **Block 1 / Block 2** banners.
/// Used by [parseSunoOutput] and [FormatValidator].
bool lineIsProducerBriefHeader(String line) {
  final u = line.trim().toUpperCase();
  return u.contains('PRODUCER BRIEF') &&
      (u.contains('CREATIVE') || u.contains('REFERENCE'));
}

bool lineIsBlock1StyleHeader(String line) {
  final t = line.trim();
  if (t.isEmpty) return false;
  final u = t.toUpperCase();
  if (u.contains('PASTE INTO SUNO:') &&
      u.contains('STYLE') &&
      !u.contains('LYRICS')) {
    return true;
  }
  if (!u.contains('BLOCK')) return false;
  if (!RegExp(r'BLOCK\s*1').hasMatch(u)) return false;
  return u.contains('STYLE');
}

bool lineIsBlock2LyricsHeader(String line) {
  final u = line.trim().toUpperCase();
  if (u.contains('PASTE INTO SUNO:') && u.contains('LYRICS')) return true;
  if (!u.contains('BLOCK')) return false;
  if (!RegExp(r'BLOCK\s*2').hasMatch(u)) return false;
  return u.contains('LYRICS');
}

bool rawContainsLegacySunoLyricsHeader(String raw) {
  return RegExp(r'(?:^|\r?\n)SUNO LYRICS\s*\r?\n', caseSensitive: false)
      .hasMatch(raw);
}
