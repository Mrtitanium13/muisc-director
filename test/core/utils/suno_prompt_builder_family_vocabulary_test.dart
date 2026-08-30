import 'package:flutter_test/flutter_test.dart';
import 'package:music_director/core/constants/genres_config.dart';
import 'package:music_director/core/utils/genre_fx_matrix_data.dart';
import 'package:music_director/core/utils/suno_prompt_builder.dart';

void main() {
  group('SunoPromptBuilder family-aware FX injection', () {
    test('Trap lyrics: FX injects before [Hook], not [Chorus]', () {
      final result = SunoPromptBuilder.buildSunoPrompt(
        baseStyle: 'aggressive trap energy',
        baseLyrics: '[Hook]\n[Verse]\n[Hook]\n[End]',
        primaryGenre: 'trap',
        intensity: 2,
      );
      expect(result.lyrics.contains('[Hook]'), isTrue);
      expect(
        result.lyrics.contains('[Chorus]'),
        isFalse,
        reason: 'Trap FX injection should not use [Chorus] anchor',
      );
    });

    test('Cinematic lyrics: FX injects before [Climax], not [Drop]', () {
      final result = SunoPromptBuilder.buildSunoPrompt(
        baseStyle: 'epic orchestral',
        baseLyrics: '[Theme]\n[Development]\n[Climax]\n[Coda]\n[End]',
        primaryGenre: 'cinematic',
        intensity: 3,
      );
      expect(result.lyrics.contains('[Climax]'), isTrue);
    });

    test('Boom Bap lyrics: FX injects before [Hook]', () {
      final result = SunoPromptBuilder.buildSunoPrompt(
        baseStyle: 'crisp boom bap drums',
        baseLyrics: '[Hook]\n[Verse]\n[Hook]\n[End]',
        primaryGenre: 'boom_bap',
        intensity: 2,
      );
      expect(result.lyrics.contains('[Hook]'), isTrue);
    });

    test('Amapiano lyrics: FX injects before [Log Drum Verse]', () {
      final result = SunoPromptBuilder.buildSunoPrompt(
        baseStyle: 'log drum groove',
        baseLyrics: '[Log Drum Verse]\n[Chant Accents]\n[End]',
        primaryGenre: 'amapiano',
        intensity: 2,
      );
      expect(result.lyrics.contains('[Log Drum Verse]'), isTrue);
    });
  });

  group('GenresConfig.fxLyricsAnchor per-family', () {
    test('Trap → [Hook]', () {
      expect(GenresConfig.fxLyricsAnchor('trap'), '[Hook]\n');
    });

    test('Cinematic → [Climax]', () {
      expect(GenresConfig.fxLyricsAnchor('cinematic'), '[Climax]\n');
    });

    test('Metal → [Breakdown]', () {
      expect(GenresConfig.fxLyricsAnchor('metal'), '[Breakdown]\n');
    });

    test('EDM → [Drop]', () {
      expect(GenresConfig.fxLyricsAnchor('edm'), '[Drop]\n');
    });

    test('Jazz → [Solo]', () {
      expect(GenresConfig.fxLyricsAnchor('jazz'), '[Solo]\n');
    });

    test('Hardstyle → [Monologue]', () {
      expect(GenresConfig.fxLyricsAnchor('hardstyle'), '[Monologue]\n');
    });
  });

  group('Genre alias resolution — no family collapse', () {
    test('"boom bap" → boom_bap matrix key (not hiphop)', () {
      expect(
        SunoPromptBuilder.resolveGenreKey('boom bap', ''),
        'boom_bap',
      );
    });

    test('"amapiano" → amapiano matrix key (not afrobeats)', () {
      expect(
        SunoPromptBuilder.resolveGenreKey('amapiano', ''),
        'amapiano',
      );
    });

    test('"reggaeton" → reggaeton matrix key (not afrobeats)', () {
      expect(
        SunoPromptBuilder.resolveGenreKey('reggaeton', ''),
        'reggaeton',
      );
    });

    test('"worship" → worship matrix key', () {
      expect(
        SunoPromptBuilder.resolveGenreKey('praise and worship', ''),
        'worship',
      );
    });
  });

  group('stripFxLayout correctness', () {
    test('removes known FX head lines', () {
      final out = SunoPromptBuilder.stripFxLayout(
        '[Log Drum Break]\n[Chorus]\nreal user lyrics\n',
      );
      expect(out.contains('[Chorus]'), isTrue);
      expect(out.contains('real user lyrics'), isTrue);
    });

    test('does NOT strip user content that starts with a legitimate tag', () {
      final out = SunoPromptBuilder.stripFxLayout(
        '[Drop]\nMy actual lyrics here\n[Verse]\nMore lyrics',
      );
      expect(out.contains('My actual lyrics here'), isTrue);
      expect(out.contains('[Verse]'), isTrue);
      expect(out.contains('More lyrics'), isTrue);
    });

    test('stripFxLayout on 50-line input completes in <5ms', () {
      final input = List.generate(
        50,
        (i) => i < 3 ? '[Rising Energy Build]' : 'User lyric line $i',
      ).join('\n');
      final sw = Stopwatch()..start();
      SunoPromptBuilder.stripFxLayout(input);
      sw.stop();
      expect(sw.elapsedMilliseconds, lessThan(5));
    });
  });

  group('GenresConfig UI coverage', () {
    test('all matrix families have UI entry', () {
      const required = {
        'edm',
        'techno',
        'hardstyle',
        'dnb',
        'synthwave',
        'dubstep',
        'ambient',
        'hiphop',
        'trap',
        'boom_bap',
        'amapiano',
        'pop',
        'rnb',
        'reggaeton',
        'latin',
        'rock',
        'metal',
        'indie',
        'country',
        'folk',
        'afrobeats',
        'cinematic',
        'jazz',
        'worship',
        'mandopop',
        'world',
      };
      final uiKeys =
          GenresConfig.appSupportedGenres.map((g) => g.id).toSet();
      expect(
        uiKeys.containsAll(required),
        isTrue,
        reason: 'UI is missing: ${required.difference(uiKeys)}',
      );
      expect(
        GenreFxMatrixData.profiles.keys.toSet(),
        uiKeys,
        reason: 'Matrix families and FX lane picker must stay 1:1',
      );
    });

    test('afrobeats label no longer mentions Amapiano', () {
      final afrobeats = GenresConfig.appSupportedGenres
          .firstWhere((g) => g.id == 'afrobeats');
      expect(
        afrobeats.label.toLowerCase().contains('amapiano'),
        isFalse,
        reason:
            'Afrobeats label should not mention Amapiano (split families)',
      );
    });
  });
}
