import 'suno_block_headers.dart';

/// Suno post-generation lyrics normalizer — strips studio jargon and converts
/// dense LLM staging into audio-engine-safe bracket tags.
String normalizeLyricsForAudioEngine(String llmLyrics) {
  if (llmLyrics.isEmpty) return llmLyrics;

  var out = llmLyrics
      .replaceAll(
        RegExp(r'\[\d+-bar\s+DJ\s+intro[^\]]*\]', caseSensitive: false),
        '[Intro]\n[Atmospheric Synth Intro]',
      )
      .replaceAll(
        RegExp(r'\[\d+-bar\s+DJ\s+outro[^\]]*\]', caseSensitive: false),
        '[Outro]\n[Minimal Outro]',
      )
      .replaceAll(
        RegExp(r'\[Dead-room[^\]]*\]', caseSensitive: false),
        '[Intimate Male Vocal]',
      )
      .replaceAll(
        RegExp(r'\[Male\s+Vocal,\s*Intimate[^\]]*\]', caseSensitive: false),
        '[Intimate Male Vocal]',
      )
      .replaceAll(
        RegExp(r'\[Male\s+Vocal,\s*Whispered[^\]]*\]', caseSensitive: false),
        '[Whispered Male Vocal]',
      )
      .replaceAll(
        RegExp(
          r'\[Male\s+Vocal,\s*Building\s+Intensity[^\]]*\]',
          caseSensitive: false,
        ),
        '[Building Intensity]\n[Accelerating Snare Roll]',
      )
      .replaceAll(RegExp(r'Prophet-5', caseSensitive: false), 'Synth')
      .replaceAll(RegExp(r'TR-909', caseSensitive: false), 'Drums')
      .replaceAll(RegExp(r'TR-808', caseSensitive: false), 'Drums')
      .replaceAll(
        RegExp(
          r'\[Drop\]\n\(Tonight\.\.\.\)\n\(Tonight\.\.\.\)',
          caseSensitive: false,
        ),
        '[Pre-Drop]\nTonight!\n\n[Drop]\n[Instrumental Drop]',
      )
      .replaceAll(
        RegExp(
          r"\[Final Drop\]\n\(Tonight\.\.\.\)\n\(We're infinite\.\.\.\)",
          caseSensitive: false,
        ),
        '[Pre-Drop]\nWe are infinite!\n\n[Final Drop]\n[Maximum Energy Instrumental Drop]',
      );

  out = _fixParenOnlyDropSections(out);
  out = out.replaceAll(RegExp(r'\n{3,}'), '\n\n').trim();
  return out;
}

String? _shoutFromParenLine(String line) {
  final m = RegExp(r'^\(([^)]+)\)\s*$').firstMatch(line.trim());
  if (m == null) return null;
  var text = m.group(1)!.trim();
  if (text.isEmpty) return null;
  text = text.replaceAll(RegExp(r'\.{2,}$'), '!');
  if (!RegExp(r'[!.?]$').hasMatch(text)) text = '$text!';
  return text;
}

bool _isDropHeader(String header) {
  final h = header.trim().toLowerCase();
  return h == 'drop' || h == 'final drop';
}

String _fixParenOnlyDropSections(String text) {
  final lines = text.split('\n');
  final out = <String>[];
  var i = 0;
  final sectionHeader = RegExp(r'^\[([^\]]+)\]\s*$');
  final parenOnly = RegExp(r'^\([^)]+\)\s*$');

  while (i < lines.length) {
    final line = lines[i];
    final headerMatch = sectionHeader.firstMatch(line.trim());
    if (headerMatch != null && _isDropHeader(headerMatch.group(1)!)) {
      final header = headerMatch.group(1)!.trim();
      final body = <String>[];
      i += 1;
      while (i < lines.length) {
        final next = lines[i];
        if (sectionHeader.hasMatch(next.trim())) break;
        if (next.trim().isNotEmpty) body.add(next);
        i += 1;
      }

      final onlyParens =
          body.isNotEmpty && body.every((l) => parenOnly.hasMatch(l.trim()));

      if (onlyParens) {
        final shout = _shoutFromParenLine(body.last);
        if (shout != null) {
          out.add('[Pre-Drop]');
          out.add(shout);
          out.add('');
        }
        out.add('[$header]');
        out.add(
          header.toLowerCase().contains('final')
              ? '[Maximum Energy Instrumental Drop]'
              : '[Instrumental Drop]',
        );
        continue;
      }

      out.add(line);
      out.addAll(body);
      continue;
    }

    out.add(line);
    i += 1;
  }

  return out.join('\n');
}

/// Splits unified V2 output into Block 2 prefix, body, and trailing suggestions.
(String prefix, String body, String suffix)? splitBlock2Parts(String raw) {
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

  final endMatch = RegExp(
    r'^(\s*\[End\]\s*)$',
    multiLine: true,
    caseSensitive: false,
  ).firstMatch(rest);

  if (endMatch != null) {
    final bodyEnd = endMatch.start;
    final body = '${rest.substring(0, bodyEnd).trimRight()}\n'
        '${rest.substring(endMatch.start, endMatch.end)}';
    final suffix = rest.substring(endMatch.end).trimLeft();
    return (prefix, body.trim(), suffix);
  }

  return (prefix, rest.trim(), '');
}

String mergeBlock2Parts(String prefix, String block2Body, String suffix) {
  final parts = <String>[prefix.trimRight(), block2Body.trim()];
  if (suffix.trim().isNotEmpty) {
    parts.add(suffix.trim());
  }
  return parts.join('\n\n');
}

/// Applies [normalizeLyricsForAudioEngine] to Block 2 only when present.
String applyAudioEngineNormalizationToSunoOutput(String fullText) {
  final parts = splitBlock2Parts(fullText);
  if (parts == null) return fullText;

  final (prefix, body, suffix) = parts;
  final normalized = normalizeLyricsForAudioEngine(body);
  if (normalized == body) return fullText;
  return mergeBlock2Parts(prefix, normalized, suffix);
}
