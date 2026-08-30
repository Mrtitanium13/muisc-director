import 'package:flutter_test/flutter_test.dart';
import 'package:music_director/core/constants/big_room_fusion_progressive_preset.dart';
import 'package:music_director/core/constants/prompt_templates.dart';

void main() {
  group('BigRoomFusionProgressivePreset', () {
    test('composeVibeProse includes sound palette and engineering terms', () {
      final vibe = BigRoomFusionProgressivePreset.composeVibeProse();
      expect(vibe, contains('Progressive House'));
      expect(vibe, contains('Big Room House'));
      expect(vibe, contains('Festival Anthem'));
      expect(vibe, contains('Mainstage EDM'));
      expect(vibe, contains('Layered supersaw leads'));
      expect(vibe, contains('Access Virus TI'));
      expect(vibe, contains('sidechain'));
      expect(vibe, contains('pre-shifted acoustic claps'));
      expect(vibe, contains('50–60 Hz'));
      expect(vibe, contains('wide stereo field expansion'));
      expect(vibe, contains('128 BPM'));
    });

    test('composeStructureNotes covers instant-tension roadmap', () {
      final notes = BigRoomFusionProgressivePreset.composeStructureNotes();
      expect(notes, contains('INSTANT TENSION'));
      expect(notes, contains('[Intro DJ Tool]'));
      expect(notes, contains('[Build-up]'));
      expect(notes, contains('[Drop]'));
      expect(notes, contains('[Breakdown Verse]'));
      expect(notes, contains('reverb washout'));
      expect(notes, contains('supersaw'));
    });

    test('composeEliteModuleBlock returns structured module', () {
      final block = BigRoomFusionProgressivePreset.composeEliteModuleBlock();
      expect(block, contains('ELITE BIG ROOM FUSION'));
      expect(block, contains('pre-shifted acoustic claps'));
      expect(block, contains('INSTANT TENSION'));
    });

    test('userInputModel wires edm_drop and production intensity', () {
      final m = BigRoomFusionProgressivePreset.userInputModel();
      expect(m.primaryGenre, 'Progressive House');
      expect(m.subGenreFusion, 'Big Room House');
      expect(m.bpm, '128');
      expect(m.songStructurePresetId, 'edm_drop');
      expect(m.productionIntensity, 3);
      expect(m.genreFxLaneId, 'edm');
      expect(m.melodyStyleId, 'anthemic_soaring');
      expect(m.generateLyrics, isTrue);
    });

    test('userInputModel accepts optional runtime overrides', () {
      final m = BigRoomFusionProgressivePreset.userInputModel(
        bpm: '130',
        keyRoot: 'A',
        scale: 'Major',
        vocalSpec: 'Male Lead',
      );
      expect(m.bpm, '130');
      expect(m.keyRoot, 'A');
      expect(m.scale, 'Major');
      expect(m.vocalSpec, 'Male Lead');
      expect(m.vibe, BigRoomFusionProgressivePreset.composeVibeProse());
    });
  });

  group('PromptTemplates big room fusion', () {
    test('template is registered and loads preset model', () {
      final t = PromptTemplates.byId(BigRoomFusionProgressivePreset.id);
      expect(t, isNotNull);
      expect(t!.title, contains('Big Room Fusion'));
      expect(t.model.vibe, contains('High-density multi-voiced'));
      expect(t.model.sonicTags, contains('high-density supersaw euphoria'));
      expect(t.model.songStructureCustom, contains('Build-Up:'));
      expect(t.model.referenceArtists, contains('Swedish House Mafia'));
    });
  });
}
