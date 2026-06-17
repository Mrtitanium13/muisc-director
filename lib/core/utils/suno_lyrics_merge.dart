/// Builds one Suno **Lyrics** field paste: section order from [structureBody]
/// (bracket lines only) merged with lyric lines from [lyricsBody].
///
/// Parenthetical staging lines from structure are omitted. If structure has no
/// bracket headers, returns trimmed [lyricsBody] only.
String? mergedSunoLyricsForPaste({
  String? structureBody,
  String? lyricsBody,
}) {
  final lyrics = lyricsBody?.trim() ?? '';
  if (lyrics.isEmpty) return null;

  final structHeaders = _extractBracketHeaders(structureBody);
  if (structHeaders.isEmpty) return lyrics;

  final lyricBlocks = _parseBracketSections(lyrics);
  if (lyricBlocks.isEmpty) return lyrics;

  // Lyrics already follow the same opening section and cover the roadmap — use as-is.
  if (lyricBlocks.length >= structHeaders.length &&
      _normHeader(lyricBlocks.first.header) ==
          _normHeader(structHeaders.first)) {
    var allMatch = true;
    for (var i = 0; i < structHeaders.length; i++) {
      if (_normHeader(lyricBlocks[i].header) != _normHeader(structHeaders[i])) {
        allMatch = false;
        break;
      }
    }
    if (allMatch) return lyrics;
  }

  final out = StringBuffer();
  var lj = 0;

  for (final h in structHeaders) {
    out.writeln(h);
    final idx = _indexOfMatchingBlock(lyricBlocks, lj, h);
    if (idx != null) {
      for (final line in lyricBlocks[idx].lines) {
        if (_isStagingParentheticalLine(line)) continue;
        out.writeln(line);
      }
      lj = idx + 1;
    }
    out.writeln();
  }

  while (lj < lyricBlocks.length) {
    out.writeln(lyricBlocks[lj].header);
    for (final line in lyricBlocks[lj].lines) {
      if (_isStagingParentheticalLine(line)) continue;
      out.writeln(line);
    }
    out.writeln();
    lj++;
  }

  return out.toString().trim();
}

String _normHeader(String h) =>
    h.toLowerCase().replaceAll(RegExp(r'\s+'), '');

bool _isStagingParentheticalLine(String line) {
  final t = line.trim();
  if (t.isEmpty) return false;
  return t.startsWith('(');
}

List<String> _extractBracketHeaders(String? text) {
  if (text == null || text.trim().isEmpty) return [];
  final re = RegExp(r'^\[[^\]]+\]$');
  return text
      .split('\n')
      .map((l) => l.trim())
      .where(re.hasMatch)
      .toList();
}

class _SectionBlock {
  _SectionBlock(this.header, this.lines);
  final String header;
  final List<String> lines;
}

List<_SectionBlock> _parseBracketSections(String text) {
  final out = <_SectionBlock>[];
  final lines = text.split('\n');
  String? currentHeader;
  final buf = <String>[];

  void flush() {
    final h = currentHeader;
    if (h != null) {
      out.add(_SectionBlock(h, List<String>.from(buf)));
      buf.clear();
    }
  }

  final headerRe = RegExp(r'^\[[^\]]+\]$');
  for (final line in lines) {
    final t = line.trim();
    if (headerRe.hasMatch(t)) {
      flush();
      currentHeader = t;
    } else if (currentHeader != null) {
      buf.add(line);
    }
  }
  flush();
  return out;
}

int? _indexOfMatchingBlock(
  List<_SectionBlock> blocks,
  int startFrom,
  String structureHeader,
) {
  final want = _normHeader(structureHeader);
  for (var i = startFrom; i < blocks.length; i++) {
    if (_normHeader(blocks[i].header) == want) return i;
  }
  return null;
}
