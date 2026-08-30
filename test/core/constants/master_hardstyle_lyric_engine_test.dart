import 'package:flutter_test/flutter_test.dart';
import 'package:music_director/core/constants/genre_lyrics_directives.dart';
import 'package:music_director/core/constants/master_hardstyle_lyric_engine.dart';

void main() {
  group('MasterHardstyleLyricEngine', () {
    test('lane detection', () {
      expect(
        MasterHardstyleLyricEngine.isHardstyleLane(primaryGenre: 'Hardstyle'),
        isTrue,
      );
      expect(
        MasterHardstyleLyricEngine.isHardstyleLane(primaryGenre: 'Rawstyle'),
        isTrue,
      );
      expect(
        MasterHardstyleLyricEngine.isHardstyleLane(primaryGenre: 'Pop'),
        isFalse,
      );
    });

    test('profile resolution', () {
      expect(
        MasterHardstyleLyricEngine.resolveProfile(primaryGenre: 'Hardstyle'),
        MasterHardstyleLyricEngine.profileEuphoric,
      );
      expect(
        MasterHardstyleLyricEngine.resolveProfile(primaryGenre: 'Rawstyle'),
        MasterHardstyleLyricEngine.profileRawstyle,
      );
      expect(
        MasterHardstyleLyricEngine.resolveProfile(primaryGenre: 'Hard Bounce'),
        MasterHardstyleLyricEngine.profileHardBounce,
      );
      expect(
        MasterHardstyleLyricEngine.resolveProfile(
          primaryGenre: 'Hardstyle',
          subGenreFusion: 'Euro-Dance Bootleg',
        ),
        MasterHardstyleLyricEngine.profileEuroBootleg,
      );
    });

    test('composeUserBlock includes cross-architecture rules', () {
      final block = MasterHardstyleLyricEngine.composeUserBlock(
        primaryGenre: 'Hardstyle',
        vibe: 'Anthemic',
        lyricThemeNotes: 'survival',
      );
      expect(block, contains('CROSS-ARCHITECTURE NON-NEGOTIABLES'));
      expect(block, contains('STRICTLY INSTRUMENTAL'));
      expect(block, contains('PRE-DROP'));
      expect(block, contains('THICK HUMANIZED VOCAL PRESENCE'));
      expect(block, contains('Write a Hardstyle song based on the following'));
      expect(block, contains('BPM: 150'));
    });

    test('few-shot ends with [End] and avoids banned clichés', () {
      for (final profile in [
        MasterHardstyleLyricEngine.profileEuphoric,
        MasterHardstyleLyricEngine.profileRawstyle,
        MasterHardstyleLyricEngine.profileHardBounce,
        MasterHardstyleLyricEngine.profileHardDance,
        MasterHardstyleLyricEngine.profileEuroBootleg,
      ]) {
        final shot = MasterHardstyleLyricEngine.fewShotAssistantTurn(profile);
        expect(shot.trim().endsWith('[End]'), isTrue, reason: profile);
        expect(shot.toLowerCase(), isNot(contains('let it go')));
        expect(shot.toLowerCase(), isNot(contains('feel the bass')));
        expect(shot.toLowerCase(), isNot(contains('we own the night')));
        expect(shot, isNot(contains('(Scream:')));
      }
      final bounce = MasterHardstyleLyricEngine.fewShotAssistantTurn(
        MasterHardstyleLyricEngine.profileHardBounce,
      );
      expect(bounce, contains('Lose the weight'));
      expect(bounce, contains('Hit the floor'));
    });

    test('GenreLyricsDirectives injects master hardstyle for Hardstyle', () {
      final block = GenreLyricsDirectives.userBlockDirective(
        primaryGenre: 'Hardstyle',
        lyricThemeNotes: 'finding strength',
      );
      expect(block, contains('EUPHORIC HARDSTYLE'));
      expect(block, contains('BREAKDOWN'));
    });
  });
}
