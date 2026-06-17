import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:music_director/core/utils/suno_format_validation.dart';
import 'package:music_director/core/utils/suno_output_split.dart';

void main() {
  String load(String name) {
    return File('test/fixtures/$name').readAsStringSync();
  }

  group('fixture paths (unified two-block)', () {
    test('Path B — default: Block 1 + Block 2 through [End]', () {
      final raw = load('suno_unified_path_b_instrumental.txt');
      final p = parseSunoOutput(raw);
      expect(p.unifiedTwoBlockFormat, isTrue);
      expect(p.styleBody, isNotNull);
      expect(p.lyricsBody, isNotNull);
      expect(p.lyricsBody, contains('[End]'));
      expect(p.block2HasEndTag, isTrue);
      expect(p.unifiedBlock2Missing, isFalse);
      final v = FormatValidationResult.validate(
        raw,
        expectLyricsBlock: true,
      );
      expect(v.hasBlock1Banner, isTrue);
      expect(FormatValidationResult.qualityScore(
        v,
        expectLyricsBlock: true,
      ), greaterThanOrEqualTo(0.85));
    });

    test('Path A — pasted lyrics: both blocks, [End], suggestions split', () {
      final raw = load('suno_unified_path_a_pasted_lyrics.txt');
      final p = parseSunoOutput(raw);
      expect(p.unifiedTwoBlockFormat, isTrue);
      expect(p.styleBody, contains('neo-soul'));
      expect(p.lyricsBody, contains('[Verse 1]'));
      expect(p.lyricsBody, contains('[End]'));
      expect(p.lyricsBody, isNot(contains('If you want')));
      expect(p.suggestionsBody, isNotNull);
      expect(p.suggestionsBody, contains('If you want'));
      expect(p.block2HasEndTag, isTrue);
      final v = FormatValidationResult.validate(
        raw,
        expectLyricsBlock: true,
      );
      expect(v.hasEndTag, isTrue);
      expect(v.followUpsPresent, isTrue);
    });

    test('Path C — generated lyrics: both blocks, [End]', () {
      final raw = load('suno_unified_path_c_generated_lyrics.txt');
      final p = parseSunoOutput(raw);
      expect(p.unifiedTwoBlockFormat, isTrue);
      expect(p.lyricsBody, contains('[Chorus]'));
      expect(p.block2HasEndTag, isTrue);
      expect(p.suggestionsBody, isNull);
    });
  });

  group('suggestionLinesFromBody', () {
    test('splits non-empty lines from suggestions tail', () {
      final raw = load('suno_unified_path_a_pasted_lyrics.txt');
      final p = parseSunoOutput(raw);
      final lines = suggestionLinesFromBody(p.suggestionsBody);
      expect(lines, isNotEmpty);
      expect(lines.every((l) => l.isNotEmpty), isTrue);
    });

    test('empty for null or blank', () {
      expect(suggestionLinesFromBody(null), isEmpty);
      expect(suggestionLinesFromBody('   \n  '), isEmpty);
    });

    test('drops stock follow-up preamble before arrow lines', () {
      const body = 'If you want, I can also:\n'
          '→ Adjust the vocal delivery\n'
          '→ Transpose the harmony';
      expect(
        suggestionLinesFromBody(body),
        ['→ Adjust the vocal delivery', '→ Transpose the harmony'],
      );
    });

    test('keeps single-line If you want when it carries the suggestion', () {
      const body =
          'If you want, I can: tighten pre-chorus rhymes or swap bridge sentiment.';
      expect(suggestionLinesFromBody(body), hasLength(1));
    });
  });

  group('FormatValidator', () {
    test('detects missing [End] for lyrics path', () {
      const raw = '''
BLOCK 1 — PASTE INTO SUNO: STYLE

House groove.

BLOCK 2 — PASTE INTO SUNO: LYRICS

[Verse]
Line
''';
      final v = FormatValidationResult.validate(
        raw,
        expectLyricsBlock: true,
      );
      expect(v.hasEndTag, isFalse);
      expect(
        FormatValidationResult.qualityScore(
          v,
          expectLyricsBlock: true,
        ),
        lessThan(0.85),
      );
    });
  });
}
