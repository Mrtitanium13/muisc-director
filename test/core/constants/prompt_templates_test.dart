import 'package:flutter_test/flutter_test.dart';
import 'package:music_director/core/constants/prompt_flow_data.dart';
import 'package:music_director/core/constants/prompt_templates.dart';
import 'package:music_director/core/constants/suno_version.dart';

void main() {
  group('PromptTemplates', () {
    test('all template ids are unique', () {
      expect(PromptTemplates.validateUniqueIds, returnsNormally);
    });

    test('byId finds templates', () {
      expect(PromptTemplates.byId('radio_pop')?.title, 'Radio pop');
      expect(PromptTemplates.byId('missing'), isNull);
    });

    test('byFamily groups correctly', () {
      final edm = PromptTemplates.byFamily(GenreFamily.edm);
      expect(edm.map((t) => t.id), contains('melodic_club'));
      expect(edm.map((t) => t.id), contains('bracket_edm_structure'));
      expect(edm.map((t) => t.id), contains(PromptTemplates.featured[2].id));
    });

    test('featured templates are a subset of all', () {
      for (final t in PromptTemplates.featured) {
        expect(PromptTemplates.all, contains(t));
        expect(t.isFeatured, isTrue);
      }
    });

    test('search works across title and genre', () {
      final results = PromptTemplates.search('trap');
      expect(results.map((t) => t.id), contains('trap_heavy'));
    });

    test('no HTML entities in display strings', () {
      final worship = PromptTemplates.byId('praise_worship_epic');
      expect(worship?.title, 'Praise & Worship');
      expect(worship?.title, isNot(contains('&amp;')));
      final neo = PromptTemplates.byId('neo_soul_ballad');
      expect(neo?.description, contains('R&B'));
      expect(neo?.description, isNot(contains('&amp;')));
    });

    test('inline templates use preferred Suno version', () {
      expect(
        PromptTemplates.byId('radio_pop')?.model.sunoVersion,
        SunoVersion.preferredValue,
      );
    });

    test('families covers registry families', () {
      final families = PromptTemplates.families();
      expect(families, contains(GenreFamily.edm));
      expect(families, contains(GenreFamily.gospel));
      expect(families, contains(GenreFamily.hardstyle));
    });
  });
}
