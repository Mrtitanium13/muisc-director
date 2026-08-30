import 'package:flutter_test/flutter_test.dart';
import 'package:music_director/core/constants/genre_lyrics_directives.dart';
import 'package:music_director/core/constants/master_edm_lyric_engine.dart';
import 'package:music_director/core/constants/master_progressive_big_room_house_lyric_engine.dart';

void main() {
  group('MasterEdmLyricEngine', () {
    test('lane detection', () {
      expect(
        MasterEdmLyricEngine.isEdmLane(primaryGenre: 'Deep House'),
        isTrue,
      );
      expect(
        MasterEdmLyricEngine.isEdmLane(primaryGenre: 'Techno'),
        isTrue,
      );
      expect(
        MasterEdmLyricEngine.isEdmLane(primaryGenre: 'Amapiano'),
        isTrue,
      );
      expect(
        MasterEdmLyricEngine.isEdmLane(primaryGenre: 'Country'),
        isFalse,
      );
    });

    test('profile resolution', () {
      expect(
        MasterEdmLyricEngine.resolveProfile(primaryGenre: 'Deep House'),
        MasterEdmLyricEngine.profileHouseDeepTech,
      );
      expect(
        MasterEdmLyricEngine.resolveProfile(primaryGenre: 'Hard Techno'),
        MasterEdmLyricEngine.profileTechno,
      );
      expect(
        MasterEdmLyricEngine.resolveProfile(primaryGenre: 'Uplifting Trance'),
        MasterEdmLyricEngine.profileTrance,
      );
      expect(
        MasterEdmLyricEngine.resolveProfile(primaryGenre: 'Future Bass'),
        MasterEdmLyricEngine.profileFutureBass,
      );
      expect(
        MasterEdmLyricEngine.resolveProfile(primaryGenre: 'Liquid DnB'),
        MasterEdmLyricEngine.profileDubstepDnb,
      );
      expect(
        MasterEdmLyricEngine.resolveProfile(primaryGenre: 'Amapiano'),
        MasterEdmLyricEngine.profileAmapianoVinahouse,
      );
      expect(
        MasterEdmLyricEngine.resolveProfile(primaryGenre: 'UK Garage'),
        MasterEdmLyricEngine.profileGarageClub,
      );
    });

    test('composeUserBlock includes cross-architecture and sub-genre', () {
      final block = MasterEdmLyricEngine.composeUserBlock(
        primaryGenre: 'Deep House',
        vibe: 'late night',
      );
      expect(block, contains('CROSS-ARCHITECTURE NON-NEGOTIABLES'));
      expect(block, contains('HOUSE / DEEP HOUSE'));
      expect(block, contains('FOURTH-WALL LAW'));
      expect(block, contains('SILENT PRE-OUTPUT QA'));
      expect(block, contains('House / Deep House / Tech House'));
    });

    test('few-shots end with [End] and avoid banned descriptors', () {
      final profiles = [
        MasterEdmLyricEngine.profileHouseDeepTech,
        MasterEdmLyricEngine.profileTechno,
        MasterEdmLyricEngine.profileTrance,
        MasterEdmLyricEngine.profileFutureBass,
        MasterEdmLyricEngine.profileDubstepDnb,
        MasterEdmLyricEngine.profileAmapianoVinahouse,
        MasterEdmLyricEngine.profileGarageClub,
      ];
      for (final profile in profiles) {
        final shot = MasterEdmLyricEngine.fewShotAssistantTurn(profile);
        expect(shot.trim().endsWith('[End]'), isTrue, reason: profile);
        expect(shot.toLowerCase(), isNot(contains('ethereal')), reason: profile);
        expect(shot, isNot(contains('Let me go')), reason: profile);
      }
    });

    test('GenreLyricsDirectives injects master for Deep House / Trance / Amapiano',
        () {
      for (final genre in ['Deep House', 'Uplifting Trance', 'Amapiano']) {
        final block = GenreLyricsDirectives.userBlockDirective(
          primaryGenre: genre,
        );
        expect(
          block,
          contains('CROSS-ARCHITECTURE NON-NEGOTIABLES'),
          reason: genre,
        );
        expect(
          block,
          isNot(contains('EDM BREAKDOWN VOCAL GUARDRAILS')),
          reason: genre,
        );
      }
    });

    test('Progressive House stays on progressive master, not EDM catch-all', () {
      final block = GenreLyricsDirectives.userBlockDirective(
        primaryGenre: 'Progressive House',
      );
      expect(block, contains('PROGRESSIVE HOUSE (VOCAL)'));
      expect(
        MasterProgressiveBigRoomHouseLyricEngine.isProgressiveBigRoomLane(
          primaryGenre: 'Progressive House',
        ),
        isTrue,
      );
    });

    test('Hardstyle takes precedence over EDM catch-all', () {
      final block = GenreLyricsDirectives.userBlockDirective(
        primaryGenre: 'Hardstyle',
      );
      expect(block.toUpperCase(), contains('HARDSTYLE'));
      expect(block, isNot(contains('Write an EDM song based on')));
    });
  });
}
