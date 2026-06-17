import 'package:flutter_test/flutter_test.dart';
import 'package:music_director/core/constants/prompt_flow_data.dart';

void main() {
  group('PromptFlowData', () {
    test('compose and parse vibe round-trip', () {
      const composed =
          'Hypnotic · Modern Amapiano lounge · Syncopated log-drum · '
          'rooftop afterparty';
      final parsed = PromptFlowData.parseStoredVibe(composed);
      expect(parsed.mood, 'Hypnotic');
      expect(parsed.era, 'Modern Amapiano lounge');
      expect(parsed.groove, 'Syncopated log-drum');
      expect(parsed.detail, 'rooftop afterparty');
      expect(
        PromptFlowData.composeVibe(
          mood: parsed.mood,
          era: parsed.era,
          groove: parsed.groove,
          detail: parsed.detail,
        ),
        composed,
      );
    });

    test('parse accepts comma and semicolon separators', () {
      const raw =
          'Yearning, Festival Hardstyle Mainstage; Pumping sidechain, peak hour';
      final parsed = PromptFlowData.parseStoredVibe(raw);
      expect(parsed.mood, 'Yearning');
      expect(parsed.era, 'Festival Hardstyle Mainstage');
      expect(parsed.groove, 'Pumping sidechain');
      expect(parsed.detail, 'peak hour');
    });

    test('legacy free-text vibe stays in detail', () {
      const raw = 'Dark trap banger about the last train home';
      final parsed = PromptFlowData.parseStoredVibe(raw);
      expect(parsed.mood, isNull);
      expect(parsed.detail, raw);
    });

    test('bpm suggestions parse genre hint range', () {
      final list = PromptFlowData.bpmSuggestionsForGenre('Techno');
      expect(list, isNotEmpty);
      expect(list.every((n) => n >= 60 && n <= 200), isTrue);
    });
  });
}
