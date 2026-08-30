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

    test('genre family resolves edm from progressive house', () {
      expect(
        PromptFlowData.resolveVibeGenreFamily(primaryGenre: 'Progressive House'),
        GenreFamily.edm,
      );
    });

    test('genre family resolution is normalization-robust', () {
      expect(
        PromptFlowData.resolveVibeGenreFamily(primaryGenre: 'r&b'),
        GenreFamily.rnb,
      );
      expect(
        PromptFlowData.resolveVibeGenreFamily(primaryGenre: 'rnb'),
        GenreFamily.rnb,
      );
      expect(
        PromptFlowData.resolveVibeGenreFamily(primaryGenre: 'rhythm and blues'),
        GenreFamily.rnb,
      );
      expect(
        PromptFlowData.resolveVibeGenreFamily(primaryGenre: 'neo-soul'),
        GenreFamily.rnb,
      );
      expect(
        PromptFlowData.resolveVibeGenreFamily(primaryGenre: 'drum & bass'),
        GenreFamily.dnb,
      );
      expect(
        PromptFlowData.resolveVibeGenreFamily(primaryGenre: 'singer-songwriter'),
        GenreFamily.folk,
      );
      expect(
        PromptFlowData.resolveVibeGenreFamily(primaryGenre: 'afro house'),
        GenreFamily.afrobeats,
      );
      expect(
        PromptFlowData.resolveVibeGenreFamily(primaryGenre: 'trap edm'),
        GenreFamily.edm,
      );
      expect(
        PromptFlowData.resolveVibeGenreFamily(primaryGenre: 'hyperpop'),
        GenreFamily.edm,
      );
      expect(
        PromptFlowData.resolveVibeGenreFamily(primaryGenre: 'drift phonk'),
        GenreFamily.hiphop,
      );
      expect(
        PromptFlowData.resolveVibeGenreFamily(primaryGenre: 'baile funk'),
        GenreFamily.latin,
      );
      expect(
        PromptFlowData.resolveVibeGenreFamily(primaryGenre: 'phonk'),
        GenreFamily.hiphop,
      );
      expect(
        PromptFlowData.resolveVibeGenreFamily(primaryGenre: 'pluggnb'),
        GenreFamily.hiphop,
      );
      expect(
        PromptFlowData.resolveVibeGenreFamily(primaryGenre: 'modular ambient'),
        GenreFamily.electronicExperimental,
      );
    });

    test('R&B resolves correctly after HTML entity fix', () {
      expect(
        PromptFlowData.resolveVibeGenreFamily(primaryGenre: 'r&b'),
        GenreFamily.rnb,
      );
      expect(
        PromptFlowData.resolveVibeGenreFamily(primaryGenre: 'rhythm & blues'),
        GenreFamily.rnb,
      );
    });

    test('genre display strings contain real ampersands', () {
      final options = PromptFlowData.grooveOptionsForGenre('rnb');
      final rb = options.firstWhere((o) => o.label.contains('808'));
      expect(rb.label, contains('R&B'));
      expect(rb.label, isNot(contains('&amp;')));
    });

    test('bpm options include custom sentinel', () {
      final bpms = PromptFlowData.bpmOptionsForGenre('techno');
      expect(bpms.last.isCustom, isTrue);
      expect(bpms.last.value, PromptFlowData.customOption);
    });

    test('findOptionByValue works', () {
      final options = PromptFlowData.moodToneOptions;
      final found = PromptFlowData.findOptionByValue(options, 'Euphoric');
      expect(found?.label, 'Euphoric');
      expect(PromptFlowData.findOptionByValue(options, 'missing'), isNull);
    });

    test('all option getters return typed unmodifiable lists', () {
      expect(PromptFlowData.moodToneOptions, everyElement(isA<Option>()));
      final grooves = PromptFlowData.grooveOptionsForGenre('hiphop');
      expect(
        () => grooves.add(const Option(value: 'x', label: 'x')),
        throwsUnsupportedError,
      );
    });

    test('new genre tokens resolve', () {
      expect(
        PromptFlowData.resolveVibeGenreFamily(primaryGenre: 'kuduro'),
        GenreFamily.afrobeats,
      );
      expect(
        PromptFlowData.resolveVibeGenreFamily(primaryGenre: 'sertanejo'),
        GenreFamily.country,
      );
      expect(
        PromptFlowData.resolveVibeGenreFamily(primaryGenre: 'mahraganat'),
        GenreFamily.electronicExperimental,
      );
      expect(
        PromptFlowData.resolveVibeGenreFamily(primaryGenre: 'forró'),
        GenreFamily.folk,
      );
    });

    test('dropdown options expose custom flag correctly', () {
      final moods = PromptFlowData.moodToneOptions;
      expect(moods.last.isCustom, isTrue);
      expect(moods.last.value, PromptFlowData.customOption);
    });

    test('coerce returns null for invalid option', () {
      expect(PromptFlowData.coerceGrooveForGenre('Boom-bap', 'edm'), isNull);
      expect(
        PromptFlowData.coerceGrooveForGenre('Boom-bap', 'hiphop'),
        'Boom-bap',
      );
    });

    test('parseStoredVibe extracts mood, era, groove', () {
      final parsed = PromptFlowData.parseStoredVibe(
        'Euphoric · Modern club/streaming · Four-on-the-floor · lasers and unity',
      );
      expect(parsed.mood, 'Euphoric');
      expect(parsed.era, 'Modern club/streaming');
      expect(parsed.groove, 'Four-on-the-floor');
      expect(parsed.detail, 'lasers and unity');
    });

    test('bpm suggestions for genre parse ranges', () {
      final bpms = PromptFlowData.bpmSuggestionsForGenre('Techno');
      expect(bpms.length, lessThanOrEqualTo(3));
      expect(bpms, orderedEquals(List<int>.from(bpms)..sort()));
    });

    test('BPM dropdown values always include Custom', () {
      final values = PromptFlowData.bpmDropdownValuesForGenre(null);
      expect(values, contains(PromptFlowData.customOption));
      expect(values.last, PromptFlowData.customOption);
      expect(values, contains('120'));
    });

    test('lists are unmodifiable', () {
      final grooves = PromptFlowData.getGrooveFeelsForGenre('hiphop');
      expect(() => grooves.add('x'), throwsUnsupportedError);
    });

    test('groove options are genre-specific', () {
      final edm = PromptFlowData.getGrooveFeelsForGenre('edm');
      final jazz = PromptFlowData.getGrooveFeelsForGenre('jazz');
      expect(edm, contains('Four-on-the-floor'));
      expect(jazz, contains('Swing'));
      expect(jazz, isNot(contains('Pounding hardstyle kick')));
    });

    test('composeVibe sanitizes middle dots in detail', () {
      final composed = PromptFlowData.composeVibe(
        mood: 'Dark',
        detail: 'late night · rooftop · rain',
      );
      expect(composed, 'Dark · late night - rooftop - rain');
    });

    test('source text path splits vibe brief from lyric source', () {
      const vibe =
          'Yearning · Modern Praise & Worship · Worship lift build · '
          'John 3:16 For God so loved the world';
      final lines = PromptFlowData.buildVibeUserBlockLines(
        vibe: vibe,
        useVibeAsLyricSource: true,
      );
      expect(
        lines.first,
        '[VIBE BRIEF] (Mood · Era/Scene · Groove Feel): '
        'Yearning · Modern Praise & Worship · Worship lift build',
      );
      expect(lines.any((l) => l.contains('[SOURCE TEXT FOR LYRICS]')), isTrue);
      expect(
        lines.any((l) => l.contains('scriptural')),
        isTrue,
      );
      expect(lines.last, contains('John 3:16'));
    });

    test('vibe detail stays in brief when source toggle is off', () {
      const vibe = 'Dark · rooftop afterparty';
      final lines = PromptFlowData.buildVibeUserBlockLines(
        vibe: vibe,
        useVibeAsLyricSource: false,
      );
      expect(lines, contains('[VIBE BRIEF] (Mood · Era/Scene · Groove Feel): Dark'));
      expect(lines, contains('Vibe / idea detail: rooftop afterparty'));
      expect(lines, isNot(contains('[SOURCE TEXT FOR LYRICS]')));
    });
  });
}
