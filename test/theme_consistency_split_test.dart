import 'package:flutter_test/flutter_test.dart';
import 'package:music_director/core/utils/theme_consistency_split.dart';

void main() {
  group('theme_consistency_split', () {
    test('splitBlock2Parts preserves prefix body suffix', () {
      const raw = '''
BLOCK 1 — PASTE INTO SUNO: STYLE

producer prose

BLOCK 2 — PASTE INTO SUNO: LYRICS

[Intro]
[16-bar kick]
(line)
[End]

→ chip suggestion''';

      final parts = splitBlock2Parts(raw);
      expect(parts, isNotNull);
      expect(parts!.prefix, contains('BLOCK 2'));
      expect(parts.block2Body, contains('[Intro]'));
      expect(parts.block2Body, contains('[End]'));
      expect(parts.suffix, contains('chip'));

      final merged = mergeBlock2Parts(
        prefix: parts.prefix,
        block2Body: parts.block2Body,
        suffix: parts.suffix,
      );
      expect(merged, contains('producer prose'));
      expect(merged, contains('[End]'));
    });

    test('block2ThemeOutputValid requires end tag', () {
      expect(
        block2ThemeOutputValid('[Verse 1]\n(line)\n[End]'),
        isTrue,
      );
      expect(block2ThemeOutputValid('[Verse 1]\n(line)'), isFalse);
    });
  });
}
