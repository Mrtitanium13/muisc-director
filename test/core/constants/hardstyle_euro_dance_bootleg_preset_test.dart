import 'package:flutter_test/flutter_test.dart';
import 'package:music_director/core/constants/genre_lyrics_directives.dart';
import 'package:music_director/core/constants/hardstyle_euro_dance_bootleg_preset.dart';
import 'package:music_director/core/constants/hardstyle_vocal_lyric_engine.dart';
import 'package:music_director/core/constants/master_hardstyle_lyric_engine.dart';
import 'package:music_director/core/constants/prompt_templates.dart';

void main() {
  group('HardstyleEuroDanceBootlegPreset', () {
    test('composeVibeProse includes kick palette and engineering terms', () {
      final vibe = HardstyleEuroDanceBootlegPreset.composeVibeProse();
      expect(vibe, contains('Hardstyle'));
      expect(vibe, contains('Euro-Dance Bootleg'));
      expect(vibe, contains('Hands Up EDM'));
      expect(vibe, contains('distorted hardstyle kick'));
      expect(vibe, contains('reverse bass'));
      expect(vibe, contains('detuned supersaw'));
      expect(vibe, contains('150 BPM'));
      expect(vibe, contains('brickwall-limited'));
      expect(vibe, contains('sidechain compression'));
    });

    test('composeStructureNotes covers intro breakdown build drop arc', () {
      final notes = HardstyleEuroDanceBootlegPreset.composeStructureNotes();
      expect(notes, contains('Intro / Club Mix'));
      expect(notes, contains('Verse / Breakdown'));
      expect(notes, contains('Build-Up'));
      expect(notes, contains('Hardstyle Drop'));
      expect(notes, contains('reverb washout'));
    });

    test('templateModel wires edm_drop and production intensity', () {
      final m = HardstyleEuroDanceBootlegPreset.templateModel;
      expect(m.primaryGenre, 'Hardstyle');
      expect(m.subGenreFusion, 'Euro-Dance Bootleg');
      expect(m.bpm, '150');
      expect(m.songStructurePresetId, 'edm_drop');
      expect(m.productionIntensity, 3);
      expect(m.generateLyrics, isTrue);
    });
  });

  group('PromptTemplates hardstyle bootleg', () {
    test('template is registered and loads preset model', () {
      final t = PromptTemplates.byId(HardstyleEuroDanceBootlegPreset.id);
      expect(t, isNotNull);
      expect(t!.title, contains('Euro-Dance'));
      expect(t.model.vibe, contains('reverse bass'));
      expect(t.model.songStructureCustom, contains('Hardstyle Drop'));
    });
  });

  group('HardstyleVocalLyricEngine bootleg profile', () {
    test('isEuroDanceBootlegProfile matches fusion lane', () {
      expect(
        HardstyleVocalLyricEngine.isEuroDanceBootlegProfile(
          primaryGenre: 'Hardstyle',
          subGenreFusion: 'Euro-Dance Bootleg',
        ),
        isTrue,
      );
    });

    test('composeUserBlock defers to Master Hardstyle for fusion lane', () {
      final legacy = HardstyleVocalLyricEngine.composeUserBlock(
        primaryGenre: 'Hardstyle',
        subGenreFusion: 'Euro-Dance Bootleg',
      );
      expect(legacy, isEmpty);

      final master = MasterHardstyleLyricEngine.composeUserBlock(
        primaryGenre: 'Hardstyle',
        subGenreFusion: 'Euro-Dance Bootleg',
      );
      expect(master, contains('EURO-DANCE BOOTLEG HARDSTYLE'));
      expect(master, contains('CROSS-ARCHITECTURE NON-NEGOTIABLES'));
      expect(
        MasterHardstyleLyricEngine.resolveProfile(
          primaryGenre: 'Hardstyle',
          subGenreFusion: 'Euro-Dance Bootleg',
        ),
        MasterHardstyleLyricEngine.profileEuroBootleg,
      );
    });
  });

  group('GenreLyricsDirectives bootleg routing', () {
    test('userBlockDirective injects Master Hardstyle euro-bootleg profile', () {
      final block = GenreLyricsDirectives.userBlockDirective(
        primaryGenre: 'Hardstyle',
        subGenreFusion: 'Euro-Dance Bootleg',
      );
      expect(block, contains('EURO-DANCE BOOTLEG HARDSTYLE'));
      expect(block, contains('CROSS-ARCHITECTURE NON-NEGOTIABLES'));
      expect(block, isNot(contains('EDM BREAKDOWN VOCAL GUARDRAILS')));
      expect(block, isNot(contains('Write an EDM song based on')));
    });
  });
}
