import 'package:flutter_test/flutter_test.dart';
import 'package:music_director/core/constants/suno_version.dart';
import 'package:music_director/core/utils/suno_syntax_renderer.dart';
import 'package:music_director/core/constants/song_structure_data.dart';

void main() {
  group('SunoVersion v6 compatibility', () {
    test('preferred is v6', () {
      expect(SunoVersion.preferredValue, 'v6');
      expect(SunoVersion.uiValues, ['v6', 'v6-wild', 'v6-mini']);
    });

    test('density aliases', () {
      expect(SunoVersion.densityKeyFor('v6'), 'v5.5');
      expect(SunoVersion.densityKeyFor('v6-wild'), 'v5.5');
      expect(SunoVersion.densityKeyFor('v6-mini'), 'v5.0');
      expect(SunoVersion.densityKeyFor('v5.5'), 'v5.5');
      expect(SunoVersion.densityKeyFor('v5.0'), 'v5.0');
      expect(SunoVersion.densityKeyFor('v4.5'), 'v4.5');
    });

    test('migrate retired models to v6 UI chip', () {
      expect(SunoVersion.migrateToUiValue('v5.5'), 'v6');
      expect(SunoVersion.migrateToUiValue('v5.0'), 'v6');
      expect(SunoVersion.migrateToUiValue('v4.5'), 'v6');
      expect(SunoVersion.migrateToUiValue('v6-wild'), 'v6-wild');
      expect(SunoVersion.migrateToUiValue('v6-mini'), 'v6-mini');
    });

    test('wild intent only for v6-wild', () {
      expect(SunoVersion.isWildIntent('v6-wild'), isTrue);
      expect(SunoVersion.isWildIntent('v6'), isFalse);
      expect(SunoVersion.modelIntentDirective('v6-wild'), contains('v6-wild'));
      expect(SunoVersion.modelIntentDirective('v6-mini'), contains('v6-mini'));
    });

    test('v6 renders rich brackets like v5.5', () {
      final section = SongSection(
        id: 'chorus',
        kind: SectionKind.chorus,
        label: 'Chorus',
        stagingNote: 'wide vocal stack, hall plate, belted lead',
      );
      final v6 = SunoSyntaxRenderer.renderSection(section, 'v6');
      final v55 = SunoSyntaxRenderer.renderSection(section, 'v5.5');
      expect(v6, startsWith('[Chorus:'));
      expect(v6, v55);
    });

    test('v6-mini renders hybrid one-descriptor like v5.0', () {
      final section = SongSection(
        id: 'chorus',
        kind: SectionKind.chorus,
        label: 'Chorus',
        stagingNote: 'wide vocal stack, hall plate, belted lead',
      );
      final mini = SunoSyntaxRenderer.renderSection(section, 'v6-mini');
      final v5 = SunoSyntaxRenderer.renderSection(section, 'v5.0');
      expect(mini, startsWith('[Chorus:'));
      expect(mini.contains(','), isFalse);
      expect(mini, v5);
    });
  });
}
