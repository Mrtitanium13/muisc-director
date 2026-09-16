import 'package:flutter_test/flutter_test.dart';
import 'package:music_director/songwriter/services/songwriter_model_router.dart';

void main() {
  group('SongwriterModelRouter stage prefs', () {
    test('select prefers Luna', () {
      expect(
        SongwriterModelRouter.preferredLogical(
          genre: 'pop',
          language: 'English',
          stage: 'select',
        ),
        'gpt-5.6-luna',
      );
    });

    test('rhyme prefers Gemini 3.1 Pro', () {
      expect(
        SongwriterModelRouter.preferredLogical(
          genre: 'pop',
          language: 'English',
          stage: 'rhyme',
        ),
        'gemini-3.1-pro',
      );
    });

    test('arc and transitions prefer Claude with Gemini 3.1 as listed backup', () {
      expect(
        SongwriterModelRouter.preferredLogical(
          genre: 'pop',
          language: 'English',
          stage: 'arc',
        ),
        'claude-sonnet',
      );
      expect(
        SongwriterModelRouter.preferredLogical(
          genre: 'pop',
          language: 'English',
          stage: 'transitions',
        ),
        'claude-sonnet',
      );
    });

    test('chorus stays Astra', () {
      expect(
        SongwriterModelRouter.preferredLogical(
          genre: 'pop',
          language: 'English',
          stage: 'chorus',
        ),
        'gpt-6-astra',
      );
    });

    test('judge stays Claude', () {
      expect(
        SongwriterModelRouter.preferredLogical(
          genre: 'pop',
          language: 'English',
          stage: 'judge',
        ),
        'claude-sonnet',
      );
    });
  });
}
