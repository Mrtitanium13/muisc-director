import 'package:flutter_test/flutter_test.dart';
import 'package:music_director/core/utils/structural_family_resolver.dart';
import 'package:music_director/data/models/track_duration_config.dart';

void main() {
  group('TrackDurationConfig — DJ bar counts are family-aware', () {
    test('EDM with DJ intro/outro uses 32-bar counts', () {
      final cfg = TrackDurationConfig.fromUserInput(
        duration: TrackDuration.s5_00,
        djIntro: true,
        djOutro: true,
        family: StructuralFamily.edmProgressiveHouse,
        bpmRaw: '128',
      );
      expect(cfg.djBarCount, equals(64));
      expect(cfg.songContentBars, equals((5.0 * 128 / 4).round() - 64));
    });

    test('Trap with DJ intro/outro uses 4-bar counts', () {
      final cfg = TrackDurationConfig.fromUserInput(
        duration: TrackDuration.s3_00,
        djIntro: true,
        djOutro: true,
        family: StructuralFamily.trap,
        bpmRaw: '140',
      );
      expect(cfg.djBarCount, equals(8));
    });

    test('Amapiano with DJ intro/outro uses 16-bar counts', () {
      final cfg = TrackDurationConfig.fromUserInput(
        duration: TrackDuration.s4_00,
        djIntro: true,
        djOutro: true,
        family: StructuralFamily.amapiano,
        bpmRaw: '112',
      );
      expect(cfg.djBarCount, equals(32));
    });

    test('Worship with DJ toggles: directives silently dropped', () {
      final cfg = TrackDurationConfig.fromUserInput(
        duration: TrackDuration.s4_00,
        djIntro: true,
        djOutro: true,
        family: StructuralFamily.worship,
        bpmRaw: '72',
      );
      expect(cfg.djIntro, isFalse);
      expect(cfg.djOutro, isFalse);
      expect(cfg.djBarCount, equals(0));
    });
  });

  group('TrackDurationConfig — section depth respects family', () {
    test('Jazz Standard uses A-section / B-section / head vocabulary', () {
      final cfg = TrackDurationConfig.fromUserInput(
        duration: TrackDuration.s4_00,
        djIntro: false,
        djOutro: false,
        family: StructuralFamily.jazzStandard,
        bpmRaw: '140',
      );
      final instruction = cfg.sectionDepthInstruction;
      expect(instruction.contains('A-section'), isTrue);
      expect(instruction.contains('B-section'), isTrue);
      expect(instruction.contains('head'), isTrue);
      expect(instruction.contains('verse'), isFalse);
    });

    test('Cinematic uses Theme / Development / Climax / Coda vocabulary', () {
      final cfg = TrackDurationConfig.fromUserInput(
        duration: TrackDuration.s4_00,
        djIntro: false,
        djOutro: false,
        family: StructuralFamily.cinematic,
        bpmRaw: '90',
      );
      final instruction = cfg.sectionDepthInstruction;
      expect(instruction.contains('Theme'), isTrue);
      expect(instruction.contains('Development'), isTrue);
      expect(instruction.contains('Climax'), isTrue);
      expect(instruction.contains('Coda'), isTrue);
    });

    test('Worship includes Vamp / Spontaneous Flow at extended tier', () {
      final cfg = TrackDurationConfig.fromUserInput(
        duration: TrackDuration.s4_30,
        djIntro: false,
        djOutro: false,
        family: StructuralFamily.worship,
        bpmRaw: '72',
      );
      final instruction = cfg.sectionDepthInstruction;
      expect(instruction.contains('Vamp'), isTrue);
      expect(instruction.contains('Spontaneous Flow'), isTrue);
    });

    test('EDM uses Build-Up / Drop / Breakdown vocabulary', () {
      final cfg = TrackDurationConfig.fromUserInput(
        duration: TrackDuration.s5_00,
        djIntro: false,
        djOutro: false,
        family: StructuralFamily.edmProgressiveHouse,
        bpmRaw: '128',
      );
      final instruction = cfg.sectionDepthInstruction;
      expect(instruction.contains('Build-Up'), isTrue);
      expect(instruction.contains('Drop'), isTrue);
      expect(instruction.contains('Breakdown'), isTrue);
    });
  });

  group('TrackDurationConfig — club tier gated for non-club families', () {
    test('6:00 Folk song caps at extended tier', () {
      final cfg = TrackDurationConfig.fromUserInput(
        duration: TrackDuration.s6_00,
        djIntro: false,
        djOutro: false,
        family: StructuralFamily.folk,
        bpmRaw: '100',
      );
      expect(
        cfg.tierFor(family: StructuralFamily.folk),
        equals(DurationTier.extended),
      );
    });

    test('6:00 EDM song keeps club tier', () {
      final cfg = TrackDurationConfig.fromUserInput(
        duration: TrackDuration.s6_00,
        djIntro: false,
        djOutro: false,
        family: StructuralFamily.edmProgressiveHouse,
        bpmRaw: '128',
      );
      expect(
        cfg.tierFor(family: StructuralFamily.edmProgressiveHouse),
        equals(DurationTier.club),
      );
    });
  });

  group('TrackDurationConfig — budget and hygiene', () {
    test('toPromptContext() total ≤ 450 chars', () {
      final cfg = TrackDurationConfig.fromUserInput(
        duration: TrackDuration.s3_30,
        djIntro: true,
        djOutro: true,
        family: StructuralFamily.edmProgressiveHouse,
        bpmRaw: '128',
      );
      expect(
        cfg.toPromptContext().length,
        lessThanOrEqualTo(450),
        reason: 'toPromptContext too verbose: ${cfg.toPromptContext()}',
      );
    });

    test('toPromptContext() contains NO "SECTION 3" references', () {
      final cfg = TrackDurationConfig.fromUserInput(
        duration: TrackDuration.s4_00,
        djIntro: true,
        djOutro: true,
        family: StructuralFamily.edmProgressiveHouse,
        bpmRaw: '124',
      );
      expect(
        cfg.toPromptContext().toLowerCase().contains('section 3'),
        isFalse,
      );
    });

    test('toPromptContext() contains no bracket-notation mid-prose', () {
      final cfg = TrackDurationConfig.fromUserInput(
        duration: TrackDuration.s4_00,
        djIntro: true,
        djOutro: false,
        family: StructuralFamily.edmProgressiveHouse,
        bpmRaw: '128',
      );
      expect(
        cfg.toPromptContext(),
        isNot(contains('[DJ ')),
        reason: 'bracket-notation [DJ ...] leaked into prose',
      );
    });
  });

  group('TrackDuration.custom — safe handling', () {
    test('custom.minutes is NaN (forces factory usage)', () {
      expect(TrackDuration.custom.minutes.isNaN, isTrue);
    });

    test('factory resolves custom duration to 3.0 when parsing fails', () {
      final cfg = TrackDurationConfig.fromUserInput(
        duration: TrackDuration.custom,
        trackDurationLabel: 'garbage',
        djIntro: false,
        djOutro: false,
        family: StructuralFamily.popStandard,
        bpmRaw: '120',
      );
      expect(cfg.effectiveMinutes, equals(3.0));
    });
  });
}
