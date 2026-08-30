import 'advanced_thematic_variator.dart';
import 'suno_lyrics_audio_normalizer.dart';

final _sectionHeader = RegExp(r'^\[([^\]]+)\]\s*$');
final _dropHeader = RegExp(r'^drop$|^final drop$', caseSensitive: false);

const _monologueDeliveryTags = [
  '[Deep Pitch-Down Male Voiceover]',
  '[Calm Controlled Spoken Word]',
];

final _vocalTagReplacements = <RegExp, String>{
  RegExp(r'\[Maximum Aggression\]', caseSensitive: false): '[Heavy Produced Mix]',
  RegExp(r'\[Aggressive Hype\]', caseSensitive: false): '[Heavy Produced Mix]',
  RegExp(r'\[Vocal Belt\]', caseSensitive: false): '[Sustained Clean Melodic Vocals]',
  RegExp(r'\[Shouted Vocal\]', caseSensitive: false): '[Sustained Clean Melodic Vocals]',
};

String _scrubExclamations(String text) => text.replaceAll('!', '.');

String _translateVocalTags(String text) {
  var out = text;
  for (final entry in _vocalTagReplacements.entries) {
    out = out.replaceAll(entry.key, entry.value);
  }
  return out;
}

bool _isDropHeader(String header) =>
    _dropHeader.hasMatch(header.trim().toLowerCase());

bool _isLyricLine(String line) {
  final t = line.trim();
  if (t.isEmpty) return false;
  return !_sectionHeader.hasMatch(t);
}

String _punchyPhrase(List<String> lines, {int maxWords = 4}) {
  final words = <String>[];
  for (final line in lines.reversed) {
    for (final word in line.trim().split(RegExp(r'\s+'))) {
      if (word.isEmpty) continue;
      words.insert(0, word);
      if (words.length >= maxWords) break;
    }
    if (words.length >= maxWords) break;
  }
  return words.take(maxWords).join(' ');
}

String _collapsePreDropCues(String text) {
  final lines = text.split('\n');
  final out = <String>[];
  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];
    final headerMatch = _sectionHeader.firstMatch(line.trim());
    if (headerMatch != null && _isDropHeader(headerMatch.group(1)!)) {
      final cueLines = <String>[];
      while (out.isNotEmpty && _isLyricLine(out.last)) {
        cueLines.insert(0, out.removeLast());
      }
      if (cueLines.length > 1 ||
          cueLines.any((row) => row.trim().split(RegExp(r'\s+')).length > 4)) {
        out.add(_punchyPhrase(cueLines));
      } else {
        out.addAll(cueLines);
      }
      out.add(line);
      continue;
    }
    out.add(line);
  }
  return out.join('\n');
}

String _applyHardstyleMonologueTags(String text) {
  final lines = text.split('\n');
  final out = <String>[];
  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];
    final headerMatch = _sectionHeader.firstMatch(line.trim());
    if (headerMatch != null &&
        headerMatch.group(1)!.trim().toLowerCase() == 'monologue') {
      out.add(line);
      final block = lines.sublist(i + 1).join('\n').toLowerCase();
      for (final tag in _monologueDeliveryTags) {
        if (!block.contains(tag.toLowerCase())) {
          out.add(tag);
        }
      }
      continue;
    }
    out.add(line);
  }
  return out.join('\n');
}

String applyAntiScreamToLyrics(
  String lyrics, {
  String primaryGenre = '',
  String subGenreFusion = '',
}) {
  if (lyrics.trim().isEmpty) return lyrics;
  var out = _scrubExclamations(lyrics);
  out = _translateVocalTags(out);
  if (isHardstyleLaneForVariator(primaryGenre, subGenreFusion)) {
    out = _applyHardstyleMonologueTags(out);
  }
  out = _collapsePreDropCues(out);
  return out;
}

String applyAntiScreamFilter(
  String fullText, {
  String primaryGenre = '',
  String subGenreFusion = '',
}) {
  final parts = splitBlock2Parts(fullText);
  if (parts == null) {
    return applyAntiScreamToLyrics(
      fullText,
      primaryGenre: primaryGenre,
      subGenreFusion: subGenreFusion,
    );
  }
  final cleaned = applyAntiScreamToLyrics(
    parts.$2,
    primaryGenre: primaryGenre,
    subGenreFusion: subGenreFusion,
  );
  if (cleaned == parts.$2) return fullText;
  return mergeBlock2Parts(parts.$1, cleaned, parts.$3);
}
