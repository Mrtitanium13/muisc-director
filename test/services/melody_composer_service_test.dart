import 'package:flutter_test/flutter_test.dart';
import 'package:music_director/config/melody_config.dart';
import 'package:music_director/data/models/melody_evolution.dart';
import 'package:music_director/services/melody_composer_service.dart';

void main() {
  group('MelodyComposerService', () {
    test('hook_led adds genre-aware style token', () {
      final result = MelodyComposerService.compose(
        melodyDirectiveId: 'hook_led',
        evolution: MelodyEvolution.strict,
        originalLyrics: '[Verse 1]\nLine one',
        primaryGenre: 'Progressive House',
      );
      expect(
        result.stylePromptTokens,
        contains('driven by a main synth hook or arpeggio'),
      );
    });

    test('hook_led falls back to default token without genre', () {
      final result = MelodyComposerService.compose(
        melodyDirectiveId: 'hook_led',
        evolution: MelodyEvolution.strict,
        originalLyrics: '',
      );
      expect(
        result.stylePromptTokens,
        contains('melodically driven by a repetitive, catchy hook'),
      );
    });

    test('progressive evolution tags final chorus', () {
      final result = MelodyComposerService.compose(
        melodyDirectiveId: 'hook_led',
        evolution: MelodyEvolution.progressive,
        originalLyrics: '[Final Chorus]\nHook line',
      );
      expect(result.modifiedLyrics, contains('layered harmonies'));
    });

    test('call and response injects parenthetical hints', () {
      final result = MelodyComposerService.compose(
        melodyDirectiveId: 'call_and_response',
        evolution: MelodyEvolution.strict,
        originalLyrics: '[Verse 1]\nFirst\nSecond',
      );
      expect(result.modifiedLyrics, contains('(lead)'));
      expect(result.modifiedLyrics, contains('(response)'));
    });

    test('auto selects arpeggiated for Melodic Techno via genre metadata', () {
      final result = MelodyComposerService.compose(
        melodyDirectiveId: MelodyConfig.autoId,
        evolution: MelodyEvolution.strict,
        originalLyrics: '',
        primaryGenre: 'Melodic Techno',
      );
      // Fine-grained family resolution now reaches the techno-specific token.
      expect(
        result.stylePromptTokens,
        contains('hypnotic sequenced techno arpeggio under the kick'),
      );
      expect(result.userNotices.first, contains('Auto-selected'));
    });

    test('getAutoMelodyToken uses genre default directive and family token', () {
      final token = MelodyComposerService.getAutoMelodyToken(
        primaryGenre: 'Uplifting Trance',
      );
      expect(
        token,
        contains('euphoric, hands-in-the-air supersaw lead melody'),
      );
    });

    test('legacy anthemic id normalizes to anthemic_soaring', () {
      final directive = MelodyConfig.getDirectiveById('anthemic');
      expect(directive.id, 'anthemic_soaring');
    });

    test('MelodyEvolution.fromId migrates rotate to progressive', () {
      expect(MelodyEvolutionIds.fromId('rotate'), MelodyEvolution.progressive);
      expect(MelodyEvolutionIds.fromId('none'), MelodyEvolution.strict);
    });

    test('custom directive injects custom notes into style token', () {
      final result = MelodyComposerService.compose(
        melodyDirectiveId: MelodyConfig.customId,
        evolution: MelodyEvolution.strict,
        customMelodyNotes: 'narrow verses, octave leap hook',
        originalLyrics: '',
      );
      expect(
        result.melodyStyleToken,
        'narrow verses, octave leap hook',
      );
    });

    test('progressive evolution lifts last [Drop] when no chorus exists', () {
      final result = MelodyComposerService.compose(
        melodyDirectiveId: 'hook_led',
        evolution: MelodyEvolution.progressive,
        originalLyrics: '[Intro]\n[Drop]\n[Breakdown]\n[Drop]\n[Outro]',
        primaryGenre: 'Techno',
      );
      final lifted = result.modifiedLyrics
          .split('\n')
          .where((l) => l.contains('layered harmonies'))
          .toList();
      expect(lifted.length, 1);
      expect(result.modifiedLyrics.indexOf('layered harmonies'),
          greaterThan(result.modifiedLyrics.indexOf('[Breakdown]')));
    });

    test('high contrast falls back to [Breakdown] when no bridge', () {
      final result = MelodyComposerService.compose(
        melodyDirectiveId: 'hook_led',
        evolution: MelodyEvolution.highContrast,
        originalLyrics: '[Intro]\n[Drop]\n[Breakdown]\n[Drop]\n[Outro]',
        primaryGenre: 'Techno',
      );
      expect(result.modifiedLyrics, contains('[Breakdown: new melodic motif'));
    });

    test('every style directive has a token for all resolvable families', () {
      const resolvableFamilies = [
        'edm',
        'dnb',
        'hardstyle',
        'hiphop',
        'amapiano',
        'afrobeats',
        'jazz',
        'rock',
        'country',
        'gospel',
        'latin',
        'pop',
        'rnb',
        'cinematic',
        'reggae',
        'funk',
        'soul',
        'blues',
        'folk',
        'electronic_experimental',
      ];
      for (final d in MelodyConfig.directives) {
        if (d.id == MelodyConfig.autoId ||
            d.id == MelodyConfig.customId ||
            d.genreTokens.isEmpty) {
          continue;
        }
        for (final family in resolvableFamilies) {
          expect(
            d.getTokenForGenre(family),
            isNotEmpty,
            reason: '${d.id} has no melody token for family: $family',
          );
        }
      }
    });

    test('recommendedEvolutionForGenre spans loop/build/contrast', () {
      expect(
        MelodyConfig.recommendedEvolutionForGenre(primaryGenre: 'Techno'),
        MelodyEvolution.strict,
      );
      expect(
        MelodyConfig.recommendedEvolutionForGenre(primaryGenre: 'Pop'),
        MelodyEvolution.progressive,
      );
      expect(
        MelodyConfig.recommendedEvolutionForGenre(primaryGenre: 'Jazz'),
        MelodyEvolution.highContrast,
      );
    });

    test('fine-grained families reach genre-specific melody tokens', () {
      const expectations = {
        'Metal / Djent': 'metal',
        'World / Bollywood / MENA': 'world',
        'Techno / Industrial': 'techno',
        'Synthwave / Retro': 'synthwave',
        'Dubstep / Riddim': 'dubstep',
        'Trap / Drill': 'trap',
        'Indie / Garage Rock': 'indie',
        'Mandopop / C-Pop': 'mandopop',
        'Reggaeton / Dembow': 'reggaeton',
        'Ambient / Soundscape': 'ambient',
        'Latin Jazz / Salsa': 'latin',
        'metal': 'metal',
      };
      expectations.forEach((genre, family) {
        expect(
          MelodyConfig.resolveMelodyGenreFamily(primaryGenre: genre),
          family,
          reason: '$genre should resolve to melody family $family',
        );
      });
    });

    test('fine-grained guards keep folk, rnb, and jazz lanes intact', () {
      expect(
        MelodyConfig.resolveMelodyGenreFamily(
          primaryGenre: 'Indie Folk / Acoustic',
        ),
        'folk',
      );
      expect(
        MelodyConfig.resolveMelodyGenreFamily(primaryGenre: 'Trap Soul'),
        'rnb',
      );
      expect(
        MelodyConfig.resolveMelodyGenreFamily(primaryGenre: 'Latin Jazz'),
        'jazz',
      );
    });

    test('hook_led uses metal token for metal lane', () {
      final result = MelodyComposerService.compose(
        melodyDirectiveId: 'hook_led',
        evolution: MelodyEvolution.strict,
        originalLyrics: '',
        primaryGenre: 'Metal / Djent',
      );
      expect(
        result.stylePromptTokens,
        contains('built on a crushing repeating riff motif'),
      );
    });

    test('evolution modifiers use colon bracket format', () {
      final progressive = MelodyComposerService.compose(
        melodyDirectiveId: 'hook_led',
        evolution: MelodyEvolution.progressive,
        originalLyrics: '[Final Chorus]\nHook line',
      );
      expect(
        progressive.modifiedLyrics,
        contains('[Final Chorus: high energy, layered harmonies]'),
      );
      final contrast = MelodyComposerService.compose(
        melodyDirectiveId: 'hook_led',
        evolution: MelodyEvolution.highContrast,
        originalLyrics: '[Verse]\n[Bridge]\n[Chorus]',
      );
      expect(
        contrast.modifiedLyrics,
        contains('[Bridge: new melodic motif, stripped back]'),
      );
    });
  });
}
