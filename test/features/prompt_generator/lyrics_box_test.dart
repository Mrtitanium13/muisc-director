import 'package:flutter_test/flutter_test.dart';
import 'package:music_director/core/constants/lyric_craft_hierarchy_directive.dart';
import 'package:music_director/core/utils/suno_path_a_lyrics.dart';
import 'package:music_director/data/models/suno_field_output_mode.dart';
import 'package:music_director/data/models/user_input_model.dart';
import 'package:music_director/features/prompt_generator/utils/form_commit.dart';

void main() {
  group('FormCommit.resolveLyricsBox', () {
    test('pasted lyrics win over generate-lyrics and vibe-as-source', () {
      final r = FormCommit.resolveLyricsBox(
        simpleMode: false,
        lyricsText: '[Verse 1]\nHello from the box',
        generateLyrics: true,
        useVibeAsLyricSource: true,
      );
      expect(r.optionalLyrics, '[Verse 1]\nHello from the box');
      expect(r.generateLyrics, isFalse);
    });

    test('empty lyrics with generate flag is Path C', () {
      final r = FormCommit.resolveLyricsBox(
        simpleMode: false,
        lyricsText: '  \n  ',
        generateLyrics: true,
        useVibeAsLyricSource: false,
      );
      expect(r.optionalLyrics, isEmpty);
      expect(r.generateLyrics, isTrue);
    });

    test('simple field mode drops lyrics so Block 2 is not requested', () {
      final r = FormCommit.resolveLyricsBox(
        simpleMode: true,
        lyricsText: 'keep me',
        generateLyrics: true,
        useVibeAsLyricSource: false,
      );
      expect(r.optionalLyrics, isEmpty);
      expect(r.generateLyrics, isFalse);
    });

    test('trims pasted lyrics on commit', () {
      final r = FormCommit.resolveLyricsBox(
        simpleMode: false,
        lyricsText: '  [Chorus]\nStay  \n',
        generateLyrics: false,
        useVibeAsLyricSource: false,
      );
      expect(r.optionalLyrics, '[Chorus]\nStay');
      expect(r.generateLyrics, isFalse);
    });
  });

  group('UserInputModel lyrics box', () {
    test('non-empty optionalLyrics is Path A (verbatim), not rewrite hierarchy', () {
      const input = UserInputModel(
        optionalLyrics: '[Verse 1]\nUser line',
        sunoFieldOutputMode: SunoFieldOutputMode.custom,
      );
      expect(LyricCraftHierarchyDirective.isComplexLyricPath(input), isTrue);
      final block = LyricCraftHierarchyDirective.userBlockDirective(input);
      expect(block, isNotNull);
      expect(block, contains('PATH A'));
      expect(block, contains('verbatim'));
    });
  });

  group('pinUserLyricsToBlock2', () {
    const generated = '''
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📋 BLOCK 1 — PASTE INTO SUNO: STYLE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

A dark pop record at 100 BPM.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📋 BLOCK 2 — PASTE INTO SUNO: LYRICS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[Verse 1]
Generated replacement line

[Chorus]
Not the user's hook

[End]

→ Tighten the pre-chorus
''';

    test('replaces generated Block 2 with pasted lyrics', () {
      const pasted = '[Verse 1]\nKitchen light still on\n\n[Chorus]\nStay or go';
      final out = pinUserLyricsToBlock2(generated, pasted);
      expect(out, contains('Kitchen light still on'));
      expect(out, contains('Stay or go'));
      expect(out, isNot(contains('Generated replacement line')));
      expect(out, isNot(contains("Not the user's hook")));
      expect(out, contains('[End]'));
      expect(out, contains('Tighten the pre-chorus'));
    });

    test('does not duplicate [End] when user already included it', () {
      const pasted = '[Chorus]\nStay\n[End]';
      final out = pinUserLyricsToBlock2(generated, pasted);
      expect(RegExp(r'\[End\]', caseSensitive: false).allMatches(out).length, 1);
    });

    test('empty paste leaves output unchanged', () {
      expect(pinUserLyricsToBlock2(generated, '  '), generated);
    });
  });
}
