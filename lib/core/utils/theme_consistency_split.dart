import 'suno_block_headers.dart';

/// Split unified output into Block 2 parts for theme consistency pass.
({String prefix, String block2Body, String suffix})? splitBlock2Parts(
  String raw,
) {
  final lines = raw.replaceAll('\r\n', '\n').split('\n');
  var iBlock2 = -1;
  for (var i = 0; i < lines.length; i++) {
    if (lineIsBlock2LyricsHeader(lines[i])) {
      iBlock2 = i;
      break;
    }
  }
  if (iBlock2 < 0) return null;

  final prefix = lines.sublist(0, iBlock2 + 1).join('\n');
  final rest = lines.sublist(iBlock2 + 1).join('\n');
  if (rest.trim().isEmpty) return null;

  final endRe = RegExp(r'^\s*\[End\]\s*$', caseSensitive: false, multiLine: true);
  final match = endRe.firstMatch(rest);
  if (match != null) {
    final before = rest.substring(0, match.start).trimRight();
    final endLine = rest.substring(match.start, match.end);
    final body = before.isEmpty ? endLine : '$before\n$endLine';
    final suffix = rest.substring(match.end).trimLeft();
    return (prefix: prefix, block2Body: body, suffix: suffix);
  }

  return (prefix: prefix, block2Body: rest.trim(), suffix: '');
}

String mergeBlock2Parts({
  required String prefix,
  required String block2Body,
  required String suffix,
}) {
  final parts = <String>[prefix.trimRight(), block2Body.trim()];
  if (suffix.trim().isNotEmpty) {
    parts.add(suffix.trim());
  }
  return parts.join('\n\n');
}

String sanitizeThemeConsistencyOutput(String text) {
  var t = text.trim();
  if (t.startsWith('```')) {
    t = t.replaceFirst(RegExp(r'^```[\w]*\n?'), '');
    t = t.replaceFirst(RegExp(r'\n?```\s*$'), '').trim();
  }
  final lines = t.split('\n');
  if (lines.isNotEmpty && lineIsBlock2LyricsHeader(lines.first)) {
    t = lines.sublist(1).join('\n').trim();
  }
  return t;
}

bool block2ThemeOutputValid(String body) {
  final t = body.trim();
  if (t.length < 12) return false;
  if (!t.toLowerCase().contains('[end]')) return false;
  if (RegExp(
    r'\[(intro|verse|chorus|hook|drop|outro)(\s|\])',
    caseSensitive: false,
  ).hasMatch(t)) {
    return true;
  }
  return t.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length >= 8;
}
