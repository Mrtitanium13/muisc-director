import '../constants/suno_version.dart';
import 'genre_key_resolver.dart';
import 'drum_matrix_data.dart';

/// Genre drum profiles for Block 2 staging hints (tools/drum_matrix.json).
class DrumProfile {
  const DrumProfile({
    required this.kit,
    required this.pattern,
    required this.mix,
    required this.negative,
  });

  final String kit;
  final String pattern;
  final String mix;
  final String negative;
}

class DrumMatrix {
  DrumMatrix._();

  static const _defaultKey = 'pop';

  static const _genreAliases = <String, String>{
    'liquid dnb': 'drum and bass',
    'drum & bass': 'drum and bass',
    'dnb': 'drum and bass',
    'neurofunk': 'drum and bass',
    'jungle': 'drum and bass',
    'melodic techno': 'melodic techno',
    'hard techno': 'hard techno',
    'tech house': 'tech house',
    'deep house': 'deep house',
    'progressive house': 'progressive house',
    'praise and worship': 'praise and worship',
    'praise/worship': 'praise and worship',
    'worship': 'praise and worship',
    'contemporary gospel': 'contemporary gospel',
    'gospel': 'contemporary gospel',
    'lo-fi hip hop': 'lo-fi hip hop',
    'hiphop': 'hip hop',
    'hip-hop': 'hip hop',
    'boom bap': 'boom bap',
    'boom_bap': 'boom bap',
    'uk drill': 'uk drill',
    'vinahouse': 'vinahouse',
    'amapiano': 'amapiano',
    'neo-soul': 'neo-soul',
    'contemporary r&b': 'contemporary r&b',
    'rnb': 'contemporary r&b',
    'heavy metal': 'heavy metal',
    'metal': 'heavy metal',
    'djent': 'heavy metal',
    'indie rock': 'indie rock',
    'indie': 'indie rock',
    'garage rock': 'indie rock',
    'classic rock': 'rock',
    'alternative rock': 'rock',
    'modern country': 'modern country',
    'country': 'modern country',
    'indie folk': 'folk',
    'acoustic': 'folk',
    'shoegaze': 'shoegaze',
    'hard bounce': 'hard bounce',
    'hardstyle': 'hardstyle',
    'future bass': 'future bass',
    'edm': 'edm bounce',
    'edm bounce': 'edm bounce',
    'big room techno': 'big room techno',
    'cloud rap': 'cloud rap',
    'hyperpop': 'hyperpop',
    'jazz rap': 'jazz rap',
    'kpop': 'k-pop',
    'nu-disco': 'house',
    'bossa nova': 'jazz',
    'blues': 'jazz',
    'drill': 'uk drill',
    'grime': 'uk drill',
    'ny drill': 'uk drill',
    'trap / drill': 'trap',
    'trap/drill': 'trap',
    'trap drill': 'trap',
    'afro-swing': 'afrobeats',
    'synth pop': 'synth-pop',
    'big room': 'big room techno',
    'future rave': 'big room techno',
    'jersey club': 'edm bounce',
    'brazilian funk': 'trap',
    'salsa': 'latin',
    'latin jazz': 'latin',
    'bachata': 'latin',
    'bollywood': 'world',
    'mena': 'world',
    'synth wave': 'synthwave',
    'retrowave': 'synthwave',
    'film score': 'cinematic',
    'orchestral': 'cinematic',
    'trailer': 'trailer',
  };

  static ({String key, DrumProfile profile}) resolveProfile(
    String primary,
    String fusion,
  ) {
    final extra = _genreAliases.entries
        .map((e) => (e.key, e.value))
        .toList(growable: false);
    final key = GenreKeyResolver.resolveKey(
      DrumMatrixData.profiles.keys,
      primary,
      fusion,
      defaultKey: _defaultKey,
      extraReplacements: extra,
    );
    final row = DrumMatrixData.profiles[key]!;
    return (
      key: key,
      profile: DrumProfile(
        kit: row['kit']!,
        pattern: row['pattern']!,
        mix: row['mix']!,
        negative: row['negative']!,
      ),
    );
  }

  static String buildStagingLine(DrumProfile profile, {int maxLen = 120}) {
    final line = '${profile.kit}, ${profile.pattern}, ${profile.mix}';
    if (line.length <= maxLen) return line;
    return '${line.substring(0, maxLen - 1)}…';
  }

  static String buildStylePrompt(
    String genre,
    String sunoVersion, {
    String fusionGenre = '',
  }) {
    final profile = resolveProfile(genre, fusionGenre).profile;
    final v = SunoVersion.densityKeyFor(sunoVersion);
    if (v == 'v4.5') {
      final s = '${profile.kit}, ${profile.pattern}, ${profile.mix}';
      return s.length <= 120 ? s : s.substring(0, 120);
    }
    if (v == 'v5.5') {
      return '${profile.kit} driving a ${profile.pattern}, featuring ${profile.mix}. '
          'Strictly avoid: ${profile.negative}.';
    }
    final hint =
        '${profile.kit} playing ${profile.pattern}. ${profile.mix}. Avoid: ${profile.negative}.';
    return hint.length <= 150 ? hint : hint.substring(0, 150);
  }

  static String userBlockDirective({
    required String primaryGenre,
    String subGenreFusion = '',
    required String sunoVersion,
  }) {
    final resolved = resolveProfile(primaryGenre, subGenreFusion);
    final profile = resolved.profile;
    final staging = buildStagingLine(profile);
    final styleHint = buildStylePrompt(
      primaryGenre,
      sunoVersion,
      fusionGenre: subGenreFusion,
    );
    final v = sunoVersion.trim().toLowerCase();
    return [
      'DRUM MATRIX (Block 2 staging + drum character — ARRANGEMENT STAGING FORMAT):',
      'Matched profile: [${resolved.key}]',
      'Kit: ${profile.kit}',
      'Pattern: ${profile.pattern}',
      'Mix: ${profile.mix}',
      'Avoid: ${profile.negative}',
      'Staging seed (≤120 chars, invent fresh per section): $staging',
      'Version drum phrasing hint ($v): $styleHint',
      'Evolve staging on repeated sections — never copy-paste identical drum cues.',
    ].join('\n');
  }
}
