import 'package:flutter_test/flutter_test.dart';
import 'package:music_director/core/constants/big_room_fusion_progressive_engine.dart';
import 'package:music_director/core/constants/big_room_fusion_progressive_preset.dart';

void main() {
  group('BigRoomFusionProgressiveEngine nested dataset', () {
    test('coreGenreAtmosphere includes user-specified tags', () {
      final c = BigRoomFusionProgressiveEngine.coreGenreAtmosphere;
      expect(c.primaryTags, contains('Mainstage EDM'));
      expect(c.primaryTags, contains('Progressive House'));
      expect(c.rhythmicBlueprint, contains('128 BPM'));
      expect(c.rhythmicBlueprint, contains('Driving 4/4 time signature'));
      expect(c.moodProfiles, contains('Euphoric tension'));
      expect(c.moodProfiles, contains('Psychological honesty'));
      expect(c.moodProfiles, contains('High-octane catharsis'));
    });

    test('soundPalette includes engineering-grade descriptors', () {
      final s = BigRoomFusionProgressiveEngine.soundPalette;
      expect(s.leads.first, contains('Layered supersaw leads'));
      expect(s.leads.any((e) => e.contains('Access Virus TI')), isTrue);
      expect(s.leads.any((e) => e.contains('JP-8000')), isTrue);
      expect(s.bassArchitecture.any((e) => e.contains('50–60 Hz')), isTrue);
      expect(
        s.drumKit.any((e) => e.contains('pre-shifted acoustic claps')),
        isTrue,
      );
      expect(
        s.vocalsAndFx.any((e) => e.contains('1/4 and 1/8 note delays')),
        isTrue,
      );
      expect(
        s.vocalsAndFx.any((e) => e.contains('laser sub-risers')),
        isTrue,
      );
    });

    test('mixingTechniques includes sidechain and washout automation', () {
      expect(
        BigRoomFusionProgressiveEngine.mixingTechniques,
        contains('Extreme sidechain compression'),
      );
      expect(
        BigRoomFusionProgressiveEngine.mixingTechniques.any(
          (e) => e.contains('Reverb washout automation on build-ups'),
        ),
        isTrue,
      );
    });

    test('arrangementComponents cover DJ tools verse build drop', () {
      final a = BigRoomFusionProgressiveEngine.arrangementComponents;
      expect(a.introDj, contains('32 bars'));
      expect(a.breakdownVerse, contains('intimate clean vocals'));
      expect(a.buildUp, contains('Accelerating snare roll'));
      expect(a.drop, contains('wall-of-sound sidechained supersaw'));
      expect(a.drop, contains('vocal stutter blocks'));
      expect(a.outroDj, contains('DJ transition'));
    });
  });

  group('BigRoomFusionProgressiveEngine composition', () {
    test('composeBlock1Seed packs weighted production prose', () {
      final seed = BigRoomFusionProgressiveEngine.composeBlock1Seed();
      expect(seed, contains('Mainstage EDM'));
      expect(seed, contains('Layered supersaw leads'));
      expect(seed, contains('Access Virus TI'));
      expect(seed, contains('pre-shifted acoustic claps'));
      expect(seed, contains('Extreme sidechain compression'));
      expect(seed.split(RegExp(r'\s+')).length, greaterThan(80));
    });

    test('composeEliteModuleBlock is structured multi-layer prompt', () {
      final block = BigRoomFusionProgressiveEngine.composeEliteModuleBlock(
        primaryGenre: 'Progressive House',
        subGenreFusion: 'Big Room House',
      );
      expect(block, contains('ELITE BIG ROOM FUSION'));
      expect(block, contains('CORE GENRE & ATMOSPHERE'));
      expect(block, contains('SOUND PALETTE — BASS ARCHITECTURE'));
      expect(block, contains('STUDIO PRODUCTION & MIXING'));
      expect(block, contains('ARRANGEMENT ARCHITECTURE'));
      expect(block, contains('INSTANT TENSION'));
      expect(block, contains('TAG CLOUD'));
      expect(block, contains('[weight: critical]'));
    });

    test('composeArrangementArchitecture splits progressive-big-room lane', () {
      final laneA =
          BigRoomFusionProgressiveEngine.composeArrangementArchitecture(
        primaryGenre: 'Progressive Big Room House',
      );
      expect(laneA, contains('8-PART ARRANGEMENT'));
      expect(laneA, contains('[Chorus]'));

      final laneB =
          BigRoomFusionProgressiveEngine.composeArrangementArchitecture(
        primaryGenre: 'Progressive House',
        subGenreFusion: 'Big Room House',
      );
      expect(laneB, contains('INSTANT TENSION'));
      expect(laneB, isNot(contains('8-PART ARRANGEMENT')));
    });

    test('userBlockAppendFor activates on fusion lane only', () {
      expect(
        BigRoomFusionProgressiveEngine.userBlockAppendFor(
          primaryGenre: 'Progressive House',
          subGenreFusion: 'Big Room House',
        ),
        isNotEmpty,
      );
      expect(
        BigRoomFusionProgressiveEngine.userBlockAppendFor(
          primaryGenre: 'Deep House',
        ),
        isEmpty,
      );
    });

    test('matchesInput detects preset template model', () {
      expect(
        BigRoomFusionProgressiveEngine.matchesInput(
          BigRoomFusionProgressivePreset.templateModel,
        ),
        isTrue,
      );
    });
  });

  group('Preset delegates to engine', () {
    test('composeVibeProse matches engine block1 seed', () {
      expect(
        BigRoomFusionProgressivePreset.composeVibeProse(),
        BigRoomFusionProgressiveEngine.composeBlock1Seed(),
      );
    });

    test('templateModel vibe aligns with engine seed keywords', () {
      expect(
        BigRoomFusionProgressivePreset.templateModel.vibe,
        contains('Mainstage EDM'),
      );
      expect(
        BigRoomFusionProgressivePreset.templateModel.vibe,
        contains('Layered supersaw leads'),
      );
      expect(
        BigRoomFusionProgressivePreset.templateModel.referenceArtists,
        contains('Swedish House Mafia'),
      );
    });
  });
}
