import 'package:flutter_test/flutter_test.dart';
import 'package:music_director/core/constants/genre_lyrics_directives.dart';
import 'package:music_director/core/constants/hardstyle_vocal_lyric_engine.dart';

void main() {
  group('HardstyleVocalLyricEngine', () {
    test('isHardstyleLane matches hardstyle family', () {
      expect(
        HardstyleVocalLyricEngine.isHardstyleLane(primaryGenre: 'Hardstyle'),
        isTrue,
      );
      expect(
        HardstyleVocalLyricEngine.isHardstyleLane(primaryGenre: 'Pop'),
        isFalse,
      );
    });

    test('composeUserBlock empty when mainstage hard dance lane owns genre', () {
      final block = HardstyleVocalLyricEngine.composeUserBlock(
        primaryGenre: 'Euphoric Hardstyle',
      );
      expect(block, isEmpty);
    });
  });

  group('GenreLyricsDirectives hardstyle routing', () {
    test('userBlockDirective injects master hardstyle engine', () {
      final block = GenreLyricsDirectives.userBlockDirective(
        primaryGenre: 'Hardstyle',
      );
      expect(block, contains('CROSS-ARCHITECTURE NON-NEGOTIABLES'));
      expect(block, contains('EUPHORIC HARDSTYLE'));
      expect(block, contains('PRE-DROP'));
      expect(block, contains('THICK HUMANIZED VOCAL PRESENCE'));
    });

    test('explicit cinematic hybrid still routes to specialty engine', () {
      final block = GenreLyricsDirectives.userBlockDirective(
        primaryGenre: 'Hardstyle',
        subGenreFusion: 'Cinematic Hybrid',
      );
      expect(block, contains('CRITICAL HARD DANCE VOCAL GUARDRAILS'));
      expect(block, contains('[Climax Drop]'));
      expect(
        block,
        contains('mainstage_euphoric_rawstyle_narrative_150_thick_humanized'),
      );
    });
  });
}
