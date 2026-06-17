import 'package:flutter_test/flutter_test.dart';
import 'package:music_director/core/utils/suno_internal_output_strip.dart';
import 'package:music_director/core/utils/suno_output_split.dart';

void main() {
  group('stripInternalCognitionBlocks', () {
    test('removes psychology_audit before Block 1', () {
      const raw = '''
<psychology_audit>
  <target_audience>Young Adult</target_audience>
  <user_proxy_line>Yes — quote line</user_proxy_line>
  <three_second_intro_anchor>N/A</three_second_intro_anchor>
</psychology_audit>

BLOCK 1 — PASTE INTO SUNO: STYLE
Neo-soul at 92 BPM.

BLOCK 2 — PASTE INTO SUNO: LYRICS
[Verse 1]
Line one
[End]
''';
      final out = stripInternalCognitionBlocks(raw);
      expect(out.toLowerCase(), isNot(contains('psychology_audit')));
      expect(out, contains('BLOCK 1'));
      expect(out, contains('[End]'));
      final parsed = parseSunoOutput(out);
      expect(parsed.unifiedTwoBlockFormat, isTrue);
    });

    test('removes psychology_audit between blocks', () {
      const block1 = 'BLOCK 1 — PASTE INTO SUNO: STYLE\nStyle prose here.';
      const audit = '<psychology_audit><cliche_sweep>No</cliche_sweep></psychology_audit>';
      const block2 = 'BLOCK 2 — PASTE INTO SUNO: LYRICS\n[Chorus]\nHook\n[End]';
      final raw = '$block1\n\n$audit\n\n$block2';
      final out = stripInternalCognitionBlocks(raw);
      expect(out, '$block1\n\n$block2');
    });

    test('leaves text unchanged when no audit present', () {
      const raw = 'BLOCK 1 — PASTE INTO SUNO: STYLE\nOnly style.';
      expect(stripInternalCognitionBlocks(raw), raw);
    });

    test('removes master_blueprint before Block 1', () {
      const raw = '''
<master_blueprint>
  <song_purpose>Festival Anthem</song_purpose>
  <qa_pass>Yes</qa_pass>
</master_blueprint>

BLOCK 1 — PASTE INTO SUNO: STYLE
House at 128 BPM.

BLOCK 2 — PASTE INTO SUNO: LYRICS
[Chorus]
Move
[End]
''';
      final out = stripInternalCognitionBlocks(raw);
      expect(out.toLowerCase(), isNot(contains('master_blueprint')));
      expect(out, contains('BLOCK 1'));
      expect(out, contains('[End]'));
    });

    test('removes lyric_audit before Block 1', () {
      const raw = '''
<lyric_audit>
  <songwriting_mode>Mode B</songwriting_mode>
  <show_dont_tell_check>Yes</show_dont_tell_check>
</lyric_audit>
BLOCK 1 — PASTE INTO SUNO: STYLE
Pop at 100 BPM.
BLOCK 2 — PASTE INTO SUNO: LYRICS
[End]
''';
      final out = stripInternalCognitionBlocks(raw);
      expect(out.toLowerCase(), isNot(contains('lyric_audit')));
      expect(out, contains('BLOCK 1'));
    });

    test('removes all three internal cognition blocks', () {
      const raw = '''
<master_blueprint><qa_pass>Yes</qa_pass></master_blueprint>
<psychology_audit><cliche_sweep>No</cliche_sweep></psychology_audit>
<lyric_audit><show_dont_tell_check>Yes</show_dont_tell_check></lyric_audit>
BLOCK 1 — PASTE INTO SUNO: STYLE
Style.
BLOCK 2 — PASTE INTO SUNO: LYRICS
[End]
''';
      final out = stripInternalCognitionBlocks(raw);
      expect(out.toLowerCase(), isNot(contains('master_blueprint')));
      expect(out.toLowerCase(), isNot(contains('psychology_audit')));
      expect(out.toLowerCase(), isNot(contains('lyric_audit')));
    });
  });
}
