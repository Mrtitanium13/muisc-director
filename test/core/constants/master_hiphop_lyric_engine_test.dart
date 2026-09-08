import 'package:flutter_test/flutter_test.dart';
import 'package:music_director/core/constants/genre_lyrics_directives.dart';
import 'package:music_director/core/constants/master_hiphop_lyric_engine.dart';

void main() {
  group('MasterHipHopLyricEngine', () {
    test('lane detection', () {
      expect(
        MasterHipHopLyricEngine.isHipHopLane(primaryGenre: 'hiphop'),
        isTrue,
      );
      expect(
        MasterHipHopLyricEngine.isHipHopLane(primaryGenre: 'unrelated ambient drone'),
        isFalse,
      );
    });

    test('profile resolution', () {
      expect(
        MasterHipHopLyricEngine.resolveProfile(primaryGenre: 'hiphop'),
        MasterHipHopLyricEngine.profileBoomBap,
      );
      expect(
        MasterHipHopLyricEngine.resolveProfile(
          primaryGenre: 'hiphop',
          subGenreFusion: 'trap',
        ),
        MasterHipHopLyricEngine.profileTrapDrill,
      );
    });

    test('composeUserBlock includes authenticity and QA', () {
      final block = MasterHipHopLyricEngine.composeUserBlock(primaryGenre: 'hiphop');
      expect(block, contains('CROSS-ARCHITECTURE NON-NEGOTIABLES'));
      expect(block, contains('HUMAN AUTHENTICITY'));
      expect(block, contains('SILENT PRE-OUTPUT QA FOR HIP-HOP'));
      expect(block, contains('rise up'));
    });

    test('few-shots end with [End] and avoid AI slogans', () {
      for (final profile in [
        MasterHipHopLyricEngine.profileBoomBap,
        MasterHipHopLyricEngine.profileTrapDrill,
        MasterHipHopLyricEngine.profileConscious,
      ]) {
        final shot = MasterHipHopLyricEngine.fewShotAssistantTurn(profile);
        expect(shot.trim().endsWith('[End]'), isTrue, reason: profile);
        expect(shot.toLowerCase(), isNot(contains('rise up')));
        expect(shot.toLowerCase(), isNot(contains('forever young')));
        expect(shot.toLowerCase(), isNot(contains('high voltage')));
        expect(shot, isNot(contains('(Lead ad-libs')));
      }
    });

    test('GenreLyricsDirectives injects master for hiphop', () {
      final block = GenreLyricsDirectives.userBlockDirective(
        primaryGenre: 'hiphop',
      );
      expect(block, contains('CROSS-ARCHITECTURE NON-NEGOTIABLES'));
      expect(block, contains('HIPHOP MASTER'));
    });
  });
}
