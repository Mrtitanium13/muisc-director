import 'package:flutter_test/flutter_test.dart';
import 'package:music_director/core/constants/edm_breakdown_vocal_lyric_engine.dart';
import 'package:music_director/core/constants/genre_lyrics_directives.dart';

void main() {
  group('EdmBreakdownVocalLyricEngine', () {
    test('isEdmBreakdownLane matches techno trance house edm', () {
      expect(
        EdmBreakdownVocalLyricEngine.isEdmBreakdownLane(
          primaryGenre: 'Techno',
        ),
        isTrue,
      );
      expect(
        EdmBreakdownVocalLyricEngine.isEdmBreakdownLane(
          primaryGenre: 'Uplifting Trance',
        ),
        isTrue,
      );
      expect(
        EdmBreakdownVocalLyricEngine.isEdmBreakdownLane(
          primaryGenre: 'Deep House',
        ),
        isTrue,
      );
      expect(
        EdmBreakdownVocalLyricEngine.isEdmBreakdownLane(
          primaryGenre: 'Country',
        ),
        isFalse,
      );
    });

    test('resolveProfile routes sub-genre matrix', () {
      expect(
        EdmBreakdownVocalLyricEngine.resolveProfile(
          primaryGenre: 'Peak-Time Techno',
        ),
        EdmBreakdownVocalLyricEngine.profilePeakTimeTechno,
      );
      expect(
        EdmBreakdownVocalLyricEngine.resolveProfile(
          primaryGenre: 'Uplifting Trance',
        ),
        EdmBreakdownVocalLyricEngine.profileVocalTrance,
      );
      expect(
        EdmBreakdownVocalLyricEngine.resolveProfile(
          primaryGenre: 'Melodic Techno',
        ),
        EdmBreakdownVocalLyricEngine.profileDeepMelodic,
      );
      expect(
        EdmBreakdownVocalLyricEngine.resolveProfile(
          primaryGenre: 'Melodic Techno',
          subGenreFusion: 'Uplifting Trance',
        ),
        EdmBreakdownVocalLyricEngine.profileVocalTrance,
      );
    });

    test('composeUserBlock includes guardrails and bans sci-fi metaphors', () {
      final block = EdmBreakdownVocalLyricEngine.composeUserBlock(
        primaryGenre: 'Deep House',
      );
      expect(block, contains('master lyricist'));
      expect(block, contains('BAN SCI-FI'));
      expect(block, contains('HUMAN AUTHENTICITY'));
      expect(block, contains('BAN AI FESTIVAL'));
      expect(block, contains('thought fragments'));
      expect(block, contains('PRE-DROP TRIGGER'));
      expect(block, contains('[Breakdown]'));
      expect(block, contains('deep_melodic'));
      expect(block, isNot(contains('4 AM')));
      expect(block, isNot(contains('PSYCHOLOGICAL REALISM')));
    });
  });

  group('GenreLyricsDirectives EDM routing', () {
    test('userBlockDirective injects Master EDM for trance', () {
      final block = GenreLyricsDirectives.userBlockDirective(
        primaryGenre: 'Uplifting Trance',
        vibe: 'euphoric festival',
      );
      expect(block, contains('CROSS-ARCHITECTURE NON-NEGOTIABLES'));
      expect(block, contains('TRANCE / UPLIFTING TRANCE'));
      expect(block, isNot(contains('EDM BREAKDOWN VOCAL GUARDRAILS')));
    });

    test('hardstyle lane takes precedence over Master EDM', () {
      final block = GenreLyricsDirectives.userBlockDirective(
        primaryGenre: 'Hardstyle',
      );
      expect(block, contains('HARDSTYLE'));
      expect(block, isNot(contains('EDM BREAKDOWN VOCAL GUARDRAILS')));
      expect(block, isNot(contains('Write an EDM song based on')));
    });

    test('Deep House and Tech House use Master EDM not Future House', () {
      for (final genre in ['Deep House', 'Tech House']) {
        final block = GenreLyricsDirectives.userBlockDirective(
          primaryGenre: genre,
        );
        expect(
          block,
          contains('CROSS-ARCHITECTURE NON-NEGOTIABLES'),
          reason: genre,
        );
        expect(block, contains('HOUSE / DEEP HOUSE'), reason: genre);
        expect(
          block,
          isNot(contains('EDM BREAKDOWN VOCAL GUARDRAILS')),
          reason: genre,
        );
        expect(
          block.toLowerCase(),
          isNot(contains('future house')),
          reason: genre,
        );
      }
    });
  });
}
