import 'package:flutter_test/flutter_test.dart';
import 'package:music_director/core/suno_prompt_router.dart';

void main() {
  group('SunoPromptRouterV2', () {
    test('getDnaTagsForGenres merges fusion genres without duplicates', () {
      final tags = SunoPromptRouterV2.getDnaTagsForGenres(['Amapiano', 'Synth Pop']);

      expect(tags, contains('log drum bassline'));
      expect(tags, contains('80s analog synths'));
      expect(tags.toSet().length, tags.length);
    });

    test('resolveGenreKeys maps aliases and fusion', () {
      final keys = SunoPromptRouterV2.resolveGenreKeys(
        primaryGenre: 'Progressive House',
        subGenreFusion: 'Big Room House',
      );

      expect(keys, contains('House'));
      expect(keys, contains('Big Room'));
    });

    test('buildStyleFieldFromTags renders natural language for v5+', () {
      final style = SunoPromptRouterV2.buildStyleFieldFromTags(
        tags: ['log drum bassline', '80s analog synths', 'retro-futuristic vibe'],
        version: SunoRouterTier.v5Plus,
        asSentence: true,
      );

      expect(style, startsWith('A track in the style of'));
      expect(style, contains('featuring'));
    });

    test('composeStyleField keeps user vibe and appends DNA tags', () {
      final style = SunoPromptRouterV2.composeStyleField(
        userVibe: 'late night drive',
        genreKeys: ['Trap'],
        additionalTokens: ['simple melodic hook'],
        sunoVersion: 'v5.5',
      );

      expect(style, contains('late night drive'));
      expect(style, contains('808 bass'));
      expect(style, contains('simple melodic hook'));
    });

    test('composeStyleField uses sentence mode when vibe is empty', () {
      final style = SunoPromptRouterV2.composeStyleField(
        userVibe: '',
        genreKeys: ['Ambient'],
        sunoVersion: 'v5.0',
      );

      expect(style, startsWith('A track in the style of'));
      expect(style, contains('long sustained pads'));
    });

    test('unknown genre falls back to lowercase genre name tag', () {
      final tags = SunoPromptRouterV2.getDnaTagsForGenres(['Hyperpop']);

      expect(tags, equals(['hyperpop']));
    });

    test('userBlockDirective matches DNA tags for LLM context', () {
      final block = SunoPromptRouterV2.userBlockDirective(
        primaryGenre: 'Trap',
        subGenreFusion: 'R&B',
      );

      expect(block, contains('808 bass'));
      expect(block, contains('smooth electric piano'));
      expect(block, contains('Write lyrics for a song'));
    });

    test('resolveMelodyEngineFamilyKey maps electronic genres', () {
      expect(
        SunoPromptRouterV2.resolveMelodyEngineFamilyKey(
          primaryGenre: 'Hardstyle',
          genreFxLaneId: 'hardstyle',
        ),
        'electronic',
      );
      expect(
        SunoPromptRouterV2.resolveMelodyEngineFamilyKey(
          primaryGenre: 'Modern Country',
        ),
        'acoustic_orchestral',
      );
    });

    test('styleTagsFor returns comma-separated DNA tags', () {
      final tags = SunoPromptRouterV2.styleTagsFor(primaryGenre: 'Jazz');
      expect(tags, contains('walking bassline'));
      expect(tags, contains('swing rhythm'));
    });

    test('HTML entities removed from strings and operators', () {
      final dna = SunoPromptRouterV2.genreDnaMap['Drum & Bass'];
      expect(dna, isNotNull);
      expect(dna!.coreTags, contains('fast breakbeat drums'));
      final rnb = SunoPromptRouterV2.genreDnaMap['R&B'];
      expect(rnb, isNotNull);
    });

    test('resolveGenreKeys maps UK Drill and Melodic Techno aliases', () {
      final keys = SunoPromptRouterV2.resolveGenreKeys(
        primaryGenre: 'UK Drill',
        subGenreFusion: 'Melodic Techno',
      );
      expect(keys, contains('Drill'));
      expect(keys, contains('Techno'));
    });

    test('styleTagsFor Amapiano contains log drum without HTML entities', () {
      final tags = SunoPromptRouterV2.styleTagsFor(
        primaryGenre: 'Amapiano',
        sunoVersion: 'v5.5',
      );
      expect(tags, contains('log drum bassline'));
      expect(tags, isNot(contains('&amp;')));
    });

    test('resolveMelodyEngineFamilyKey routes gospel lane', () {
      expect(
        SunoPromptRouterV2.resolveMelodyEngineFamilyKey(
          primaryGenre: 'Pop',
          genreFxLaneId: 'gospel',
        ),
        'acoustic_orchestral',
      );
    });

    test('buildStyleFieldFromTags respects char limit', () {
      final long = List<String>.filled(200, 'big reverb');
      final style = SunoPromptRouterV2.buildStyleFieldFromTags(
        tags: long,
        version: SunoRouterTier.v5Plus,
      );
      expect(style.length, lessThanOrEqualTo(1000));
    });
  });
}
