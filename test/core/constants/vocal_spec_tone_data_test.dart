import 'package:flutter_test/flutter_test.dart';
import 'package:music_director/core/constants/prompt_flow_data.dart';
import 'package:music_director/core/constants/vocal_spec_tone_data.dart';
import 'package:music_director/features/prompt_generator/utils/prompt_form_constants.dart';

void main() {
  group('VocalSpecToneData', () {
    test('vocalSpecs includes chant and unison arrangement chips', () {
      expect(VocalSpecToneData.vocalSpecs, contains('Vocal Chants Only'));
      expect(VocalSpecToneData.vocalSpecs, contains('Unison Stacks'));
      expect(PromptFormConstants.vocals, VocalSpecToneData.vocalSpecs);
    });

    test('vocalTones no longer duplicate spec-only entries', () {
      expect(PromptFlowData.vocalTones, isNot(contains('Vocal Chants Only')));
      expect(PromptFlowData.vocalTones, isNot(contains('Unison Stacks')));
    });

    test('userBlockLine labels spec and tone separately', () {
      expect(
        VocalSpecToneData.userBlockLine(
          vocalSpec: 'Male Lead',
          vocalTone: 'Breathy',
        ),
        'Vocal: spec=Male Lead · tone=Breathy',
      );
      expect(
        VocalSpecToneData.userBlockLine(vocalSpec: null, vocalTone: null),
        'Vocal:',
      );
    });

    test('userBlockDirective routes instrumental and chant specs', () {
      final instrumental = VocalSpecToneData.userBlockDirective(
        vocalSpec: VocalSpecToneData.instrumentalOnlySpec,
        vocalTone: null,
      );
      expect(instrumental, contains('instrumental-only'));

      final chants = VocalSpecToneData.userBlockDirective(
        vocalSpec: VocalSpecToneData.vocalChantsOnlySpec,
        vocalTone: 'hypnotic spoken chant hooks',
      );
      expect(chants, contains('chant-first'));
      expect(chants, contains('user_vocal_tone'));
    });

    test('coerceSpec normalizes case', () {
      expect(
        VocalSpecToneData.coerceSpec('male lead'),
        'Male Lead',
      );
    });

    test('predicate helpers classify chips', () {
      expect(VocalSpecToneData.isChoir(VocalSpecToneData.gospelChoirSpec), isTrue);
      expect(
        VocalSpecToneData.isRapForward(VocalSpecToneData.rapVocalSpaceSpec),
        isTrue,
      );
      expect(
        VocalSpecToneData.routesToBlock2(VocalSpecToneData.instrumentalOnlySpec),
        isTrue,
      );
      expect(
        VocalSpecToneData.suppressesLeadLyrics(
          VocalSpecToneData.instrumentalOnlySpec,
        ),
        isTrue,
      );
      expect(VocalSpecToneData.isCustomSpec('Custom Breath Stack'), isTrue);
      expect(
        VocalSpecToneData.normalizeTone('  warm   breathy  '),
        'warm breathy',
      );
    });
  });
}
