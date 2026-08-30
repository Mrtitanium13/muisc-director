import 'package:flutter_test/flutter_test.dart';
import 'package:music_director/config/melody_config.dart';
import 'package:music_director/data/models/melody_evolution.dart';
import 'package:music_director/data/models/user_input_model.dart';
import 'package:music_director/services/composition_pipeline_service.dart';

void main() {
  group('CompositionPipelineService', () {
    test('merges genre-aware melody tokens into vibe', () {
      const input = UserInputModel(
        primaryGenre: 'Progressive House',
        genreFxLaneId: 'edm',
        vibe: 'festival energy',
        melodyStyleId: 'hook_led',
      );

      final result = CompositionPipelineService.run(userInput: input);

      expect(
        result.melodyStyleTokens.first,
        contains('driven by a main synth hook or arpeggio'),
      );
      expect(result.composedInput.vibe, contains('festival energy'));
      expect(
        result.composedInput.vibe,
        contains('driven by a main synth hook or arpeggio'),
      );
    });

    test('includes genre DNA tags for resolved genres', () {
      const input = UserInputModel(
        primaryGenre: 'Big Room',
        vibe: 'mainstage drop',
        melodyStyleId: MelodyConfig.autoId,
        melodyEvolution: MelodyEvolution.strict,
      );

      final result = CompositionPipelineService.run(userInput: input);

      expect(result.genreKeys, contains('Big Room'));
      expect(result.genreStyleTokens, contains('anthem synth lead'));
      expect(result.composedInput.vibe, contains('anthem synth lead'));
    });

    test('withVibe swaps base vibe but keeps genre and melody tokens', () {
      const input = UserInputModel(
        primaryGenre: 'Trap',
        vibe: 'original',
        melodyStyleId: 'hook_led',
      );

      final result = CompositionPipelineService.run(userInput: input);
      final alt = result.withVibe('alt arrangement');

      expect(alt.vibe, contains('alt arrangement'));
      expect(alt.vibe, contains('808 bass'));
      expect(alt.vibe, contains('[MELODY EVOLUTION PLAN]'));
      expect(alt.vibe, isNot(contains('original')));
      expect(alt.optionalLyrics, result.composedInput.optionalLyrics);
    });

    test('vibeOverride replaces vibe before token merge', () {
      const input = UserInputModel(
        primaryGenre: 'Pop',
        vibe: 'ignored',
        melodyStyleId: 'hook_led',
      );

      final result = CompositionPipelineService.run(
        userInput: input,
        vibeOverride: 'custom side vibe',
      );

      expect(result.composedInput.vibe, contains('custom side vibe'));
      expect(result.composedInput.vibe, isNot(contains('ignored')));
    });

    test('applies lyric evolution once', () {
      const input = UserInputModel(
        melodyStyleId: MelodyConfig.autoId,
        melodyEvolution: MelodyEvolution.progressive,
        optionalLyrics: '[Final Chorus]\nHook',
        primaryGenre: 'Progressive House',
        genreFxLaneId: 'edm',
      );

      final result = CompositionPipelineService.run(userInput: input);

      expect(result.composedInput.optionalLyrics, contains('layered harmonies'));
    });

    test('injects melody evolution plan into composed vibe', () {
      const input = UserInputModel(
        primaryGenre: 'Pop',
        vibe: 'bright',
        melodyStyleId: 'hook_led',
        melodyEvolution: MelodyEvolution.progressive,
      );

      final result = CompositionPipelineService.run(userInput: input);

      expect(result.composedInput.vibe, contains('[MELODY EVOLUTION PLAN]'));
      expect(
        result.composedInput.vibe,
        contains('Later returns MUST build on it'),
      );
    });
  });
}
