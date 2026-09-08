import 'package:flutter_test/flutter_test.dart';
import 'package:music_director/core/constants/genre_lyrics_directives.dart';
import 'package:music_director/core/constants/master_progressive_big_room_house_lyric_engine.dart';

void main() {
  group('MasterProgressiveBigRoomHouseLyricEngine', () {
    test('lane detection', () {
      expect(
        MasterProgressiveBigRoomHouseLyricEngine.isProgressiveBigRoomLane(
          primaryGenre: 'Progressive House',
        ),
        isTrue,
      );
      expect(
        MasterProgressiveBigRoomHouseLyricEngine.isProgressiveBigRoomLane(
          primaryGenre: 'Big Room Fusion',
        ),
        isTrue,
      );
      expect(
        MasterProgressiveBigRoomHouseLyricEngine.isProgressiveBigRoomLane(
          primaryGenre: 'Trap',
        ),
        isFalse,
      );
    });

    test('profile resolution', () {
      expect(
        MasterProgressiveBigRoomHouseLyricEngine.resolveProfile(
          primaryGenre: 'Progressive House',
        ),
        MasterProgressiveBigRoomHouseLyricEngine.profileProgressiveVocal,
      );
      expect(
        MasterProgressiveBigRoomHouseLyricEngine.resolveProfile(
          primaryGenre: 'Big Room Fusion',
        ),
        MasterProgressiveBigRoomHouseLyricEngine.profileBigRoomFusion,
      );
      expect(
        MasterProgressiveBigRoomHouseLyricEngine.resolveProfile(
          primaryGenre: 'Festival Anthem',
        ),
        MasterProgressiveBigRoomHouseLyricEngine.profileFestivalAnthem,
      );
      expect(
        MasterProgressiveBigRoomHouseLyricEngine.resolveProfile(
          primaryGenre: 'Melodic Progressive',
        ),
        MasterProgressiveBigRoomHouseLyricEngine.profileMelodicProg,
      );
    });

    test('composeUserBlock includes cross-architecture rules', () {
      final block = MasterProgressiveBigRoomHouseLyricEngine.composeUserBlock(
        primaryGenre: 'Progressive House',
        vibe: 'Emotional',
        lyricThemeNotes: 'trust fracture',
      );
      expect(block, contains('CROSS-ARCHITECTURE NON-NEGOTIABLES'));
      expect(block, contains('THICK HUMANIZED VOCAL PRESENCE'));
      expect(block, contains('Pre-Drop Trigger'));
      expect(block, contains('BPM: 128'));
      expect(
        block,
        contains('Write a Progressive/Big Room House song based on'),
      );
    });

    test('few-shot ends with [End] and avoids banned clichés', () {
      for (final profile in [
        MasterProgressiveBigRoomHouseLyricEngine.profileProgressiveVocal,
        MasterProgressiveBigRoomHouseLyricEngine.profileBigRoomFusion,
        MasterProgressiveBigRoomHouseLyricEngine.profileFestivalAnthem,
        MasterProgressiveBigRoomHouseLyricEngine.profileMelodicProg,
        MasterProgressiveBigRoomHouseLyricEngine.profileStadiumBallad,
      ]) {
        final shot =
            MasterProgressiveBigRoomHouseLyricEngine.fewShotAssistantTurn(
          profile,
        );
        expect(shot.trim().endsWith('[End]'), isTrue, reason: profile);
        expect(shot.toLowerCase(), isNot(contains('let it go')));
        expect(shot.toLowerCase(), isNot(contains('hands up')));
        expect(shot.toLowerCase(), isNot(contains('feel the beat')));
        expect(shot, isNot(contains('(Build:')));
      }
      final festival =
          MasterProgressiveBigRoomHouseLyricEngine.fewShotAssistantTurn(
        MasterProgressiveBigRoomHouseLyricEngine.profileFestivalAnthem,
      );
      expect(festival, contains("Don't promise next year"));
      expect(festival.toLowerCase(), isNot(contains('we are thunder')));
      expect(festival.toLowerCase(), isNot(contains('hold the line')));
      expect(festival.toLowerCase(), isNot(contains('we carry on')));
      final progressive =
          MasterProgressiveBigRoomHouseLyricEngine.fewShotAssistantTurn(
        MasterProgressiveBigRoomHouseLyricEngine.profileProgressiveVocal,
      );
      expect(progressive, contains("Don't call me baby"));
      expect(progressive.toLowerCase(), isNot(contains('let it fall')));
      final bigRoom =
          MasterProgressiveBigRoomHouseLyricEngine.fewShotAssistantTurn(
        MasterProgressiveBigRoomHouseLyricEngine.profileBigRoomFusion,
      );
      expect(bigRoom, contains('Leave your jacket'));
      expect(bigRoom.toLowerCase(), isNot(contains('we are thunder')));
      expect(bigRoom.toLowerCase(), isNot(contains('rise up')));
      final melodic =
          MasterProgressiveBigRoomHouseLyricEngine.fewShotAssistantTurn(
        MasterProgressiveBigRoomHouseLyricEngine.profileMelodicProg,
      );
      expect(melodic, contains('And I keep driving'));
    });

    test('GenreLyricsDirectives injects master for Progressive House', () {
      final block = GenreLyricsDirectives.userBlockDirective(
        primaryGenre: 'Progressive House',
      );
      expect(block, contains('PROGRESSIVE HOUSE (VOCAL)'));
      expect(block, contains('CROSS-ARCHITECTURE NON-NEGOTIABLES'));
    });
  });
}
