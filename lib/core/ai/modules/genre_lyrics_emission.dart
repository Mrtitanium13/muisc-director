/// Whether a genre family expects lyric output (vs instrumental / vocalese-rare).
class GenreLyricsEmission {
  GenreLyricsEmission._();

  /// Exact labels treated as instrumental-first (no human-voice / lyric QA).
  /// Short tokens use exact match so "melodic techno" still gets human voice.
  static const _instrumentalExact = {
    'orchestral',
    'ambient',
    'dark ambient',
    'ambient score',
    'post-rock',
    'post rock',
    'dub',
    'techno',
    'minimal',
    'film score',
    'instrumental',
  };

  static const _instrumentalPhrases = [
    'ambient score',
    'dark ambient',
    'post-rock',
    'post rock',
    'film score',
  ];

  /// True when human-voice directive + lyric QA apply.
  static bool emitsLyrics(String genre) {
    final g = genre.toLowerCase().trim();
    if (g.isEmpty) return true;
    if (_instrumentalExact.contains(g)) return false;
    return !_instrumentalPhrases.any(g.contains);
  }
}
