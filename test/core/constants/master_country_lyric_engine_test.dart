import 'package:flutter_test/flutter_test.dart';
import 'package:music_director/core/constants/genre_lyrics_directives.dart';
import 'package:music_director/core/constants/master_country_lyric_engine.dart';

void main() {
  group('MasterCountryLyricEngine', () {
    test('lane detection', () {
      expect(
        MasterCountryLyricEngine.isCountryLane(primaryGenre: 'country'),
        isTrue,
      );
      expect(
        MasterCountryLyricEngine.isCountryLane(primaryGenre: 'unrelated ambient drone'),
        isFalse,
      );
    });

    test('profile resolution', () {
      expect(
        MasterCountryLyricEngine.resolveProfile(primaryGenre: 'country'),
        MasterCountryLyricEngine.profileModernCountry,
      );
      expect(
        MasterCountryLyricEngine.resolveProfile(
          primaryGenre: 'country',
          subGenreFusion: 'outlaw',
        ),
        MasterCountryLyricEngine.profileOutlawAmericana,
      );
    });

    test('composeUserBlock includes authenticity and QA', () {
      final block = MasterCountryLyricEngine.composeUserBlock(primaryGenre: 'country');
      expect(block, contains('CROSS-ARCHITECTURE NON-NEGOTIABLES'));
      expect(block, contains('HUMAN AUTHENTICITY'));
      expect(block, contains('SILENT PRE-OUTPUT QA FOR COUNTRY'));
      expect(block, contains('rise up'));
    });

    test('few-shots end with [End] and avoid AI slogans', () {
      for (final profile in [
        MasterCountryLyricEngine.profileModernCountry,
        MasterCountryLyricEngine.profileOutlawAmericana,
        MasterCountryLyricEngine.profileFolkSongwriter,
      ]) {
        final shot = MasterCountryLyricEngine.fewShotAssistantTurn(profile);
        expect(shot.trim().endsWith('[End]'), isTrue, reason: profile);
        expect(shot.toLowerCase(), isNot(contains('rise up')));
        expect(shot.toLowerCase(), isNot(contains('forever young')));
        expect(shot.toLowerCase(), isNot(contains('high voltage')));
        expect(shot, isNot(contains('(Lead ad-libs')));
      }
    });

    test('GenreLyricsDirectives injects master for country', () {
      final block = GenreLyricsDirectives.userBlockDirective(
        primaryGenre: 'country',
      );
      expect(block, contains('CROSS-ARCHITECTURE NON-NEGOTIABLES'));
      expect(block, contains('COUNTRY MASTER'));
    });
  });
}
