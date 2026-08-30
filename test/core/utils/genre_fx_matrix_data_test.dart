import 'package:flutter_test/flutter_test.dart';
import 'package:music_director/core/utils/genre_fx_matrix_data.dart';

void main() {
  group('GenreFxMatrixData coverage', () {
    const required = {
      'edm',
      'techno',
      'hardstyle',
      'dnb',
      'synthwave',
      'dubstep',
      'ambient',
      'hiphop',
      'trap',
      'boom_bap',
      'amapiano',
      'pop',
      'rnb',
      'reggaeton',
      'latin',
      'rock',
      'metal',
      'indie',
      'country',
      'folk',
      'afrobeats',
      'cinematic',
      'jazz',
      'worship',
      'mandopop',
      'world',
    };

    test('all required families present', () {
      for (final fam in required) {
        expect(
          GenreFxMatrixData.profiles.containsKey(fam),
          isTrue,
          reason: 'Missing family: $fam',
        );
        expect(
          GenreFxMatrixData.primaryAnchors.containsKey(fam),
          isTrue,
          reason: 'Missing anchors: $fam',
        );
      }
    });

    test('every family has all 3 tiers with both keys', () {
      for (final fam in required) {
        final row = GenreFxMatrixData.profiles[fam];
        for (final tier in ['1', '2', '3']) {
          expect(row, contains(tier), reason: '$fam missing tier $tier');
          expect(
            row![tier]!,
            containsPair('style', isNotNull),
            reason: '$fam[$tier] missing style',
          );
          expect(
            row[tier]!,
            containsPair('lyrics', isNotNull),
            reason: '$fam[$tier] missing lyrics',
          );
        }
      }
    });

    test('no DAW-routing jargon in any style', () {
      const banned = ['sidechain', 'brick-wall', 'brick wall', 'bus routing'];
      for (final fam in required) {
        for (final tier in ['1', '2', '3']) {
          final style =
              GenreFxMatrixData.profiles[fam]![tier]!['style']!.toLowerCase();
          for (final term in banned) {
            expect(
              style.contains(term),
              isFalse,
              reason: '$fam[$tier] contains banned term: $term',
            );
          }
        }
      }
    });

    test('lyrics values have no leading/trailing whitespace', () {
      for (final fam in required) {
        for (final tier in ['1', '2', '3']) {
          final lyrics = GenreFxMatrixData.profiles[fam]![tier]!['lyrics']!;
          expect(
            lyrics,
            equals(lyrics.trim()),
            reason: '$fam[$tier] lyrics has surrounding whitespace',
          );
        }
      }
    });
  });

  group('GenreFxMatrixData.getFx safe accessor', () {
    test('getFx returns valid values for known family', () {
      final fx = GenreFxMatrixData.getFx(family: 'edm', tier: '2');
      expect(fx.style, isNotEmpty);
      expect(fx.lyrics, isNotEmpty);
    });

    test('getAnchors returns lane-specific golden anchors', () {
      expect(
        GenreFxMatrixData.getAnchors(family: 'hardstyle'),
        ['[Monologue]', '[Drop: Reverse Bass]'],
      );
      expect(
        GenreFxMatrixData.getAnchors(family: 'techno'),
        ['[Drop: Heavy Kick]'],
      );
    });

    test('getFx falls back to sibling for boom_bap', () {
      final fx = GenreFxMatrixData.getFx(family: 'boom_bap', tier: '2');
      expect(
        fx.style.contains('hiphop'),
        isFalse,
        reason: 'fallback should use hiphop content, not literal text',
      );
      expect(fx.style, isNotEmpty);
    });

    test('getFx falls back to sibling for amapiano', () {
      final fx = GenreFxMatrixData.getFx(family: 'amapiano', tier: '2');
      expect(fx.style, contains('log drum'));
    });

    test('getFx returns empty strings for unknown family with no fallback', () {
      final fx = GenreFxMatrixData.getFx(family: 'notarealgenre', tier: '2');
      expect(fx.style, isEmpty);
      expect(fx.lyrics, isEmpty);
    });

    test('tier 1 lyrics is empty for all families (convention)', () {
      for (final fam in GenreFxMatrixData.profiles.keys) {
        final fx = GenreFxMatrixData.getFx(family: fam, tier: '1');
        expect(
          fx.lyrics,
          isEmpty,
          reason: 'tier 1 lyrics should be empty for $fam',
        );
      }
    });

    test('trap uses Hook vocabulary (not Pre-Chorus/Chorus/Drop)', () {
      final fx2 = GenreFxMatrixData.getFx(family: 'trap', tier: '2');
      expect(fx2.lyrics.contains('Pre-Chorus'), isFalse);
      expect(fx2.lyrics.contains('Chorus'), isFalse);
      final fx3 = GenreFxMatrixData.getFx(family: 'trap', tier: '3');
      expect(fx3.lyrics.contains('Drop:'), isFalse);
    });

    test('cinematic uses Climax/Coda vocabulary (not Chorus/Drop)', () {
      final fx3 = GenreFxMatrixData.getFx(family: 'cinematic', tier: '3');
      expect(fx3.lyrics.contains('Chorus'), isFalse);
      expect(fx3.lyrics.contains('Drop:'), isFalse);
    });
  });
}
