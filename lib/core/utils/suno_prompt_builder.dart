import 'genre_fx_matrix_data.dart';
import 'genre_key_resolver.dart';
import '../constants/genres_config.dart';

/// Result of [SunoPromptBuilder.buildSunoPrompt].
class SunoPromptBuildResult {
  const SunoPromptBuildResult({
    required this.prompt,
    required this.lyrics,
    required this.matchedGenreKey,
    required this.intensity,
  });

  final String prompt;
  final String lyrics;
  final String matchedGenreKey;
  final int intensity;
}

/// Suno AI Prompt & Arrangement Builder — genre-specific production FX by intensity.
class SunoPromptBuilder {
  SunoPromptBuilder._();

  static const _defaultKey = 'pop';

  static const _genreAliases = <String, String>{
    'big room': 'edm',
    'festival edm': 'edm',
    'future bass': 'edm',
    'future house': 'edm',
    'rawstyle': 'hardstyle',
    'euphoric hardstyle': 'hardstyle',
    'hard bounce': 'hardstyle',
    'hardstyle': 'hardstyle',
    'house': 'edm',
    'deep house': 'edm',
    'tech house': 'edm',
    'progressive house': 'edm',
    'melodic house': 'edm',
    'trance': 'edm',
    'uplifting trance': 'edm',
    'electro': 'edm',
    'edm bounce': 'edm',
    'hard techno': 'techno',
    'melodic techno': 'techno',
    'acid techno': 'techno',
    'minimal techno': 'techno',
    'big room techno': 'techno',
    'drum and bass': 'dnb',
    'liquid dnb': 'dnb',
    'neurofunk': 'dnb',
    'jungle': 'dnb',
    'synthwave': 'synthwave',
    'retrowave': 'synthwave',
    'vaporwave': 'synthwave',
    'melodic dubstep': 'dubstep',
    'riddim': 'dubstep',
    'brostep': 'dubstep',
    'dark ambient': 'ambient',
    'ambient score': 'ambient',
    'hip hop': 'hiphop',
    'boom bap': 'hiphop',
    'lo-fi hip hop': 'hiphop',
    'conscious hip hop': 'hiphop',
    'drill': 'trap',
    'uk drill': 'trap',
    'melodic trap': 'trap',
    'phonk': 'trap',
    'mainstream pop': 'pop',
    'electropop': 'pop',
    'dance pop': 'pop',
    'k-pop': 'pop',
    'j-pop': 'pop',
    'contemporary r&b': 'rnb',
    'neo-soul': 'rnb',
    'soul': 'rnb',
    'trap soul': 'rnb',
    'dembow': 'reggaeton',
    'indie rock': 'rock',
    'alt rock': 'rock',
    'alternative rock': 'rock',
    'hard rock': 'rock',
    'punk': 'rock',
    'heavy metal': 'metal',
    'metalcore': 'metal',
    'indie pop': 'indie',
    'bedroom pop': 'indie',
    'shoegaze': 'indie',
    'dream pop': 'indie',
    'post-rock': 'indie',
    'modern country': 'country',
    'americana': 'country',
    'bluegrass': 'country',
    'singer-songwriter': 'folk',
    'indie folk': 'folk',
    'amapiano': 'afrobeats',
    'afro house': 'afrobeats',
    'highlife': 'afrobeats',
    'vinahouse': 'afrobeats',
    'latin pop': 'latin',
    'salsa': 'latin',
    'bachata': 'latin',
    'bossa nova': 'latin',
    'cumbia': 'latin',
    'film score': 'cinematic',
    'orchestral': 'cinematic',
    'trailer': 'cinematic',
    'smooth jazz': 'jazz',
    'bebop': 'jazz',
    'vocal jazz': 'jazz',
    'jazz rap': 'hiphop',
  };

  static String resolveGenreKey(String primary, String fusion) {
    final extra = _genreAliases.entries
        .map((e) => (e.key, e.value))
        .toList(growable: false);
    return GenreKeyResolver.resolveKey(
      GenreFxMatrixData.profiles.keys,
      primary,
      fusion,
      defaultKey: _defaultKey,
      extraReplacements: extra,
      applyDefaultAliases: false,
    );
  }

  static bool _isInstrumental(String lyrics) {
    final t = lyrics.trim();
    if (t.isEmpty) return true;
    return t.toLowerCase() == '[instrumental]';
  }

  /// Removes genre-FX arrangement prefixes so re-applying intensity/lane is idempotent.
  static String stripFxLayout(String lyrics) {
    var out = lyrics;
    var changed = true;
    while (changed) {
      changed = false;
      for (final profile in GenreFxMatrixData.profiles.values) {
        for (final level in const ['1', '2', '3']) {
          final fx = (profile[level]?['lyrics'] ?? '').trim();
          if (fx.isNotEmpty && out.startsWith(fx)) {
            out = out.substring(fx.length).trimLeft();
            changed = true;
          }
        }
      }
    }
    return out;
  }

  /// Compiles FX into vibe + optional lyrics (server / on-device generation).
  static ({String vibe, String optionalLyrics}) applyGenreFxToInputs({
    required String vibe,
    required String optionalLyrics,
    required String genreFxLaneId,
    required String primaryGenre,
    required String fusionGenre,
    required int intensity,
  }) {
    final lane = genreFxLaneId.trim().isNotEmpty
        ? genreFxLaneId.trim().toLowerCase()
        : resolveGenreKey(primaryGenre, fusionGenre);
    final vibeTrim = vibe.trim();
    final lyricsTrim = stripFxLayout(optionalLyrics.trim());
    if (vibeTrim.isEmpty && lyricsTrim.isEmpty) {
      return (vibe: vibeTrim, optionalLyrics: lyricsTrim);
    }
    final built = buildSunoPrompt(
      baseStyle: vibeTrim,
      baseLyrics: lyricsTrim.isEmpty
          ? GenresConfig.fxLyricsAnchor(lane)
          : lyricsTrim,
      primaryGenre: lane,
      intensity: intensity,
    );
    return (
      vibe: vibeTrim.isNotEmpty ? built.prompt : vibeTrim,
      optionalLyrics: lyricsTrim.isNotEmpty ? built.lyrics : lyricsTrim,
    );
  }

