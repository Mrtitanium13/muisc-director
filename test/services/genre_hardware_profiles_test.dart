import 'package:flutter_test/flutter_test.dart';
import 'package:music_director/core/constants/genre_data.dart';
import 'package:music_director/core/constants/suno_version.dart';
import 'package:music_director/data/generated/genre_hardware_profiles_data.dart';
import 'package:music_director/services/genre_hardware_profiles.dart';

void main() {
  group('DJ delegation: this file does NOT emit DJ phrasing', () {
    test('v5.5 output contains NO "sixteen-bar" wording', () {
      final out = GenreHardwareProfiles.userBlockDirective(
        primaryGenre: 'Techno',
        sunoVersion: 'v5.5',
      );
      expect(out.toLowerCase().contains('sixteen'), isFalse);
      expect(out.toLowerCase().contains('16-'), isFalse);
    });

    test('v5.5 output contains NO DJ intro/outro phrasing', () {
      final out = GenreHardwareProfiles.userBlockDirective(
        primaryGenre: 'Techno',
        sunoVersion: 'v5.5',
      );
      expect(out.toLowerCase().contains('dj intro'), isFalse);
      expect(out.toLowerCase().contains('dj outro'), isFalse);
      expect(out.toLowerCase().contains('mix-in'), isFalse);
      expect(out.toLowerCase().contains('mix-out'), isFalse);
      expect(out.toLowerCase().contains('beatmatch'), isFalse);
    });
  });

  group('Version routing', () {
    test('parseVersion maps v4.5 / v5 / v5.5 / v6 density', () {
      expect(GenreHardwareProfiles.parseVersion('v4.5'), SunoVersion.v4_5);
      expect(GenreHardwareProfiles.parseVersion('v5'), SunoVersion.v5);
      expect(GenreHardwareProfiles.parseVersion('v5.0'), SunoVersion.v5);
      expect(GenreHardwareProfiles.parseVersion('v5.5-alpha'), SunoVersion.v5_5);
      expect(GenreHardwareProfiles.parseVersion('v6'), SunoVersion.v5_5);
      expect(GenreHardwareProfiles.parseVersion('v6-wild'), SunoVersion.v5_5);
      expect(GenreHardwareProfiles.parseVersion('v6-mini'), SunoVersion.v5);
      // Unknown / empty → rich density (legacy v5.5 formatter)
      expect(GenreHardwareProfiles.parseVersion(''), SunoVersion.v5_5);
    });

    test('v4.5 output is ≤ 200 chars', () {
      final out = GenreHardwareProfiles.userBlockDirective(
        primaryGenre: 'Boom Bap',
        sunoVersion: 'v4.5',
      );
      expect(out.length, lessThanOrEqualTo(200));
    });

    test('v5 output is ≤ 600 chars', () {
      final out = GenreHardwareProfiles.userBlockDirective(
        primaryGenre: 'Worship',
        sunoVersion: 'v5',
      );
      expect(out.length, lessThanOrEqualTo(600));
    });

    test('v5.5 output is ≤ 500 chars', () {
      final out = GenreHardwareProfiles.userBlockDirective(
        primaryGenre: 'Amapiano',
        sunoVersion: 'v5.5',
      );
      expect(out.length, lessThanOrEqualTo(500));
    });

    test('Progressive House stays in per-version budgets', () {
      expect(
        GenreHardwareProfiles.userBlockDirective(
          primaryGenre: 'Progressive House',
          sunoVersion: 'v4.5',
        ).length,
        lessThanOrEqualTo(200),
      );
      expect(
        GenreHardwareProfiles.userBlockDirective(
          primaryGenre: 'Progressive House',
          sunoVersion: 'v5',
        ).length,
        lessThanOrEqualTo(600),
      );
      expect(
        GenreHardwareProfiles.userBlockDirective(
          primaryGenre: 'Progressive House',
          sunoVersion: 'v5.5',
        ).length,
        lessThanOrEqualTo(500),
      );
    });
  });

  group('Vocabulary: DAW routing jargon must not appear', () {
    test('no sidechain / side-chained wording in output', () {
      final out = GenreHardwareProfiles.userBlockDirective(
        primaryGenre: 'Techno',
        sunoVersion: 'v5.5',
      );
      expect(out.toLowerCase().contains('sidechain'), isFalse);
    });

    test('no bus-routing wording', () {
      final out = GenreHardwareProfiles.userBlockDirective(
        primaryGenre: 'Techno',
        sunoVersion: 'v5.5',
      );
      expect(out.toLowerCase().contains('bus routing'), isFalse);
    });
  });

  group('Vocabulary: legitimate sonic + mastering terms preserved', () {
    test('dBTP true-peak ceiling preserved (legitimate mastering spec)', () {
      final out = GenreHardwareProfiles.userBlockDirective(
        primaryGenre: 'Amapiano',
        sunoVersion: 'v5.5',
      );
      expect(out.contains('dBTP'), isTrue);
      expect(out.contains('true-peak'), isTrue);
    });

    test('LUFS loudness targets preserved', () {
      final out = GenreHardwareProfiles.userBlockDirective(
        primaryGenre: 'Boom Bap',
        sunoVersion: 'v5.5',
      );
      expect(out.contains('LUFS'), isTrue);
    });

    test('signal-chain gear notation preserved (Neumann U87, 1073, etc.)', () {
      final out = GenreHardwareProfiles.userBlockDirective(
        primaryGenre: 'Pop',
        sunoVersion: 'v5.5',
      );
      final tokens = [
        'Neumann',
        'U87',
        'SM7B',
        '1073',
        '1176',
        'LA-2A',
        'SSL G',
        'Genelec',
        'NS10',
        'Rhodes',
      ];
      expect(
        tokens.any((t) => out.contains(t)),
        isTrue,
        reason: 'Expected at least one hardware token in output',
      );
    });

    test('"release-ready" prose preserved', () {
      final out = GenreHardwareProfiles.userBlockDirective(
        primaryGenre: 'Pop',
        sunoVersion: 'v5.5',
      );
      expect(out.contains('release-ready'), isTrue);
    });
  });

  group('Profile resolution edge cases', () {
    test('empty primary + empty fusion returns DEFAULT-style output', () {
      final out = GenreHardwareProfiles.userBlockDirective(
        primaryGenre: '',
        subGenreFusion: '',
        sunoVersion: 'v5.5',
      );
      expect(out.isNotEmpty, isTrue);
    });

    test('"folk rock" resolves to one profile without crashing', () {
      final out = GenreHardwareProfiles.userBlockDirective(
        primaryGenre: 'folk',
        subGenreFusion: 'rock',
        sunoVersion: 'v5.5',
      );
      expect(out.isNotEmpty, isTrue);
    });

    test('"west coast hip hop" does NOT accidentally match Afro House', () {
      final out = GenreHardwareProfiles.userBlockDirective(
        primaryGenre: 'west coast hip hop',
        subGenreFusion: '',
        sunoVersion: 'v5.5',
      );
      expect(out.isNotEmpty, isTrue);
      expect(
        out.toLowerCase().contains('log drum'),
        isFalse,
        reason: 'Hip-hop prompt mis-matched to Amapiano',
      );
    });

    test('profile id appears in output when resolve succeeds', () {
      final out = GenreHardwareProfiles.userBlockDirective(
        primaryGenre: 'Techno',
        sunoVersion: 'v5.5',
      );
      expect(out.contains('['), isTrue);
    });

    test('resolves exact genres including accented Forró', () {
      expect(
        GenreHardwareProfiles.resolveProfileId('House', ''),
        'HW.001.house',
      );
      expect(
        GenreHardwareProfiles.resolveProfileId('Forró', ''),
        'HW.127.forr',
      );
      expect(
        GenreHardwareProfiles.resolveProfileId('Forro', ''),
        'HW.127.forr',
      );
    });

    test('falls back to longest keyword', () {
      expect(
        GenreHardwareProfiles.resolveProfileId('Melodic Dubstep Fusion', ''),
        'HW.016.melodic_dubstep',
      );
    });

    test('detects fusion profiles for Afro House + R&B', () {
      final profiles = GenreHardwareProfiles.resolveAllProfiles(
        'Afro House',
        'R&B',
      );
      final ids = profiles.map((p) => p.id).toList();
      expect(ids, contains('HW.029.afro_house'));
      expect(ids, contains('HW.047.r_b'));

      final blended = GenreHardwareProfiles.userBlockDirective(
        primaryGenre: 'Afro House',
        subGenreFusion: 'R&B',
        sunoVersion: 'v5.5',
        includeFusionProfiles: true,
      );
      expect(blended, contains('HW.029.afro_house'));
      expect(blended, contains('HW.047.r_b'));
      expect(blended.length, lessThanOrEqualTo(500));
    });

    test('normalizeGenre folds accents and HTML entities', () {
      expect(GenreHardwareProfiles.normalizeGenre('Forró'), 'forro');
      expect(GenreHardwareProfiles.normalizeGenre('R&amp;B'), 'r&b');
    });
  });

  group('1:1 genre hardware map', () {
    test('covers every unique app genre with a direct profile', () {
      final appGenres = <String>{};
      for (final list in GenreData.subGenresByCategory.values) {
        appGenres.addAll(list);
      }
      expect(GenreHardwareProfilesData.profiles.length, greaterThanOrEqualTo(157));
      expect(
        GenreHardwareProfilesData.profileIndexByGenre.length,
        GenreHardwareProfilesData.profiles.length,
      );
      for (final genre in appGenres) {
        final profile = GenreHardwareProfiles.resolveProfile(genre, '');
        expect(
          GenreHardwareProfiles.hasProfile(genre, ''),
          isTrue,
          reason: 'Missing hardware profile for $genre',
        );
        expect(profile.genre, genre);
      }
    });

    test('Techno resolves to HW profile id (not keyword-only fallback)', () {
      final profile = GenreHardwareProfiles.resolveProfile('Techno', '');
      expect(profile.genre, 'Techno');
      expect(profile.id, startsWith('HW.'));
      expect(
        GenreHardwareProfiles.resolveProfileId('Techno', ''),
        startsWith('HW.'),
      );
      expect(GenreHardwareProfiles.hasProfile('Techno', ''), isTrue);
      expect(GenreHardwareProfiles.resolve('Techno', '').source, 'exact');
    });

    test('Amapiano resolves to amapiano hardware cluster', () {
      final profile = GenreHardwareProfiles.resolveProfile('Amapiano', '');
      expect(profile.genre, 'Amapiano');
      expect(profile.clusterId, 'EDM.12');
      expect(profile.drums.toLowerCase().contains('log'), isTrue);
    });
  });

  group('Output format', () {
    test('v5.5 form does NOT start with a "GENRE HARDWARE DEFAULTS:" header', () {
      final out = GenreHardwareProfiles.userBlockDirective(
        primaryGenre: 'Techno',
        sunoVersion: 'v5.5',
      );
      expect(out.trimLeft().startsWith('GENRE HARDWARE DEFAULTS'), isFalse);
    });
  });
}
