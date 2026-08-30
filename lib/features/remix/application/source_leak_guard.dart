import 'package:music_director/features/remix/domain/remix_mode.dart';

/// Deterministic source-name leak guard for Style + Lyrics paste output.
({String text, bool leaked}) sourceLeakGuard({
  required String output,
  required String title,
  required String artist,
}) {
  final variants = <String>{
    title.trim(),
    artist.trim(),
    ..._splitFeat(artist),
  }.where((v) => v.length >= 3).toSet();

  if (variants.isEmpty) return (text: output, leaked: false);

  final hay = _norm(output);
  final hits = <String>[];
  for (final v in variants) {
    final n = _norm(v);
    if (n.length >= 3 && hay.contains(n)) hits.add(v);
  }
  if (hits.isEmpty) return (text: output, leaked: false);

  var cleaned = output;
  for (final h in hits) {
    cleaned = cleaned.replaceAll(
      RegExp(RegExp.escape(h), caseSensitive: false),
      '[redacted]',
    );
  }
  return (text: cleaned, leaked: true);
}

Iterable<String> _splitFeat(String artist) {
  return artist
      .split(RegExp(r'\s*(?:feat\.?|ft\.?|,|&)\s*', caseSensitive: false))
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty);
}

String _norm(String s) {
  var t = s.toLowerCase();
  // Fold common accents coarsely (NFKD-lite for Latin).
  const map = {
    'á': 'a',
    'à': 'a',
    'ä': 'a',
    'â': 'a',
    'ã': 'a',
    'é': 'e',
    'è': 'e',
    'ë': 'e',
    'ê': 'e',
    'í': 'i',
    'ì': 'i',
    'ï': 'i',
    'î': 'i',
    'ó': 'o',
    'ò': 'o',
    'ö': 'o',
    'ô': 'o',
    'õ': 'o',
    'ú': 'u',
    'ù': 'u',
    'ü': 'u',
    'û': 'u',
    'ñ': 'n',
    'ç': 'c',
  };
  for (final e in map.entries) {
    t = t.replaceAll(e.key, e.value);
  }
  return t.replaceAll(RegExp(r'[^a-z0-9 ]'), '');
}

/// Apply leak guard when interpolation mode is active.
String applyRemixLeakGuardIfNeeded({
  required String output,
  required RemixMode mode,
  required String title,
  required String artist,
}) {
  if (mode != RemixMode.interpolation) return output;
  return sourceLeakGuard(output: output, title: title, artist: artist).text;
}
