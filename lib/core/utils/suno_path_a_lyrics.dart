import 'theme_consistency_split.dart';

/// Path A: force Block 2 sung lines to the lyrics-box paste, after the LLM.
String pinUserLyricsToBlock2(String output, String userLyrics) {
  final user = userLyrics.trim();
  if (user.isEmpty) return output;
  final parts = splitBlock2Parts(output);
  if (parts == null) return output;
  var body = user;
  if (!RegExp(r'\[End\]', caseSensitive: false).hasMatch(body)) {
    body = '$body\n\n[End]';
  }
  return mergeBlock2Parts(
    prefix: parts.prefix,
    block2Body: body,
    suffix: parts.suffix,
  );
}
