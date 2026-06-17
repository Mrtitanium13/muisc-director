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

  static ({String key, DrumProfile profile}) resolveProfile(
    String primary,
    String fusion,
  ) {
    final key = GenreKeyResolver.resolveKey(
      DrumMatrixData.profiles.keys,
      primary,
      fusion,
      defaultKey: _defaultKey,
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
    final v = sunoVersion.trim().toLowerCase();
    if (v == 'v4.5') {
      final s = '${profile.kit}, ${profile.pattern}, ${profile.mix}';
      return s.length <= 120 ? s : s.substring(0, 120);
    }
    if (v.startsWith('v5.5')) {
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
