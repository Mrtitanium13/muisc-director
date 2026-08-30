import 'package:flutter_test/flutter_test.dart';
import 'package:music_director/core/constants/big_room_hardstyle_cinematic_hybrid_engine.dart';
import 'package:music_director/core/constants/big_room_hardstyle_cinematic_hybrid_preset.dart';
import 'package:music_director/core/constants/big_room_hardstyle_cinematic_hybrid_vocal_lyric_engine.dart';
import 'package:music_director/core/constants/genre_lyrics_directives.dart';
import 'package:music_director/core/constants/hardstyle_vocal_lyric_engine.dart';
import 'package:music_director/core/constants/prompt_templates.dart';

void main() {
  group('BigRoomHardstyleCinematicHybridEngine', () {
    test('coreMeta includes 150 BPM and hard dance tags', () {
      final c = BigRoomHardstyleCinematicHybridEngine.coreMeta;
      expect(c.primaryTags, contains('Mainstage Hard Dance'));
      expect(c.rhythmicBlueprint, contains('150 BPM'));
      expect(c.moodProfiles, contains('Cinematic melancholy'));
    });

    test('composeBlock1Seed includes hardstyle sonic layers', () {
      final seed = BigRoomHardstyleCinematicHybridEngine.composeBlock1Seed();
      expect(seed, contains('150 BPM'));
      expect(seed, contains('hypersaw'));
      expect(seed, contains('reverse bass'));
      expect(seed, contains('Brick-wall limited'));
      expect(seed, contains('Authentic Hardstyle intro tool'));
      expect(seed, contains('Authentic Hardstyle outro tool'));
    });

    test('composeStructuralConstraintsBlock includes compact lyric template',
        () {
      final block = BigRoomHardstyleCinematicHybridEngine
          .composeStructuralConstraintsBlock();
      expect(block, contains('[DJ intro tool layout'));
      expect(block, contains('[Climax Drop]'));
      expect(block, contains('[Percussive fade out, final low-end hit, complete silence]'));
      expect(block, contains('Vocals are strictly barred'));
    });

    test('composeDjMixEnforcementBlock requires DJ intro and outro', () {
      final block =
          BigRoomHardstyleCinematicHybridEngine.composeDjMixEnforcementBlock();
      expect(block, contains('DJ intro (mix-in) = REQUIRED'));
      expect(block, contains('DJ outro (mix-out) = REQUIRED'));
      expect(block, contains('32-bar'));
    });

    test('composeEliteModuleBlock includes hardstyle palettes', () {
      final block =
          BigRoomHardstyleCinematicHybridEngine.composeEliteModuleBlock(
        primaryGenre: 'Hardstyle',
        subGenreFusion: 'Euphoric Hardstyle / Rawstyle',
      );
      expect(block, contains('ELITE HARDSTYLE ARRANGEMENT MODULE'));
      expect(block, contains('SYNTH LEAD INSTRUMENTATION'));
      expect(block, contains('CINEMATIC BREAKDOWN PALETTE'));
      expect(block, contains('STRUCTURAL CONSTRAINTS'));
      expect(block, contains('CANONICAL MAIN STAGE'));
    });

    test('composeArrangementArchitecture splits progressive lane', () {
      final progressive =
          BigRoomHardstyleCinematicHybridEngine.composeArrangementArchitecture(
        primaryGenre: 'Progressive Hardstyle',
      );
      expect(progressive, contains('8-PART HARD DANCE ARC'));

      final classic =
          BigRoomHardstyleCinematicHybridEngine.composeArrangementArchitecture(
        primaryGenre: 'Hardstyle',
        subGenreFusion: 'Rawstyle',
      );
      expect(classic, contains('CANONICAL MAIN STAGE'));
      expect(classic, isNot(contains('8-PART HARD DANCE ARC')));
    });

    test('matchesLane detects hardstyle family', () {
      expect(
        BigRoomHardstyleCinematicHybridEngine.matchesLane(
          primaryGenre: 'Hardstyle',
          subGenreFusion: 'Euphoric Hardstyle / Rawstyle',
        ),
        isTrue,
      );
      expect(
        BigRoomHardstyleCinematicHybridEngine.matchesLane(
          primaryGenre: 'Big Room House',
          subGenreFusion: 'Euphoric Hardstyle Cinematic Hybrid',
        ),
        isTrue,
      );
      expect(
        BigRoomHardstyleCinematicHybridEngine.matchesLane(
          primaryGenre: 'Deep House',
        ),
        isFalse,
      );
    });
  });

  group('BigRoomHardstyleCinematicHybridPreset', () {
    test('templateModel enables DJ intro/outro and seeds hardstyle tags', () {
      final m = BigRoomHardstyleCinematicHybridPreset.templateModel;
      expect(m.djIntroMixIn, isTrue);
      expect(m.djOutroMixOut, isTrue);
      expect(m.vibe, contains('Authentic Hardstyle intro tool'));
      expect(m.vibe, contains('Climax drops'));
      expect(m.songStructureCustom, contains('[Climax Drop]'));
      expect(
        m.songStructureCustom,
        contains('[Percussive fade out, final low-end hit, complete silence]'),
      );
      expect(m.sonicTags, contains('rawstyle'));
      expect(m.sonicTags, contains('250Hz vocal warmth pocket'));
      expect(m.vocalTone, contains('heavy throat texture'));
      expect(m.avoid, contains('thin distant washed-out vocals'));
      expect(m.referenceArtists, contains('D-Sturb'));
    });

    test('templateModel is 150 BPM with hardstyle theme', () {
      final m = BigRoomHardstyleCinematicHybridPreset.templateModel;
      expect(m.bpm, '150');
      expect(m.primaryGenre, 'Hardstyle');
      expect(m.vocalSpec, 'Male Lead');
      expect(m.generateLyrics, isTrue);
      expect(m.lyricThemeNotes, contains('street-racing'));
    });

    test('userInputModel accepts runtime key/vocal/bpm overrides', () {
      final m = BigRoomHardstyleCinematicHybridPreset.userInputModel(
        keyRoot: 'A',
        scale: 'Major',
        vocalSpec: 'Female Lead',
        bpm: '155',
      );
      expect(m.keyRoot, 'A');
      expect(m.scale, 'Major');
      expect(m.vocalSpec, 'Female Lead');
      expect(m.bpm, '155');
      expect(m.vibe, BigRoomHardstyleCinematicHybridPreset.composeVibeProse());
    });

    test('registered in PromptTemplates', () {
      final t = PromptTemplates.byId(BigRoomHardstyleCinematicHybridPreset.id);
      expect(t, isNotNull);
      expect(t!.title, contains('Hardstyle'));
    });
  });

  group('Hybrid vocal lyric engine and routing', () {
    test('composeUserBlock includes hard dance guardrails and climax drop', () {
      final block =
          BigRoomHardstyleCinematicHybridVocalLyricEngine.composeUserBlock(
        primaryGenre: 'Hardstyle',
        subGenreFusion: 'Cinematic Hybrid',
      );
      expect(block, contains('CRITICAL HARD DANCE VOCAL GUARDRAILS'));
      expect(block, contains('[Climax Drop]'));
      expect(block, contains('[Mid-Intro]'));
      expect(block, contains('ELITE HARD DANCE VOCAL SONIC PROFILE'));
      expect(block, contains('250Hz vocal warmth pocket'));
      expect(block, contains('1176-slammed mouth clicks'));
      expect(
        block,
        contains('mainstage_euphoric_rawstyle_narrative_150_thick_humanized'),
      );
      expect(block, contains('[DJ intro tool layout'));
      expect(block, contains('DJ-READY BOOKENDS'));
    });

    test('master hardstyle owns standard euphoric/raw fusion lanes', () {
      final block = GenreLyricsDirectives.userBlockDirective(
        primaryGenre: 'Hardstyle',
        subGenreFusion: 'Euphoric Hardstyle / Rawstyle',
      );
      expect(block, contains('CROSS-ARCHITECTURE NON-NEGOTIABLES'));
      // Rawstyle token wins over euphoric when both appear in the blob.
      expect(block, contains('SUB-GENRE: RAWSTYLE'));
      expect(block, isNot(contains('CRITICAL HARDSTYLE VOCAL GUARDRAILS')));
    });

    test('generic hardstyle composeUserBlock empty when master lane owns it',
        () {
      expect(
        HardstyleVocalLyricEngine.composeUserBlock(
          primaryGenre: 'Hardstyle',
          subGenreFusion: 'Euphoric Hardstyle / Rawstyle',
        ),
        isEmpty,
      );
    });

    test('euro-dance bootleg is excluded from cinematic hybrid vocal lane', () {
      expect(
        BigRoomHardstyleCinematicHybridVocalLyricEngine.isHybridLane(
          primaryGenre: 'Hardstyle',
          subGenreFusion: 'Euro-Dance Bootleg',
        ),
        isFalse,
      );
    });
  });
}
