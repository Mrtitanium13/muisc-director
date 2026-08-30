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
      expect(
        out,
        contains(
          '[Master Style: Contemporary R&B Soul, West African Delivery]',
        ),
      );
      expect(out, contains('[Production Layout:'));
      expect(out, contains('Thick multi-tracked vocal doubles'));
      expect(out, contains('forward in the mix'));
      expect(out, contains('F# Minor, 104 BPM'));
      expect(out, contains('Analog SSL console master glue'));
    });

    test('defaults key and style', () {
      final p = generateThickVocalPrompt(
        baseUserPrompt: '',
        bpm: 130,
        keyScale: '',
      );
      expect(
        p,
        contains(
          '[Master Style: ${AudioAnalysisModel.fallbackAnalyzerSummary}]',
        ),
      );
      expect(p, contains('C Major'));
      expect(p, contains('130 BPM'));
      expect(p, contains('Thick multi-tracked vocal doubles'));
    });

    test('clamps BPM', () {
      final low = generateThickVocalPrompt(
        baseUserPrompt: 'sad pop',
        bpm: 20,
        keyScale: 'A Minor',
      );
      expect(low, contains('40 BPM'));

      final high = generateThickVocalPrompt(
        baseUserPrompt: 'sad pop',
        bpm: 300,
        keyScale: 'A Minor',
      );
      expect(high, contains('220 BPM'));
    });

    test('can disable thick modifiers', () {
      final p = generateThickVocalPrompt(
        baseUserPrompt: 'minimal ambient',
        bpm: 90,
        keyScale: 'D Dorian',
        forceThickPresence: false,
      );
      expect(p, isNot(contains('Thick multi-tracked vocal doubles')));
      expect(p, contains('[Production Layout: D Dorian, 90 BPM'));
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
      expect(
        out.indexOf('[Master Style:'),
        lessThan(out.indexOf('SOURCE AUDIO ANALYSIS')),
      );
      expect(out, contains('Contemporary R&B Soul'));
      expect(out, contains('SOURCE AUDIO ANALYSIS'));
      expect(out, contains('104 BPM'));
    });
  });

  group('baseStyleFromAnalysis', () {
    test('combines genre and profile', () {
      final analysis = AudioAnalysisModel(
        genre: 'Synthwave',
        analyzerSummary: 'retro, neon, 80s drums, dry room',
      );
      expect(
        baseStyleFromAnalysis(analysis),
        'Synthwave, retro, neon, 80s drums, dry room',
      );
    });

    test('falls back to profile', () {
      final analysis = AudioAnalysisModel(
        genre: null,
        analyzerSummary: 'raw, intimate, close-mic, dry room',
      );
      expect(
        baseStyleFromAnalysis(analysis),
        'raw, intimate, close-mic, dry room',
      );
    });

    test('falls back to profile when genre empty', () {
      final analysis = AudioAnalysisModel(
        genre: '  ',
        analyzerSummary: 'warm, dry, soft, studio',
      );
      expect(baseStyleFromAnalysis(analysis), analysis.compactProfile);
      expect(baseStyleFromAnalysis(analysis), isNot(startsWith(',')));
    });
  });
}
