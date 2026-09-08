import 'package:flutter_test/flutter_test.dart';
import 'package:music_director/core/constants/genre_lyrics_directives.dart';
import 'package:music_director/core/constants/master_rock_lyric_engine.dart';

void main() {
  group('MasterRockLyricEngine', () {
    test('lane detection', () {
      expect(
        MasterRockLyricEngine.isRockLane(primaryGenre: 'rock'),
        isTrue,
      );
      expect(
        MasterRockLyricEngine.isRockLane(primaryGenre: 'unrelated ambient drone'),
        isFalse,
      );
    });

    test('profile resolution', () {
      expect(
        MasterRockLyricEngine.resolveProfile(primaryGenre: 'rock'),
        MasterRockLyricEngine.profileClassicAlt,
      );
      expect(
        MasterRockLyricEngine.resolveProfile(
          primaryGenre: 'rock',
          subGenreFusion: 'pop punk',
        ),
        MasterRockLyricEngine.profilePopPunkEmo,
      );
    });

    test('composeUserBlock includes authenticity and QA', () {
      final block = MasterRockLyricEngine.composeUserBlock(primaryGenre: 'rock');
      expect(block, contains('CROSS-ARCHITECTURE NON-NEGOTIABLES'));
      expect(block, contains('HUMAN AUTHENTICITY'));
      expect(block, contains('SILENT PRE-OUTPUT QA FOR ROCK'));
      expect(block, contains('rise up'));
    });

    test('few-shots end with [End] and avoid AI slogans', () {
      for (final profile in [
        MasterRockLyricEngine.profileClassicAlt,
        MasterRockLyricEngine.profilePopPunkEmo,
        MasterRockLyricEngine.profileMetalHeavy,
      ]) {
        final shot = MasterRockLyricEngine.fewShotAssistantTurn(profile);
        expect(shot.trim().endsWith('[End]'), isTrue, reason: profile);
        expect(shot.toLowerCase(), isNot(contains('rise up')));
        expect(shot.toLowerCase(), isNot(contains('forever young')));
        expect(shot.toLowerCase(), isNot(contains('high voltage')));
        expect(shot, isNot(contains('(Lead ad-libs')));
      }
    });

    test('GenreLyricsDirectives injects master for rock', () {
      final block = GenreLyricsDirectives.userBlockDirective(
        primaryGenre: 'rock',
      );
      expect(block, contains('CROSS-ARCHITECTURE NON-NEGOTIABLES'));
      expect(block, contains('ROCK MASTER'));
    });
  });
}
