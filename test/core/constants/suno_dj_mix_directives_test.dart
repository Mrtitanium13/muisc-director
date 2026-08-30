import 'package:flutter_test/flutter_test.dart';

import 'package:music_director/core/constants/suno_dj_mix_directives.dart';
import 'package:music_director/core/utils/structural_family_resolver.dart';

void main() {
  group('DJ mix directives — language hygiene', () {
    test('NO sidechain / sidechain-friendly wording', () {
      final intro = _allIntroCopy.join('\n');
      final outro = _allOutroCopy.join('\n');
      expect(intro.toLowerCase().contains('sidechain'), isFalse);
      expect(outro.toLowerCase().contains('sidechain'), isFalse);
    });

    test('NO mono-safe wording', () {
      final intro = _allIntroCopy.join('\n');
      expect(intro.toLowerCase().contains('mono-safe'), isFalse);
    });

    test('positive content-first vocabulary preserved', () {
      final both = '${_allIntroCopy.join('\n')}\n${_allOutroCopy.join('\n')}';
      const mustKeep = [
        'kick',
        'wordless',
        'percussion',
        'instrumental intro',
        'loopable fade',
        '[dj intro: on]',
        '[dj outro: on]',
      ];
      for (final word in mustKeep) {
        expect(
          both.toLowerCase().contains(word.toLowerCase()),
          isTrue,
          reason: 'DJ sonic vocabulary "$word" must be preserved',
        );
      }
    });

    test('never instructs negation phrasing as the render strategy', () {
      for (final out in [..._allIntroCopy, ..._allOutroCopy]) {
        final lower = out.toLowerCase();
        expect(
          lower.contains('never "no vocals / no melody"'),
          isTrue,
          reason: 'must ban negation phrasing explicitly',
        );
        expect(lower.contains('no lead vocal'), isFalse);
        expect(lower.contains('no hard cut'), isFalse);
      }
    });
  });

  group('DJ mix directives — genre gating', () {
    test('DJ mix allowed for EDM', () {
      expect(djMixAllowedForFamily(StructuralFamily.edmProgressiveHouse), isTrue);
    });

    test('DJ mix allowed for Amapiano', () {
      expect(djMixAllowedForFamily(StructuralFamily.amapiano), isTrue);
    });

    test('DJ mix allowed for Trap', () {
      expect(djMixAllowedForFamily(StructuralFamily.trap), isTrue);
    });

    test('DJ mix disallowed for Worship', () {
      expect(djMixAllowedForFamily(StructuralFamily.worship), isFalse);
    });

    test('DJ mix disallowed for Jazz Standard', () {
      expect(djMixAllowedForFamily(StructuralFamily.jazzStandard), isFalse);
    });

    test('DJ mix disallowed for Folk', () {
      expect(djMixAllowedForFamily(StructuralFamily.folk), isFalse);
    });

    test('DJ mix disallowed for Cinematic', () {
      expect(djMixAllowedForFamily(StructuralFamily.cinematic), isFalse);
    });

    test('DJ mix disallowed for Mandopop', () {
      expect(djMixAllowedForFamily(StructuralFamily.mandopop), isFalse);
    });

    test('worship toggle on returns empty directive', () {
      final out = buildDjMixUserBlock(
        djIntroMixIn: true,
        djOutroMixOut: true,
        sunoVersion: 'v5.5',
        family: StructuralFamily.worship,
      );
      expect(out, isEmpty);
    });
  });

  group('DJ mix directives — genre-aware bar counts', () {
    test('EDM uses 32-bar intro and outro', () {
      final config = djBarConfigFor(StructuralFamily.edmProgressiveHouse);
      expect(config.introBars, equals(32));
      expect(config.outroBars, equals(32));
    });

    test('Amapiano uses 16-bar intro and outro', () {
      final config = djBarConfigFor(StructuralFamily.amapiano);
      expect(config.introBars, equals(16));
      expect(config.outroBars, equals(16));
    });

    test('Trap uses 4-bar intro and outro', () {
      final config = djBarConfigFor(StructuralFamily.trap);
      expect(config.introBars, equals(4));
      expect(config.outroBars, equals(4));
    });

    test('Hip-Hop / Boom-Bap use 4-bar intro and outro', () {
      expect(djBarConfigFor(StructuralFamily.hiphop).introBars, equals(4));
      expect(djBarConfigFor(StructuralFamily.boom_bap).introBars, equals(4));
    });

    test('EDM directive cites 32-bar count not generic range', () {
      final out = buildDjMixUserBlock(
        djIntroMixIn: true,
        djOutroMixOut: false,
        sunoVersion: 'v5.5',
        family: StructuralFamily.edmProgressiveHouse,
      );
      expect(out.contains('~32 bars'), isTrue);
      expect(out.contains('16–48'), isFalse);
      expect(out.contains('16-48'), isFalse);
    });
  });

  group('DJ mix directives — production brief', () {
    test('enabled intro uses authoritative production requirement header', () {
      final out = buildDjMixUserBlock(
        djIntroMixIn: true,
        djOutroMixOut: false,
        sunoVersion: 'v5.5',
        family: StructuralFamily.edmProgressiveHouse,
      );
      expect(out, contains('[PRODUCTION REQUIREMENT: DJ-FRIENDLY STRUCTURE]'));
      expect(out.toLowerCase(), contains('section 1f'));
      expect(out, contains('[DJ INTRO: ON]'));
      expect(out, contains('wordless percussion intro'));
      expect(out, contains('[Instrumental Intro:'));
      expect(out, contains('[Percussion Build:'));
      expect(out, contains('[Riser:'));
    });

    test('enabled outro uses content-rich fade bookends', () {
      final out = buildDjMixUserBlock(
        djIntroMixIn: false,
        djOutroMixOut: true,
        sunoVersion: 'v5.5',
        family: StructuralFamily.edmProgressiveHouse,
      );
      expect(out, contains('[DJ OUTRO: ON]'));
      expect(out, contains('[Instrumental Outro:'));
      expect(out, contains('[Fade Out:'));
      expect(out, contains('loopable fade'));
    });

    test('off state returns empty string', () {
      final out = buildDjMixUserBlock(
        djIntroMixIn: false,
        djOutroMixOut: false,
        sunoVersion: 'v5.5',
        family: StructuralFamily.edmProgressiveHouse,
      );
      expect(out, isEmpty);
    });

    test('v4.5 includes bar phrasing without v5.5 multi-descriptor brackets', () {
      final out = buildDjMixUserBlock(
        djIntroMixIn: true,
        djOutroMixOut: false,
        sunoVersion: 'v4.5',
        family: StructuralFamily.edmProgressiveHouse,
      );
      expect(out, contains('~32-bar'));
      expect(out, contains('sonic language'));
      expect(out.toLowerCase(), isNot(contains("director's notes")));
    });

    test('v5 returns short bracket meta lines (≤1 descriptor each)', () {
      final out = buildDjMixUserBlock(
        djIntroMixIn: true,
        djOutroMixOut: true,
        sunoVersion: 'v5',
        family: StructuralFamily.edmProgressiveHouse,
      );
      final bracketLines = out
          .split('\n')
          .where((l) => l.trimLeft().startsWith('['))
          .toList();
      for (final l in bracketLines) {
        final content = l.replaceFirst('[', '').replaceFirst(']', '');
        expect(content.split(',').length, lessThanOrEqualTo(1),
            reason: 'v5 DJ bracket line must NOT have multiple descriptors: $l');
      }
    });

    test('v5.5 supports multi-descriptor cinematic staging', () {
      final out = buildDjMixUserBlock(
        djIntroMixIn: true,
        djOutroMixOut: true,
        sunoVersion: 'v5.5',
        family: StructuralFamily.edmProgressiveHouse,
      );
      expect(out.contains('filter'), isFalse); // audio-first: no filter-motion mandate
      expect(out, contains('[Instrumental Intro: four-on-the-floor kick loop'));
      expect(out, contains('loopable fade'));
      expect(out.toLowerCase(), contains("director's notes"));
    });
  });

  group('DJ mix directives — budget', () {
    test('total directive ≤ $kDjMixUserBlockCharCap chars', () {
      final out = buildDjMixUserBlock(
        djIntroMixIn: true,
        djOutroMixOut: true,
        sunoVersion: 'v5.5',
        family: StructuralFamily.edmProgressiveHouse,
      );
      expect(out.length, lessThanOrEqualTo(kDjMixUserBlockCharCap),
          reason:
              'DJ directive total ${out.length} exceeds $kDjMixUserBlockCharCap-char cap');
    });
  });

  group('DJ mix directives — genre modifier', () {
    test('appends DJ Tool modifier when mix enabled', () {
      final out = primaryGenreWithDjToolModifier(
        primaryGenre: 'Progressive House',
        djIntroMixIn: true,
        djOutroMixOut: false,
        family: StructuralFamily.edmProgressiveHouse,
      );
      expect(out, 'Progressive House, DJ Tool, Club Mix');
    });

    test('skips modifier when mix disabled', () {
      final out = primaryGenreWithDjToolModifier(
        primaryGenre: 'Progressive House',
        djIntroMixIn: false,
        djOutroMixOut: false,
        family: StructuralFamily.edmProgressiveHouse,
      );
      expect(out, 'Progressive House');
    });
  });

  group('DJ mix directives — no verbatim mirror instruction', () {
    test('_impl copy must NOT instruct LLM to repeat verbatim across blocks', () {
      const stringsToCheck = [djMixImplV1, djMixImplV2];
      const banned = [
        'verbatim',
        'repeat the dj',
        'mirror it as',
        'mirror it in',
      ];
      for (final s in stringsToCheck) {
        for (final b in banned) {
          expect(s.toLowerCase().contains(b.toLowerCase()), isFalse,
              reason:
                  '_impl must not instruct LLM to mirror/verbatim-repeat. Found: "$b"');
        }
      }
    });
  });

  group('DJ mix directives — resolver routing', () {
    test('tech house routes to edmTechno for DJ bar config', () {
      expect(
        StructuralFamilyResolver.resolve(primaryGenre: 'Tech House'),
        StructuralFamily.edmTechno,
      );
    });

    test('dj house routes to edmTechno', () {
      expect(
        StructuralFamilyResolver.resolve(primaryGenre: 'DJ House'),
        StructuralFamily.edmTechno,
      );
    });
  });
}

final _allIntroCopy = [
  for (final f in [
    StructuralFamily.edmProgressiveHouse,
    StructuralFamily.trap,
    StructuralFamily.amapiano,
  ])
    for (final v in ['v4.5', 'v5', 'v5.5'])
      buildDjMixUserBlock(
        djIntroMixIn: true,
        djOutroMixOut: false,
        sunoVersion: v,
        family: f,
      ),
];

final _allOutroCopy = [
  for (final f in [
    StructuralFamily.edmProgressiveHouse,
    StructuralFamily.trap,
    StructuralFamily.amapiano,
  ])
    for (final v in ['v4.5', 'v5', 'v5.5'])
      buildDjMixUserBlock(
        djIntroMixIn: false,
        djOutroMixOut: true,
        sunoVersion: v,
        family: f,
      ),
];
