import 'package:flutter_test/flutter_test.dart';
import 'package:music_director/core/constants/genre_lyrics_directives.dart';
import 'package:music_director/core/constants/master_gospel_lyric_engine.dart';
import 'package:music_director/core/constants/southern_gospel_country_lyric_engine.dart';

void main() {
  group('SouthernGospelCountryLyricEngine', () {
    test('detects southern gospel / country gospel lanes', () {
      expect(
        SouthernGospelCountryLyricEngine.isLane(
          primaryGenre: 'Southern Gospel',
        ),
        isTrue,
      );
      expect(
        SouthernGospelCountryLyricEngine.isLane(
          primaryGenre: 'Country',
          vibe: 'Gospel Country Lift',
        ),
        isTrue,
      );
      expect(
        SouthernGospelCountryLyricEngine.isLane(primaryGenre: 'Techno'),
        isFalse,
      );
    });

    test('few-shot prefix has user then assistant turn', () {
      final turns = SouthernGospelCountryLyricEngine.fewShotPrefixMessages();
      expect(turns.length, 2);
      expect(turns.first['role'], 'user');
      expect(turns.last['role'], 'assistant');
      expect(turns.last['content'], contains('GOOD (Write in this style)'));
      expect(turns.last['content'], contains('crowded, lonely room'));
    });

    test('UI mapping: soulful female prayerful cadence', () {
      final out = SouthernGospelCountryLyricEngine.uiDirectiveAppend(
        vocalSpec: 'Female Lead',
        vocalTone: 'prayerful, soulful',
      );
      expect(out, contains('heavy vowel sounds'));
      expect(out, contains('prayerful cadence'));
    });

    test('UI mapping: Gospel Country Lift chorus directive', () {
      final out = SouthernGospelCountryLyricEngine.uiDirectiveAppend(
        vibe: 'Gospel Country Lift',
      );
      expect(out, contains('gospel choir'));
      expect(out, contains('anthemic'));
    });

    test('GenreLyricsDirectives injects cliché ban for raw country lane', () {
      final block = GenreLyricsDirectives.userBlockDirective(
        primaryGenre: 'Outlaw Country',
        vibe: 'raw country',
        lyricThemeNotes: 'forgiveness',
        vocalSpec: 'Male Lead',
        vocalTone: 'twang',
      );
      expect(block, contains('BAN THE CLICHÉS'));
      expect(block, isNot(contains('PRODIGAL FRAMEWORK')));
    });

    test('shouldInjectFewShot when lyrics task and lane match', () {
      expect(
        SouthernGospelCountryLyricEngine.shouldInjectFewShot(
          primaryGenre: 'Country Gospel',
          lyricsTask: true,
        ),
        isFalse,
      );
      expect(
        MasterGospelLyricEngine.shouldInjectFewShot(
          primaryGenre: 'Worship Ballad',
          lyricsTask: true,
        ),
        isTrue,
      );
    });
  });
}