  /// Builds style and lyrics payloads with genre FX for the given intensity (1–3).
  static SunoPromptBuildResult buildSunoPrompt({
    required String baseStyle,
    required String baseLyrics,
    required String primaryGenre,
    String fusionGenre = '',
    int intensity = 2,
  }) {
    var finalStyle = baseStyle.trim();
    var finalLyrics = baseLyrics.trim();
    final instrumental = _isInstrumental(finalLyrics);
    final targetIntensity = intensity.clamp(1, 3);
    final genreKey = resolveGenreKey(primaryGenre, fusionGenre);
    final profile = GenreFxMatrixData.profiles[genreKey];
    if (profile == null) {
      return SunoPromptBuildResult(
        prompt: finalStyle,
        lyrics: instrumental ? '[Instrumental]' : finalLyrics,
        matchedGenreKey: genreKey,
        intensity: targetIntensity,
      );
    }
    final levelKey = '$targetIntensity';
    final fx = profile[levelKey];
    if (fx == null) {
      return SunoPromptBuildResult(
        prompt: finalStyle,
        lyrics: instrumental ? '[Instrumental]' : finalLyrics,
        matchedGenreKey: genreKey,
        intensity: targetIntensity,
      );
    }
    final fxStyle = (fx['style'] ?? '').trim();
    final fxLyrics = fx['lyrics'] ?? '';
    if (fxStyle.isNotEmpty) {
      finalStyle = finalStyle.isEmpty ? fxStyle : '$finalStyle, $fxStyle';
    }
    if (fxLyrics.trim().isNotEmpty) {
      if (instrumental) {
        finalLyrics = '${fxLyrics.trim()}\n[Instrumental]';
      } else if (finalLyrics.contains('[Drop]')) {
        finalLyrics = finalLyrics.replaceFirst(
          '[Drop]',
          '${fxLyrics.trim()}\n[Drop]',
        );
      } else if (finalLyrics.contains('[Monologue]')) {
        finalLyrics = finalLyrics.replaceFirst(
          '[Monologue]',
          '${fxLyrics.trim()}\n[Monologue]',
        );
      } else if (finalLyrics.contains('[Chorus]')) {
        finalLyrics = finalLyrics.replaceFirst(
          '[Chorus]',
          '${fxLyrics.trim()}\n[Chorus]',
        );
      } else {
        finalLyrics = '${fxLyrics.trim()}$finalLyrics';
      }
    } else if (instrumental) {
      finalLyrics = '[Instrumental]';
    }
    return SunoPromptBuildResult(
      prompt: finalStyle,
      lyrics: finalLyrics,
      matchedGenreKey: genreKey,
      intensity: targetIntensity,
    );
  }

  /// Runtime user-block injection for Music Director prompt generation.
  static String userBlockDirective({
    required String primaryGenre,
    String subGenreFusion = '',
    required int intensity,
    String baseStyle = '',
    String baseLyrics = '',
  }) {
    final clamped = intensity.clamp(1, 3);
    final built = buildSunoPrompt(
      baseStyle: baseStyle,
      baseLyrics: baseLyrics,
      primaryGenre: primaryGenre,
      fusionGenre: subGenreFusion,
      intensity: clamped,
    );
    final label = switch (clamped) {
      1 => 'Low',
      2 => 'Medium',
      3 => 'High',
      _ => 'Medium',
    };
    final lines = <String>[
      'GENRE FX MATRIX (Suno Prompt Builder — production FX by intensity):',
      'Intensity: $clamped ($label) · Matched lane: [${built.matchedGenreKey}]',
    ];
    if (built.prompt.isNotEmpty) {
      lines.add(
        'Block 1 — weave these production FX clauses into producer prose (comma-linked, within SECTION 0 caps): ${built.prompt}',
      );
    }
    if (built.lyrics.trim().isNotEmpty) {
      lines.add(
        'Block 2 — insert these arrangement section tags at the first [Drop] or [Chorus] anchor (or before main hook sections); evolve staging per ARRANGEMENT STAGING FORMAT:',
      );
      lines.add(built.lyrics.trim());
    } else {
      lines.add(
        'Block 2 — intensity $clamped: no extra FX section tags for this lane; keep genre-native structure.',
      );
    }
    lines.add(
      'Do not paste this matrix header into user-visible output — apply silently inside BLOCK 1 + BLOCK 2.',
    );
    return lines.join('\n');
  }

  /// Mirrors server `_genre_fx_preservation_line` after pre-compiled FX in vibe/lyrics.
  static String genreFxPreservationDirective({
    required String genreFxLaneId,
    required String primaryGenre,
    String subGenreFusion = '',
    required int intensity,
  }) {
    final lane = genreFxLaneId.trim().isNotEmpty
        ? genreFxLaneId.trim().toLowerCase()
        : resolveGenreKey(primaryGenre, subGenreFusion);
    final clamped = intensity.clamp(1, 3);
    return 'GENRE FX: lane [$lane] at intensity $clamped — production clauses in VIBE '
        'and arrangement tags in USER LYRICS are pre-compiled. Preserve bracket scaffolding, '
        'evolve staging per ARRANGEMENT STAGING FORMAT, and do not duplicate FX blocks.';
  }
}
