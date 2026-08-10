import 'dart:io';

import 'package:muisc_director/build_dj_mix_user_block.dart';
import 'package:muisc_director/prompts/consolidated_body.dart';
import 'package:muisc_director/prompts/section_ids.dart';
import 'package:test/test.dart';

void main() {
  final repoRoot = _findRepoRoot();
  final promptsRoot = '$repoRoot/prompts';

  group('Section 1F', () {
    test('loads positive content-first DJ mix-in and mix-out rules', () {
      final content = section1FContent(basePath: promptsRoot);

      expect(content, contains('SECTION 1F'));
      expect(content, contains(djMixInTag));
      expect(content, contains(djMixOutTag));
      expect(content, contains(endTag));
      expect(content, contains('8–16 bars'));
      expect(content, contains('16–32 bars'));
      expect(content, contains('VERIFICATION CHECKLIST'));
    });

    test('does not rely on negative-only instructions', () {
      final content = section1FContent(basePath: promptsRoot);

      // Positive content-first: must describe what TO include
      expect(content, contains('Establish the kick drum'));
      expect(content, contains('Maintain the kick drum'));
      expect(content, contains('MUST open with a DJ Mix-In intro'));
      expect(content, contains('MUST close with a DJ Mix-Out outro'));
    });

    test('standalone module wraps section with framing header', () {
      final standalone = buildSection1FStandalone(basePath: promptsRoot);

      expect(standalone, contains('DJ MIX BOOKEND MODULE'));
      expect(standalone, contains('Standalone'));
      expect(standalone, contains(djMixInTag));
      expect(standalone, contains(djMixOutTag));
    });

    test('consolidated body includes all sections in order', () {
      final body = buildConsolidatedBody(basePath: promptsRoot);

      expect(body, contains('SECTION 1A'));
      expect(body, contains('SECTION 1B'));
      expect(body, contains('SECTION 1C'));
      expect(body, contains('SECTION 1D'));
      expect(body, contains('SECTION 1E'));
      expect(body, contains('SECTION 1F'));

      final index1A = body.indexOf('SECTION 1A');
      final index1F = body.indexOf('SECTION 1F');
      expect(index1A, lessThan(index1F));
    });
  });

  group('buildDjMixUserBlock', () {
    test('includes mandatory mix-in and mix-out structure requirements', () {
      final block = buildDjMixUserBlock(
        const DjMixRequest(
          trackTitle: 'Midnight Pulse',
          genre: 'deep house',
          bpm: 124,
        ),
      );

      expect(block, contains('[Intro: DJ Mix-In]'));
      expect(block, contains('[Outro: DJ Mix-Out]'));
      expect(block, contains('[End]'));
      expect(block, contains('124 BPM'));
      expect(block, contains('Midnight Pulse'));
      expect(block, contains('deep house'));
    });

    test('includes DJ tag instruction when tag is provided', () {
      final block = buildDjMixUserBlock(
        const DjMixRequest(
          trackTitle: 'Sunrise Set',
          genre: 'progressive house',
          bpm: 128,
          djTag: 'You are listening to DJ Titanium',
        ),
      );

      expect(block, contains('DJ tag (spoken during mix-in only)'));
      expect(block, contains('You are listening to DJ Titanium'));
      expect(block, contains('Include the DJ tag as spoken word'));
    });

    test('defaults to instrumental mix-in when no DJ tag', () {
      final block = buildDjMixUserBlock(
        const DjMixRequest(
          trackTitle: 'Instrumental Groove',
          genre: 'techno',
          bpm: 130,
        ),
      );

      expect(block, contains('Keep the mix-in instrumental (no vocals)'));
      expect(block, isNot(contains('Include the DJ tag')));
    });

    test('includes optional fields when provided', () {
      final block = buildDjMixUserBlock(
        const DjMixRequest(
          trackTitle: 'Key Test',
          genre: 'house',
          bpm: 126,
          mood: 'euphoric',
          keySignature: 'A minor',
          vocalStyle: 'female, breathy',
          additionalNotes: 'Peak-time club weapon',
        ),
      );

      expect(block, contains('Mood: euphoric'));
      expect(block, contains('Key: A minor'));
      expect(block, contains('Vocal style: female, breathy'));
      expect(block, contains('Notes: Peak-time club weapon'));
    });
  });
}

String _findRepoRoot() {
  var dir = Directory.current;
  while (true) {
    if (File('${dir.path}/pubspec.yaml').existsSync()) {
      return dir.path;
    }
    final parent = dir.parent;
    if (parent.path == dir.path) {
      throw StateError('Could not find repo root');
    }
    dir = parent;
  }
}
