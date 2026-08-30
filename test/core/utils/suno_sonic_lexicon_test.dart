import 'package:flutter_test/flutter_test.dart';
import 'package:music_director/core/utils/suno_sonic_lexicon.dart';

void main() {
  group('SunoStagingReformulator', () {
    test('reformulates multi-tracked → stacked layering', () {
      const in_ = 'multi-tracked vocal doubles, max vocal energy';
      final out = SunoStagingReformulator.reformulate(in_);
      expect(out.contains('multi-track'), isFalse);
      expect(out.contains('stacked'), isTrue);
    });

    test('reformulates multi-tracked variants', () {
      expect(
        SunoStagingReformulator.reformulate('multi-tracked vocal doubles'),
        'stacked vocal doubles, layered harmonies',
      );
      expect(
        SunoStagingReformulator.reformulate('multi-tracked vocals'),
        'layered vocal stack',
      );
      expect(
        SunoStagingReformulator.reformulate('multi-tracked'),
        'stacked',
      );
    });

    test('longest match wins', () {
      expect(
        SunoStagingReformulator.reformulate(
          'add multi-tracked vocal doubles here',
        ),
        'add stacked vocal doubles, layered harmonies here',
      );
    });

    test('case insensitive', () {
      expect(
        SunoStagingReformulator.reformulate('MULTI-TRACKED VOCALS'),
        'layered vocal stack',
      );
    });

    test('cleans comma runs and whitespace', () {
      expect(
        SunoStagingReformulator.reformulate('hard fill,,,  hard snare fill , '),
        'hard snare roll, hard snare roll accent',
      );
    });

    test('wouldChange helper', () {
      expect(SunoStagingReformulator.wouldChange('hard fill'), isTrue);
      expect(SunoStagingReformulator.wouldChange('clean vocal'), isFalse);
    });

    test('leaves already-valid sonic character UNTOUCHED', () {
      const in_ =
          'cathedral reverb, belted chest voice, vintage tape saturation, '
          'mono low groove, sudden one-bar gap, ad-lib flood';
      final out = SunoStagingReformulator.reformulate(in_);
      expect(
        out,
        equals(in_),
        reason: 'Valid sonic character must not be reformulated',
      );
    });

    test('is idempotent', () {
      const in_ = 'multi-tracked vocal doubles';
      final a = SunoStagingReformulator.reformulate(in_);
      final b = SunoStagingReformulator.reformulate(a);
      expect(a, equals(b));
    });

    test('preserves comma-separated descriptor structure', () {
      const in_ =
          'stacked vocal doubles, cathedral reverb, warm tape saturation';
      final out = SunoStagingReformulator.reformulate(in_);
      expect(out.split(',').length, equals(in_.split(',').length));
    });
  });
}
