import 'package:flutter_test/flutter_test.dart';
import 'package:music_director/core/constants/lyric_temperament_data.dart';

void main() {
  group('LyricTemperament', () {
    test('fromCode resolves known codes case-insensitively', () {
      expect(LyricTemperament.fromCode('/grit'), LyricTemperament.grit);
      expect(LyricTemperament.fromCode('/ELEVATED'), LyricTemperament.elevated);
      expect(LyricTemperament.fromCode(' /CHILL '), LyricTemperament.chill);
    });

    test('fromCode falls back to custom for unknown or null', () {
      expect(LyricTemperament.fromCode(null), LyricTemperament.custom);
      expect(LyricTemperament.fromCode('/UNKNOWN'), LyricTemperament.custom);
    });
  });

  group('LyricTemperamentData', () {
    test('codes lists presets without custom sentinel', () {
      expect(LyricTemperamentData.codes, contains('/BOUNCE'));
      expect(LyricTemperamentData.codes, isNot(contains('__custom__')));
      expect(LyricTemperamentData.codes.length, 10);
    });

    test('labelFor maps presets and passes through unknown tokens', () {
      expect(LyricTemperamentData.labelFor('/SWAGGER'), 'Swagger');
      expect(LyricTemperamentData.labelFor('/wired'), 'Wired');
      expect(LyricTemperamentData.labelFor('/MYVIBE'), '/MYVIBE');
    });
  });
}
