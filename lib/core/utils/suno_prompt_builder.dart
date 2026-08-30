import 'package:flutter/foundation.dart';

import 'genre_fx_matrix_data.dart';
import 'genre_key_resolver.dart';
import '../constants/genres_config.dart';
import '../suno_prompt_router.dart';
import '../constants/song_structure_data.dart';

/// Result of [SunoPromptBuilder.buildSunoPrompt].
@immutable
final class SunoPromptBuildResult {
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

  @override
  String toString() =>
      'SunoPromptBuildResult($matchedGenreKey@$intensity, ${prompt.length} chars)';
}

/// Suno AI Prompt & Arrangement Builder — genre-specific production FX by intensity.
abstract final class SunoPromptBuilder {
  SunoPromptBuilder._();

  static const String _defaultKey = 'pop';

  /// Map of free-form user genre labels → canonical [GenreFxMatrixData] lane key.
  static const Map<String, String> _genreAliases = {
    // EDM / electronic
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
    'nu-disco': 'edm',
    'future funk': 'edm',
    'disco house': 'edm',
    'uk garage': 'edm',
    'soulful house': 'edm',
    'hard techno': 'techno',
    'melodic techno': 'techno',
    'acid techno': 'techno',
    'minimal techno': 'techno',
    'big room techno': 'techno',
    'techno': 'techno',
    'drum and bass': 'dnb',
    'drum & bass': 'dnb',
    'liquid dnb': 'dnb',
    'neurofunk': 'dnb',
    'jungle': 'dnb',
    'dnb': 'dnb',
    'synthwave': 'synthwave',
    'retrowave': 'synthwave',
    'vaporwave': 'synthwave',
    'new wave': 'synthwave',
    'melodic dubstep': 'dubstep',
    'riddim': 'dubstep',
    'brostep': 'dubstep',
    'dubstep': 'dubstep',
    'dark ambient': 'ambient',
    'ambient score': 'ambient',
    'ambient': 'ambient',
    'hyperpop': 'pop',
    'digicore': 'pop',
    'idm': 'ambient',
    'glitch': 'ambient',
    'industrial': 'techno',
    'industrial metal': 'metal',
    'industrial rock': 'rock',
    'ebm': 'techno',
    'breakcore': 'dnb',
    'witch house': 'ambient',
    'experimental': 'ambient',
    'modular': 'ambient',
    'electronic_experimental': 'ambient',
    // Hip-hop
    'hip hop': 'hiphop',
    'hip-hop': 'hiphop',
    'boom bap': 'boom_bap',
    'lo-fi hip hop': 'hiphop',
    'conscious hip hop': 'hiphop',
    'underground hip hop': 'hiphop',
    'jazz rap': 'boom_bap',
    'chillhop': 'hiphop',
    'cloud rap': 'hiphop',
    'afro rap': 'hiphop',
    'drill': 'trap',
    'uk drill': 'trap',
    'ny drill': 'trap',
    'melodic trap': 'trap',
    'phonk': 'trap',
    'trap': 'trap',
    'rage': 'hiphop',
    'jersey club': 'hiphop',
    'memphis rap': 'boom_bap',
    // Pop
    'mainstream pop': 'pop',
    'electropop': 'pop',
    'dance pop': 'pop',
    'pop / max martin': 'pop',
    'k-pop': 'pop',
    'j-pop': 'pop',
    'c-pop': 'mandopop',
    'mandopop': 'mandopop',
    'indie pop': 'indie',
    'bedroom pop': 'indie',
    'dream pop': 'indie',
    'post-rock': 'indie',
    'synth pop': 'pop',
    // R&B / soul / funk
    'contemporary r&b': 'rnb',
    'contemporary rnb': 'rnb',
    'contemporary r and b': 'rnb',
    '90s r&b': 'rnb',
    '90s rnb': 'rnb',
    '90s r and b': 'rnb',
    'r&b': 'rnb',
    'rnb': 'rnb',
    'r and b': 'rnb',
    'neo-soul': 'rnb',
    'neo soul': 'rnb',
    'soul': 'rnb',
    'trap soul': 'rnb',
    'quiet storm': 'rnb',
    'new jack swing': 'rnb',
    'funk': 'rnb',
    'p-funk': 'rnb',
    'gogo': 'rnb',
    'motown': 'rnb',
    // Rock / metal
    'indie rock': 'rock',
    'alt rock': 'rock',
    'alternative rock': 'rock',
    'alternative': 'rock',
    'classic rock': 'rock',
    'hard rock': 'rock',
    'punk': 'rock',
    'pop punk': 'rock',
    'emo': 'rock',
    'grunge': 'rock',
    'shoegaze': 'indie',
    'britpop': 'rock',
    'heavy metal': 'metal',
    'death metal': 'metal',
    'metalcore': 'metal',
    'metal': 'metal',
    // Country / folk
    'modern country': 'country',
    'outlaw country': 'country',
    'americana': 'country',
    'bluegrass': 'country',
    'sertanejo': 'country',
    'country': 'country',
    'singer-songwriter': 'folk',
    'indie folk': 'folk',
    'folk-rock': 'folk',
    'folk rock': 'folk',
    'folk': 'folk',
    // Afro / global
    'amapiano': 'amapiano',
    'amapiano-vinahouse': 'amapiano',
    'afro house': 'amapiano',
    'vinahouse': 'amapiano',
    'gqom': 'amapiano',
    'highlife': 'afrobeats',
    'afrobeats': 'afrobeats',
    'afro-swing': 'afrobeats',
    'fuji': 'afrobeats',
    'bongo flava': 'afrobeats',
    'gengetone': 'afrobeats',
    'azonto': 'afrobeats',
    // South Asian / MENA → world lane
    'bollywood': 'world',
    'filmi': 'world',
    'punjabi': 'world',
    'bhangra': 'world',
    'middle eastern': 'world',
    'city pop': 'pop',
    // Worship / gospel
    'praise and worship': 'worship',
    'praise/worship': 'worship',
    'contemporary gospel': 'worship',
    'traditional gospel': 'worship',
    'urban gospel': 'worship',
    'gospel': 'worship',
    'modern worship': 'worship',
    'worship ballad': 'worship',
    'pop worship': 'worship',
    'afro-gospel': 'worship',
    'southern gospel': 'worship',
    'country gospel': 'worship',
    'ccm': 'worship',
    // Latin / Caribbean
    'latin pop': 'latin',
    'salsa': 'latin',
    'bachata': 'latin',
    'bossa nova': 'latin',
    'cumbia': 'latin',
    'dembow': 'reggaeton',
    'reggaeton': 'reggaeton',
    'latin trap': 'reggaeton',
    'baile funk': 'latin',
    'brazilian funk': 'latin',
    'forró': 'latin',
    'forro': 'latin',
    'perreo': 'latin',
    'guaracha': 'latin',
    'champeta': 'latin',
    'moombahton': 'latin',
    'soca': 'latin',
    'calypso': 'latin',
    'merengue': 'latin',
    'vallenato': 'latin',
    'tango': 'latin',
    'reggae': 'reggae',
    'roots reggae': 'reggae',
    'dub': 'reggae',
    'ska': 'reggae',
    'rocksteady': 'reggae',
    'dancehall': 'reggaeton',
    // Cinematic / jazz / experimental electronic
    'film score': 'cinematic',
    'orchestral': 'cinematic',
    'trailer': 'cinematic',
    'cinematic': 'cinematic',
    'smooth jazz': 'jazz',
    'bebop': 'jazz',
    'vocal jazz': 'jazz',
    'jazz fusion': 'jazz',
    'fusion': 'jazz',
    'nu-jazz': 'jazz',
    'acid jazz': 'jazz',
    'big band': 'jazz',
    'jazz': 'jazz',
    'latin jazz': 'jazz',
    // Blues → jazz lane (no dedicated blues matrix family)
    'blues': 'jazz',
    'delta blues': 'jazz',
    'chicago blues': 'jazz',
    'electric blues': 'jazz',
  };

