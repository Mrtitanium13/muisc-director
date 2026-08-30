import 'package:flutter_test/flutter_test.dart';
import 'package:music_director/core/constants/genre_data.dart';
import 'package:music_director/core/constants/genre_lyrics_directives.dart';
import 'package:music_director/core/utils/drum_matrix.dart';
import 'package:music_director/core/utils/dynamic_structural_engine.dart';
import 'package:music_director/core/utils/genre_hybridization_matrix.dart';
import 'package:music_director/core/utils/suno_prompt_builder.dart';
import 'package:music_director/services/genre_hardware_profiles.dart';

void main() {
  final allGenres = [
    for (final subs in GenreData.subGenresByCategory.values) ...subs,
  ];

  // Representative fusion partners spanning very different families.
  const fusionPartners = [
    'Vinahouse',
    'Melodic Techno',
    'Boom Bap',
    'Synthwave',
    'Modern Country',
    'Praise and Worship',
  ];

  group('hybrid fusion sweep (all catalog genres)', () {
    test('catalog is non-trivial', () {
      expect(allGenres.length, greaterThan(50));
    });

    test('every catalog primary resolves a hardware profile (never fallback)',
        () {
      final misses = <String>[];
      for (final genre in allGenres) {
        if (GenreHardwareProfiles.resolve(genre, '').isFallback) {
          misses.add(genre);
        }
      }
      expect(misses, isEmpty, reason: 'no hardware profile for: $misses');
    });

    test('every primary × fusion pair resolves hardware without crashing', () {
      for (final primary in allGenres) {
        for (final fusion in fusionPartners) {
          final res = GenreHardwareProfiles.resolve(primary, fusion);
          expect(res.profile.id, isNotEmpty,
              reason: '$primary + $fusion produced empty profile');
        }
      }
    });

    test('every primary × fusion pair assembles a full structural arc', () {
      for (final primary in allGenres) {
        for (final fusion in fusionPartners) {
          final arc = DynamicStructuralEngine.userBlockDirective(
            primaryGenre: primary,
            subGenreFusion: fusion,
            sunoVersion: 'v5.5',
          );
          expect(arc, contains('DYNAMIC STRUCTURAL ENGINE'),
              reason: '$primary + $fusion');
          expect(arc, contains('[End]'), reason: '$primary + $fusion');
        }
      }
    });

    test('every primary × fusion pair resolves a drum profile', () {
      for (final primary in allGenres) {
        for (final fusion in fusionPartners) {
          final drum = DrumMatrix.resolveProfile(primary, fusion);
          expect(drum.key, isNotEmpty, reason: '$primary + $fusion');
          expect(drum.profile.kit, isNotEmpty, reason: '$primary + $fusion');
        }
      }
    });

    test('every primary × fusion pair resolves an FX lane key', () {
      for (final primary in allGenres) {
        for (final fusion in fusionPartners) {
          final key = SunoPromptBuilder.resolveGenreKey(primary, fusion);
          expect(key, isNotEmpty, reason: '$primary + $fusion');
        }
      }
    });

    test('hybridization block is generic — emitted for every primary genre',
        () {
      for (final primary in allGenres) {
        final block = GenreHybridizationMatrix.userBlockDirective(
          primaryGenre: primary,
          subGenreFusion: 'Melodic Techno',
        );
        expect(block, contains('GENRE HYBRIDIZATION'), reason: primary);
        expect(block, contains('primaryGenre=$primary'), reason: primary);
      }
    });

    test('lyric directives resolve for every primary × fusion pair', () {
      for (final primary in allGenres) {
        for (final fusion in fusionPartners) {
          // Must not throw; empty is acceptable for non-lyric lanes.
          GenreLyricsDirectives.userBlockDirective(
            primaryGenre: primary,
            subGenreFusion: fusion,
          );
        }
      }
    });

    test('fusion blending returns both profiles for cross-family pairs', () {
      final both = GenreHardwareProfiles.resolveAllProfiles(
        'Melodic Techno',
        'Modern Country',
      );
      expect(both.length, greaterThanOrEqualTo(2));
      final ids = both.map((p) => p.id).toSet();
      expect(ids.length, both.length, reason: 'profiles deduped by id');
    });

    test('inactive fusion markers produce no hybridization block', () {
      for (final marker in ['', 'none', 'N/A', '-', '—']) {
        expect(
          GenreHybridizationMatrix.userBlockDirective(
            primaryGenre: 'Amapiano',
            subGenreFusion: marker,
          ),
          isEmpty,
          reason: 'marker "$marker"',
        );
      }
    });
  });
}
