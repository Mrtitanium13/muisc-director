/// Internal cognition tags stripped before user-visible Suno output.
const _internalCognitionTags = [
  'master_blueprint',
  'psychology_audit',
  'lyric_audit',
];

/// Strip internal cognition blocks leaked by the model (e.g. master_blueprint).
String stripInternalCognitionBlocks(String text) {
  if (text.isEmpty) return text;
  final lower = text.toLowerCase();
  if (!_internalCognitionTags.any((tag) => lower.contains('<$tag'))) {
    return text;
  }

  var out = text;
  for (final tag in _internalCognitionTags) {
    out = out.replaceAll(
      RegExp(
        '<$tag\\b[^>]*>.*?</$tag>',
        caseSensitive: false,
        dotAll: true,
      ),
      '',
    );
    if (out.toLowerCase().contains('<$tag')) {
      out = out.replaceAll(
        RegExp(
          '<$tag\\b[^>]*>.*',
          caseSensitive: false,
          dotAll: true,
        ),
        '',
      );
    }
  }
  out = out.replaceAll(RegExp(r'\n{3,}'), '\n\n');
  return out.trim();
}
