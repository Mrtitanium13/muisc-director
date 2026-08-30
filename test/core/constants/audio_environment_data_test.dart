import 'package:flutter_test/flutter_test.dart';
import 'package:music_director/core/constants/audio_environment_data.dart';

void main() {
  group('AudioEnvironmentData', () {
    test('defaults to studio', () {
      expect(AudioEnvironmentData.coerceId(null), 'studio_isolated');
      expect(AudioEnvironmentData.coerceId('unknown'), 'studio_isolated');
      expect(AudioEnvironmentData.optionForId(null).isStudio, isTrue);
      expect(AudioEnvironmentData.isStudioIsolated(null), isTrue);
      expect(
        AudioEnvironmentData.modeForId(null),
        AudioEnvironmentMode.studioIsolated,
      );
    });

    test('resolves live performance', () {
      expect(
        AudioEnvironmentData.coerceId('live_performance'),
        'live_performance',
      );
      expect(
        AudioEnvironmentData.isLivePerformance('live_performance'),
        isTrue,
      );
      expect(
        AudioEnvironmentData.optionForId('live_performance').label,
        'Live Arena (Crowd & Cheers)',
      );
      expect(
        AudioEnvironmentData.optionForId('live_performance').isLive,
        isTrue,
      );
    });

    test('HTML escaping is applied on demand only', () {
      final opt = AudioEnvironmentData.optionForId('live_performance');
      expect(opt.label, 'Live Arena (Crowd & Cheers)');
      expect(opt.htmlLabel, 'Live Arena (Crowd &amp; Cheers)');
      expect(
        AudioEnvironmentData.userBlockDirectiveHtml('live_performance'),
        contains('Crowd &amp; Cheers'),
      );
      expect(
        AudioEnvironmentData.userBlockDirective('live_performance'),
        contains('Crowd & Cheers'),
      );
      expect(
        AudioEnvironmentData.userBlockDirective('live_performance'),
        isNot(contains('&amp;')),
      );
    });

    test('compact line switches by mode', () {
      expect(
        AudioEnvironmentData.postProcessCompactLine('studio_isolated'),
        startsWith('ENV:studio'),
      );
      expect(
        AudioEnvironmentData.postProcessCompactLine('live_performance'),
        startsWith('ENV:live-arena'),
      );
      expect(
        AudioEnvironmentData.postProcessCompactLine(null),
        startsWith('ENV:studio'),
      );
    });

    test('ids expose known modes', () {
      expect(AudioEnvironmentData.ids, contains('studio_isolated'));
      expect(AudioEnvironmentData.ids, contains('live_performance'));
    });

    test('user block includes label and directive', () {
      final studio = AudioEnvironmentData.userBlockDirective(null);
      expect(studio, contains('AUDIO ENVIRONMENT'));
      expect(studio, contains('Dead-room isolation'));
      expect(studio, contains('Isolated multi-tracked vocal doubles'));

      final live = AudioEnvironmentData.userBlockDirective('live_performance');
      expect(live, contains('Crowd & Cheers'));
      expect(live, contains('Thunderous stadium crowd'));
    });
  });
}
