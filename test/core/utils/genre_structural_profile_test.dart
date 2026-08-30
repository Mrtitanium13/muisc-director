import 'package:flutter_test/flutter_test.dart';
import 'package:music_director/core/constants/song_structure_data.dart';
import 'package:music_director/core/utils/final_chorus_mutation_rule.dart';
import 'package:music_director/core/utils/genre_structural_profile.dart';
import 'package:music_director/core/utils/structural_family_resolver.dart';

void main() {
  group('GenreStructuralProfile — label overrides', () {
    test('boom_bap hook renders as Chorus', () {
      const s = SongSection(
        kind: SectionKind.hook,
        id: 'hook',
        label: 'Hook',
      );
      expect(
        GenreStructuralProfile.displayLabel(s, StructuralFamily.boom_bap),
        'Chorus',
      );
    });

    test('worship spontaneous flow uses full label', () {
      const s = SongSection(
        kind: SectionKind.spontaneousFlow,
        id: 'flow',
        label: 'Spontaneous Flow',
      );
      expect(
        GenreStructuralProfile.displayLabel(s, StructuralFamily.worship),
        'Spontaneous Worship / Flow',
      );
    });
  });

  group('GenreStructuralProfile — staging vocabulary', () {
    test('mandopop intro references traditional Chinese instrument', () {
      const ctx = StagingContext(kind: SectionKind.intro, label: 'Intro');
      final staging = GenreStructuralProfile.defaultStaging(
        StructuralFamily.mandopop,
        ctx,
      );
      expect(
        staging.contains('erhu') ||
            staging.contains('guzheng') ||
            staging.contains('pipa') ||
            staging.contains('dizi'),
        isTrue,
      );
    });

    test('hiphop verse 2 differs from verse 1', () {
      final v1 = GenreStructuralProfile.defaultStaging(
        StructuralFamily.hiphop,
        const StagingContext(
          kind: SectionKind.verse,
          label: 'Verse 1',
          verseOrdinal: 1,
        ),
      );
      final v2 = GenreStructuralProfile.defaultStaging(
        StructuralFamily.hiphop,
        const StagingContext(
          kind: SectionKind.verse,
          label: 'Verse 2',
          verseOrdinal: 2,
        ),
      );
      expect(v1, isNot(equals(v2)));
    });

    test('edm intro mentions 16-bar DJ loop', () {
      const ctx = StagingContext(kind: SectionKind.intro, label: 'Intro');
      final staging = GenreStructuralProfile.defaultStaging(
        StructuralFamily.edmProgressiveHouse,
        ctx,
      );
      expect(staging.toLowerCase(), contains('16-bar'));
    });

    test('no family staging contains banned imperative phrases', () {
      const banned = [
        'ground the',
        'sonic world establish',
        'the turn, strip back',
        'lead hook repeat',
        'decay / fade / tag',
      ];
      for (final family in StructuralFamily.values) {
        for (final kind in SectionKind.values) {
          if (kind == SectionKind.end || kind == SectionKind.unknown) continue;
          final staging = GenreStructuralProfile.defaultStaging(
            family,
            StagingContext(
              kind: kind,
              label: 'Test',
              verseOrdinal: 1,
              hookOrdinal: 1,
              chorusOrdinal: 1,
            ),
          );
          for (final b in banned) {
            expect(
              staging.toLowerCase().contains(b.toLowerCase()),
              isFalse,
              reason: '$family/$kind leaked "$b"',
            );
          }
        }
      }
    });
  });

  group('FinalChorusMutationRule — mutation table', () {
    test('covers all structural families', () {
      for (final family in StructuralFamily.values) {
        expect(FinalChorusMutationRule.mutationTable.containsKey(family), isTrue,
            reason: '$family missing from mutationTable');
      }
    });

    test('hiphop and boom_bap use hookExtensionWithAdLibFlood', () {
      expect(
        FinalChorusMutationRule.mutationFor(StructuralFamily.hiphop),
        FinalChorusMutation.hookExtensionWithAdLibFlood,
      );
      expect(
        FinalChorusMutationRule.mutationFor(StructuralFamily.boom_bap),
        FinalChorusMutation.hookExtensionWithAdLibFlood,
      );
    });

    test('worship mutation routing', () {
      expect(
        FinalChorusMutationRule.mutationFor(StructuralFamily.worship),
        FinalChorusMutation.gospelVampCallAndResponse,
      );
    });

    test('stagingNoteFor covers every enum value', () {
      for (final m in FinalChorusMutation.values) {
        expect(FinalChorusMutationRule.stagingNoteFor(m), isNotEmpty);
      }
    });

    test('directiveFor v4.5 does not emit staging', () {
      final d = FinalChorusMutationRule.directiveFor(
        mutation: FinalChorusMutation.keyChangeAndOctaveDouble,
        sunoVersion: 'v4.5',
      );
      expect(d, contains('v4.5'));
      expect(d, isNot(contains('key-change lift')));
    });

    test('directiveFor v5.5 emits full staging', () {
      final d = FinalChorusMutationRule.directiveFor(
        mutation: FinalChorusMutation.keyChangeAndOctaveDouble,
        sunoVersion: 'v5.5',
      );
      expect(d, contains('key-change lift'));
      expect(d, contains('mandatory'));
    });

    test('inline staging shortens for non-v5.5', () {
      final inline = FinalChorusMutationRule.directiveFor(
        mutation: FinalChorusMutation.adLibCounterMelody,
        sunoVersion: 'v5',
        inline: true,
      );
      expect(inline, 'ad-lib counter-melody');
    });

    test('inline staging empty for v4.5', () {
      final inline = FinalChorusMutationRule.directiveFor(
        mutation: FinalChorusMutation.beatSwitchVariation,
        sunoVersion: 'v4.5',
        inline: true,
      );
      expect(inline, isEmpty);
    });

    test('inlineStagingFor routes through family table', () {
      final staging = FinalChorusMutationRule.inlineStagingFor(
        family: StructuralFamily.amapiano,
        sunoVersion: 'v5.5',
      );
      expect(staging, contains('log drum'));
    });
  });
}
