import 'package:flutter_test/flutter_test.dart';
import 'package:music_director/core/constants/song_structure_data.dart';
import 'package:music_director/core/utils/dynamic_structural_engine.dart';

String _primaryFor(StructuralFamily family) =>
    StructuralFamilyResolver.laneHintFor(family);

void main() {
  group('DynamicStructuralEngine — family resolution', () {
    test('worship resolves to gospel family', () {
      expect(
        StructuralFamilyResolver.resolve(primaryGenre: 'Praise/Worship'),
        StructuralFamily.worship,
      );
    });

    test('amapiano resolves to amapiano family', () {
      expect(
        StructuralFamilyResolver.resolve(primaryGenre: 'Amapiano'),
        StructuralFamily.amapiano,
      );
    });

    test('trap resolves to trap family (not generic hiphop)', () {
      expect(
        StructuralFamilyResolver.resolve(primaryGenre: 'Melodic Trap'),
        StructuralFamily.trap,
      );
    });

    test('unknown genre falls back to popStandard', () {
      expect(
        StructuralFamilyResolver.resolve(primaryGenre: 'random'),
        StructuralFamily.popStandard,
      );
    });

    test('progressive house resolves to edmProgressiveHouse family', () {
      expect(
        StructuralFamilyResolver.resolve(primaryGenre: 'Progressive House'),
        StructuralFamily.edmProgressiveHouse,
      );
    });

    test('trance resolves to edmTrance family', () {
      expect(
        StructuralFamilyResolver.resolve(primaryGenre: 'Uplifting Trance'),
        StructuralFamily.edmTrance,
      );
    });

    test('hardstyle resolves to edmHardstyle family', () {
      expect(
        StructuralFamilyResolver.resolve(
          primaryGenre: 'Hardstyle',
          fusionGenre: 'Big Room House',
        ),
        StructuralFamily.edmHardstyle,
      );
    });

    test('fusion overrides primary when primary is unknown', () {
      expect(
        StructuralFamilyResolver.resolve(
          primaryGenre: 'misc',
          fusionGenre: 'Amapiano',
        ),
        StructuralFamily.amapiano,
      );
    });
  });

  group('DynamicStructuralEngine — structural assembly', () {
    test('every family ends with [End]', () {
      for (final family in StructuralFamily.values) {
        final sections = DynamicStructuralEngine.assembleSections(
          family: family,
          sunoVersion: 'v5.5',
        );
        expect(sections.last.label, 'End', reason: '$family must end with End');
      }
    });

    test('every family produces at least 4 sections', () {
      for (final family in StructuralFamily.values) {
        final sections = DynamicStructuralEngine.assembleSections(
          family: family,
          sunoVersion: 'v5.5',
        );
        expect(sections.length, greaterThanOrEqualTo(4));
      }
    });

    test('worship includes Vamp and Spontaneous Flow', () {
      final sections = DynamicStructuralEngine.assembleSections(
        family: StructuralFamily.worship,
        intent: SongIntent.congregational,
      );
      expect(sections.any((s) => s.kind == SectionKind.vamp), isTrue);
      expect(
        sections.any((s) => s.kind == SectionKind.spontaneousFlow),
        isTrue,
      );
    });

    test('EDM progressive house includes Drop A and Drop B', () {
      final sections = DynamicStructuralEngine.assembleSections(
        family: StructuralFamily.edmProgressiveHouse,
      );
      expect(sections.any((s) => s.kind == SectionKind.dropA), isTrue);
      expect(sections.any((s) => s.kind == SectionKind.dropB), isTrue);
    });

    test('EDM hardstyle includes Anti-Climax', () {
      final sections = DynamicStructuralEngine.assembleSections(
        family: StructuralFamily.edmHardstyle,
      );
      expect(sections.any((s) => s.kind == SectionKind.antiClimax), isTrue);
    });

    test('EDM drum and bass includes Drop A and Final Drop', () {
      final sections = DynamicStructuralEngine.assembleSections(
        family: StructuralFamily.edmDrumAndBass,
      );
      expect(sections.any((s) => s.kind == SectionKind.dropA), isTrue);
      expect(sections.any((s) => s.kind == SectionKind.finalDrop), isTrue);
    });

    test('folk has NO Drop', () {
      final sections = DynamicStructuralEngine.assembleSections(
        family: StructuralFamily.folk,
      );
      expect(
        sections.any((s) => s.kind == SectionKind.drop),
        isFalse,
        reason: 'Folk must strictly prune Drop',
      );
    });
  });

  group('DynamicStructuralEngine — userBlockDirective', () {
    test('output is deterministic (idempotent calls)', () {
      final a = DynamicStructuralEngine.userBlockDirective(
        primaryGenre: 'Amapiano',
        sunoVersion: 'v5.5',
      );
      final b = DynamicStructuralEngine.userBlockDirective(
        primaryGenre: 'Amapiano',
        sunoVersion: 'v5.5',
      );
      expect(a, equals(b));
    });

    test('directive contains no HTML entities', () {
      final d = DynamicStructuralEngine.userBlockDirective(
        primaryGenre: 'Pop',
        sunoVersion: 'v5.5',
      );
      expect(d, isNot(contains('&amp;')));
      expect(d, isNot(contains('&lt;')));
      expect(d, isNot(contains('&gt;')));
    });

    test('folk family forbids drops in directive', () {
      final d = DynamicStructuralEngine.userBlockDirective(
        primaryGenre: 'Folk',
        sunoVersion: 'v5.5',
      );
      expect(d, contains('STRICTLY NO [Drop]'));
    });

    test('assembleSections returns typed list', () {
      final sections = DynamicStructuralEngine.assembleSections(
        family: StructuralFamily.edmProgressiveHouse,
        sunoVersion: 'v5.5',
      );
      expect(sections, isA<List<SongSection>>());
      expect(sections, isNotEmpty);
    });

    test('output ends with [End] bracket rule', () {
      final out = DynamicStructuralEngine.userBlockDirective(
        primaryGenre: 'EDM',
        sunoVersion: 'v5.5',
      );
      expect(out.contains('[End]'), isTrue);
    });

    test('v4.5 output has no staging descriptors inside brackets', () {
      final out = DynamicStructuralEngine.userBlockDirective(
        primaryGenre: 'Pop',
        sunoVersion: 'v4.5',
      );
      final bracketLines = out
          .split('\n')
          .where((l) => l.trimLeft().startsWith('[') && l.contains(']'))
          .toList();
      for (final l in bracketLines) {
        expect(l.contains(':'), isFalse,
            reason: 'v4.5 bracket line must not contain staging: $l');
      }
    });

    test('user-defined roadmap renders without engine injection', () {
      const userSections = [
        SongSection(
          kind: SectionKind.verse,
          id: 'v1',
          label: 'Verse 1',
        ),
        SongSection(
          kind: SectionKind.chorus,
          id: 'c',
          label: 'Chorus',
        ),
      ];
      final out = DynamicStructuralEngine.userBlockDirective(
        sunoVersion: 'v5.5',
        userProvidedSections: userSections,
      );
      expect(out, contains('[USER-DEFINED ROADMAP]'));
      expect(out, contains('user_defined'));
      expect(out, contains('[Verse 1:'));
      expect(out, contains('[Chorus:'));
    });

    test('rendered bracket block stays below density cap', () {
      final out = DynamicStructuralEngine.userBlockDirective(
        primaryGenre: 'Progressive House',
        sunoVersion: 'v5.5',
      );
      final start = out.indexOf('RENDERED BRACKET LAYOUT');
      final end = out.indexOf('SHIP GATE');
      expect(start, greaterThan(-1));
      expect(end, greaterThan(start));
      final block = out.substring(start, end);
      expect(
        block.length,
        lessThanOrEqualTo(DynamicStructuralEngine.structuralPreambleCap + 120),
        reason: 'Bracket block should respect ~30% density budget',
      );
    });
  });

  group('SunoSyntaxRenderer — canonical validation', () {
    test('rejects non-canonical section names', () {
      const bad = [
        SongSection(
          kind: SectionKind.unknown,
          id: 'bad',
          label: 'Hook Drop',
        ),
      ];
      final failed = SunoSyntaxRenderer.validateCanonical(bad);
      expect(failed, contains('Hook Drop'));
    });

    test('accepts all canonical names', () {
      const canonical = [
        SongSection(kind: SectionKind.intro, id: 'i', label: 'Intro'),
        SongSection(kind: SectionKind.verse, id: 'v', label: 'Verse 1'),
        SongSection(kind: SectionKind.chorus, id: 'c', label: 'Chorus'),
        SongSection(kind: SectionKind.bridge, id: 'b', label: 'Bridge'),
        SongSection(kind: SectionKind.outro, id: 'o', label: 'Outro'),
      ];
      final failed = SunoSyntaxRenderer.validateCanonical(canonical);
      expect(failed, isEmpty);
    });
  });

  group('Universal rules across ALL families', () {
    for (final family in StructuralFamily.values) {
      test('$family: no imperative-verb instruction phrasing in defaults', () {
        const banned = [
          'ground the',
          'sonic world establish',
          'the turn, strip back',
          'or shift',
          'lead hook repeat',
          'decay / fade / tag',
        ];
        final sections = DynamicStructuralEngine.assembleSections(
          family: family,
          sunoVersion: 'v5.5',
        );
        for (final s in sections) {
          final idx = sections.indexOf(s);
          final rendered = SunoSyntaxRenderer.renderSection(
            s,
            'v5.5',
            family: family,
            sectionIndex: idx,
            allSections: sections,
          );
          for (final b in banned) {
            expect(rendered.toLowerCase().contains(b.toLowerCase()), isFalse,
                reason: '$family: "$s" leaked banned phrase "$b"');
          }
        }
      });

      test('$family: Verse 2 staging ≠ Verse 1 staging (escalation rule)', () {
        final sections = DynamicStructuralEngine.assembleSections(
          family: family,
          sunoVersion: 'v5.5',
        );
        final verses =
            sections.where((s) => s.kind == SectionKind.verse).toList();
        if (verses.length >= 2) {
          final v1 = SunoSyntaxRenderer.renderSection(
            verses[0],
            'v5.5',
            family: family,
            allSections: sections,
            sectionIndex: sections.indexOf(verses[0]),
          );
          final v2 = SunoSyntaxRenderer.renderSection(
            verses[1],
            'v5.5',
            family: family,
            allSections: sections,
            sectionIndex: sections.indexOf(verses[1]),
          );
          expect(v1, isNot(equals(v2)),
              reason: '$family: Verse 2 staging must escalate');
        }
      });

      test('$family: ends with End section', () {
        final sections = DynamicStructuralEngine.assembleSections(
          family: family,
        );
        expect(sections.last.label, 'End');
      });

      test('$family: bracket preamble ≤ 750 chars for v5.5', () {
        final out = DynamicStructuralEngine.userBlockDirective(
          primaryGenre: _primaryFor(family),
          sunoVersion: 'v5.5',
        );
        expect(
          out.split('SHIP GATE').first.length,
          lessThanOrEqualTo(750),
          reason: '$family preamble exceeds 750-char cap',
        );
      });

      test('$family: vocal-spec never as standalone bracket line', () {
        final out = DynamicStructuralEngine.userBlockDirective(
          primaryGenre: _primaryFor(family),
          sunoVersion: 'v5.5',
        );
        final bracketOnlyLines = out
            .split('\n')
            .where((l) => l.trimLeft().startsWith('[') && l.contains(']'))
            .where((l) => !l.startsWith('[End]'));
        for (final l in bracketOnlyLines) {
          expect(
            l.length,
            lessThan(80),
            reason: 'Standalone vocal spec leaked as bracket: $l',
          );
        }
      });
    }
  });

  group('Per-family canonical label overrides', () {
    test('EDM progressive house renders Drop A and Final Drop labels', () {
      final sections = DynamicStructuralEngine.assembleSections(
        family: StructuralFamily.edmProgressiveHouse,
      );
      expect(sections.any((s) => s.label == 'Drop A'), isTrue);
      expect(sections.any((s) => s.label == 'Drop B'), isTrue);
      expect(sections.any((s) => s.label == 'Chorus'), isFalse);
    });

    test('Worship arc includes Vamp + Spontaneous Flow when congregational', () {
      final sections = DynamicStructuralEngine.assembleSections(
        family: StructuralFamily.worship,
        intent: SongIntent.congregational,
      );
      expect(sections.any((s) => s.kind == SectionKind.vamp), isTrue);
      expect(
        sections.any((s) => s.kind == SectionKind.spontaneousFlow),
        isTrue,
      );
    });

    test('Amapiano: Bridge (if any) comes AFTER Verse 2, never before', () {
      final sections = DynamicStructuralEngine.assembleSections(
        family: StructuralFamily.amapiano,
        intent: SongIntent.complex,
      );
      final bridgeIdx =
          sections.indexWhere((s) => s.kind == SectionKind.bridge);
      final v2Idx = sections.indexWhere((s) {
        if (s.kind != SectionKind.verse) return false;
        return sections
                .sublist(0, sections.indexOf(s) + 1)
                .where((x) => x.kind == SectionKind.verse)
                .length ==
            2;
      });
      if (bridgeIdx >= 0) {
        expect(bridgeIdx, greaterThan(v2Idx),
            reason: 'Amapiano: Bridge must follow V2, never precede it');
      }
    });

    test('Folk has NO Drop sections', () {
      final sections = DynamicStructuralEngine.assembleSections(
        family: StructuralFamily.folk,
      );
      expect(sections.any((s) => s.kind == SectionKind.drop), isFalse);
    });

    test('Jazz Standard uses AABA head + solo + head-out form', () {
      final sections = DynamicStructuralEngine.assembleSections(
        family: StructuralFamily.jazzStandard,
      );
      expect(sections.any((s) => s.label.contains('Head')), isTrue);
      expect(sections.any((s) => s.label.contains('Middle Eight')), isTrue);
      expect(sections.any((s) => s.label.contains('Solo')), isTrue);
    });

    test('Cinematic uses Theme / Development / Climax / Coda labels', () {
      final sections = DynamicStructuralEngine.assembleSections(
        family: StructuralFamily.cinematic,
      );
      expect(sections.any((s) => s.label.contains('Theme')), isTrue);
      expect(sections.any((s) => s.label == 'Development'), isTrue);
      expect(sections.any((s) => s.label == 'Climax'), isTrue);
      expect(sections.any((s) => s.label == 'Coda'), isTrue);
    });

    test('Mandopop includes traditional instrument cues in default staging', () {
      final sections = DynamicStructuralEngine.assembleSections(
        family: StructuralFamily.mandopop,
      );
      final intro = sections.firstWhere((s) => s.kind == SectionKind.intro);
      final rendered = SunoSyntaxRenderer.renderSection(
        intro,
        'v5.5',
        family: StructuralFamily.mandopop,
        allSections: sections,
        sectionIndex: sections.indexOf(intro),
      );
      expect(
        rendered.contains('erhu') ||
            rendered.contains('guzheng') ||
            rendered.contains('pipa') ||
            rendered.contains('dizi'),
        isTrue,
        reason: 'Mandopop intro should reference traditional Chinese instrument',
      );
    });

    test('Boom Bap uses "Break" not "Bridge", "Chorus" not "Hook"', () {
      final sections = DynamicStructuralEngine.assembleSections(
        family: StructuralFamily.boom_bap,
      );
      expect(sections.any((s) => s.label == 'Bridge'), isFalse);
      expect(
        sections.any((s) =>
            s.label.contains('Break') || s.label.contains('Scratch')),
        isTrue,
      );
      expect(sections.any((s) => s.label == 'Chorus'), isTrue);
    });

    test('Trap leads with Hook (not Verse)', () {
      final sections = DynamicStructuralEngine.assembleSections(
        family: StructuralFamily.trap,
      );
      final firstAfterIntro = sections
          .skipWhile((s) => s.kind == SectionKind.intro)
          .first;
      expect(
        firstAfterIntro.kind == SectionKind.hook,
        isTrue,
        reason: 'Trap must lead with Hook after Intro',
      );
    });

    test('resolves "Boom Bap" genre to boom_bap family', () {
      expect(
        StructuralFamilyResolver.resolve(primaryGenre: 'Boom Bap'),
        StructuralFamily.boom_bap,
      );
      expect(
        StructuralFamilyResolver.resolve(primaryGenre: '90s Hip Hop'),
        StructuralFamily.boom_bap,
      );
    });
  });
}
