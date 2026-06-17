import '../utils/suno_prompt_builder.dart';

/// UI + API genre lane aligned to [tools/genre_fx_matrix.json].
class AppSupportedGenre {
  const AppSupportedGenre({
    required this.id,
    required this.label,
    required this.category,
  });

  final String id;
  final String label;
  final String category;
}

/// Front-end config for FX matrix genre picker (mirrors genresConfig.js).
class GenresConfig {
  GenresConfig._();

  /// Empty id = auto-resolve from primary / fusion genre.
  static const String autoLaneId = '';

  static const List<AppSupportedGenre> appSupportedGenres = [
    AppSupportedGenre(
      id: 'edm',
      label: 'EDM / Progressive House',
      category: 'Electronic',
    ),
    AppSupportedGenre(
      id: 'hardstyle',
      label: 'Hardstyle / Rawstyle',
      category: 'Electronic',
    ),
    AppSupportedGenre(
      id: 'techno',
      label: 'Techno / Industrial',
      category: 'Electronic',
    ),
    AppSupportedGenre(
      id: 'dnb',
      label: 'Drum & Bass',
      category: 'Electronic',
    ),
    AppSupportedGenre(
      id: 'synthwave',
      label: 'Synthwave / Retro',
      category: 'Electronic',
    ),
    AppSupportedGenre(
      id: 'dubstep',
      label: 'Dubstep / Riddim',
      category: 'Electronic',
    ),
    AppSupportedGenre(
      id: 'ambient',
      label: 'Ambient / Soundscape',
      category: 'Electronic',
    ),
    AppSupportedGenre(
      id: 'hiphop',
      label: 'Hip-Hop / Boom Bap',
      category: 'Urban',
    ),
    AppSupportedGenre(
      id: 'trap',
      label: 'Trap / Drill',
      category: 'Urban',
    ),
    AppSupportedGenre(
      id: 'pop',
      label: 'Mainstream Pop',
      category: 'Urban',
    ),
    AppSupportedGenre(
      id: 'rnb',
      label: 'R&B / Neo-Soul',
      category: 'Urban',
    ),
    AppSupportedGenre(
      id: 'reggaeton',
      label: 'Reggaeton / Dembow',
      category: 'Urban',
    ),
    AppSupportedGenre(
      id: 'rock',
      label: 'Alternative / Classic Rock',
      category: 'Rock',
    ),
    AppSupportedGenre(
      id: 'metal',
      label: 'Metal / Djent',
      category: 'Rock',
    ),
    AppSupportedGenre(
      id: 'indie',
      label: 'Indie / Garage Rock',
      category: 'Rock',
    ),
    AppSupportedGenre(
      id: 'country',
      label: 'Modern Country',
      category: 'Traditional',
    ),
    AppSupportedGenre(
      id: 'folk',
      label: 'Indie Folk / Acoustic',
      category: 'Traditional',
    ),
    AppSupportedGenre(
      id: 'afrobeats',
      label: 'Afrobeats / Amapiano',
      category: 'World',
    ),
    AppSupportedGenre(
      id: 'latin',
      label: 'Latin Jazz / Salsa',
      category: 'World',
    ),
    AppSupportedGenre(
      id: 'cinematic',
      label: 'Cinematic Film Score',
      category: 'Other',
    ),
    AppSupportedGenre(
      id: 'jazz',
      label: 'Jazz / Classic Swing',
      category: 'Other',
    ),
  ];

  static AppSupportedGenre? byId(String id) {
    final key = id.trim().toLowerCase();
    if (key.isEmpty) return null;
    for (final g in appSupportedGenres) {
      if (g.id == key) return g;
    }
    return null;
  }

  static String resolveLaneId(String primaryGenre, String fusionGenre) {
    return SunoPromptBuilder.resolveGenreKey(primaryGenre, fusionGenre);
  }

  static String effectiveLaneId({
    required String genreFxLaneId,
    required String primaryGenre,
    required String fusionGenre,
  }) {
    final manual = genreFxLaneId.trim().toLowerCase();
    if (manual.isNotEmpty && byId(manual) != null) return manual;
    return resolveLaneId(primaryGenre, fusionGenre);
  }

  static String fxLyricsAnchor(String laneId) {
    if (laneId.trim().toLowerCase() == 'hardstyle') {
      return '[Monologue]\n';
    }
    return '[Chorus]\n';
  }

  static List<String> categoriesInOrder() {
    final seen = <String>{};
    final out = <String>[];
    for (final g in appSupportedGenres) {
      if (seen.add(g.category)) out.add(g.category);
    }
    return out;
  }
}
