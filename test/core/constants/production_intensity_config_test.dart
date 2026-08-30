import 'package:flutter_test/flutter_test.dart';
import 'package:music_director/core/constants/production_intensity_config.dart';

void main() {
  group('ProductionIntensityConfig', () {
    test('clamping works', () {
      expect(ProductionIntensityConfig.clampLevel(0), 1);
      expect(ProductionIntensityConfig.clampLevel(2), 2);
      expect(ProductionIntensityConfig.clampLevel(5), 3);
    });

    test('band data is correct', () {
      expect(ProductionIntensityConfig.levelLabel(1), 'Low');
      expect(ProductionIntensityConfig.levelLabel(2), 'Medium');
      expect(ProductionIntensityConfig.levelLabel(3), 'High');
      expect(
        ProductionIntensityConfig.levelInstruction(3),
        contains('Maximum production spectacle'),
      );
    });

    test('options expose correct values', () {
      final options = ProductionIntensityConfig.options;
      expect(options, hasLength(3));
      expect(options.first.value, '1');
      expect(options.first.label, '1 — Low');
      expect(options.last.label, '3 — High');
    });

    test('optionFor clamps out-of-range', () {
      final opt = ProductionIntensityConfig.optionFor(99);
      expect(opt.value, '3');
      expect(opt.label, '3 — High');
    });

    test('parseOptionValue handles strings', () {
      expect(ProductionIntensityConfig.parseOptionValue('2'), 2);
      expect(ProductionIntensityConfig.parseOptionValue(null), isNull);
      expect(ProductionIntensityConfig.parseOptionValue('abc'), isNull);
    });

    test('directive includes intensity instructions', () {
      final directive = ProductionIntensityConfig.userBlockDirective(2);
      expect(directive, contains('PRODUCTION FX INTENSITY: 2/3'));
      expect(directive, contains('MEDIUM'));
      expect(directive, contains('GENRE FX MATRIX'));
    });
  });
}
