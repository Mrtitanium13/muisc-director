import 'package:flutter_test/flutter_test.dart';
import 'package:music_director/core/constants/gospel_theme_directives.dart';

void main() {
  group('GospelThemeDirectives', () {
    test('resolves forgiveness theme', () {
      expect(
        GospelThemeDirectives.resolveThemeKey(lyricThemeNotes: 'forgiveness'),
        GospelThemeDirectives.themeForgiveness,
      );
    });

    test('resolves gratitude theme from vibe and notes', () {
      expect(
        GospelThemeDirectives.resolveThemeKey(lyricThemeNotes: 'gratitude'),
        GospelThemeDirectives.themeGratitude,
      );
      expect(
        GospelThemeDirectives.resolveThemeKey(vibe: 'celebratory praise'),
        GospelThemeDirectives.themeGratitude,
      );
    });

    test('resolves spiritual warfare theme', () {
      expect(
        GospelThemeDirectives.resolveThemeKey(lyricThemeNotes: 'deliverance breakthrough'),
        GospelThemeDirectives.themeSpiritualWarfare,
      );
    });

    test('forgiveness directive includes Prodigal Son paradigm', () {
      final block = GospelThemeDirectives.directiveBlock(
        lyricThemeNotes: 'forgiveness',
      );
      expect(block, contains('THEME DIRECTIVES for Forgiveness'));
      expect(block, contains('Prodigal Son'));
    });

    test('gratitude directive avoids guilt themes', () {
      final block = GospelThemeDirectives.directiveBlock(
        lyricThemeNotes: 'gratitude',
      );
      expect(block, contains('THEME DIRECTIVES for Gratitude/Praise'));
      expect(block, contains('Avoid heavy themes of guilt'));
      expect(block, isNot(contains('Prodigal')));
    });

    test('custom theme falls back to THEME NOTES when no key matches', () {
      final block = GospelThemeDirectives.directiveBlock(
        lyricThemeNotes: 'holding on through grief',
      );
      expect(block, contains('THEME NOTES'));
      expect(block, contains('holding on through grief'));
    });
  });
}
