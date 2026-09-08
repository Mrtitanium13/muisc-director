import 'package:flutter_test/flutter_test.dart';
import 'package:music_director/core/constants/genre_lyrics_directives.dart';
import 'package:music_director/core/constants/master_rnb_lyric_engine.dart';

void main() {
  group('MasterRnbLyricEngine', () {
    test('lane detection', () {
      expect(
        MasterRnbLyricEngine.isRnbLane(primaryGenre: 'rnb'),
        isTrue,
      );
      expect(
        MasterRnbLyricEngine.isRnbLane(primaryGenre: 'unrelated ambient drone'),
        isFalse,
      );
    });

    test('profile resolution', () {
      expect(
        MasterRnbLyricEngine.resolveProfile(primaryGenre: 'rnb'),
        MasterRnbLyricEngine.profileContemporary,
      );
      expect(
        MasterRnbLyricEngine.resolveProfile(
          primaryGenre: 'rnb',
          subGenreFusion: 'neo-soul',
        ),
        MasterRnbLyricEngine.profileNeoSoul,
      );
    });

    test('composeUserBlock includes authenticity and QA', () {
      final block = MasterRnbLyricEngine.composeUserBlock(primaryGenre: 'rnb');
      expect(block, contains('CROSS-ARCHITECTURE NON-NEGOTIABLES'));
      expect(block, contains('HUMAN AUTHENTICITY'));
      expect(block, contains('SILENT PRE-OUTPUT QA FOR R&B'));
      expect(block, contains('rise up'));
    });

    test('few-shots end with [End] and avoid AI slogans', () {
      for (final profile in [
        MasterRnbLyricEngine.profileTrapSoul,
        MasterRnbLyricEngine.profileNeoSoul,
        MasterRnbLyricEngine.profileContemporary,
      ]) {
        final shot = MasterRnbLyricEngine.fewShotAssistantTurn(profile);
        expect(shot.trim().endsWith('[End]'), isTrue, reason: profile);
        expect(shot.toLowerCase(), isNot(contains('rise up')));
        expect(shot.toLowerCase(), isNot(contains('forever young')));
        expect(shot.toLowerCase(), isNot(contains('high voltage')));
        expect(shot, isNot(contains('(Lead ad-libs')));
      }
    });

    test('GenreLyricsDirectives injects master for rnb', () {
      final block = GenreLyricsDirectives.userBlockDirective(
        primaryGenre: 'rnb',
      );
      expect(block, contains('CROSS-ARCHITECTURE NON-NEGOTIABLES'));
      expect(block, contains('RNB MASTER'));
    });
  });
}
