import 'package:flutter_test/flutter_test.dart';
import 'package:music_director/services/prompt_assembler.dart';

void main() {
  test('v3.5 overflow drops mood before genre', () {
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
}
