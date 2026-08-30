import 'package:flutter_test/flutter_test.dart';
import 'package:music_director/core/utils/drum_matrix.dart';

void main() {
  group('DrumMatrix genre lane resolution', () {
    // Every app-supported genre lane (label + raw id) must resolve to a
    // genre-correct profile — never silently fall back to 'pop'.
    const laneExpectations = <String, String>{
      'EDM / Progressive House': 'progressive house',
      'Hardstyle / Rawstyle': 'hardstyle',
      'Techno / Industrial': 'techno',
      'Drum & Bass': 'drum and bass',
      'Synthwave / Retro': 'synthwave',
      'Dubstep / Riddim': 'dubstep',
      'Ambient / Soundscape': 'ambient',
      'Hip-Hop / Rap': 'hip hop',
      'Trap / Drill': 'trap',
      'Boom Bap / Old School Hip-Hop': 'boom bap',
      'Reggaeton / Dembow': 'reggaeton',
      'R&B / Neo-Soul': 'contemporary r&b',
      'Mainstream Pop': 'pop',
      'Mandopop / C-Pop': 'mandopop',
      'Alternative / Classic Rock': 'rock',
      'Metal / Djent': 'heavy metal',
      'Indie / Garage Rock': 'indie rock',
      'Modern Country': 'modern country',
      'Indie Folk / Acoustic': 'folk',
      'Afrobeats / Afro-Pop': 'afrobeats',
      'Amapiano / Log Drum': 'amapiano',
      'Latin Jazz / Salsa': 'latin',
      'World / Bollywood / MENA': 'world',
      'Cinematic Film Score': 'cinematic',
      'Worship / Gospel': 'contemporary gospel',
      'Jazz / Classic Swing': 'jazz',
      // raw ids
      'edm': 'edm bounce',
      'dnb': 'drum and bass',
      'hiphop': 'hip hop',
      'boom_bap': 'boom bap',
      'metal': 'heavy metal',
      'country': 'modern country',
      'worship': 'praise and worship',
    };

    for (final entry in laneExpectations.entries) {
      test('${entry.key} -> ${entry.value}', () {
        final resolved = DrumMatrix.resolveProfile(entry.key, '');
        expect(resolved.key, entry.value);
      });
    }
  });

  group('DrumMatrix subgenre aliases', () {
    const aliasExpectations = <String, String>{
      'UK Drill': 'uk drill',
      'drill': 'uk drill',
      'liquid DnB': 'drum and bass',
      'big room': 'big room techno',
      'salsa': 'latin',
      'bossa nova': 'jazz',
      'synth pop': 'synth-pop',
      'heavy metal': 'heavy metal',
      'lo-fi hip hop': 'lo-fi hip hop',
      'grime': 'uk drill',
    };

    for (final entry in aliasExpectations.entries) {
      test('${entry.key} -> ${entry.value}', () {
        final resolved = DrumMatrix.resolveProfile(entry.key, '');
        expect(resolved.key, entry.value);
      });
    }
  });

  group('DrumMatrix profile content stays genre-accurate', () {
    test('reggae keeps one-drop on beat 3', () {
      final p = DrumMatrix.resolveProfile('reggae', '').profile;
      expect(p.kit, contains('one-drop'));
      expect(p.negative, contains('no four-on-the-floor'));
    });

    test('trap names half-time snare and triplet hats', () {
      final p = DrumMatrix.resolveProfile('trap', '').profile;
      expect(p.pattern, contains('half-time'));
      expect(p.pattern, contains('triplet'));
    });

    test('amapiano keeps log drum', () {
      final p = DrumMatrix.resolveProfile('amapiano', '').profile;
      expect(p.kit, contains('log drum'));
    });

    test('reggaeton uses dembow grid, not trap hats', () {
      final p = DrumMatrix.resolveProfile('reggaeton', '').profile;
      expect(p.kit, contains('dembow'));
      expect(p.kit, isNot(contains('rolling hats')));
    });

    test('deep house negative does not contradict its swung hats', () {
      final p = DrumMatrix.resolveProfile('deep house', '').profile;
      expect(p.pattern, contains('shuffling'));
      expect(p.negative, isNot(contains('no swing')));
    });

    test('dubstep keeps half-time snare on beat 3', () {
      final p = DrumMatrix.resolveProfile('dubstep', '').profile;
      expect(p.kit, contains('half-time snare on beat 3'));
    });

    test('synthwave uses 80s drum machines with gated snare', () {
      final p = DrumMatrix.resolveProfile('synthwave', '').profile;
      expect(p.kit, contains('LinnDrum'));
      expect(p.kit, contains('gated-reverb'));
    });
  });

  group('DrumMatrix prompt output', () {
    test('user block directive names matched profile and core fields', () {
      final out = DrumMatrix.userBlockDirective(
        primaryGenre: 'Amapiano / Log Drum',
        sunoVersion: 'v4.5',
      );
      expect(out, contains('Matched profile: [amapiano]'));
      expect(out, contains('Kit:'));
      expect(out, contains('Pattern:'));
      expect(out, contains('Avoid:'));
    });

    test('v4.5 style prompt stays within 120 chars', () {
      final out = DrumMatrix.buildStylePrompt('Techno / Industrial', 'v4.5');
      expect(out.length, lessThanOrEqualTo(120));
    });
  });
}
