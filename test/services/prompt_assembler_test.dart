import 'package:flutter_test/flutter_test.dart';
import 'package:music_director/config/engine_config.dart';
import 'package:music_director/services/prompt_assembler.dart';

void main() {
  group('EngineConfig v6 anti-artifact', () {
    test('UI keys are v6 family only', () {
      expect(EngineConfig.uiModelKeys, [
        'suno_v6',
        'suno_v6_wild',
        'suno_v6_mini',
      ]);
      expect(EngineConfig.preferredModelKey, 'suno_v6');
    });

    test('migrateModelKey remaps retired keys to suno_v6', () {
      expect(EngineConfig.migrateModelKey('suno_v4'), 'suno_v6');
      expect(EngineConfig.migrateModelKey('suno_v5.5_pro'), 'suno_v6');
      expect(EngineConfig.migrateModelKey('v6-wild'), 'suno_v6_wild');
      expect(EngineConfig.migrateModelKey('v6-mini'), 'suno_v6_mini');
    });

    test('profileFor resolves wild and mini', () {
      expect(EngineConfig.profileFor('suno_v6_wild').promptMode,
          PromptMode.naturalLanguage);
      expect(EngineConfig.profileFor('suno_v6_mini').tokenBudgetMax, 10);
    });
  });

  test('legacy v3.5 overflow still drops mood before genre', () {
    const input = AssemblerInput(
      modelVersion: 'suno_v3.5',
      genres: ['electronic', 'rock_metal'],
      tempo: 'mid',
      vocal: 'duet',
      mood: 'euphoric',
      customTokens: ['textured pads'],
    );

    final output = PromptAssembler.assemble(input);

    expect(output.tokenCount, lessThanOrEqualTo(8));
    expect(output.stylePrompt.toLowerCase(), contains('electronic'));
    expect(output.stylePrompt.toLowerCase(), isNot(contains('euphoric')));
  });

  test('v6-mini assemble uses lean profile without crashing', () {
    const input = AssemblerInput(
      modelVersion: 'suno_v6_mini',
      genres: ['electronic'],
      tempo: 'mid',
      vocal: 'female',
      mood: 'euphoric',
      customTokens: ['organic dynamics'],
    );

    final output = PromptAssembler.assemble(input);
    expect(output.budgetMax, 10);
    expect(output.stylePrompt, isNotEmpty);
    expect(output.warnings, isNotEmpty); // sheen tip for NL without enough humanizing context
  });
}
