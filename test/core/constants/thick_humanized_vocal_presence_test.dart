import 'package:flutter_test/flutter_test.dart';
import 'package:music_director/core/constants/thick_humanized_vocal_presence.dart';
import 'package:music_director/core/constants/vocal_spec_tone_data.dart';

void main() {
  group('ThickHumanizedVocalPresence', () {
    test('skips instrumental-only', () {
      expect(
        ThickHumanizedVocalPresence.composeUserBlock(
          primaryGenre: 'Trance',
          vocalSpec: 'Instrumental Only',
        ),
        isEmpty,
      );
    });

    test('injects pop overlay for vocal pop', () {
      final block = ThickHumanizedVocalPresence.composeUserBlock(
        primaryGenre: 'Pop',
        vocalSpec: 'Female Lead',
      );
      expect(block, contains('THICK HUMANIZED VOCAL PRESENCE'));
      expect(block.toLowerCase(), contains('ultra-close-mic'));
      expect(block, contains('FAMILY OVERLAY — POP'));
    });

    test('edm dense overlay for hardstyle / big room / trance', () {
      for (final genre in [
        'Hardstyle',
        'Progressive House',
        'Trance',
        'Big Room House',
      ]) {
        final block = ThickHumanizedVocalPresence.composeUserBlock(
          primaryGenre: genre,
          vocalSpec: 'Female Lead',
        );
        expect(block, contains('FAMILY OVERLAY — EDM DENSE'));
        expect(block, contains('supersaw'));
      }
    });

    test('normalizes punctuated genre labels', () {
      expect(
        ThickHumanizedVocalPresence.detectFamily('Hard-Style', 'Rawstyle Fusion'),
        VocalFamily.edmDense,
      );
      expect(
        ThickHumanizedVocalPresence.detectFamily('K-Pop', ''),
        VocalFamily.asianPop,
      );
      expect(
        ThickHumanizedVocalPresence.composeUserBlock(
          primaryGenre: 'R&B',
          vocalSpec: VocalSpecToneData.femaleLeadSpec,
        ),
        contains('R&B'),
      );
    });

    test('word-boundary matching avoids false positives', () {
      expect(
        ThickHumanizedVocalPresence.detectFamily('Afternoon Folk Set', ''),
        VocalFamily.acoustic,
      );
      expect(
        ThickHumanizedVocalPresence.detectFamilies('Afternoon Folk Set', ''),
        isNot(contains(VocalFamily.afro)),
      );
      // kpop is asian; bare "pop" must not win via substring inside kpop
      expect(
        ThickHumanizedVocalPresence.detectFamily('kpop', ''),
        VocalFamily.asianPop,
      );
    });

    test('detectFamilies returns fusion matches in priority order', () {
      final families = ThickHumanizedVocalPresence.detectFamilies(
        'Afro House',
        'R&B Fusion',
      );
      expect(families, containsAll([VocalFamily.afro, VocalFamily.rnb]));
      expect(families.first, VocalFamily.afro);

      final single = ThickHumanizedVocalPresence.composeUserBlock(
        primaryGenre: 'Afro House',
        subGenreFusion: 'R&B',
        vocalSpec: 'Female Lead',
      );
      expect(single, contains('AFRO'));
      expect(single, isNot(contains('R&B / SOUL')));

      final multi = ThickHumanizedVocalPresence.composeUserBlock(
        primaryGenre: 'Afro House',
        subGenreFusion: 'R&B',
        vocalSpec: 'Female Lead',
        includeAllFamilyMatches: true,
      );
      expect(multi, contains('AFRO'));
      expect(multi, contains('R&B / SOUL'));
    });

    test('latin and pop families', () {
      expect(
        ThickHumanizedVocalPresence.detectFamily('Reggaeton', ''),
        VocalFamily.latin,
      );
      expect(
        ThickHumanizedVocalPresence.composeUserBlock(
          primaryGenre: 'Reggaeton',
          vocalSpec: 'Male Lead',
        ),
        contains('LATIN'),
      );
      expect(
        ThickHumanizedVocalPresence.detectFamily('Bedroom Pop', ''),
        VocalFamily.pop,
      );
    });

    test('falls back to vocal spec when genre family unknown', () {
      // Use a genre that matches no family keyword so the spec fallback fires.
      expect(
        ThickHumanizedVocalPresence.composeUserBlock(
          primaryGenre: 'Zither Polka Fusion',
          vocalSpec: VocalSpecToneData.rapVocalSpaceSpec,
        ),
        contains('HIP-HOP'),
      );
      expect(
        ThickHumanizedVocalPresence.composeUserBlock(
          primaryGenre: 'Zither Polka Fusion',
          vocalSpec: VocalSpecToneData.gospelChoirSpec,
        ),
        contains('GOSPEL'),
      );
    });

    test('ambient maps to acoustic family overlay', () {
      expect(
        ThickHumanizedVocalPresence.composeUserBlock(
          primaryGenre: 'Ambient Drone',
          vocalSpec: VocalSpecToneData.maleLeadSpec,
        ),
        contains('ACOUSTIC'),
      );
    });

    test('family overlays for hip-hop gospel afro asian rnb rock acoustic', () {
      expect(
        ThickHumanizedVocalPresence.composeUserBlock(
          primaryGenre: 'Trap',
          vocalSpec: 'Male Lead',
        ),
        contains('HIP-HOP'),
      );
      expect(
        ThickHumanizedVocalPresence.composeUserBlock(
          primaryGenre: 'Gospel',
          vocalSpec: 'Choir',
        ),
        contains('GOSPEL'),
      );
      expect(
        ThickHumanizedVocalPresence.composeUserBlock(
          primaryGenre: 'Amapiano',
          vocalSpec: 'Female Lead',
        ),
        contains('AFRO'),
      );
      expect(
        ThickHumanizedVocalPresence.composeUserBlock(
          primaryGenre: 'K-Pop',
          vocalSpec: 'Female Lead',
        ),
        contains('ASIAN POP'),
      );
      expect(
        ThickHumanizedVocalPresence.composeUserBlock(
          primaryGenre: 'R&B',
          vocalSpec: 'Female Lead',
        ),
        contains('R&B'),
      );
      expect(
        ThickHumanizedVocalPresence.composeUserBlock(
          primaryGenre: 'Indie Rock',
          vocalSpec: 'Male Lead',
        ),
        contains('ROCK'),
      );
      expect(
        ThickHumanizedVocalPresence.composeUserBlock(
          primaryGenre: 'Folk',
          vocalSpec: 'Female Lead',
        ),
        contains('ACOUSTIC'),
      );
    });
  });
}