  static final Set<String> _fxLyricsLines = _precomputeFxLyricsLines();

  static Set<String> _precomputeFxLyricsLines() {
    final out = <String>{};
    for (final profile in GenreFxMatrixData.profiles.values) {
      for (final level in const ['1', '2', '3']) {
        final fx = (profile[level]?['lyrics'] ?? '').toString().trim();
        if (fx.isEmpty) continue;
        for (final line in fx.split('\n')) {
          final trimmed = line.trim();
          if (trimmed.isNotEmpty) out.add(trimmed);
        }
      }
    }
    return out;
  }

  /// Resolves a primary + fusion genre pair to a canonical FX lane key.
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
    );
  }

  static bool _isInstrumental(String lyrics) {
    final t = lyrics.trim();
    if (t.isEmpty) return true;
    return t.toLowerCase() == '[instrumental]';
  }

  static bool _isFxOnlyHeadLine(String trimmed) {
    if (!_fxLyricsLines.contains(trimmed)) return false;
    if (trimmed.startsWith('[') &&
        trimmed.endsWith(']') &&
        !trimmed.contains(':')) {
      final inner = trimmed.substring(1, trimmed.length - 1).trim().toLowerCase();
      const bareStructural = {
        'chorus',
        'hook',
        'verse',
        'drop',
        'bridge',
        'intro',
        'outro',
        'monologue',
        'solo',
        'breakdown',
        'build',
        'build-up',
        'build up',
        'climax',
        'coda',
        'pre-chorus',
        'pre chorus',
        'end',
      };
      if (bareStructural.contains(inner)) return false;
    }
    return true;
  }

  /// Removes genre-FX arrangement prefixes so re-applying intensity/lane is idempotent.
  static String stripFxLayout(String lyrics) {
    if (lyrics.isEmpty) return lyrics;
    final lines = lyrics.split('\n');
    final out = <String>[];
    var strippingHead = true;
    for (final line in lines) {
      if (strippingHead) {
        final t = line.trim();
        if (t.isEmpty) continue;
        if (_isFxOnlyHeadLine(t)) continue;
        strippingHead = false;
      }
      out.add(line);
    }
    return out.join('\n');
  }

  /// FX arrangement head only (everything [stripFxLayout] would remove).
  static String extractFxLayout(String lyrics) {
    if (lyrics.isEmpty) return '';
    final lines = lyrics.split('\n');
    final fx = <String>[];
    for (final line in lines) {
      final t = line.trim();
      if (t.isEmpty) {
        if (fx.isNotEmpty) fx.add(line);
        continue;
      }
      if (_isFxOnlyHeadLine(t)) {
        fx.add(line);
        continue;
      }
      break;
    }
    return fx.join('\n').trimRight();
  }

  /// Preview of lane+intensity FX tags (no user lyric body).
  static String fxLayoutPreview({
    required String primaryGenre,
    String fusionGenre = '',
    int intensity = 2,
    String sunoVersion = 'v4.5',
  }) {
    final lane = resolveGenreKey(primaryGenre, fusionGenre);
    final built = buildSunoPrompt(
      baseStyle: '',
      baseLyrics: GenresConfig.fxLyricsAnchor(lane),
      primaryGenre: lane,
      fusionGenre: fusionGenre,
      intensity: intensity,
      sunoVersion: sunoVersion,
    );
    return extractFxLayout(built.lyrics);
  }

  static List<String> _anchorsForFamily(String family) =>
      GenresConfig.canonicalAnchorsForFamily(family);

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
    String sunoVersion = 'v4.5',
  }) {
    var finalStyle = baseStyle.trim();
    var finalLyrics = baseLyrics.trim();
    final instrumental = _isInstrumental(finalLyrics);
    final targetIntensity = intensity.clamp(1, 3);
    final genreKey = resolveGenreKey(primaryGenre, fusionGenre);
    final profile = GenreFxMatrixData.profiles[genreKey];

    String fallbackLyrics() =>
        instrumental ? '[Instrumental]' : _stripVocalSpecBracketLines(finalLyrics);

    if (profile == null) {
      return SunoPromptBuildResult(
        prompt: finalStyle,
        lyrics: fallbackLyrics(),
        matchedGenreKey: genreKey,
        intensity: targetIntensity,
      );
    }

    final levelKey = '$targetIntensity';
    final fx = profile[levelKey];
    if (fx == null) {
      return SunoPromptBuildResult(
        prompt: finalStyle,
        lyrics: fallbackLyrics(),
        matchedGenreKey: genreKey,
        intensity: targetIntensity,
      );
    }

    final fxStyle = (fx['style'] ?? '').toString().trim();
    final fxLyrics = fx['lyrics'] ?? '';
    final refinementTags = SunoPromptRouterV2.styleTagsFor(
      primaryGenre: primaryGenre,
      subGenreFusion: fusionGenre,
      sunoVersion: sunoVersion,
    );

    if (fxStyle.isNotEmpty) {
      finalStyle = finalStyle.isEmpty ? fxStyle : '$finalStyle, $fxStyle';
    }
    if (refinementTags.isNotEmpty) {
      finalStyle =
          finalStyle.isEmpty ? refinementTags : '$finalStyle, $refinementTags';
    }

    if (fxLyrics.toString().trim().isNotEmpty) {
      final fxTrimmed = fxLyrics.toString().trim();
      if (instrumental) {
        finalLyrics = '$fxTrimmed\n[Instrumental]';
      } else {
        final anchors = _anchorsForFamily(genreKey);
        var injected = false;
        for (final anchor in anchors) {
          if (finalLyrics.contains(anchor)) {
            finalLyrics = finalLyrics.replaceFirst(
              anchor,
              '$fxTrimmed\n$anchor',
            );
            injected = true;
            break;
          }
        }
        if (!injected) {
          finalLyrics = '$fxTrimmed\n$finalLyrics';
        }
      }
    } else if (instrumental) {
      finalLyrics = '[Instrumental]';
    }

    finalLyrics = _stripVocalSpecBracketLines(finalLyrics);
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
      'Apply these FX silently inside BLOCK 1 producer prose + BLOCK 2 arrangement scaffolding. Never surface matrix labels in user-visible output.',
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

  /// Vocal-spec selections (e.g. "Intimate Male Vocal") belong in Block 1
  /// producer prose — never as standalone bracket section lines in Block 2.
  static String _stripVocalSpecBracketLines(String lyrics) {
    if (lyrics.isEmpty) return lyrics;
    final lines = lyrics.split('\n');
    final out = <String>[];
    for (final line in lines) {
      final t = line.trim();
      if (t.startsWith('[') && t.endsWith(']') && !t.contains(':')) {
        final inner = t.substring(1, t.length - 1).trim();
        if (_looksLikeVocalSpecBracket(inner) &&
            !SongStructureData.isCanonicalSection(inner)) {
          continue;
        }
      }
      out.add(line);
    }
    return out.join('\n');
  }

  static bool _looksLikeVocalSpecBracket(String inner) {
    final lower = inner.toLowerCase();
    const markers = [
      'intimate male vocal',
      'whispered male vocal',
      'building intensity',
      'male vocal',
      'female vocal',
      'male lead',
      'female lead',
      'rap vocal',
      'vocal chants',
      'unison stacks',
      'instrumental only',
    ];
    return markers.any(lower.contains);
  }
}
