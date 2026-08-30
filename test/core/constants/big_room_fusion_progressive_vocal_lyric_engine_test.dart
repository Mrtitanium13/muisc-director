import 'package:flutter_test/flutter_test.dart';
import 'package:music_director/core/constants/big_room_fusion_progressive_vocal_lyric_engine.dart';
import 'package:music_director/core/constants/edm_breakdown_vocal_lyric_engine.dart';
import 'package:music_director/core/constants/genre_lyrics_directives.dart';
import 'package:music_director/core/ai/modules/k_genre_cliche_blacklist.dart';
import 'package:music_director/core/utils/advanced_thematic_variator.dart';

void main() {
  group('BigRoomFusionProgressiveVocalLyricEngine', () {
    test('isBigRoomFusionLane matches fusion combo and markers', () {
      expect(
        BigRoomFusionProgressiveVocalLyricEngine.isBigRoomFusionLane(
          primaryGenre: 'Progressive House',
          subGenreFusion: 'Big Room House',
        ),
        isTrue,
      );
      expect(
        BigRoomFusionProgressiveVocalLyricEngine.isBigRoomFusionLane(
          primaryGenre: 'Big Room',
          subGenreFusion: 'Progressive House',
        ),
        isTrue,
      );
      expect(
        BigRoomFusionProgressiveVocalLyricEngine.isBigRoomFusionLane(
          primaryGenre: 'Melodic Techno',
        ),
        isFalse,
      );
    });

    test('legacy composeUserBlock empty when master progressive owns lane', () {
      final block = BigRoomFusionProgressiveVocalLyricEngine.composeUserBlock(
        primaryGenre: 'Progressive House',
        subGenreFusion: 'Big Room House',
      );
      expect(block, isEmpty);
    });

    test('expanded markers catch progressive festival house big room', () {
      expect(
        BigRoomFusionProgressiveVocalLyricEngine.isBigRoomFusionLane(
          primaryGenre: 'Progressive Festival House Big Room',
        ),
        isTrue,
      );
    });
  });

  group('GenreLyricsDirectives big room fusion routing', () {
    test('userBlockDirective injects master progressive big room engine', () {
      final block = GenreLyricsDirectives.userBlockDirective(
        primaryGenre: 'Progressive House',
        subGenreFusion: 'Big Room House',
      );
      expect(block, contains('CROSS-ARCHITECTURE NON-NEGOTIABLES'));
      expect(block, contains('BIG ROOM FUSION'));
      expect(block, isNot(contains('EDM BREAKDOWN VOCAL GUARDRAILS')));
    });

    test('big room fusion takes precedence over generic EDM breakdown', () {
      expect(
        EdmBreakdownVocalLyricEngine.isEdmBreakdownLane(
          primaryGenre: 'Progressive House',
          subGenreFusion: 'Big Room House',
        ),
        isFalse,
      );
    });

    test('pure progressive house uses master progressive vocal profile', () {
      final block = GenreLyricsDirectives.userBlockDirective(
        primaryGenre: 'Progressive House',
      );
      expect(block, contains('CROSS-ARCHITECTURE NON-NEGOTIABLES'));
      expect(block, contains('PROGRESSIVE HOUSE (VOCAL)'));
      expect(block, isNot(contains('EDM BREAKDOWN VOCAL GUARDRAILS')));
    });
  });

  group('Big room fusion thematic variator', () {
    test('resolveThematicProfile returns big_room_fusion', () {
      expect(
        resolveThematicProfile('Progressive House', 'Big Room House'),
        'big_room_fusion',
      );
    });
  });

  group('Big room fusion cliché pack', () {
    test('clichePackKeyFor routes fusion lane', () {
      expect(
        clichePackKeyFor('Progressive House Big Room House'),
        'big_room_fusion_vocal',
      );
    });
  });
}
