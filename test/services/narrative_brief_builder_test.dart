import 'package:flutter_test/flutter_test.dart';
import 'package:music_director/services/narrative_brief_builder.dart';

void main() {
  group('NarrativeBriefBuilder', () {
    test('uses Amapiano template for amapiano primary genre', () {
      final brief = NarrativeBriefBuilder.build(
        primaryGenre: 'Amapiano',
        mood: 'flirtatious',
        themes: ['connection', 'movement'],
      );

      expect(brief, contains('Amapiano track'));
      expect(brief, contains('flirtatious'));
      expect(brief, contains('connection and movement'));
      expect(brief, contains('nightlife'));
    });

    test('prefers fusion genre template when mapped', () {
      final brief = NarrativeBriefBuilder.build(
        primaryGenre: 'Pop',
        subGenreFusion: 'Metal',
        mood: 'defiant',
        themes: ['resilience'],
      );

      expect(brief, contains('Metal track'));
      expect(brief, contains('defiant'));
    });

    test('Deep House falls back to House parent template', () {
      final brief = NarrativeBriefBuilder.build(
        primaryGenre: 'Deep House',
        mood: 'euphoric',
        themes: ['unity'],
      );

      expect(brief, contains('House track'));
      expect(brief, contains('sing along'));
    });

    test('Gospel template handles worship themes', () {
      final brief = NarrativeBriefBuilder.build(
        primaryGenre: 'Traditional Gospel',
        mood: 'joyful',
        themes: ['grace', 'deliverance'],
      );

      expect(brief, contains('Gospel song'));
      expect(brief, contains('testimony'));
    });

    test('falls back to generic template for unknown genre', () {
      final brief = NarrativeBriefBuilder.build(
        primaryGenre: 'Zydeco Experimental Fusion',
        mood: 'chaotic',
        themes: ['identity'],
      );

      expect(brief, contains('Write the lyrics for a song'));
      expect(brief, contains('chaotic'));
      expect(brief, contains('identity'));
    });

    test('themesFromNotes splits comma-separated notes', () {
      expect(
        NarrativeBriefBuilder.themesFromNotes('love, loss; hope'),
        ['love', 'loss', 'hope'],
      );
    });

    test('empty themes use default phrase in generic template', () {
      final brief = NarrativeBriefBuilder.build(
        primaryGenre: 'Unknown Genre XYZ',
        mood: 'calm',
        themes: [],
      );

      expect(brief, contains('everyday emotion and connection'));
    });
  });
}
