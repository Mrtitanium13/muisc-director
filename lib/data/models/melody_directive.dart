/// Defines WHERE melody tokens should be applied.
enum MelodyPlacement {
  /// Tokens go directly into Suno's Style Prompt.
  stylePrompt,

  /// Tokens are used as lyric bracket modifiers.
  bracketModifier,

  /// Structural change to lyrics, not a style tag.
  structural,
}

/// A single melody preset directive with genre-aware prompt tokens.
class MelodyDirective {
  final String id;
  final String label;
  final String description;

  /// Genre-family key → style-prompt phrase (e.g. `edm`, `hiphop`, `worship`).
  final Map<String, String> genreTokens;

  /// Fallback when [genreFamily] is absent or not in [genreTokens].
  final String defaultToken;

  /// Legacy/auxiliary tokens (e.g. call/response parenthetical hints).
  final List<String> tokens;
  final MelodyPlacement placement;

  const MelodyDirective({
    required this.id,
    required this.label,
    required this.description,
    this.genreTokens = const {},
    this.defaultToken = '',
    this.tokens = const [],
    this.placement = MelodyPlacement.stylePrompt,
  });

  /// Resolves the best style-prompt token for a vibe genre family key.
  String getTokenForGenre(String? genreFamily) {
    if (genreFamily == null || genreFamily.trim().isEmpty) {
      return defaultToken;
    }
    final key = _normalizeFamilyKey(genreFamily);
    return genreTokens[key] ?? defaultToken;
  }

  /// Maps [GenreFamily] / FX-lane aliases onto melody token keys.
  static String _normalizeFamilyKey(String genreFamily) {
    final key = genreFamily.trim().toLowerCase();
    return switch (key) {
      'gospel' || 'worship' => 'worship',
      'r&b' || 'rnb' || 'soul' || 'neo-soul' || 'neo_soul' => 'rnb',
      'funk' => 'funk',
      'blues' => 'blues',
      'reggae' || 'dub' || 'dancehall' => 'reggae',
      'dnb' || 'drum and bass' || 'drum_and_bass' => 'dnb',
      'hardstyle' || 'rawstyle' => 'hardstyle',
      'techno' => 'techno',
      'synthwave' || 'retrowave' || 'vaporwave' => 'synthwave',
      'dubstep' || 'riddim' => 'dubstep',
      'ambient' || 'electronic_experimental' || 'experimental' => 'ambient',
      'trap' || 'drill' || 'phonk' => 'trap',
      'boom_bap' || 'boombap' => 'hiphop',
      'reggaeton' || 'dembow' => 'reggaeton',
      'metal' || 'metalcore' => 'metal',
      'indie' || 'indie_rock' => 'indie',
      'mandopop' || 'c-pop' || 'c_pop' => 'mandopop',
      'world' || 'bollywood' || 'bhangra' || 'middle eastern' => 'world',
      'folk' || 'americana_folk' => 'folk',
      'latin' || 'salsa' || 'bachata' => 'latin',
      'cinematic' || 'film_score' || 'orchestral' => 'cinematic',
      'country' => 'country',
      'jazz' => 'jazz',
      'rock' => 'rock',
      'pop' => 'pop',
      'hiphop' || 'hip-hop' || 'hip hop' => 'hiphop',
      'amapiano' => 'amapiano',
      'afrobeats' || 'afrobeat' => 'afrobeats',
      'edm' || 'house' || 'trance' => 'edm',
      _ => key,
    };
  }
}
