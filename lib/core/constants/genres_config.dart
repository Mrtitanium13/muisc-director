import '../utils/genre_fx_matrix_data.dart';
import '../utils/suno_prompt_builder.dart';

/// Engine family for FX lane routing (anti-artifact factory + melody auto-mode).
enum EngineFamily {
  electronic,
  rockMetal,
  hiphopPop,
  acousticOrchestral,
}

extension EngineFamilyConfigKey on EngineFamily {
  String get configKey => switch (this) {
        EngineFamily.electronic => 'electronic',
        EngineFamily.rockMetal => 'rock_metal',
        EngineFamily.hiphopPop => 'hiphop_pop',
        EngineFamily.acousticOrchestral => 'acoustic_orchestral',
      };
}

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
      label: 'Hip-Hop / Rap',
      category: 'Urban',
    ),
    AppSupportedGenre(
      id: 'trap',
      label: 'Trap / Drill',
      category: 'Urban',
    ),
    AppSupportedGenre(
      id: 'boom_bap',
      label: 'Boom Bap / Old School Hip-Hop',
      category: 'Urban',
    ),
    AppSupportedGenre(
      id: 'reggaeton',
      label: 'Reggaeton / Dembow',
      category: 'Urban',
    ),
    AppSupportedGenre(
      id: 'rnb',
      label: 'R&B / Neo-Soul',
      category: 'Urban',
    ),
    AppSupportedGenre(
      id: 'pop',
      label: 'Mainstream Pop',
      category: 'Pop',
    ),
    AppSupportedGenre(
      id: 'mandopop',
      label: 'Mandopop / C-Pop',
      category: 'Pop',
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
      label: 'Afrobeats / Afro-Pop',
      category: 'World',
    ),
    AppSupportedGenre(
      id: 'amapiano',
      label: 'Amapiano / Log Drum',
      category: 'World',
    ),
    AppSupportedGenre(
      id: 'latin',
      label: 'Latin Jazz / Salsa',
      category: 'World',
    ),
    AppSupportedGenre(
      id: 'world',
      label: 'World / Bollywood / MENA',
      category: 'World',
    ),
    AppSupportedGenre(
      id: 'reggae',
      label: 'Reggae / Dub',
      category: 'World',
    ),
    AppSupportedGenre(
      id: 'cinematic',
      label: 'Cinematic Film Score',
      category: 'Other',
    ),
    AppSupportedGenre(
      id: 'worship',
      label: 'Worship / Gospel',
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

  /// All canonical anchors for a family's FX injection points, in priority
  /// order. Without `[Tag]\n` suffixes — for injection logic that needs
  /// to check multiple anchors.
  static List<String> canonicalAnchorsForFamily(String laneId) {
    return GenreFxMatrixData.getAnchors(family: laneId);
  }

  /// Primary canonical anchor for a family's FX injection point in Block 2.
  /// Returns the first `[Tag]\n` form (with trailing newline).
  static String fxLyricsAnchor(String laneId) {
    final anchors = canonicalAnchorsForFamily(laneId);
    return '${anchors.first}\n';
  }

  static List<String> categoriesInOrder() {
    final seen = <String>{};
    final out = <String>[];
    for (final g in appSupportedGenres) {
      if (seen.add(g.category)) out.add(g.category);
    }
    return out;
  }

  /// GenresConfig lane category → EngineConfig family (Refinement v3.0).
  static EngineFamily? engineFamilyForCategory(String category) {
    return switch (category) {
      'Electronic' => EngineFamily.electronic,
      'Urban' || 'Pop' => EngineFamily.hiphopPop,
      'Rock' => EngineFamily.rockMetal,
      'Traditional' || 'World' || 'Other' => EngineFamily.acousticOrchestral,
      _ => null,
    };
  }

  static EngineFamily? engineFamilyForLaneId(String laneId) {
    final genre = byId(laneId.trim().toLowerCase());
    if (genre == null) return null;
    return engineFamilyForCategory(genre.category);
  }

  /// Representative FX lane id for an engine family.
  static String laneForFamily(EngineFamily family) {
    return switch (family) {
      EngineFamily.electronic => 'edm',
      EngineFamily.hiphopPop => 'hiphop',
      EngineFamily.rockMetal => 'rock',
      EngineFamily.acousticOrchestral => 'cinematic',
    };
  }
}
