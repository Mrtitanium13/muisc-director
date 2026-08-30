import 'package:flutter_test/flutter_test.dart';
import 'package:music_director/core/constants/genre_lyrics_directives.dart';
import 'package:music_director/core/constants/master_gospel_lyric_engine.dart';

void main() {
  group('MasterGospelLyricEngine', () {
    test('word boundary gospel detection', () {
      expect(
        MasterGospelLyricEngine.isGospelLane(primaryGenre: 'christian rock'),
        isTrue,
      );
      expect(
        MasterGospelLyricEngine.isGospelLane(
          primaryGenre: 'antichristian metal',
        ),
        isFalse,
      );
      expect(
        MasterGospelLyricEngine.isGospelLane(primaryGenre: 'praise dance'),
        isTrue,
      );
    });

    test('primary gospel + Afro-Gospel fusion resolves afro profile', () {
      expect(
        MasterGospelLyricEngine.resolveProfile(
          primaryGenre: 'gospel',
          subGenreFusion: 'Afro-Gospel',
        ),
        MasterGospelLyricEngine.profileAfroGospel,
      );
    });

    test('bare gospel defaults to traditional urban', () {
      expect(
        MasterGospelLyricEngine.resolveProfile(primaryGenre: 'gospel'),
        MasterGospelLyricEngine.profileTraditionalUrban,
      );
      expect(
        MasterGospelLyricEngine.resolveProfile(primaryGenre: 'afro-gospel'),
        MasterGospelLyricEngine.profileAfroGospel,
      );
      expect(
        MasterGospelLyricEngine.resolveProfile(primaryGenre: 'ccm'),
        MasterGospelLyricEngine.profilePraiseWorship,
      );
      expect(
        MasterGospelLyricEngine.resolveProfile(primaryGenre: 'southern gospel'),
        MasterGospelLyricEngine.profileGospelCountry,
      );
    });

    test('few-shot assistant turns end with [End] and avoid banned descriptors', () {
      for (final profile in [
        MasterGospelLyricEngine.profileAfroGospel,
        MasterGospelLyricEngine.profileTraditionalUrban,
        MasterGospelLyricEngine.profileGospelCountry,
        MasterGospelLyricEngine.profilePraiseWorship,
        MasterGospelLyricEngine.profileTraditionalQuartet,
      ]) {
        final shot = MasterGospelLyricEngine.fewShotAssistantTurn(profile);
        expect(shot.trim().endsWith('[End]'), isTrue, reason: profile);
        expect(shot.toLowerCase(), isNot(contains('soulful male')));
        expect(shot, isNot(contains('(Lead ad-libs')));
        expect(shot, isNot(contains('(Choir:')));
      }
      final user = MasterGospelLyricEngine.fewShotUserTurn(
        profile: MasterGospelLyricEngine.profileAfroGospel,
      );
      expect(user.toLowerCase(), isNot(contains('soulful')));
      expect(user, contains('Warm chest-register'));
    });

    test('composeUserBlock includes cross-architecture gospel rules', () {
      final block = MasterGospelLyricEngine.composeUserBlock(
        primaryGenre: 'gospel',
      );
      expect(block, contains('CROSS-ARCHITECTURE NON-NEGOTIABLES'));
      expect(block, contains('STUDIO-ISOLATION'));
      expect(block, contains('HOOK DOMINANCE'));
      expect(block, contains('SILENT PRE-OUTPUT QA FOR GOSPEL'));
    });

    test('sub-genre labels use raw ampersand', () {
      expect(
        MasterGospelLyricEngine.subGenreLabel(
          MasterGospelLyricEngine.profilePraiseWorship,
        ),
        'Praise & Worship / Inspirational',
      );
    });

    test('few shot messages are well-typed', () {
      final messages = MasterGospelLyricEngine.fewShotPrefixMessages(
        primaryGenre: 'gospel',
      );
      expect(messages, hasLength(2));
      expect(messages.first['role'], 'user');
      expect(messages.first['content'], isNotEmpty);
    });

    test('resolves Afro-Gospel profile', () {
      expect(
        MasterGospelLyricEngine.resolveProfile(primaryGenre: 'Afro-Gospel'),
        MasterGospelLyricEngine.profileAfroGospel,
      );
    });

    test('resolves Contemporary Gospel to urban profile', () {
      expect(
        MasterGospelLyricEngine.resolveProfile(
          primaryGenre: 'Contemporary Gospel',
        ),
        MasterGospelLyricEngine.profileTraditionalUrban,
      );
    });

    test('resolves Southern Gospel to country profile', () {
      expect(
        MasterGospelLyricEngine.resolveProfile(primaryGenre: 'Southern Gospel'),
        MasterGospelLyricEngine.profileGospelCountry,
      );
    });

    test('resolves Praise/Worship to praise profile', () {
      expect(
        MasterGospelLyricEngine.resolveProfile(primaryGenre: 'Praise/Worship'),
        MasterGospelLyricEngine.profilePraiseWorship,
      );
    });

    test('composeUserBlock uses universal prompt and user selections format', () {
      final block = MasterGospelLyricEngine.composeUserBlock(
        primaryGenre: 'Afro-Gospel',
        vibe: 'Up-tempo, Joyful',
        lyricThemeNotes: 'gratitude',
        vocalSpec: 'Male Lead',
        vocalTone: 'soulful, rhythmic',
      );
      expect(block, contains('master lyricist and music arranger'));
      expect(block, contains('AFRO-GOSPEL / AFROBEATS WORSHIP'));
      expect(block, contains('STRICT WRITING RULES FOR ALL GOSPEL'));
      expect(block, contains('Write a song based on the following user selections'));
      expect(block, contains('THEME DIRECTIVES for Gratitude/Praise'));
      expect(block, isNot(contains('PRODIGAL FRAMEWORK')));
    });

    test('Afro-Gospel few-shot includes pidgin vocabulary example', () {
      final turns = MasterGospelLyricEngine.fewShotPrefixMessages(
        primaryGenre: 'Afro-Gospel',
        lyricThemeNotes: 'Celebrating favor',
      );
      expect(turns.length, 2);
      expect(turns.first['content'], contains('user selections'));
      expect(turns.last['content'], contains('Jehovah overdo'));
      expect(turns.last['content'], contains('[Vamp/Flow'));
    });

    test('GenreLyricsDirectives injects master gospel for Urban Gospel', () {
      final block = GenreLyricsDirectives.userBlockDirective(
        primaryGenre: 'Urban Gospel',
        lyricThemeNotes: 'deliverance testimony',
      );
      expect(block, contains('TRADITIONAL GOSPEL / URBAN CONTEMPORARY'));
      expect(block, contains('THEME DIRECTIVES for Warfare/Victory'));
    });

    test('Country Gospel gratitude has no Prodigal in base prompt', () {
      final block = GenreLyricsDirectives.userBlockDirective(
        primaryGenre: 'Country Gospel',
        vibe: 'Prayerful, Close-mic, Intimate',
        lyricThemeNotes: 'gratitude',
        vocalSpec: 'Female Lead',
        vocalTone: 'prayerful',
      );
      expect(block, contains('GOSPEL COUNTRY / SOUTHERN GOSPEL'));
      expect(block, contains('THEME DIRECTIVES for Gratitude/Praise'));
      expect(block, isNot(contains('Prodigal Son')));
      expect(block, isNot(contains('PRODIGAL FRAMEWORK')));
      expect(block, contains('prayerful cadence'));
    });

    test('Country Gospel forgiveness injects Prodigal via theme directive only', () {
      final block = GenreLyricsDirectives.userBlockDirective(
        primaryGenre: 'Country Gospel',
        lyricThemeNotes: 'forgiveness',
        vocalSpec: 'Female Lead',
        vocalTone: 'prayerful',
      );
      expect(block, contains('THEME DIRECTIVES for Forgiveness'));
      expect(block, contains('Prodigal Son'));
      expect(block, isNot(contains('PRODIGAL FRAMEWORK')));
      expect(block, isNot(contains('VISCERAL GEOGRAPHY')));
    });
  });
}
