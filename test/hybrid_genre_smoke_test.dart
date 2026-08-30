import 'package:flutter_test/flutter_test.dart';
import 'package:music_director/core/constants/block1_mix_master_directive.dart';
import 'package:music_director/core/utils/genre_hybridization_matrix.dart';
import 'package:music_director/core/constants/genre_lyrics_directives.dart';
import 'package:music_director/core/utils/drum_matrix.dart';
import 'package:music_director/core/utils/dynamic_structural_engine.dart';
import 'package:music_director/core/utils/genre_fx_matrix_data.dart';
import 'package:music_director/core/utils/suno_prompt_builder.dart';
import 'package:music_director/services/genre_hardware_profiles.dart';

void main() {
  group('hybrid genre smoke (audit)', () {
    test('Amapiano-Vinahouse resolves across all matrices', () {
      // Hardware profile (Block 1 directive)
      final hw = Block1MixMasterDirective.userBlockDirective(
        primaryGenre: 'Amapiano-Vinahouse',
        sunoVersion: 'v5.5',
      );
      expect(hw, contains('[HW.030.amapiano_vinahouse]'));

      final res = GenreHardwareProfiles.resolve('Amapiano-Vinahouse', '');
      expect(res.isFallback, isFalse);

      // Structural family
      final family = StructuralFamilyResolver.resolve(
        primaryGenre: 'Amapiano-Vinahouse',
      );
      expect(family, isNotNull);

      // Structural engine emits a full arc
      final arc = DynamicStructuralEngine.userBlockDirective(
        primaryGenre: 'Amapiano-Vinahouse',
        subGenreFusion: '',
        sunoVersion: 'v5.5',
      );
      expect(arc, contains('DYNAMIC STRUCTURAL ENGINE'));
      expect(arc, contains('[End]'));

      // Drum matrix: vinahouse has its own dedicated drum profile, which is
      // the more specific (correct) match for the combined genre.
      final drum = DrumMatrix.resolveProfile('Amapiano-Vinahouse', '');
      expect(drum.key.toLowerCase(), anyOf('vinahouse', contains('amapiano')));

      // Genre FX lane key resolution
      expect(
        SunoPromptBuilder.resolveGenreKey('Amapiano-Vinahouse', ''),
        'amapiano',
      );
      expect(
        SunoPromptBuilder.resolveGenreKey('Vinahouse', ''),
        'amapiano',
      );

      // FX matrix family fallback works (amapiano is a required family)
      final fx = GenreFxMatrixData.getFx(family: 'amapiano', tier: '2');
      expect(fx.style, isNotEmpty);

      // Lyric directives
      final lyrics = GenreLyricsDirectives.userBlockDirective(
        primaryGenre: 'Amapiano-Vinahouse',
        subGenreFusion: '',
      );
      expect(lyrics, contains('AMAPIANO / VINAHOUSE'));
    });

    test('fusion pairs still produce hybridization blocks', () {
      // Curated pair covered by the matrix (Amapiano×Vinahouse is a single
      // combined primary genre, not a matrix pair).
      final block = GenreHybridizationMatrix.userBlockDirective(
        primaryGenre: 'Melodic Techno',
        subGenreFusion: 'Indie Acoustic',
      );
      expect(block, contains('GENRE HYBRIDIZATION'));
    });

    test('other hyphenated/fusion genres do not fall back silently', () {
      for (final genre in [
        'Amapiano-Vinahouse',
        'Afro House',
        'Melodic Techno',
        'Liquid DnB',
        'Trap Soul',
        'UK Garage',
      ]) {
        final res = GenreHardwareProfiles.resolve(genre, '');
        expect(res.isFallback, isFalse, reason: '$genre hit fallback profile');
      }
    });
  });
}
