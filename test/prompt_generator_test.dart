import 'package:flutter_test/flutter_test.dart';
import 'package:music_director/core/utils/prompt_generator.dart';
import 'package:music_director/data/models/audio_analysis_model.dart';

void main() {
  group('generateThickVocalPrompt', () {
    test('emits master style and production layout brackets', () {
      final out = generateThickVocalPrompt(
        baseUserPrompt: 'Contemporary R&B Soul, West African Delivery',
        bpm: 104,
        keyScale: 'F# Minor',
      );
      expect(out, contains('[Master Style: Contemporary R&B Soul, West African Delivery]'));
      expect(out, contains('[Production Layout:'));
      expect(out, contains('Thick multi-tracked vocal doubles'));
      expect(out, contains('forward in the mix'));
      expect(out, contains('F# Minor, 104 BPM'));
      expect(out, contains('Analog SSL console master glue'));
    });

    test('buildAnalyzerPromptWithThickVocals prepends layout before profile', () {
      const profile =
          'Female Lead, Emotional Close-Mic, High Energy Driving, Club Room';
      final analysis = AudioAnalysisModel.fromJson({
        'analyzerSummary': profile,
        'bpm': 104,
        'keyScale': 'F# Minor',
        'genre': 'Contemporary R&B Soul',
      });
      final out = buildAnalyzerPromptWithThickVocals(analysis);
      expect(out.indexOf('[Master Style:'), lessThan(out.indexOf('TARGET AUDIO PROFILE')));
      expect(out, contains('Contemporary R&B Soul'));
      expect(out, contains('TARGET AUDIO PROFILE'));
      expect(out, contains('104 BPM'));
    });
  });
}
