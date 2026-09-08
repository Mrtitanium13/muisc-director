import 'package:flutter_test/flutter_test.dart';
import 'package:music_director/core/constants/genre_lyrics_directives.dart';
import 'package:music_director/core/constants/master_pop_lyric_engine.dart';

void main() {
  group('MasterPopLyricEngine', () {
    test('lane detection', () {
      expect(
        MasterPopLyricEngine.isPopLane(primaryGenre: 'pop'),
        isTrue,
      );
      expect(
        MasterPopLyricEngine.isPopLane(primaryGenre: 'unrelated ambient drone'),
        isFalse,
      );
    });

    test('profile resolution', () {
      expect(
        MasterPopLyricEngine.resolveProfile(primaryGenre: 'pop'),
        MasterPopLyricEngine.profileMainstream,
      );
      expect(
        MasterPopLyricEngine.resolveProfile(
          primaryGenre: 'pop',
          subGenreFusion: 'bedroom',
        ),
        MasterPopLyricEngine.profileBedroomIndie,
      );
    });

    test('composeUserBlock includes authenticity and QA', () {
      final block = MasterPopLyricEngine.composeUserBlock(primaryGenre: 'pop');
      expect(block, contains('CROSS-ARCHITECTURE NON-NEGOTIABLES'));
      expect(block, contains('HUMAN AUTHENTICITY'));
      expect(block, contains('SILENT PRE-OUTPUT QA FOR POP'));
      expect(block, contains('rise up'));
    });

    test('few-shots end with [End] and avoid AI slogans', () {
      for (final profile in [
        MasterPopLyricEngine.profileMainstream,
        MasterPopLyricEngine.profileBedroomIndie,
        MasterPopLyricEngine.profileIdolPop,
      ]) {
        final shot = MasterPopLyricEngine.fewShotAssistantTurn(profile);
        expect(shot.trim().endsWith('[End]'), isTrue, reason: profile);
        expect(shot.toLowerCase(), isNot(contains('rise up')));
        expect(shot.toLowerCase(), isNot(contains('forever young')));
        expect(shot.toLowerCase(), isNot(contains('high voltage')));
        expect(shot, isNot(contains('(Lead ad-libs')));
      }
    });

    test('GenreLyricsDirectives injects master for pop', () {
      final block = GenreLyricsDirectives.userBlockDirective(
        primaryGenre: 'pop',
      );
      expect(block, contains('CROSS-ARCHITECTURE NON-NEGOTIABLES'));
      expect(block, contains('POP MASTER'));
    });
  });
}
