import 'package:flutter_test/flutter_test.dart';
import 'package:music_director/core/constants/hitmaker_max_martin_directives.dart';
import 'package:music_director/core/utils/quick_describe_mapper.dart';
import 'package:music_director/data/models/suno_field_output_mode.dart';
import 'package:music_director/data/models/track_duration_config.dart';
import 'package:music_director/data/models/user_input_model.dart';

void main() {
  group('mapQuickDescribeToUserInput', () {
    const base = UserInputModel();

    test('empty returns base', () {
      final r = mapQuickDescribeToUserInput('', base);
      expect(r.appliedHints, isEmpty);
      expect(r.merged, base);
    });

    test('extracts BPM suffix and genre', () {
      final r = mapQuickDescribeToUserInput(
        'Dark trap 140 bpm night drive',
        base,
      );
      expect(r.merged.bpm, '140');
      expect(r.merged.primaryGenre, 'Trap');
      expect(r.merged.vibe, contains('Dark trap'));
      expect(r.appliedHints, contains('BPM 140'));
      expect(r.appliedHints, contains('Genre Trap'));
    });

    test('extracts temperament and power codes', () {
      final r = mapQuickDescribeToUserInput(
        'boom bap /GRIT /BEASTMODE',
        base,
      );
      expect(r.merged.lyricTemperamentCodes, contains('/GRIT'));
      expect(r.merged.vibe, contains('/BEASTMODE'));
      expect(r.merged.generateLyrics, isFalse);
    });

    test('/WRITEIT sets generateLyrics', () {
      final r = mapQuickDescribeToUserInput(
        'pop love song /WRITEIT',
        base,
      );
      expect(r.merged.generateLyrics, isTrue);
    });

    test('instrumental disables generateLyrics', () {
      final r = mapQuickDescribeToUserInput(
        'techno instrumental 128 bpm',
        base,
      );
      expect(r.merged.vocalSpec, 'Instrumental only');
      expect(r.merged.generateLyrics, isFalse);
    });

    test('parses key', () {
      final r = mapQuickDescribeToUserInput(
        'jazz in D minor slow',
        base,
      );
      expect(r.merged.keyRoot, 'D');
      expect(r.merged.scale, 'Minor');
      expect(r.merged.primaryGenre, 'Jazz');
    });

    test('Hitmaker / Max Martin lane overrides genre', () {
      final r = mapQuickDescribeToUserInput(
        'commercial pop max martin hooky 120 bpm',
        base,
      );
      expect(r.merged.primaryGenre, hitmakerMaxMartinGenreLabel);
      expect(r.appliedHints, contains(contains('Hitmaker')));
    });

    test('simple mode clears lyrics path', () {
      const withLyrics = UserInputModel(
        optionalLyrics: 'la la',
        generateLyrics: true,
      );
      final r = mapQuickDescribeToUserInput(
        'house 124 simple mode',
        withLyrics,
      );
      expect(r.merged.sunoFieldOutputMode, SunoFieldOutputMode.simple);
      expect(r.merged.optionalLyrics, isEmpty);
      expect(r.merged.generateLyrics, isFalse);
    });

    test('parses target length mm:ss', () {
      final r = mapQuickDescribeToUserInput(
        'synth pop 118 bpm length 3:45',
        base,
      );
      expect(r.merged.trackDuration, TrackDuration.custom);
      expect(r.merged.trackDurationLabel, '3:45');
    });
  });
}
