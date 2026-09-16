import 'package:flutter_test/flutter_test.dart';
import 'package:music_director/core/constants/api_constants.dart';
import 'package:music_director/data/models/audio_analysis_model.dart';
import 'package:music_director/core/constants/suno_prompt_limits.dart';
import 'package:music_director/core/utils/openai_key_validation.dart';
import 'package:music_director/core/constants/genre_data.dart';
import 'package:music_director/core/constants/block1_mix_master_directive.dart';
import 'package:music_director/core/utils/drum_matrix.dart';
import 'package:music_director/core/utils/advanced_thematic_variator.dart';
import 'package:music_director/core/utils/anti_scream_filter.dart';
import 'package:music_director/core/constants/genre_lyrics_directives.dart';
import 'package:music_director/core/utils/dynamic_structural_engine.dart';
import 'package:music_director/core/utils/suno_prompt_builder.dart';
import 'package:music_director/core/utils/genre_hybridization_matrix.dart';
import 'package:music_director/core/utils/suno_lyric_phonetic_sanitize.dart';
import 'package:music_director/core/utils/suno_lyrics_audio_normalizer.dart';
import 'package:music_director/core/utils/live_instrument_matrix.dart';
import 'package:music_director/core/utils/live_instrument_matrix_data.dart';
import 'package:music_director/core/utils/code_translation_matrix.dart';
import 'package:music_director/core/constants/audio_environment_data.dart';
import 'package:music_director/core/utils/chat_completion_helpers.dart';
import 'package:music_director/core/utils/suno_output_qa.dart';
import 'package:music_director/core/utils/payload_optimization.dart';
import 'package:music_director/core/utils/remix_payload_compiler.dart';
import 'package:music_director/features/remix/application/remix_telemetry.dart';
import 'package:music_director/features/remix/application/source_leak_guard.dart';
import 'package:music_director/data/models/song_generation_type.dart';
import 'package:music_director/data/models/user_input_model.dart';
import 'package:music_director/core/constants/human_authenticity_config.dart';
import 'package:music_director/core/constants/suno_system_prompt_v2_candidate.dart';
import 'package:music_director/core/constants/human_realism_config.dart';
import 'package:music_director/core/constants/elite_human_lyricist_directive.dart';
import 'package:music_director/prompts/elite_human_lyricist.dart';
import 'package:music_director/core/constants/power_code_data.dart';
import 'package:music_director/core/constants/hitmaker_max_martin_directives.dart';
import 'package:music_director/core/constants/big_room_fusion_progressive_preset.dart';
import 'package:music_director/core/constants/big_room_hardstyle_cinematic_hybrid_preset.dart';
import 'package:music_director/core/constants/hardstyle_euro_dance_bootleg_preset.dart';
import 'package:music_director/core/constants/prompt_templates.dart';
import 'package:music_director/core/constants/suno_dj_mix_directives.dart';
import 'package:music_director/core/constants/real_instruments_data.dart';
import 'package:music_director/core/constants/chord_progression_data.dart';
import 'package:music_director/config/melody_config.dart';
import 'package:music_director/data/models/melody_evolution.dart';
import 'package:music_director/core/constants/song_structure_data.dart';
import 'package:music_director/core/constants/suno_compression_pass.dart';
import 'package:music_director/core/constants/humanization_pass.dart';
import 'package:music_director/core/constants/dialect_style_data.dart';
import 'package:music_director/core/constants/vocal_accent_data.dart';
import 'package:music_director/core/constants/suno_structure_examples.dart';
import 'package:music_director/core/utils/duration_format.dart';
import 'package:music_director/core/utils/suno_lyrics_merge.dart';
import 'package:music_director/core/utils/suno_block2_opt_out.dart';
import 'package:music_director/core/utils/suno_output_split.dart'
    show enforceUnifiedBlock1CharLimit, parseSunoDualOutput, parseSunoOutput;
import 'package:music_director/services/melody_composer_service.dart';
import 'package:music_director/data/models/suno_field_output_mode.dart';
import 'package:music_director/data/models/track_duration_config.dart';

void main() {
  group('TrackDurationUtils', () {
    test('format zero/negative durations', () {
      expect(TrackDurationUtils.format(Duration.zero), '—');
      expect(
        TrackDurationUtils.format(const Duration(milliseconds: -500)),
        '—',
      );
    });

    test('format short durations', () {
      expect(TrackDurationUtils.format(const Duration(seconds: 5)), '0:05');
      expect(TrackDurationUtils.format(const Duration(seconds: 65)), '1:05');
      expect(
        TrackDurationUtils.format(const Duration(minutes: 3, seconds: 45)),
        '3:45',
      );
    });

    test('format hour durations', () {
      expect(
        TrackDurationUtils.format(
          const Duration(hours: 1, minutes: 2, seconds: 3),
        ),
        '1:02:03',
      );
    });

    test('formatMinutes handles decimals', () {
      expect(TrackDurationUtils.formatMinutes(3.5), '3:30');
      expect(TrackDurationUtils.formatMinutes(0.0), '0:00');
      expect(TrackDurationUtils.formatMinutes(double.nan), '0:00');
    });

    test('parseMinutes colon formats', () {
      expect(TrackDurationUtils.parseMinutes('3:30'), 3.5);
      expect(TrackDurationUtils.parseMinutes('1:02:03'), 62.05);
      expect(TrackDurationUtils.parseMinutes('3:75'), isNull);
    });

    test('parseMinutes suffix and plain', () {
      expect(TrackDurationUtils.parseMinutes('3min'), 3.0);
      expect(TrackDurationUtils.parseMinutes('3.5 minutes'), 3.5);
      expect(TrackDurationUtils.parseMinutes('4 min'), 4.0);
      expect(TrackDurationUtils.parseMinutes('180'), 3.0);
      expect(TrackDurationUtils.parseMinutes('3'), 3.0);
      expect(TrackDurationUtils.parseMinutes('10'), 10.0);
      expect(TrackDurationUtils.parseMinutes('3.5'), 3.5);
    });

    test('parseMinutes rejects invalid', () {
      expect(TrackDurationUtils.parseMinutes(''), isNull);
      expect(TrackDurationUtils.parseMinutes('abc'), isNull);
      expect(TrackDurationUtils.parseMinutes('-3'), isNull);
    });

    test('extension works', () {
      expect(const Duration(minutes: 4, seconds: 20).trackDisplay, '4:20');
    });

    test('back-compat aliases still work', () {
      expect(formatTrackDuration(Duration.zero), '—');
      expect(formatMinutesToMmSs(3.75), '3:45');
      expect(parseFlexibleDurationMinutes('3:45'), closeTo(3.75, 1e-9));
    });
  });

  group('parseFlexibleDurationMinutes / formatMinutesToMmSs', () {
    test('parses M:SS and normalizes', () {
      expect(parseFlexibleDurationMinutes('3:45'), closeTo(3.75, 1e-9));
      expect(formatMinutesToMmSs(3.75), '3:45');
    });

    test('parses H:MM:SS', () {
      expect(parseFlexibleDurationMinutes('1:02:03'), closeTo(62.05, 1e-9));
    });

    test('plain integer: minutes vs seconds', () {
      expect(parseFlexibleDurationMinutes('10'), 10.0);
      expect(parseFlexibleDurationMinutes('180'), 3.0);
    });

    test('min suffix and decimals', () {
      expect(parseFlexibleDurationMinutes('4 min'), 4.0);
      expect(parseFlexibleDurationMinutes('3.5'), 3.5);
    });

    test('custom TrackDurationConfig uses label', () {
      final c = TrackDurationConfig.fromUserInput(
        duration: TrackDuration.custom,
        trackDurationLabel: '3:10',
        djIntro: false,
        djOutro: false,
        bpmRaw: '120',
        family: StructuralFamily.popStandard,
      );
      expect(c.displayLabel, '3:10');
      expect(c.tier, DurationTier.standard);
      expect(c.totalBars, 95);
    });
  });

  group('Hitmaker / Max Martin', () {
    test('genre label is in Pop sub-genres', () {
      expect(
        GenreData.subGenresByCategory['Pop'],
        contains(hitmakerMaxMartinGenreLabel),
      );
    });

    test('userRequestedHitmakerMode detects primary and fusion', () {
      expect(
        userRequestedHitmakerMode(
          const UserInputModel(primaryGenre: hitmakerMaxMartinGenreLabel),
        ),
        isTrue,
      );
      expect(
        userRequestedHitmakerMode(
          const UserInputModel(
            primaryGenre: 'Synth Pop',
            subGenreFusion: 'Pop / Max Martin blend',
          ),
        ),
        isTrue,
      );
      expect(
        userRequestedHitmakerMode(
          const UserInputModel(primaryGenre: 'Synth Pop'),
        ),
        isFalse,
      );
    });

    test('user block lists power keywords', () {
      final b = buildHitmakerModeUserBlock(v2UnifiedOutput: true);
      expect(b, contains('Melodic Math'));
      expect(b, contains('1176 FET Compression'));
      expect(b, contains('Vocal Stacking'));
      expect(b, contains('Sidechained Pulsing Bass'));
      expect(b, contains('−8 LUFS'));
      expect(b, contains('A–A–B–A'));
    });
  });

  group('SongStructureData.userBlockDirective', () {
    test('flexible assembles deterministic arc', () {
      final s = SongStructureData.userBlockDirective(
        presetId: SongStructureData.flexibleId,
        customNotes: '',
        primaryGenre: 'Amapiano',
        sunoVersion: 'v5.5',
      );
      expect(s, contains('STRUCTURE_LOCK (MANDATORY — assembled arc)'));
      expect(s, contains('Verse 2'));
      expect(s, contains('Breakdown'));
      expect(s, contains('[End]'));
    });

    test('empty preset id matches flexible assembly', () {
      final a = SongStructureData.userBlockDirective(
        presetId: '',
        customNotes: '',
        primaryGenre: 'Pop',
      );
      final b = SongStructureData.userBlockDirective(
        presetId: SongStructureData.flexibleId,
        customNotes: '',
        primaryGenre: 'Pop',
      );
      expect(a, b);
    });

    test('standard_pop embeds required roadmap', () {
      final s = SongStructureData.userBlockDirective(
        presetId: 'standard_pop',
        customNotes: '',
      );
      expect(s, contains('STRUCTURE_LOCK (MANDATORY'));
      expect(s, contains('Standard pop'));
      expect(s, contains('Intro'));
      expect(s, contains('Outro'));
    });

    test('custom empty assembles flexible arc', () {
      final s = SongStructureData.userBlockDirective(
        presetId: SongStructureData.customId,
        customNotes: '   ',
        primaryGenre: 'Pop',
      );
      expect(s, contains('STRUCTURE_LOCK (MANDATORY — assembled arc)'));
      expect(s, contains('Intro'));
    });

    test('custom with notes passes through outline', () {
      final outline = 'Intro → Drop → Outro';
      final s = SongStructureData.userBlockDirective(
        presetId: SongStructureData.customId,
        customNotes: outline,
      );
      expect(s, contains(outline));
      expect(s, contains('STRUCTURE_LOCK (MANDATORY'));
    });

    test('custom with bracket headers asks for bracket layout', () {
      const outline = '[Intro]\n(piano)\n[Drop]\n(kick)';
      final s = SongStructureData.userBlockDirective(
        presetId: SongStructureData.customId,
        customNotes: outline,
      );
      expect(s, contains('bracketed'));
      expect(s, contains('[Section: staging]'));
      expect(s, contains(outline));
    });

    test('DJ mix flags prepend structure note linking intro/outro tags', () {
      final s = SongStructureData.userBlockDirective(
        presetId: SongStructureData.flexibleId,
        customNotes: '',
        primaryGenre: 'Progressive House',
        includeDjIntro: true,
        includeDjOutro: true,
      );
      expect(s, contains('Production Requirement block'));
      expect(s, contains('NOT standard musical intros/outros'));
    });
  });

  group('StructureAssembler', () {
    test('every family produces sections ending in End', () {
      for (final family in StructuralFamily.values) {
        final sections = StructureAssembler.assemble(
          sunoVersion: 'v5.5',
          commercialLane: StructuralFamilyResolver.laneHintFor(family),
        )!;
        expect(sections.last.label, 'End');
        expect(sections.length, greaterThanOrEqualTo(4));
      }
    });

    test('amapiano bridge only after verse 2 when complex intent', () {
      final standard = StructureAssembler.assemble(
        sunoVersion: 'v5.5',
        primaryGenre: 'Amapiano',
        intent: SongIntent.standard,
      )!;
      final complex = StructureAssembler.assemble(
        sunoVersion: 'v5.5',
        primaryGenre: 'Amapiano',
        intent: SongIntent.complex,
      )!;
      expect(standard.any((s) => s.kind == SectionKind.bridge), isFalse);
      expect(complex.any((s) => s.kind == SectionKind.bridge), isTrue);
      final v2Index = complex.indexWhere((s) => s.label == 'Verse 2');
      final bridgeIndex = complex.indexWhere((s) => s.kind == SectionKind.bridge);
      expect(bridgeIndex, greaterThan(v2Index));
    });

    test('v5.5 brackets have no nested brackets or BPM tokens', () {
      for (final family in StructuralFamily.values) {
        final sections = StructureAssembler.assemble(
          sunoVersion: 'v5.5',
          commercialLane: StructuralFamilyResolver.laneHintFor(family),
        )!;
        for (final line in StructureAssembler.toSunoBrackets(
          sections,
          sunoVersion: 'v5.5',
        )) {
          expect(line, matches(r'^\[[^\[\]]+\]$'));
          expect(line.toLowerCase(), isNot(contains('bpm')));
        }
      }
    });

    test('worship defaults to congregational vamp', () {
      final sections = StructureAssembler.assemble(
        sunoVersion: 'v5.5',
        primaryGenre: 'Modern Worship',
      )!;
      expect(sections.any((s) => s.kind == SectionKind.vamp), isTrue);
      expect(
        sections.any((s) => s.kind == SectionKind.spontaneousFlow),
        isTrue,
      );
    });

    test('final chorus mutation staging on v5.5 via renderer', () {
      // Generic "EDM" maps to progressive Drop A/B scaffold (no Final Drop).
      // Use Trance so Final Drop mutation staging injects beat-switch.
      final sections = StructureAssembler.assemble(
        sunoVersion: 'v5.5',
        primaryGenre: 'Trance',
      )!;
      final family = StructuralFamilyResolver.resolve(primaryGenre: 'Trance');
      final rendered = SunoSyntaxRenderer.renderSections(
        sections,
        'v5.5',
        family: family,
      );
      expect(rendered, contains('Final Drop'));
      expect(rendered, contains('beat-switch'));
    });
  });

  group('SongStructureData v2 presets', () {
    test('standard_pop typed sections and Suno brackets', () {
      final preset = SongStructureData.presetById('standard_pop');
      expect(preset, isNotNull);
      expect(preset!.hasBridge, isTrue);
      expect(preset.sectionCount, 8);
      expect(preset.toSunoBrackets(), contains('[Intro]'));
      expect(preset.toSunoBrackets(), contains('[Final Chorus]'));
    });

    test('presetsForGenre matches amapiano affinity', () {
      final hits = SongStructureData.presetsForGenre('Amapiano');
      expect(hits.map((p) => p.id), contains('amapiano'));
    });

    test('worship preset includes vamp', () {
      final preset = SongStructureData.presetById('worship');
      expect(preset!.hasVamp, isTrue);
    });

    test('presets are unique by id', () {
      final ids = SongStructureData.presets.map((p) => p.id).toList();
      expect(ids.toSet().length, ids.length);
    });

    test('arrangement dropdown lists Custom after Flexible', () {
      final dropdown = SongStructureData.arrangementDropdownPresets;
      expect(dropdown.length, SongStructureData.presets.length);
      expect(dropdown.first.id, SongStructureData.flexibleId);
      expect(dropdown[1].id, SongStructureData.customId);
    });

    test('HTML entities removed from labels', () {
      final worship = SongStructureData.presetById('worship');
      expect(worship?.label, 'Praise & Worship');
      expect(worship?.label, isNot(contains('&amp;')));
    });

    test('genre index finds presets', () {
      final edm = SongStructureData.presetsForGenre('EDM');
      expect(edm.map((p) => p.id), contains('edm_drop'));
    });

    test('new presets exist', () {
      expect(SongStructureData.presetById('dnb_roller'), isNotNull);
      expect(SongStructureData.presetById('hardstyle_anthem'), isNotNull);
      expect(SongStructureData.presetById('country_story'), isNotNull);
      expect(SongStructureData.presetById('rock_alt'), isNotNull);
      expect(SongStructureData.presetById('reggae'), isNotNull);
    });

    test('isKnownPresetId works', () {
      expect(SongStructureData.isKnownPresetId('flexible'), isTrue);
      expect(SongStructureData.isKnownPresetId('custom'), isTrue);
      expect(SongStructureData.isKnownPresetId('missing'), isFalse);
    });
  });

  group('userRequestedBlock2OptOut', () {
    test('detects opt-out phrases case-insensitively', () {
      expect(
        userRequestedBlock2OptOut(
          const UserInputModel(vibe: 'Style ONLY please'),
        ),
        isTrue,
      );
      expect(
        userRequestedBlock2OptOut(
          const UserInputModel(vibe: 'trap banger'),
        ),
        isFalse,
      );
      expect(
        userRequestedBlock2OptOut(
          const UserInputModel(lyricThemeNotes: 'Block 1 only'),
        ),
        isTrue,
      );
    });
  });

  group('Block1MixMasterDirective', () {
    test('Part E v2.1 profile includes hardware, LUFS, no DJ phrasing', () {
      final techno = Block1MixMasterDirective.userBlockDirective(
        primaryGenre: 'Techno',
        sunoVersion: 'v5.5',
      );
      expect(techno, contains('[HW.008.techno]'));
      expect(techno, contains('LUFS'));
      expect(techno, contains('−1.0 dBTP'));
      expect(techno.toLowerCase().contains('dj intro'), isFalse);
      expect(techno.toLowerCase().contains('beatmatch'), isFalse);

      final prog = Block1MixMasterDirective.userBlockDirective(
        primaryGenre: 'Progressive House',
        sunoVersion: 'v5.5',
      );
      expect(prog, contains('[HW.005.progressive_house]'));
      expect(prog.toLowerCase(), contains('sidechain'));

      final amapiano = Block1MixMasterDirective.userBlockDirective(
        primaryGenre: 'Amapiano-Vinahouse',
        sunoVersion: 'v5.5',
      );
      expect(amapiano, contains('[HW.030.amapiano_vinahouse]'));
      expect(amapiano.toLowerCase(), contains('log-drum'));

      final chill = Block1MixMasterDirective.userBlockDirective(
        primaryGenre: 'Chillhop',
        sunoVersion: 'v5.5',
      );
      expect(chill, contains('[HW.041.chillhop]'));

      final synth = Block1MixMasterDirective.userBlockDirective(
        primaryGenre: 'Synthwave',
        sunoVersion: 'v5.5',
      );
      expect(synth, contains('[HW.156.synthwave]'));

      final ukg = Block1MixMasterDirective.userBlockDirective(
        primaryGenre: 'UK Garage',
        sunoVersion: 'v5.5',
      );
      expect(ukg, contains('[HW.031.uk_garage]'));

      final trapSoul = Block1MixMasterDirective.userBlockDirective(
        primaryGenre: 'Trap Soul',
        sunoVersion: 'v5.5',
      );
      expect(trapSoul, contains('[HW.054.trap_soul]'));
    });
  });

  group('remixPayloadCompiler', () {
    test('remixPostProcessCompactLine is leak-safe (no source names)', () {
      final line = remixPostProcessCompactLine(
        originalSongTitle: 'Mercy',
        originalArtist: 'Band',
        generationType: SongGenerationType.fullSong,
      );
      expect(line, contains('lock:melody+rhythm+chords'));
      expect(line, contains('v=1.3'));
      expect(line, contains('fp='));
      expect(line, isNot(contains('Mercy')));
      expect(line, isNot(contains('Band')));
      expect(line, isNot(contains('RMX:src=')));
    });

    test('remixEngineActive when title and artist set', () {
      const on = UserInputModel(
        remixOriginalSongTitle: 'Mercy',
        remixOriginalArtist: 'Worship Band',
      );
      expect(remixEngineActive(on), isTrue);
      expect(remixEngineActive(const UserInputModel()), isFalse);
    });

    test('analyzer flag wins over title/artist (mutual exclusion)', () {
      const both = UserInputModel(
        remixOriginalSongTitle: 'Mercy',
        remixOriginalArtist: 'Band',
        remixFromAnalyzer: true,
      );
      expect(remixEngineActive(both), isFalse);
      expect(remixResolutionFor(both).mode, RemixMode.analyzerGenreFlip);
    });

    test('near-activation when only title filled', () {
      const partial = UserInputModel(remixOriginalSongTitle: 'Mercy');
      final r = remixResolutionFor(partial);
      expect(r.mode, RemixMode.none);
      expect(r.nearActivation, isTrue);
      expect(remixEngineActive(partial), isFalse);
    });

    test('applyInstrumentalRemixOutput strips lyric lines', () {
      const raw = '''
BLOCK 2 — PASTE INTO SUNO: LYRICS
[Intro]
[Reimagined melodic interpolation, sparse rhythm bed]
(Soft hum...)
[Verse 1]
[Intimate close-mic delivery]
Left the porch light on again.
[Chorus]
[Isolated multi-tracked vocal doubles]
So I am saying thank You.''';
      final out = applyInstrumentalRemixOutput(raw);
      expect(out, isNot(contains('Left the porch')));
      expect(out, isNot(contains('thank You')));
      expect(out, contains('Intimate close-mic delivery'));
    });

    test('sourceLeakGuard redacts feat variants', () {
      final r = sourceLeakGuard(
        output: 'Style about Someone and Test Song vibes',
        title: 'Test Song',
        artist: 'Test Artist feat. Someone',
      );
      expect(r.leaked, isTrue);
      expect(r.text, isNot(contains('Test Song')));
      expect(r.text, contains('[redacted]'));
    });

    test('descriptor-only user block excludes catalog names', () {
      final block = remixStyleFlipUserBlockSupplement(
        originalSongTitle: 'Test Song',
        originalArtist: 'Test Artist feat. Someone',
        targetGenre: 'synthwave',
        generationType: SongGenerationType.fullSong,
        bpm: '118',
        keyRoot: 'A',
        scale: 'Minor',
      );
      expect(block, contains('DESCRIPTOR-ONLY'));
      expect(block, contains('REFERENCE DNA'));
      expect(block, contains('synthwave'));
      expect(block, contains('118'));
      expect(block, isNot(contains('Test Song')));
      expect(block, isNot(contains('Test Artist')));
      expect(block, isNot(contains('Someone')));
    });

    test('idempotent style-flip block when marker already present', () {
      final again = remixStyleFlipUserBlockSupplement(
        originalSongTitle: 'Mercy',
        originalArtist: 'Band',
        targetGenre: 'Jazz',
        generationType: SongGenerationType.fullSong,
        existingUserBlock: '… $remixBlockMarker already …',
      );
      expect(again, isEmpty);
    });

    test('telemetry fields never include raw title/artist', () {
      const title = 'Secret Song Title XYZ';
      const artist = 'Secret Artist Name ABC';
      final act = RemixTelemetry.activationFields(
        mode: RemixMode.interpolation,
        nearActivation: false,
        genre: 'House',
        songGenerationType: 'full_song',
        title: title,
        artist: artist,
        blockInjected: true,
      );
      final post = RemixTelemetry.postProcessFields(
        mode: RemixMode.interpolation,
        songGenerationType: 'instrumental',
        strippedLyricLines: 2,
        stagingInjected: 1,
        leakHit: true,
        title: title,
        artist: artist,
      );
      final joined = '${act.values.join(' ')} ${post.values.join(' ')}';
      expect(joined, isNot(contains(title)));
      expect(joined, isNot(contains(artist)));
      expect(act['fp'], isNot('none'));
      expect(post['strip_n'], 2);
      expect(post['leak'], isTrue);
    });

    test('applyInstrumentalRemixOutputDetailed reports strip counts', () {
      const raw = '''
BLOCK 2 — PASTE INTO SUNO: LYRICS
[Verse 1]
Lyric line one.
Lyric line two.''';
      final detail = applyInstrumentalRemixOutputDetailed(raw);
      expect(detail.strippedLyricLines, 2);
      expect(detail.stagingInjected, greaterThanOrEqualTo(1));
      expect(detail.text, isNot(contains('Lyric line')));
    });
  });

  group('payloadOptimization', () {
    test('truncateContinuationPrior keeps head and tail', () {
      final prior = '${'A' * 2000}\n${'B' * 8000}';
      final out = truncateContinuationPrior(prior, maxChars: 3000);
      expect(out, contains('truncated for token budget'));
      expect(out.startsWith('A'), isTrue);
      expect(out.trimRight().endsWith('B'), isTrue);
    });

    test('compactPayloadText collapses excessive newlines', () {
      expect(
        compactPayloadText('line one  \n\n\n\nline two  \n'),
        'line one\n\nline two',
      );
    });

    test('cleanLaoZhangOnDevicePayload collapses stacked brackets', () {
      const raw = '[Intro]\n[Dead-room isolation] [Close-mic vocal]\nLine.';
      final out = cleanLaoZhangOnDevicePayload(raw);
      expect(out, contains('[Dead-room isolation, Close-mic vocal]'));
      expect(out, isNot(contains('] [')));
    });

    test('cleanLaoZhangOnDevicePayload evicts SATB and harmonic backing', () {
      const raw = '[Chorus]\n[Studio Harmonic Backing, SATB Choir swell]';
      final out = cleanLaoZhangOnDevicePayload(raw);
      expect(out, contains('Isolated multi-tracked vocal doubles'));
      expect(out, isNot(contains('Harmonic Backing')));
      expect(out, isNot(contains('SATB')));
    });
  });

  group('sanitizeSunoPostOutput', () {
    test('strips trailing apostrophes and expands round', () {
      const raw = "'round we go, turnin' slow, glidin' free";
      final out = sanitizeSunoPostOutput(raw);
      expect(out, contains('around we go'));
      expect(out, isNot(contains("turnin'")));
      expect(out, contains('turnin slow'));
      expect(out, contains('glidin free'));
    });

    test('instrumental break strips Feature verb leak', () {
      const raw =
          '[Instrumental Break: Feature bright strummed rhythm, tight pocket Acoustic Guitar, wide stereo]';
      final out = sanitizeSunoPostOutput(raw);
      expect(out, isNot(contains('Feature ')));
      expect(out, contains('bright strummed rhythm'));
    });

    test('gospel lane replaces sidechain in brackets', () {
      const raw = '[Chorus: wide stacks, sidechain pump, hook lift]';
      final out = sanitizeSunoPostOutput(
        raw,
        primaryGenre: 'Praise and Worship',
      );
      expect(out.toLowerCase(), isNot(contains('sidechain')));
      expect(out, contains('Analog VCA glue'));
    });

    test('folk lane strips drum loop token', () {
      const raw = '[Intro: Acoustic Guitar, drum loop, warm room]';
      final out = applyCriticalReconciliation(
        raw,
        primaryGenre: 'Folk',
      );
      expect(out.toLowerCase(), isNot(contains('drum loop')));
      expect(out, contains('Acoustic Guitar'));
    });

    test('studio isolation skipped for live performance mode', () {
      const raw = '''
[Intro]
[Live band count-in, Full SATB Choir Stack, Sanctuary reverb]
Opening line.''';
      final out = sanitizeStudioIsolationTags(
        raw,
        primaryGenre: 'Praise and Worship',
        audioEnvironmentModeId: AudioEnvironmentData.livePerformanceId,
      );
      expect(out.toUpperCase(), contains('SATB'));
      expect(out, contains('Sanctuary'));
    });

    test('studio isolation strips crowd triggers from intro', () {
      const raw = '''
[Intro]
[Live band count-in, Full SATB Choir Stack, Sanctuary reverb]
Opening line.
[Chorus]
[Full SATB Choir Stack, hook lift]''';
      final out = sanitizeStudioIsolationTags(
        raw,
        primaryGenre: 'Praise and Worship',
      );
      final introBlock = out.split('[Chorus]').first;
      expect(introBlock.toUpperCase(), isNot(contains('SATB')));
      expect(introBlock, isNot(contains('Sanctuary')));
      expect(introBlock, isNot(contains('Live band')));
      expect(introBlock, contains('Isolated multi-tracked vocal doubles'));
      expect(introBlock, isNot(contains('Harmonic Backing')));
    });

    test('studio isolation swaps tape hiss in intro', () {
      const raw = '''
[Intro]
[Dead-room isolation, Subtle Tape Hiss, close-mic vocal]
Opening line.''';
      final out = sanitizeStudioIsolationTags(
        raw,
        primaryGenre: 'Indie Acoustic',
      );
      expect(out.toLowerCase(), isNot(contains('tape hiss')));
      expect(out.toLowerCase(), contains('focused studio room'));
    });

    test('studio isolation swaps harmonic backing in chorus', () {
      const raw = '''
[Chorus]
[Studio Harmonic Backing, Hammond swell]
Hook line.''';
      final out = sanitizeStudioIsolationTags(
        raw,
        primaryGenre: 'Praise and Worship',
      );
      expect(out, contains('Isolated multi-tracked vocal doubles'));
      expect(out, isNot(contains('Harmonic Backing')));
    });

    test('studio isolation strips crowd triggers from chorus brackets', () {
      const raw = '''
[Chorus]
[Thunderous stadium crowd cheering, crowd singing along loudly]
Hook line.''';
      final out = sanitizeStudioIsolationTags(
        raw,
        primaryGenre: 'Afrobeats',
      );
      expect(out.toLowerCase(), isNot(contains('crowd')));
      expect(out.toLowerCase(), isNot(contains('stadium')));
      expect(out, contains('Multi-tracked vocal overlays'));
    });

    test('studio isolation scrubs crowd tokens from block 1 prose', () {
      const raw = '''
BLOCK 1 — PASTE INTO SUNO: STYLE
Afrobeats, zero audience noise, no crowd sounds, pristine mix.

BLOCK 2 — PASTE INTO SUNO: LYRICS
[Intro]
[Dead-room isolation, close-mic vocal]
Line one.''';
      final out = sanitizeStudioIsolationTags(raw, primaryGenre: 'Afrobeats');
      final block1 = out.split('BLOCK 2').first;
      expect(block1.toLowerCase(), isNot(contains('audience')));
      expect(block1.toLowerCase(), isNot(contains('crowd')));
    });

    test('audio engine normalizer strips DJ intro jargon in block 2', () {
      const raw = '''
BLOCK 1 — PASTE INTO SUNO: STYLE
Progressive house, intimate male vocal.

BLOCK 2 — PASTE INTO SUNO: LYRICS
[16-bar DJ intro, filtered TR-909 kick, low-pass sweep opening]
[Build-up]
[Male Vocal, Intimate, American (General) Delivery]
Headlights paint the ceiling white
[Drop]
(Tonight...)
(Tonight...)
[End]''';
      final out = sanitizeSunoPostOutput(raw);
      expect(out, contains('[Intro]'));
      expect(out, contains('[Atmospheric Synth Intro]'));
      expect(out, isNot(contains('TR-909')));
      expect(out, contains('[Intimate Male Vocal]'));
      expect(out, isNot(contains('American (General) Delivery')));
      expect(out, contains('[Pre-Drop]'));
      expect(out, contains('Tonight!'));
      expect(out, contains('[Instrumental Drop]'));
      expect(out, isNot(contains('(Tonight...)')));
    });
  });

  group('normalizeLyricsForAudioEngine', () {
    test('collapses stacked vocal tags and hardware names', () {
      const raw = '''
[Build-up]
[Male Vocal, Whispered, close-mic]
Prophet-5 pad swells
Tonight''';
      final out = normalizeLyricsForAudioEngine(raw);
      expect(out, contains('[Whispered Male Vocal]'));
      expect(out, contains('Synth pad swells'));
      expect(out, isNot(contains('Prophet-5')));
    });

    test('final drop parenthetical trap becomes instrumental', () {
      const raw = '''
[Final Drop]
(We're infinite...)
(We're infinite...)''';
      final out = normalizeLyricsForAudioEngine(raw);
      expect(out, contains('[Pre-Drop]'));
      expect(out, contains('[Maximum Energy Instrumental Drop]'));
    });
  });

  group('GenreHybridizationMatrix', () {
    test('user block when fusion is set', () {
      final block = GenreHybridizationMatrix.userBlockDirective(
        primaryGenre: 'Melodic Techno',
        subGenreFusion: 'Indie Acoustic',
      );
      expect(block, contains('GENRE HYBRIDIZATION & CULTURAL ROUTING MATRIX'));
      expect(block, contains('PART 1'));
      expect(block, contains('Split-DNA'));
      expect(block, contains('primaryGenre=Melodic Techno'));
      expect(block, contains('subGenreFusion=Indie Acoustic'));
      expect(block, contains('sidechain'));
      expect(block, contains('Subordinate tag accent rule'));
    });

    test('empty when fusion unset', () {
      expect(
        GenreHybridizationMatrix.userBlockDirective(
          primaryGenre: 'Melodic Techno',
          subGenreFusion: '',
        ),
        isEmpty,
      );
      expect(
        GenreHybridizationMatrix.userBlockDirective(
          primaryGenre: 'Melodic Techno',
          subGenreFusion: 'none',
        ),
        isEmpty,
      );
    });
  });

  group('DrumMatrix', () {
    test('resolves longest genre match and staging cap', () {
      final resolved = DrumMatrix.resolveProfile('Melodic Techno', 'House');
      expect(resolved.key, 'melodic techno');
      expect(resolved.profile.kit.toLowerCase(), contains('driving clean kick'));

      final dnb = DrumMatrix.resolveProfile('Liquid DnB', '');
      expect(dnb.key, 'drum and bass');

      final staging = DrumMatrix.buildStagingLine(resolved.profile);
      expect(staging.length, lessThanOrEqualTo(120));
    });

    test('user block includes matched profile and version hint', () {
      final block = DrumMatrix.userBlockDirective(
        primaryGenre: 'Hardstyle',
        sunoVersion: 'v5.5',
      );
      expect(block, contains('DRUM MATRIX'));
      expect(block, contains('[hardstyle]'));
      expect(block.toLowerCase(), contains('reverse-bass kick'));
    });
  });

  group('SunoPromptBuilder', () {
    test('all 21 genre lanes build at max intensity', () {
      const genres = [
        'edm',
        'hardstyle',
        'techno',
        'dnb',
        'synthwave',
        'dubstep',
        'ambient',
        'hiphop',
        'trap',
        'pop',
        'rnb',
        'reggaeton',
        'rock',
        'metal',
        'indie',
        'country',
        'folk',
        'afrobeats',
        'latin',
        'cinematic',
        'jazz',
      ];
      for (final genre in genres) {
        final output = SunoPromptBuilder.buildSunoPrompt(
          baseStyle: 'Base Style Text',
          baseLyrics: '[Chorus]\nSinging lyrics here...',
          primaryGenre: genre,
          intensity: 3,
        );
        expect(output.prompt, contains('Base Style Text'));
        expect(output.lyrics, contains('[Chorus]'));
        expect(output.matchedGenreKey, genre);
      }
    });

    test('resolves app genre labels to matrix keys', () {
      expect(
        SunoPromptBuilder.resolveGenreKey('Hard Techno', ''),
        'techno',
      );
      expect(
        SunoPromptBuilder.resolveGenreKey('Liquid DnB', ''),
        'dnb',
      );
      expect(
        SunoPromptBuilder.resolveGenreKey('Modern Country', ''),
        'country',
      );
    });

    test('resolveGenreKey maps aliases correctly', () {
      expect(
        SunoPromptBuilder.resolveGenreKey('Hardstyle', ''),
        'hardstyle',
      );
      expect(
        SunoPromptBuilder.resolveGenreKey('Vinahouse', ''),
        'amapiano',
      );
      expect(
        SunoPromptBuilder.resolveGenreKey('Neo-Soul', ''),
        'rnb',
      );
      expect(
        SunoPromptBuilder.resolveGenreKey('R&B', ''),
        'rnb',
      );
      expect(
        SunoPromptBuilder.resolveGenreKey('90s R&B', ''),
        'rnb',
      );
      expect(
        SunoPromptBuilder.resolveGenreKey('Bollywood', ''),
        'world',
      );
      expect(
        SunoPromptBuilder.resolveGenreKey('UK Garage', ''),
        'edm',
      );
      expect(
        SunoPromptBuilder.resolveGenreKey('Boom Bap', ''),
        'boom_bap',
      );
    });

    test('stripFxLayout is idempotent on built lyrics', () {
      final built = SunoPromptBuilder.buildSunoPrompt(
        baseStyle: '',
        baseLyrics: '[Chorus]\nLyrics here',
        primaryGenre: 'metal',
        intensity: 3,
      );
      final once = SunoPromptBuilder.stripFxLayout(built.lyrics);
      final twice = SunoPromptBuilder.stripFxLayout(once);
      expect(once, twice);
      expect(once, contains('[Chorus]'));
    });

    test('buildSunoPrompt clamps intensity', () {
      final r = SunoPromptBuilder.buildSunoPrompt(
        baseStyle: 'sad pop',
        baseLyrics: '[Verse]\nhello',
        primaryGenre: 'Pop',
        intensity: 5,
      );
      expect(r.intensity, 3);
    });

    test('vocal spec brackets are stripped', () {
      final cleaned = SunoPromptBuilder.buildSunoPrompt(
        baseStyle: '',
        baseLyrics: '[Intimate Male Vocal]\n[Verse]\nline',
        primaryGenre: 'Pop',
        intensity: 1,
      );
      expect(cleaned.lyrics, isNot(contains('[Intimate Male Vocal]')));
      expect(cleaned.lyrics, contains('[Verse]'));
    });

    test('userBlockDirective contains no HTML entities', () {
      final d = SunoPromptBuilder.userBlockDirective(
        primaryGenre: 'Pop',
        intensity: 2,
      );
      expect(d, isNot(contains('&amp;')));
      expect(d, isNot(contains('&lt;')));
      expect(d, isNot(contains('&gt;')));
    });

    test('amapiano genre lyrics includes master EDM amapiano profile', () {
      final block = GenreLyricsDirectives.userBlockDirective(
        primaryGenre: 'Amapiano',
        subGenreFusion: 'Private School',
      );
      expect(block, contains('GLOBAL LYRICIST GUARDRAIL'));
      expect(block, contains('CROSS-ARCHITECTURE NON-NEGOTIABLES'));
      expect(block, contains('AMAPIANO / VINAHOUSE'));
      expect(block.toLowerCase(), contains('log-drum'));
    });

    test('amapiano thematic variator block', () {
      final block = advancedThematicVariatorBlock(
        primary: 'Amapiano',
        fusion: 'Private School',
        vibe: 'log drum lounge',
      );
      expect(block, contains('AMAPIANO'));
      expect(block, contains('LOG DRUM IS KING'));
    });

    test('secret inside chest injects template', () {
      final block = GenreLyricsDirectives.userBlockDirective(
        primaryGenre: 'Amapiano',
        vibe: 'Secret Inside Your Chest',
        lyricThemeNotes: 'affair at midnight',
      );
      expect(block, contains('Secret Inside Your Chest'));
      expect(block, contains('[Drop: Destructive 32nd-Note Log Drum]'));
    });

    test('dont call me lonely injects master', () {
      final block = GenreLyricsDirectives.userBlockDirective(
        primaryGenre: 'Amapiano',
        vibe: "Don't call me lonely",
        lyricThemeNotes: 'call me outside',
      );
      expect(block, contains("Don't Call Me Lonely"));
      expect(block, contains('Rain on the pavement'));
      expect(block, contains('[Verse 2]'));
      expect(block, contains('COMMERCIAL ARRANGEMENT ORDER'));
    });

    test('amapiano bans age cliche in directive', () {
      final block = GenreLyricsDirectives.userBlockDirective(
        primaryGenre: 'Amapiano',
      );
      expect(block.toLowerCase(), contains('she was nineteen'));
      expect(block, contains('Verse 2'));
    });

    test('dynamic structural engine amapiano breakdown', () {
      final block = DynamicStructuralEngine.userBlockDirective(
        primaryGenre: 'Amapiano',
        subGenreFusion: 'Private School',
        sunoVersion: 'v5.5',
      );
      expect(block, contains('DYNAMIC STRUCTURAL ENGINE'));
      expect(block, contains('Breakdown'));
      expect(block, contains('v5.5 PRO syntax'));
      expect(block, contains('v5.5_max_arc=true'));
      expect(block, contains('[End]'));
      expect(block, contains('RENDERED BRACKET LAYOUT'));
    });

    test('dynamic structural engine folk no drop', () {
      final block = DynamicStructuralEngine.userBlockDirective(
        primaryGenre: 'Folk',
        subGenreFusion: 'Acoustic',
      );
      expect(block, contains('NO [Drop]'));
      expect(block, contains('Instrumental Interlude'));
    });

    test('future house thematic variator block', () {
      final block = advancedThematicVariatorBlock(
        primary: 'Future House',
        vibe: 'chrome lobby',
      );
      expect(block, contains('FUTURE HOUSE'));
      expect(block, contains('BLACKLIST'));
      expect(block, contains('neon'));
    });

    test('anti-scream scrubs exclamations', () {
      const raw = '[Chorus]\nWake up now!\n[Maximum Aggression]\n[Drop]\nGo!';
      final out = applyAntiScreamToLyrics(
        raw,
        primaryGenre: 'hardstyle',
      );
      expect(out.contains('!'), isFalse);
      expect(out, contains('[Heavy Produced Mix]'));
    });

    test('genre lyrics directive includes variator for hardstyle', () {
      final block = GenreLyricsDirectives.userBlockDirective(
        primaryGenre: 'Hardstyle',
        vibe: 'festival',
      );
      expect(block, contains('ADVANCED THEMATIC GUARDRAILS'));
      expect(block, contains('CROSS-ARCHITECTURE NON-NEGOTIABLES'));
      expect(block, contains('DYNAMIC SHIFT'));
      expect(block, contains('EUPHORIC HARDSTYLE'));
    });

    test('hardstyle resolves and injects monologue at intensity 3', () {
      expect(
        SunoPromptBuilder.resolveGenreKey('Hardstyle', ''),
        'hardstyle',
      );
      final output = SunoPromptBuilder.buildSunoPrompt(
        baseStyle: 'reverse-bass kick',
        baseLyrics: '[Monologue]\nWe gather here tonight.',
        primaryGenre: 'hardstyle',
        intensity: 3,
      );
      expect(output.matchedGenreKey, 'hardstyle');
      expect(output.lyrics, contains('[Monologue]'));
      expect(output.prompt.toLowerCase(), contains('reverse-bass'));
      expect(output.lyrics, contains('[Drop: Reverse Bass Impact]'));
    });

    test('stripFxLayout removes injected tags before re-apply', () {
      final built = SunoPromptBuilder.buildSunoPrompt(
        baseStyle: '',
        baseLyrics: '[Chorus]\nLyrics here',
        primaryGenre: 'metal',
        intensity: 3,
      );
      final stripped = SunoPromptBuilder.stripFxLayout(built.lyrics);
      expect(stripped, contains('[Chorus]'));
      expect(stripped, isNot(contains('[Pre-Breakdown')));
    });

    test('applyGenreFxToInputs compiles metal high intensity', () {
      final fx = SunoPromptBuilder.applyGenreFxToInputs(
        vibe: 'Melodic vocal melody',
        optionalLyrics: '[Verse 1]\nUser line',
        genreFxLaneId: 'metal',
        primaryGenre: '',
        fusionGenre: '',
        intensity: 3,
      );
      expect(fx.vibe.toLowerCase(), contains('djent'));
      expect(fx.optionalLyrics, contains('[Pre-Breakdown'));
      expect(fx.optionalLyrics, contains('[Verse 1]'));
    });

    test('user block includes genre FX matrix at intensity 3', () {
      final block = SunoPromptBuilder.userBlockDirective(
        primaryGenre: 'Festival EDM',
        intensity: 3,
      );
      expect(block, contains('GENRE FX MATRIX'));
      expect(block, contains('[edm]'));
      expect(block, contains('white noise'));
    });
  });

  group('HumanRealismConfig', () {
    test('band labels match value ranges', () {
      expect(HumanRealismConfig.bandLabel(0), 'Highly poetic and stylized');
      expect(HumanRealismConfig.bandLabel(25), 'Professional songwriter');
      expect(HumanRealismConfig.bandLabel(50), 'Balanced');
      expect(HumanRealismConfig.bandLabel(70), 'Authentic artist');
      expect(HumanRealismConfig.bandLabel(90), 'Raw human realism');
    });

    test('user block includes level and band instructions', () {
      final block = HumanRealismConfig.userBlockDirective(82);
      expect(block, contains('Human Realism Level: 82/100'));
      expect(block, contains('Maximum human realism'));
      expect(block, contains('HUMAN REALISM'));
      expect(block, contains('ELITE HUMAN LYRICIST'));
      expect(block, contains('ANCHOR ROTATION FILTER'));
      expect(block, contains('FLEXIBLE ANCHOR RULE'));
      expect(block, contains('MANDATORY PRE-OUTPUT VALIDATION'));
    });

    test('low realism adds poetic allowance without dropping elite bans', () {
      final block = HumanRealismConfig.userBlockDirective(25);
      expect(block, contains('Human Realism Level: 25/100'));
      expect(block, contains('Elite Human Lyricist core bans'));
    });

    test('user block injects pidgin phonetic rule when dialect set', () {
      final block = HumanRealismConfig.userBlockDirective(
        75,
        dialectStyleId: DialectStyleData.nigerianPidginId,
      );
      expect(block, contains('PHONETIC INTEGRITY'));
      expect(block, contains('Nigerian Pidgin'));
      expect(block, contains('dey'));
    });
  });

  group('EliteHumanLyricistStage1', () {
    test('directive includes audit-hardened Stage 1 sections', () {
      expect(kEliteHumanLyricist, contains('§0.3A'));
      expect(kEliteHumanLyricist, contains('Genre Overlap Rule'));
      expect(kEliteHumanLyricist, contains('Repetition vs. cliché'));
      expect(kEliteHumanLyricist, contains('Sensory anchoring'));
      expect(kEliteHumanLyricist, contains('FIELD:simple'));
      expect(
        kEliteHumanLyricist,
        isNot(contains('k_genre_cliche_blacklist.dart')),
      );
    });

    test('buildPhoneticIntegrityRule respects dialect', () {
      final std = EliteHumanLyricistDirective.buildPhoneticIntegrityRule();
      final pidgin = EliteHumanLyricistDirective.buildPhoneticIntegrityRule(
        dialectStyleId: DialectStyleData.nigerianPidginId,
      );
      expect(std, contains('PHONETIC INTEGRITY'));
      expect(std, contains('breathing'));
      expect(pidgin, contains('Nigerian Pidgin'));
      expect(pidgin, contains('wahala'));
    });

    test('userBlockPrefix injects runtime phonetic rule', () {
      final block = EliteHumanLyricistDirective.userBlockPrefix(
        dialectStyleId: DialectStyleData.standardEnglishId,
      );
      expect(block, contains('ELITE HUMAN LYRICIST'));
      expect(block, contains('PHONETIC INTEGRITY'));
    });
  });

  group('HumanAuthenticityConfig', () {
    test('festival lane detection', () {
      expect(
        HumanAuthenticityConfig.isFestivalVocalLane('Uplifting Trance', ''),
        isTrue,
      );
      expect(
        HumanAuthenticityConfig.isElectronicLane('Melodic Techno', ''),
        isTrue,
      );
      expect(
        HumanAuthenticityConfig.isGospelLane('Praise and Worship', ''),
        isTrue,
      );
      expect(
        HumanAuthenticityConfig.isFestivalVocalLane('Bluegrass', ''),
        isFalse,
      );
    });

    test('word boundaries prevent false positives', () {
      expect(HumanAuthenticityConfig.isElectronicLane('warehouse', ''), isFalse);
      expect(HumanAuthenticityConfig.isElectronicLane('Future Bass', ''), isTrue);
      expect(
        HumanAuthenticityConfig.isSituationFirstStoryLane(
          'singer-songwriter',
          '',
        ),
        isTrue,
      );
      expect(HumanAuthenticityConfig.isFestivalVocalLane('k-pop', ''), isTrue);
    });

    test('festival vocal includes electronic lanes', () {
      expect(HumanAuthenticityConfig.isFestivalVocalLane('big room', ''), isTrue);
      expect(HumanAuthenticityConfig.isFestivalVocalLane('k-pop', ''), isTrue);
    });

    test('r&b resolves as story lane', () {
      expect(
        HumanAuthenticityConfig.isSituationFirstStoryLane('r&b', ''),
        isTrue,
      );
      expect(
        HumanAuthenticityConfig.isSituationFirstStoryLane('rnb', ''),
        isTrue,
      );
    });

    test('gospel is story lane but not partial', () {
      expect(
        HumanAuthenticityConfig.isSituationFirstStoryLane('gospel', ''),
        isTrue,
      );
      expect(
        HumanAuthenticityConfig.isPartialSituationStoryLane('gospel', ''),
        isFalse,
      );
    });

    test('situation-first story lane scope', () {
      expect(
        HumanAuthenticityConfig.isSituationFirstStoryLane('Modern Country', ''),
        isTrue,
      );
      expect(
        HumanAuthenticityConfig.isMantraDominantLane('Hard Techno', ''),
        isTrue,
      );
      expect(
        HumanAuthenticityConfig.isSituationFirstStoryLane('Hard Techno', ''),
        isFalse,
      );
      expect(
        HumanAuthenticityConfig.isPartialSituationStoryLane(
          'Progressive House',
          '',
        ),
        isTrue,
      );
    });

    test('user block activates situation-first for country', () {
      final block = HumanAuthenticityConfig.userBlockDirective(
        primaryGenre: 'Modern Country',
      );
      expect(block, contains('§17 SITUATION-FIRST STORY'));
    });

    test('user block waives situation-first for hard techno', () {
      final block = HumanAuthenticityConfig.userBlockDirective(
        primaryGenre: 'Hard Techno',
      );
      expect(block, contains('§17 WAIVED'));
    });

    test('user block includes specificity and zero artist names', () {
      final block = HumanAuthenticityConfig.userBlockDirective(
        primaryGenre: 'Melodic Techno',
        djOutro: true,
      );
      expect(block, contains('HUMAN AUTHENTICITY ENGINE'));
      expect(block, contains('concrete images'));
      expect(block, contains('NEVER output artist'));
      expect(block, contains('Festival/melodic electronic'));
      expect(block, contains('Electronic: breakdown intimacy'));
      expect(block, contains('DJ-friendly'));
    });

    test('gospel lane uses sanctuary staging not DJ mix-out', () {
      final block = HumanAuthenticityConfig.userBlockDirective(
        primaryGenre: 'Praise and Worship',
        djOutro: true,
      );
      expect(block, contains('Traditional Gospel Architecture'));
      expect(block, contains('SATB Choir Stack'));
      expect(block, isNot(contains('DJ-friendly')));
    });

    test('gospel output includes live/studio branch', () {
      final studio = HumanAuthenticityConfig.userBlockDirective(
        primaryGenre: 'gospel',
        audioEnvironmentModeId: AudioEnvironmentData.studioIsolatedId,
      );
      final live = HumanAuthenticityConfig.userBlockDirective(
        primaryGenre: 'gospel',
        audioEnvironmentModeId: AudioEnvironmentData.livePerformanceId,
      );
      expect(studio, contains('Studio-Isolation Directive'));
      expect(live, contains('Live Performance Arena Mode'));
    });
  });

  group('DialectStyleData', () {
    test('nigerian pidgin user block is non-negotiable', () {
      final block = DialectStyleData.userBlockDirective(
        DialectStyleData.nigerianPidginId,
      );
      expect(block, contains('NON-NEGOTIABLE'));
      expect(block, contains('wahala'));
      expect(DialectStyleData.isNigerianPidgin('nigerian_pidgin'), isTrue);
    });

    test('standard english yields empty user block', () {
      expect(
        DialectStyleData.userBlockDirective(DialectStyleData.standardEnglishId),
        isEmpty,
      );
    });

    test('ibibio variant injects regional flavor', () {
      final block = DialectStyleData.userBlockDirective(
        DialectStyleData.nigerianPidginId,
        dialectVariantId: 'ibibio',
      );
      expect(block, contains('Ibibio-inflected Pidgin'));
      expect(block, contains('Akwa Ibom'));
    });

    test('pidgin variants list includes ibibio and yoruba', () {
      final ids = DialectStyleData.pidginVariants.map((v) => v.id).toList();
      expect(ids, contains('ibibio'));
      expect(ids, contains('yoruba'));
      expect(ids, contains('igbo'));
    });
  });

  group('VocalAccentData', () {
    test('user block mandates Layer 1 descriptors with standard English lyrics', () {
      final block = VocalAccentData.userBlockDirective(
        accent: 'british',
        vocalSpec: 'Female Lead',
        language: 'English',
      );
      expect(block, contains('NON-NEGOTIABLE'));
      expect(block, contains('user_selected_accent: british'));
      expect(block, contains('Layer 1 descriptor set'));
      expect(block, contains('dry room close-mic'));
      expect(block, contains('STAGING AND ACCENT RULES'));
      expect(block, contains('English only'));
    });

    test('coerces legacy accent labels to canonical keys', () {
      expect(
        VocalAccentData.coerceStored('British (England)'),
        'british',
      );
      expect(
        VocalAccentData.coerceStored('West African (Nigeria)'),
        'nigerian',
      );
      expect(
        VocalAccentData.layer1DescriptorFor('nigerian_ibibio'),
        contains('triplet-feel vocal pocket'),
      );
    });

    test('accent vs dialect constraint applies when accent only', () {
      expect(
        VocalAccentData.accentVsDialectConstraintLine('british'),
        contains('wahala'),
      );
      expect(
        VocalAccentData.accentVsDialectConstraintLine(
          'nigerian',
          dialectStyleId: DialectStyleData.nigerianPidginId,
        ),
        isEmpty,
      );
    });

    test('post-process context preserves accent key', () {
      expect(
        VocalAccentData.postProcessContextLine('irish'),
        contains('irish'),
      );
    });

    test('splitForUi maps Nigerian sub-keys to hierarchical UI', () {
      expect(
        VocalAccentData.splitForUi('nigerian'),
        (topLevel: 'nigerian', nigerianSub: null),
      );
      expect(
        VocalAccentData.splitForUi('nigerian_ibibio'),
        (topLevel: 'nigerian', nigerianSub: 'nigerian_ibibio'),
      );
      expect(
        VocalAccentData.splitForUi('british'),
        (topLevel: 'british', nigerianSub: null),
      );
    });

    test('resolveEffectiveAccent uses sub-region only when pidgin active', () {
      expect(
        VocalAccentData.resolveEffectiveAccent(
          topLevel: 'nigerian',
          nigerianSub: 'nigerian_rivers_state',
          useNigerianSubRegion: true,
        ),
        'nigerian_rivers_state',
      );
      expect(
        VocalAccentData.resolveEffectiveAccent(
          topLevel: 'nigerian',
          nigerianSub: 'nigerian_rivers_state',
        ),
        'nigerian',
      );
      expect(
        VocalAccentData.resolveEffectiveAccent(
          topLevel: 'nigerian',
          nigerianSub: null,
          useNigerianSubRegion: true,
        ),
        VocalAccentData.defaultNigerianSubAccent,
      );
      expect(
        VocalAccentData.resolveEffectiveAccent(
          topLevel: 'british',
          nigerianSub: 'nigerian_ibibio',
        ),
        'british',
      );
    });

    test('ibibio Layer 1 uses Akwa Ibom / Cross-river tokens not Calabar', () {
      final d = VocalAccentData.layer1DescriptorFor('nigerian_ibibio');
      expect(d.toLowerCase(), isNot(contains('calabar')));
      expect(d, contains('Cross-river coastal cadence'));
      expect(d, contains('Akwa Ibom vocal warmth'));
    });
  });

  group('VocalAccentData genre smoke', () {
    void expectAccentRoutes(String genre, String accent, String token) {
      test('$genre + $accent injects Layer 1 without raw nationality labels', () {
        final block = VocalAccentData.userBlockDirective(
          accent: accent,
          vocalSpec: 'Male Lead',
          language: 'English',
        );
        expect(block, contains('user_selected_accent: $accent'));
        final layer1 = RegExp(
          r'Layer 1 descriptor set: (.+)',
          caseSensitive: false,
        ).firstMatch(block)?.group(1);
        expect(layer1, isNotNull);
        expect(layer1!, contains(token));
        expect(layer1.toLowerCase(), isNot(contains('british accent')));
        expect(layer1.toLowerCase(), isNot(contains('nigerian accent')));
      });
    }

    expectAccentRoutes('Gospel', 'nigerian_ibibio', 'Cross-river coastal cadence');
    expectAccentRoutes('Afrobeats', 'nigerian', 'Afrobeats vocal pocket');
    expectAccentRoutes('Reggaeton', 'latin_american', 'Spanish consonant treatment');
    expectAccentRoutes('Jazz', 'american', 'polished vocal');
    expectAccentRoutes('Metal', 'british', 'dry room close-mic');
  });

  group('HumanizationPassConfig', () {
    test('user message contains Block 2 marker and is trimmed', () {
      final msg = HumanizationPassConfig.buildUserMessage(
        block2Body: '[Verse 1]\nLine one',
        primaryGenre: 'pop',
        subGenreFusion: '',
        vibe: 'warm',
        lyricThemeNotes: 'love',
        language: 'English',
      );

      expect(msg, startsWith('G:'));
      expect(msg, contains('BLOCK 2 (humanize; keep structure):'));
      expect(msg, contains('[Verse 1]'));
      expect(msg, contains('Return ONLY revised Block 2 through [End]'));
      expect(msg, isNot(endsWith('\n')));
    });

    test('empty compact lines are filtered out', () {
      final msg = HumanizationPassConfig.buildUserMessage(
        block2Body: '[Verse 1]\nLine',
        primaryGenre: 'pop',
        subGenreFusion: '',
        vibe: 'warm',
        lyricThemeNotes: 'love',
        language: 'English',
      );

      expect(msg, isNot(contains('\n\n\n')));
    });

    test('top-level wrappers stay compatible', () {
      expect(kHumanizationSystemPrompt, HumanizationPassConfig.systemPrompt);
      final viaWrapper = buildHumanizationUserMessage(
        block2Body: '[Verse 1]\nLine',
        primaryGenre: 'pop',
        subGenreFusion: '',
        vibe: 'warm',
        lyricThemeNotes: 'love',
        language: 'English',
      );
      final viaClass = HumanizationPassConfig.buildUserMessage(
        block2Body: '[Verse 1]\nLine',
        primaryGenre: 'pop',
        subGenreFusion: '',
        vibe: 'warm',
        lyricThemeNotes: 'love',
        language: 'English',
      );
      expect(viaWrapper, viaClass);
    });
  });

  group('SunoCompressionPass', () {
    test('Stage 5 system prompt mandates syntax compression law', () {
      expect(kSunoCompressionSystemPrompt, contains('STAGE 5 SYNTAX COMPRESSION LAW'));
      expect(kSunoCompressionSystemPrompt, contains('NO MULTI-BRACKET STACKING'));
      expect(kSunoCompressionSystemPrompt, contains('NO VERB PHRASES'));
      expect(kSunoCompressionSystemPrompt, contains('APOSTROPHE SANITIZATION'));
      expect(kSunoCompressionSystemPrompt, contains('phoneme mapping'));
      expect(
        kSunoCompressionSystemPrompt,
        isNot(contains('syllable clipping')),
      );
    });

    test('user message references Stage 5 law', () {
      final msg = buildSunoCompressionUserMessage(
        fullOutput: 'BLOCK 1\n\nx\n\nBLOCK 2\n\n[End]',
        primaryGenre: 'Gospel',
        subGenreFusion: '',
        vibe: 'worship',
        lyricThemeNotes: '',
        language: 'English',
        fieldMode: 'custom',
      );
      expect(msg, contains('Stage 5 Syntax Compression Law'));
    });
  });

  group('OpenRouterPipelineModels', () {
    test('Qwen 3.7 generate/theme/compress; Mistral humanize', () {
      expect(
        ApiConstants.openRouterChatModelForPrompt(
          language: 'English',
          lightweight: false,
        ),
        'qwen/qwen3.7-plus',
      );
      expect(
        ApiConstants.themeConsistencyModelForPromptWithProvider(
          useOpenRouter: true,
        ),
        ApiConstants.openRouterGenerateChatModel,
      );
      expect(
        ApiConstants.humanizationModelForProvider(useOpenRouter: true),
        'mistralai/mistral-large',
      );
      expect(
        ApiConstants.humanizationModelForPrompt(
          useOpenRouter: false,
          language: 'English',
        ),
        ApiConstants.laozhangClaudeSonnet45Model,
      );
      expect(
        ApiConstants.humanizationModelForPrompt(
          useOpenRouter: false,
          language: 'French',
        ),
        ApiConstants.laozhangGpt6AstraModel,
      );
      expect(
        ApiConstants.humanizationModelForPrompt(
          useOpenRouter: false,
          language: 'English',
          dialectStyleId: 'nigerian_pidgin',
        ),
        ApiConstants.laozhangGpt6AstraModel,
      );
      expect(
        ApiConstants.compressionModelForProvider(useOpenRouter: true),
        ApiConstants.openRouterGenerateChatModel,
      );
      expect(
        ApiConstants.compressionModelForProvider(useOpenRouter: false),
        ApiConstants.laozhangGpt56LunaModel,
      );
      expect(
        ApiConstants.themeConsistencyModelForPromptWithProvider(
          useOpenRouter: false,
        ),
        ApiConstants.laozhangClaudeSonnet45Model,
      );
    });
  });

  group('SunoSystemPromptV2', () {
    test('mandates Block 2 arrangement staging format', () {
      const prompt = kSunoDirectorSystemPromptV2Candidate;
      expect(prompt, startsWith(
        'Before emitting any staging bracket, scan it against SECTION D — '
        'AI-GENERIC WORD BLACKLIST',
      ));
      expect(prompt, contains('SECTION D — AI-GENERIC WORD BLACKLIST'));
      expect(prompt, contains('STAGING COHERENCE + ACCENT ROUTING + GENRE HYGIENE'));
      expect(prompt, contains('BLOCK 2 — LYRIC & STRUCTURE GENERATION PROTOCOL'));
      expect(
        prompt,
        contains('ARRANGEMENT STAGING FORMAT & LEXICON (SOLE AUTHORITY)'),
      );
      expect(prompt, contains('SECTION 1F — DJ INTRO / OUTRO GENERATION MODULE'));
      expect(prompt, contains('SUNO RENDERS WHAT YOU DESCRIBE'));
      expect(prompt, contains('wordless percussion intro'));
      expect(prompt, contains('[Instrumental Intro: four-on-the-floor kick loop'));
      expect(prompt, contains('EDM Breakdown Vocal (Techno'));
      expect(prompt, contains('[{staging}]'));
      expect(prompt, contains('GENRE-SPECIFIC LYRICS PROMPTS'));
      expect(prompt, contains('GENRE-SPECIFIC HUMANIZATION & AUTHENTICITY ENGINE'));
      expect(prompt, contains('MELODY-SYNCED LYRIC ENGINE'));
      expect(prompt, contains('ELECTRONIC LOOP GRIDS'));
      expect(prompt, contains('GENRE HYBRIDIZATION & CULTURAL ROUTING MATRIX'));
      expect(prompt, contains('NIGERIA CULTURAL REALISM ENGINE'));
      expect(prompt, contains('Instrumental-Staging Constraint'));
      expect(prompt, contains('§10. QA Checklist'));
      expect(prompt, contains('Traditional Gospel / Praise & Worship Architecture'));
      expect(prompt, contains('fourth_wall_clean'));
      expect(prompt, contains('critical_reconciliation'));
    });
  });

  group('UserInputModel', () {
    test('defaults song structure to flexible', () {
      const m = UserInputModel();
      expect(m.songStructurePresetId, 'flexible');
      expect(m.songStructureCustom, '');
      expect(m.remixFromAnalyzer, isFalse);
      expect(m.realInstrumentals, '');
      expect(m.melodyStyleId, MelodyConfig.autoId);
      expect(m.melodyCustomNotes, '');
      expect(m.melodyEvolution, MelodyEvolution.strict);
      expect(m.chordProgression, '');
      expect(m.generateLyrics, isFalse);
      expect(m.lyricThemeNotes, '');
      expect(m.activeModifierCodes, '');
      expect(m.humanRealism, 75);
    });

    test('copyWith updates melody and chord fields', () {
      const m = UserInputModel();
      final n = m.copyWith(
        melodyStyleId: 'hook_led',
        melodyCustomNotes: 'test',
        melodyEvolution: MelodyEvolution.progressive,
        chordProgression: 'I–V–vi–IV',
      );
      expect(n.melodyStyleId, 'hook_led');
      expect(n.melodyCustomNotes, 'test');
      expect(n.melodyEvolution, MelodyEvolution.progressive);
      expect(n.chordProgression, 'I–V–vi–IV');
    });

    test('copyWith clears trackDurationLabel with null', () {
      const withLabel = UserInputModel(trackDurationLabel: '3:45');
      final cleared = withLabel.copyWith(trackDurationLabel: null);
      expect(cleared.trackDurationLabel, isNull);
    });

    test('copyWith clears vocalAccent with null', () {
      const withAccent = UserInputModel(vocalAccent: 'British (England)');
      final cleared = withAccent.copyWith(vocalAccent: null);
      expect(cleared.vocalAccent, isNull);
    });

    test('copyWith preserves trackDurationLabel when unset', () {
      const m = UserInputModel(trackDurationLabel: '2:00');
      final next = m.copyWith(vibe: 'x');
      expect(next.trackDurationLabel, '2:00');
    });
  });

  group('SunoPromptLimits', () {
    test('v2 field budget lines use 130–150-word prose Style and 1000-char cap', () {
      final a = SunoPromptLimits.v2FieldBudgetUserLine(
        'v5.0',
        hasPastedLyrics: true,
        generateLyrics: false,
      );
      expect(a, contains('130'));
      expect(a, contains('150'));
      expect(a, contains('1000'));
      expect(a, contains('2500'));
      expect(a, contains('CUSTOM'));
      expect(a, contains('BLOCK 2'));
      expect(a, contains('SECTION 0B'));
      final b = SunoPromptLimits.v2FieldBudgetUserLine(
        'v5.0',
        hasPastedLyrics: false,
        generateLyrics: true,
      );
      expect(b, contains('Path C'));
      expect(b, contains('2500'));
      final c = SunoPromptLimits.v2FieldBudgetUserLine(
        'v5.0',
        hasPastedLyrics: false,
        generateLyrics: false,
      );
      expect(c, contains('BLOCK 2'));
      expect(c, contains('always'));
      final s = SunoPromptLimits.v2FieldBudgetUserLine(
        'v5.0',
        hasPastedLyrics: false,
        generateLyrics: true,
        fieldMode: SunoFieldOutputMode.simple,
      );
      expect(s, contains('SIMPLE'));
      expect(s, contains('1000'));
      expect(s, contains('BLOCK 2'));
      final o = SunoPromptLimits.v2FieldBudgetUserLine(
        'v5.0',
        hasPastedLyrics: false,
        generateLyrics: false,
        block2OptOut: true,
      );
      expect(o, contains('BLOCK 1 ONLY'));
      expect(o, contains('Do **not** output a Block 2'));
      expect(SunoPromptLimits.styleCharLimitFor('v4'), 200);
      expect(SunoPromptLimits.styleCharLimitFor('v5.0'), 400);
    });

    test('word ranges match tier tooltips', () {
      expect(SunoPromptLimits.wordRangeFor('v4.5'), (min: 80, max: 150));
      expect(SunoPromptLimits.wordRangeFor('v5.0'), (min: 150, max: 250));
      expect(SunoPromptLimits.wordRangeFor('v5.5'), (min: 200, max: 350));
      expect(SunoPromptLimits.structureWordRangeFor('v4.5'), (min: 50, max: 130));
      expect(
        SunoPromptLimits.maxCompletionTokensFor(
          'v4.5',
          hasUserLyrics: false,
        ),
        508,
      );
      expect(
        SunoPromptLimits.maxCompletionTokensFor(
          'v4.5',
          hasUserLyrics: true,
        ),
        816,
      );
      expect(
        SunoPromptLimits.maxCompletionTokensFor(
          'v5.5',
          hasUserLyrics: true,
        ),
        1181,
      );
      expect(
        SunoPromptLimits.maxCompletionTokensFor(
          'v5.5',
          hasUserLyrics: true,
          userLyricsWordCount: 500,
        ),
        1748,
      );
      expect(
        SunoPromptLimits.maxCompletionTokensFor(
          'v5.5',
          hasUserLyrics: false,
          generateLyrics: true,
        ),
        2173,
      );
    });

    test('maxCompletionTokensFor V2 uses Block 1 prose budget (+ lyrics)', () {
      expect(
        SunoPromptLimits.maxCompletionTokensFor(
          'v4.5',
          hasUserLyrics: false,
          useV2FormatLawStyle: true,
        ),
        1423,
      );
      expect(
        SunoPromptLimits.maxCompletionTokensFor(
          'v4.5',
          hasUserLyrics: true,
          useV2FormatLawStyle: true,
        ),
        1500,
      );
      expect(
        SunoPromptLimits.maxCompletionTokensFor(
          'v5.5',
          hasUserLyrics: false,
          generateLyrics: true,
          useV2FormatLawStyle: true,
        ),
        1423,
      );
      expect(
        SunoPromptLimits.maxCompletionTokensFor(
          'v5.0',
          hasUserLyrics: false,
          useV2FormatLawStyle: true,
          sunoFieldOutputMode: SunoFieldOutputMode.simple,
        ),
        1423,
      );
      expect(
        SunoPromptLimits.maxCompletionTokensFor(
          'v4.5',
          hasUserLyrics: false,
          useV2FormatLawStyle: true,
          block2OptOut: true,
        ),
        1000,
      );
    });
  });

  group('ApiConstants chat routing', () {
    test('v4.5 default generation uses primary model (Block 2 always on)', () {
      const instrumental = UserInputModel(
        sunoVersion: 'v4.5',
        primaryGenre: 'Hip Hop',
        vibe: 'test',
      );
      expect(
        ApiConstants.shouldUseLightweightChatModel(instrumental),
        isFalse,
      );
      const withLyrics = UserInputModel(
        sunoVersion: 'v4.5',
        primaryGenre: 'Hip Hop',
        vibe: 'test',
        optionalLyrics: 'line',
      );
      expect(
        ApiConstants.shouldUseLightweightChatModel(withLyrics),
        isFalse,
      );
    });

    test('Simple field mode uses primary model when Block 2 is expected', () {
      const simple = UserInputModel(
        sunoVersion: 'v5.0',
        primaryGenre: 'House',
        vibe: 'test',
        sunoFieldOutputMode: SunoFieldOutputMode.simple,
      );
      expect(ApiConstants.shouldUseLightweightChatModel(simple), isFalse);
    });

    test('Simple + explicit Block 2 opt-out can use lightweight', () {
      const simple = UserInputModel(
        sunoVersion: 'v5.0',
        primaryGenre: 'House',
        vibe: 'style only',
        sunoFieldOutputMode: SunoFieldOutputMode.simple,
      );
      expect(ApiConstants.shouldUseLightweightChatModel(simple), isTrue);
    });

    test('regenerate flag forces lightweight', () {
      const full = UserInputModel(
        sunoVersion: 'v5.5',
        primaryGenre: 'Techno',
        vibe: 'peak time',
        generateLyrics: true,
      );
      expect(
        ApiConstants.shouldUseLightweightChatModel(
          full,
          preferLightweightForRegenerate: true,
        ),
        isTrue,
      );
    });

    test('BEASTMODE lowers temperature tier', () {
      const base = UserInputModel(
        primaryGenre: 'Hardstyle',
        vibe: 'warehouse /BEASTMODE',
      );
      expect(
        ApiConstants.promptTemperatureFor(base),
        ApiConstants.promptTemperatureBeastmode,
      );
    });

    test('chatModelForTier maps OpenRouter slugs', () {
      expect(
        ApiConstants.chatModelForTier(
          useOpenRouter: true,
          lightweight: false,
        ),
        ApiConstants.openRouterPrimaryChatModel,
      );
      expect(
        ApiConstants.chatModelForTier(
          useOpenRouter: false,
          lightweight: true,
        ),
        ApiConstants.openAiLightChatModel,
      );
    });

    test('laozhang chatModelForPrompt uses Gemini 3.1 Pro English / Astra multilingual', () {
      expect(
        ApiConstants.chatModelForPrompt(
          language: 'English',
          lightweight: false,
          apiKey: 'lz-key-abc',
        ),
        ApiConstants.laozhangGemini31ProModel,
      );
      expect(
        ApiConstants.chatModelForPrompt(
          language: 'French',
          lightweight: false,
          apiKey: 'lz-key-abc',
        ),
        ApiConstants.laozhangGpt6AstraModel,
      );
      expect(
        ApiConstants.onDeviceChatCompletionsUrl('lz-key'),
        ApiConstants.laozhangChatCompletions,
      );
    });

    test('AudioAnalysisModel parses Gemini fields and summary', () {
      const profile =
          'Female Lead, Emotional Close-Mic, High Energy Driving, Club Room';
      final m = AudioAnalysisModel.fromJson({
        'analyzerSummary': profile,
        'success': true,
        'bpm': 124,
        'keyScale': 'A Minor',
        'genre': 'House · Deep',
        'subGenre': 'Deep',
        'moodTags': ['dark', 'driving'],
        'vocals': 'Female lead',
        'structure': 'Intro → Verse → Chorus',
        'lyricsTranscription': 'Line one',
        'richDescription': 'Club-ready deep house.',
        'analysisMode': 'gemini',
      });
      expect(m.bpm, 124.0);
      expect(m.hasLyrics, isTrue);
      expect(m.compactProfile, profile);
      expect(m.toPromptSummary(), contains('SOURCE AUDIO ANALYSIS'));
      expect(m.toPromptSummary(), contains(profile));
      expect(m.toPromptSummary(), contains('Structure:'));
      expect(m.toPromptSummary(), contains('Lyrics transcription:'));
      expect(m.toPromptSummary(), contains('Club-ready'));
    });

    test('AudioAnalysisModel never returns empty compact profile', () {
      final m = AudioAnalysisModel.fromJson({'bpm': 100});
      expect(m.compactProfile, isNotEmpty);
      expect(m.compactProfile, AudioAnalysisModel.fallbackAnalyzerSummary);
    });

    test('AudioAnalysisModel includes harmony and melody in summary', () {
      final m = AudioAnalysisModel.fromJson({
        'keyScale': 'A Minor',
        'impliedChords': 'Implied Progression Base: A-C-E',
        'melodyProfile': 'Vocal Melody Range Notes: A, C, E',
      });
      expect(m.toPromptSummary(), contains('Implied Progression Base:'));
      expect(m.toPromptSummary(), contains('Vocal Melody Range Notes:'));
    });

    test('AudioAnalysisModel includes acapella production intent in summary', () {
      final m = AudioAnalysisModel.fromJson({
        'bpm': 72,
        'genre': 'Hip Hop / Rap Vocals / Acapella (estimate)',
        'isAcapella': true,
        'productionIntent':
            'Build a full commercial pop/dance arrangement around this isolated vocal stem.',
      });
      expect(m.isAcapella, isTrue);
      expect(m.toPromptSummary(), contains('Production intent:'));
      expect(m.toPromptSummary(), contains('acapella stem'));
    });

    test('AudioAnalysisModel parses AudD track metadata from camelCase json', () {
      final m = AudioAnalysisModel.fromJson({
        'title': 'Blinding Lights',
        'artist': 'The Weeknd',
        'album': 'After Hours',
        'releaseDate': '2020-03-20',
        'trackRecognized': true,
        'bpm': 171,
      });
      expect(m.title, 'Blinding Lights');
      expect(m.artist, 'The Weeknd');
      expect(m.album, 'After Hours');
      expect(m.releaseDate, '2020-03-20');
      expect(m.hasRecognizedTrack, isTrue);
      expect(m.toPromptSummary(), contains('Blinding Lights'));
      expect(m.toPromptSummary(), contains('The Weeknd'));
    });

    test('AudioAnalysisModel uses fallback track metadata when missing', () {
      final m = AudioAnalysisModel.fromJson({'bpm': 100});
      expect(m.title, AudioAnalysisModel.fallbackTitle);
      expect(m.artist, AudioAnalysisModel.fallbackArtist);
      expect(m.hasRecognizedTrack, isFalse);
    });

    test('hybrid prompt pipeline on for LaoZhang on-device', () {
      expect(
        ApiConstants.useHybridPromptPipeline(
          lightweight: false,
          apiKey: 'lz-key',
        ),
        isTrue,
      );
      expect(
        ApiConstants.useHybridPromptPipeline(
          lightweight: true,
          apiKey: 'lz-key',
        ),
        isFalse,
      );
      expect(
        ApiConstants.useHybridPromptPipeline(
          lightweight: false,
          apiKey: 'sk-or-v1-x',
        ),
        isFalse,
      );
      expect(
        ApiConstants.polishModelForPrompt(apiKey: 'lz'),
        ApiConstants.laozhangClaudeSonnet45Model,
      );
    });

    test('OpenRouter key switches URL and models', () {
      const orKey = 'sk-or-v1-test';
      expect(
        ApiConstants.onDeviceChatCompletionsUrl(orKey),
        ApiConstants.openRouterChatCompletions,
      );
      expect(
        ApiConstants.chatModelForPrompt(
          language: 'English',
          lightweight: false,
          apiKey: orKey,
        ),
        ApiConstants.openRouterPrimaryChatModel,
      );
    });

    test('multilingual primary uses Mistral Large on OpenRouter', () {
      expect(
        ApiConstants.preferMultilingualPrimaryModelForLanguage('English'),
        isFalse,
      );
      expect(
        ApiConstants.preferMultilingualPrimaryModelForLanguage('english'),
        isFalse,
      );
      expect(
        ApiConstants.preferMultilingualPrimaryModelForLanguage('日本語'),
        isTrue,
      );
      expect(
        ApiConstants.preferMultilingualPrimaryModelForLanguage('French'),
        isTrue,
      );
      expect(
        ApiConstants.openRouterChatModelForPrompt(
          language: 'Japanese',
          lightweight: false,
        ),
        ApiConstants.openRouterMultilingualPrimaryChatModel,
      );
      expect(
        ApiConstants.openRouterChatModelForPrompt(
          language: 'Japanese',
          lightweight: true,
        ),
        ApiConstants.openRouterLightChatModel,
      );
      expect(
        ApiConstants.openRouterChatModelForPrompt(
          language: 'English',
          lightweight: false,
        ),
        ApiConstants.openRouterPrimaryChatModel,
      );
    });
  });

  group('parseSunoOutput', () {
    test('splits STRUCTURE, STYLE, and LYRICS', () {
      const raw = '''SUNO STRUCTURE
Intro then verse then chorus.

SUNO STYLE
house groove 128 BPM.

SUNO LYRICS
[Verse]
Line one

[Chorus]
Hey''';
      final p = parseSunoOutput(raw);
      expect(p.structureBody, contains('Intro'));
      expect(p.structureBody, isNot(contains('BPM')));
      expect(p.styleBody, contains('house groove'));
      expect(p.lyricsBody, contains('[Verse]'));
    });

    test('legacy: SUNO STYLE and SUNO LYRICS without STRUCTURE', () {
      const raw = '''SUNO STYLE
house groove 128 BPM.

SUNO LYRICS
[Verse]
Line one''';
      final p = parseSunoOutput(raw);
      expect(p.structureBody, isNull);
      expect(p.styleBody, contains('house'));
      expect(p.lyricsBody, contains('[Verse]'));
    });

    test('single STYLE block without LYRICS yields null lyricsBody', () {
      const raw = '''SUNO STYLE
instrumental only.''';
      final p = parseSunoOutput(raw);
      expect(p.lyricsBody, isNull);
      expect(p.styleBody, contains('instrumental'));
    });

    test('enforceUnifiedBlock1CharLimit trims long Custom Block 1 prose', () {
      final longProse = List.filled(220, 'token').join(' ');
      final raw = '''
BLOCK 1 — PASTE INTO SUNO: STYLE

$longProse

BLOCK 2 — PASTE INTO SUNO: LYRICS

[Verse]
Line

[End]
''';
      final fixed = enforceUnifiedBlock1CharLimit(
        raw,
        SunoFieldOutputMode.custom,
      );
      final p = parseSunoOutput(fixed);
      expect(p.styleBody, isNotNull);
      expect(p.styleBody!.length, lessThanOrEqualTo(1000));
      final wc = p.styleBody!.split(RegExp(r'\s+')).where((x) => x.isNotEmpty).length;
      expect(wc, lessThanOrEqualTo(150));
      expect(p.lyricsBody, contains('[Verse]'));
    });

    test('enforceUnifiedBlock1CharLimit trims long Simple Block 1', () {
      final longSentence = List.filled(220, 'w').join(' ');
      final raw = '''
BLOCK 1 — PASTE INTO SUNO: STYLE

$longSentence
''';
      final fixed = enforceUnifiedBlock1CharLimit(
        raw,
        SunoFieldOutputMode.simple,
      );
      final p = parseSunoOutput(fixed);
      expect(p.styleBody, isNotNull);
      expect(p.styleBody!.length, lessThanOrEqualTo(1000));
      expect(p.unifiedBlock2Missing, isTrue);
    });

    test('unified Block 1 / Block 2 splits style and lyrics', () {
      const raw = '''
BLOCK 1 — PASTE INTO SUNO: STYLE

Neo-soul groove at 90 BPM.

BLOCK 2 — PASTE INTO SUNO: LYRICS

[Verse 1]
[Rap Verse]
Line one

[End]

→ optional follow-up
''';
      final p = parseSunoOutput(raw);
      expect(p.unifiedTwoBlockFormat, isTrue);
      expect(p.unifiedThreeSectionFormat, isFalse);
      expect(p.producerBriefBody, isNull);
      expect(p.structureBody, isNull);
      expect(p.styleBody, contains('Neo-soul'));
      expect(p.styleBody, isNot(contains('BLOCK 2')));
      expect(p.lyricsBody, contains('[Verse 1]'));
      expect(p.lyricsBody, contains('[End]'));
      expect(p.lyricsBody, isNot(contains('follow-up')));
      expect(p.suggestionsBody, contains('follow-up'));
      expect(p.block2HasEndTag, isTrue);
      expect(p.unifiedBlock2Missing, isFalse);
    });

    test('strips ---BLOCK_1_END--- separator from style body', () {
      const raw = '''
BLOCK 1 — PASTE INTO SUNO: STYLE

Neo-soul groove at 90 BPM in Eb minor.
---BLOCK_1_END---
BLOCK 2 — PASTE INTO SUNO: LYRICS

[Verse 1]
Line one

[End]
''';
      final p = parseSunoOutput(raw);
      expect(p.styleBody, contains('Neo-soul'));
      expect(p.styleBody, isNot(contains('BLOCK_1_END')));
      expect(p.lyricsBody, contains('[Verse 1]'));
    });

    test('legacy Producer Brief banner merges into Block 1 style body', () {
      const raw = '''
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🎛️ PRODUCER BRIEF — Creative Reference
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Neo-soul at ninety BPM in E flat minor with a warm intimate arc.
The drums are dry and pocketed. The bass walks with round warmth.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
BLOCK 1 — PASTE INTO SUNO: STYLE

neo-soul, 90 BPM, Eb minor, warm, dry drums, round bass, Rhodes lead

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
BLOCK 2 — PASTE INTO SUNO: LYRICS

[Verse 1]
Line

[End]
''';
      final p = parseSunoOutput(raw);
      expect(p.unifiedTwoBlockFormat, isTrue);
      expect(p.unifiedThreeSectionFormat, isFalse);
      expect(p.producerBriefBody, isNull);
      expect(p.styleBody, contains('Neo-soul'));
      expect(p.styleBody, contains('neo-soul'));
      expect(p.lyricsBody, contains('[Verse 1]'));
      expect(p.block2HasEndTag, isTrue);
    });

    test('unified paste-into lines without BLOCK keyword still parse', () {
      const raw = '''
PASTE INTO SUNO: STYLE

House beat.

PASTE INTO SUNO: LYRICS

[Intro]

[End]
''';
      final p = parseSunoOutput(raw);
      expect(p.unifiedTwoBlockFormat, isTrue);
      expect(p.styleBody, contains('House'));
      expect(p.lyricsBody, '[Intro]\n\n[End]');
      expect(p.block2HasEndTag, isTrue);
      expect(p.suggestionsBody, isNull);
    });
  });

  group('mergedSunoLyricsForPaste', () {
    test('returns lyrics only when structure has no bracket headers', () {
      expect(
        mergedSunoLyricsForPaste(
          structureBody: 'Intro then verse — prose roadmap',
          lyricsBody: '[Verse]\nLine',
        ),
        '[Verse]\nLine',
      );
    });

    test('returns unchanged when lyrics roadmap matches structure', () {
      const lyrics = '[Verse 1]\nA\n\n[Chorus]\nB';
      expect(
        mergedSunoLyricsForPaste(
          structureBody: '[Verse 1]\n(notes)\n[Chorus]\n(notes)',
          lyricsBody: lyrics,
        ),
        lyrics,
      );
    });

    test('inserts leading sections from structure before lyric blocks', () {
      final m = mergedSunoLyricsForPaste(
        structureBody: '[Intro]\n(filtered)\n[Verse 1]\n(build)\n[Chorus]\n(peak)',
        lyricsBody: '[Verse 1]\nHello\n\n[Chorus]\nHey',
      );
      expect(m, isNotNull);
      expect(m!, startsWith('[Intro]'));
      expect(m, contains('[Verse 1]'));
      expect(m, contains('Hello'));
      expect(m, contains('[Chorus]'));
      expect(m, contains('Hey'));
    });
  });

  group('parseSunoDualOutput', () {
    test('still exposes style and lyrics for older call sites', () {
      const raw = '''SUNO STYLE
x

SUNO LYRICS
y''';
      final p = parseSunoDualOutput(raw);
      expect(p.styleBody, 'x');
      expect(p.lyricsBody, 'y');
    });
  });

  group('openai_key_validation', () {
    test('detects OpenRouter-style prefix', () {
      expect(looksLikeOpenRouterKey('sk-or-v1-abc'), isTrue);
      expect(looksLikeOpenRouterKey('sk-proj-xx'), isFalse);
      expect(openRouterKeySavedMessage('sk-or-v1-x'), contains('OpenRouter'));
      expect(laozhangKeySavedMessage('lz-abc'), contains('LaoZhang'));
    });
  });

  group('GenreData remix targets', () {
    test('remixTargetGenres merges catalog + quick picks', () {
      expect(GenreData.remixTargetGenres.length, greaterThan(GenreData.quickPickGenres.length));
      expect(GenreData.remixTargetGenres, contains('Techno'));
      expect(GenreData.remixTargetGenres, contains('Reggaeton'));
      expect(GenreData.remixTargetGenres, contains('Hip Hop'));
      expect(GenreData.remixTargetGenres, contains('Pop'));
      expect(GenreData.remixTargetGenres, contains('Drill'));
      expect(GenreData.remixTargetGenres, contains('Country'));
      expect(GenreData.remixTargetGenres, contains('Folk'));
    });

    test('categoryForSubGenre resolves parent tab', () {
      expect(GenreData.categoryForSubGenre('Melodic Techno'), 'EDM');
      expect(GenreData.categoryForSubGenre('Bluegrass'), 'Country');
      expect(GenreData.categoryForSubGenre('Unknown XYZ'), isNull);
    });
  });

  group('SunoStructureExamples', () {
    test('every example ends with [End]', () {
      for (final entry in SunoStructureExamples.allExamplesByVersion.entries) {
        for (final example in entry.value) {
          expect(
            example.trim().endsWith('[End]'),
            isTrue,
            reason: 'Example for ${entry.key} must end with [End]',
          );
        }
      }
    });

    test('no bracket contains slash or stacked brackets on one line', () {
      final slashInBracket = RegExp(r'\[[^\]]*\/[^\]]*\]');
      final stackedOnLine = RegExp(r'\]\s*\[');
      for (final examples in SunoStructureExamples.allExamplesByVersion.values) {
        for (final example in examples) {
          expect(slashInBracket.hasMatch(example), isFalse);
          for (final line in example.split('\n')) {
            expect(stackedOnLine.hasMatch(line), isFalse);
          }
        }
      }
    });

    test('no bracket contains BPM token', () {
      final bpmInBracket = RegExp(r'\[[^\]]*\d+\s*BPM', caseSensitive: false);
      for (final examples in SunoStructureExamples.allExamplesByVersion.values) {
        for (final example in examples) {
          expect(bpmInBracket.hasMatch(example), isFalse);
        }
      }
    });

    test('familyForGenre routes worship correctly', () {
      expect(SunoStructureExamples.familyForGenre('Praise/Worship'), 'worship');
      expect(SunoStructureExamples.familyForGenre('Modern Worship'), 'worship');
      expect(SunoStructureExamples.familyForGenre('Afro-Gospel'), 'worship');
    });

    test('familyForGenre routes EDM family correctly', () {
      expect(SunoStructureExamples.familyForGenre('Melodic Techno'), 'edm');
      expect(SunoStructureExamples.familyForGenre('Future Bass'), 'edm');
      expect(SunoStructureExamples.familyForGenre('Hardstyle'), 'edm');
    });

    test('unknown genre falls back to generic family', () {
      expect(SunoStructureExamples.familyForGenre(null), 'generic');
      expect(SunoStructureExamples.familyForGenre(''), 'generic');
      expect(SunoStructureExamples.familyForGenre('RandomGarbage'), 'generic');
    });

    test('v5.5 routing prefers matching family', () {
      final edm = SunoStructureExamples.exampleForVersion(
        version: 'v5.5',
        familyKey: 'edm',
      );
      expect(edm, contains('[Drop:'));
      expect(edm, contains('[Build-up:'));
    });

    test('v4.5 has no staging notes in brackets', () {
      expect(SunoStructureExamples.v45_generic.contains(':'), isFalse);
      expect(SunoStructureExamples.v45_edm.contains(':'), isFalse);
    });

    test('buildStructurePreamble includes example and directive', () {
      final block = SunoStructureExamples.buildStructurePreamble(
        sunoVersion: 'v5.5',
        selectedGenre: 'Trap',
      );
      expect(block, contains('Canonical bracket layout example'));
      expect(block, contains('[Hook:'));
      expect(block, contains('Always terminate with [End]'));
    });
  });

  group('PromptTemplates', () {
    test('defines multiple presets', () {
      expect(PromptTemplates.all.length, greaterThanOrEqualTo(6));
      expect(PromptTemplates.byId('melodic_club'), isNotNull);
      expect(
        PromptTemplates.byId(BigRoomHardstyleCinematicHybridPreset.id),
        isNotNull,
      );
      expect(
        PromptTemplates.byId(HardstyleEuroDanceBootlegPreset.id),
        isNotNull,
      );
      expect(
        PromptTemplates.byId(BigRoomFusionProgressivePreset.id),
        isNotNull,
      );
      final bracket = PromptTemplates.byId('bracket_edm_structure');
      expect(bracket, isNotNull);
      expect(
        bracket!.model.songStructureCustom,
        SunoStructureExamples.v55_edm,
      );
    });
  });

  group('buildDjMixUserBlock', () {
    test('off state returns empty', () {
      final s = buildDjMixUserBlock(
        djIntroMixIn: false,
        djOutroMixOut: false,
        sunoVersion: 'v5.5',
        family: StructuralFamily.edmProgressiveHouse,
      );
      expect(s, isEmpty);
    });

    test('intro on includes production brief for v5.5 EDM', () {
      final s = buildDjMixUserBlock(
        djIntroMixIn: true,
        djOutroMixOut: false,
        sunoVersion: 'v5.5',
        family: StructuralFamily.edmProgressiveHouse,
      );
      expect(s, contains('[PRODUCTION REQUIREMENT'));
      expect(s, contains('[DJ INTRO: ON]'));
      expect(s, contains('~32 bars'));
    });

    test('V2 wording references Block 1 prose limits and Block 2', () {
      final s = buildDjMixUserBlock(
        djIntroMixIn: true,
        djOutroMixOut: true,
        sunoVersion: 'v5.5',
        family: StructuralFamily.edmProgressiveHouse,
        v2UnifiedOutput: true,
      );
      expect(s, contains('Block 1'));
      expect(s, contains('Block 2'));
      expect(s, contains('[Instrumental Intro:'));
      expect(s, contains('[Instrumental Outro:'));
      expect(s, isNot(contains('verbatim')));
    });
  });

  group('SunoPromptLimits remix supplement', () {
    test('remix supplement echoes structure and style word bands', () {
      final s = SunoPromptLimits.remixFromAnalyzerUserBlockSupplement('v5.5');
      expect(s, contains('REMIX / GENRE-FLIP'));
      expect(s, contains('80-200'));
      expect(s, contains('200-350'));
    });

    test('remix V2 supplement echoes Block 1 prose + 1000-char cap', () {
      final s = SunoPromptLimits.remixFromAnalyzerUserBlockSupplementV2('v5.0');
      expect(s, contains('REMIX / GENRE-FLIP'));
      expect(s, contains('Block 1'));
      expect(s, contains('1000'));
      expect(s, contains('2500'));
    });
  });

  group('SunoPromptLimits production wording', () {
    test('word budget mentions pro studio polish', () {
      final a = SunoPromptLimits.wordBudgetUserLine('v5.0', hasUserLyrics: false);
      final b = SunoPromptLimits.wordBudgetUserLine('v5.0', hasUserLyrics: true);
      expect(a, contains('pro studio'));
      expect(b, contains('pro studio'));
    });
  });

  group('PowerCodeData', () {
    test('lists L99 UDA BEASTMODE with labels', () {
      expect(PowerCodeData.codes, contains('/L99'));
      expect(PowerCodeData.codes, contains('/UDA'));
      expect(PowerCodeData.codes, contains('/BEASTMODE'));
      expect(PowerCodeData.labelFor('/BEASTMODE'), 'Beast Mode');
      expect(PowerCodeData.labelFor('/L99'), 'Super Mode');
      expect(PowerCodeData.labelFor('/UDA'), 'Ultra Mode');
      expect(PowerCodeData.hintFor('/L99'), isNotEmpty);
    });
  });

  group('CodeTranslationMatrix', () {
    test('shoegaze /TENDER + /L99 blends rock_metal strings on v5.5', () {
      expect(
        CodeTranslationMatrix.getGenreCategory('Shoegaze', ''),
        'rock_metal',
      );
      final cFinal = CodeTranslationMatrix.applyGenreSpecificCodes(
        genre: 'Shoegaze',
        codesBlob: '/TENDER /L99',
        sunoVersion: 'v5.5',
      );
      expect(cFinal.toLowerCase(), contains('clean chorus guitar'));
      expect(cFinal, contains('Les Paul'));
    });

    test('user block includes C_final for active codes', () {
      final block = CodeTranslationMatrix.userBlockDirective(
        primaryGenre: 'Neo-Soul',
        codesBlob: '/TENDER /L99',
        sunoVersion: 'v5.5',
      );
      expect(block, contains('[CODE TRANSLATION: /TENDER for rnb_soul]'));
      expect(block, contains('[CODE TRANSLATION: /L99 for rnb_soul]'));
      expect(block, contains('Apply these specific sonic characteristics'));
    });
  });

  group('LiveInstrumentMatrix', () {
    test('LiveInstrumentMatrixData schema and bundle helpers', () {
      expect(LiveInstrumentMatrixData.schemaVersion, '1.4.2');
      expect(LiveInstrumentMatrixData.categoryTaxonomy, isNotEmpty);
      expect(LiveInstrumentMatrixData.categoryClassificationRules, isNotEmpty);
      expect(LiveInstrumentMatrixData.bundleKeyForGenre('Neo-Soul'), 'neo_soul');
      expect(LiveInstrumentMatrixData.bundleKeyForGenre('Tech House'), 'deep_house');
      expect(LiveInstrumentMatrixData.bundleKeyForGenre('Kizomba'), 'afrobeats');
      expect(LiveInstrumentMatrixData.bundleKeyForGenre('Rage'), 'trap');
      expect(LiveInstrumentMatrixData.bundleKeyForGenre('Memphis Rap'), 'trap');
      expect(LiveInstrumentMatrixData.bundleKeyForGenre('Worship'), 'praise_and_worship');
      expect(LiveInstrumentMatrixData.voicesForGenre('Trap').length, 10);
    });

    test('resolves genre and generates v5.5 prompt with /L99 gear', () {
      final neo = LiveInstrumentMatrix.instrumentsForGenre('Neo-Soul', '');
      expect(neo.map((i) => i.name), contains('Wurlitzer Electric Piano'));

      final prompt = LiveInstrumentMatrix.generatePrompt(
        genre: 'Neo-Soul',
        selectionRaw: 'Wurlitzer Electric Piano, Fender Jazz Bass',
        sunoVersion: 'v5.5',
        powerCodes: '/L99 /TENDER',
      );
      expect(prompt.styleInjection, contains('elevated by'));
      expect(prompt.styleInjection, contains('Neve 1073'));
      expect(prompt.metaTagInjection, contains('[Instrumental Break:'));
      expect(prompt.metaTagInjection, contains('[Bridge:'));
    });

    test('user block includes protocol fields', () {
      final block = LiveInstrumentMatrix.userBlockDirective(
        primaryGenre: 'Hardstyle',
        selectionRaw: 'Prepared Bowed Zither Fusion 9000',
        sunoVersion: 'v5.0',
      );
      expect(block, contains('REAL INSTRUMENT ACCOMPANIMENT'));
      expect(block, contains('Matrix schema: 1.4.2'));
      expect(block, contains('MANDATORY: Feature the following'));
      expect(block, contains('Free-text instruments'));
    });

    test('prompt_text overrides Live label in style injection', () {
      final prompt = LiveInstrumentMatrix.generatePrompt(
        genre: 'Pop',
        selectionRaw: 'Live Drum Kit & Congas',
        sunoVersion: 'v5.5',
      );
      expect(prompt.styleInjection.toLowerCase(), isNot(contains('stadium')));
      expect(
        prompt.styleInjection,
        contains('Acoustic studio drum kit'),
      );
    });

    test('augmentAvoidClause adds studio safeguards for Live instruments', () {
      final out = LiveInstrumentMatrix.augmentAvoidClause(
        avoid: 'harsh clipping',
        realInstrumentals: 'Live Drum Kit & Congas',
      );
      expect(out, contains('harsh clipping'));
      expect(out, contains('dead-room isolation'));
      expect(out, isNot(contains('crowd noise')));
    });

    test('harmonized aliases and primary-first resolution', () {
      expect(
        LiveInstrumentMatrix.resolveGenreKey('Praise/Worship', ''),
        'praise_and_worship',
      );
      expect(LiveInstrumentMatrix.resolveGenreKey('Vinahouse', ''), 'vinahouse');
      expect(
        LiveInstrumentMatrix.resolveGenreKey('Amapiano', 'Soulful House'),
        'amapiano',
      );
      expect(
        LiveInstrumentMatrix.resolveGenreKey('Tech House', ''),
        'deep_house',
      );
    });
  });

  group('RealInstrumentsData', () {
    test('matrix-backed genre picks and curated essentials', () {
      expect(RealInstrumentsData.quickPicks.length, greaterThanOrEqualTo(10));
      expect(RealInstrumentsData.quickPicks.length, lessThanOrEqualTo(30));
      expect(RealInstrumentsData.quickPicks, contains('Wurlitzer Electric Piano'));
      expect(RealInstrumentsData.quickPicks, contains('Fender Jazz Bass'));
      expect(RealInstrumentsData.quickPicks, contains('Grand Piano'));
      final neo = RealInstrumentsData.instrumentsForGenre('Neo-Soul');
      expect(neo, contains('Wurlitzer Electric Piano'));
      expect(
        RealInstrumentsData.instrumentsForGenreFilter(null),
        RealInstrumentsData.quickPicks,
      );
    });

    test('quickPicks are unique curated essentials', () {
      final picks = RealInstrumentsData.quickPicks;
      expect(picks, isA<List<String>>());
      expect(picks, isNotEmpty);
      expect(picks.toSet().length, picks.length);
    });

    test('decongestGenrePicks caps chip count', () {
      final fat = List<String>.generate(40, (i) => 'Inst $i');
      final slim = RealInstrumentsData.decongestGenrePicks(fat);
      expect(slim.length, lessThanOrEqualTo(RealInstrumentsData.genreChipCap));
    });

    test('instrumentsForGenreFilter falls back to quickPicks', () {
      final all = RealInstrumentsData.quickPicks;
      expect(RealInstrumentsData.instrumentsForGenreFilter(null), all);
      expect(RealInstrumentsData.instrumentsForGenreFilter(''), all);
    });

    test('rich instruments can be grouped by family', () {
      final grouped = RealInstrumentsData.instrumentsByFamily('Jazz');
      expect(grouped, isA<Map<String, List<InstrumentModel>>>());
      expect(grouped, isNotEmpty);
      for (final list in grouped.values) {
        expect(list, isNotEmpty);
      }
    });

    test('search filters by name and tag', () {
      final all = RealInstrumentsData.allInstruments;
      expect(all, isNotEmpty);
      final query = all.first.name.substring(0, 3).toLowerCase();
      final results = RealInstrumentsData.search(query);
      expect(results, isNotEmpty);
      expect(
        results.any((i) => i.name.toLowerCase().contains(query)),
        isTrue,
      );
    });

    test('InstrumentModel equality uses signature', () {
      final a = const InstrumentModel(name: 'Violin', family: 'Strings');
      final b = const InstrumentModel(name: 'Violin', family: 'Strings');
      final c = const InstrumentModel(name: 'Violin', family: 'Orchestral');
      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });
  });

  group('ChordProgressionData', () {
    test('quick picks are non-empty', () {
      expect(ChordProgressionData.quickPicks, isNotEmpty);
      expect(ChordProgressionData.quickPicks.first.insert, isNotEmpty);
    });
  });

  group('MelodyComposerService integration', () {
    test('hook_led adds style tokens for direct vibe injection', () {
      final result = MelodyComposerService.compose(
        melodyDirectiveId: 'hook_led',
        evolution: MelodyEvolution.progressive,
        originalLyrics: '',
        primaryGenre: 'Pop',
      );
      expect(
        result.stylePromptTokens,
        contains('built around a memorable, repetitive vocal chorus melody'),
      );
    });

    test('auto with strict selects genre-informed tokens', () {
      final result = MelodyComposerService.compose(
        melodyDirectiveId: MelodyConfig.autoId,
        evolution: MelodyEvolution.strict,
        originalLyrics: '',
        primaryGenre: 'Melodic Techno',
      );
      // Fine-grained family resolution reaches the techno-specific token.
      expect(
        result.stylePromptTokens,
        contains('hypnotic sequenced techno arpeggio under the kick'),
      );
      expect(result.userNotices.first, contains('Auto-selected'));
    });

    test('anthemic_soaring preset includes genre-aware default token', () {
      final d = MelodyConfig.getDirectiveById('anthemic_soaring');
      expect(
        d.getTokenForGenre('default'),
        contains('big, anthemic, and soaring melody'),
      );
    });

    test('legacy hybrid_split_dna normalizes to hook_led tokens', () {
      final result = MelodyComposerService.compose(
        melodyDirectiveId: 'hybrid_split_dna',
        evolution: MelodyEvolution.strict,
        originalLyrics: '',
      );
      expect(
        result.stylePromptTokens,
        contains('melodically driven by a repetitive, catchy hook'),
      );
    });
  });

  group('GenreData categories and Part E sub-genres', () {
    test('Gospel, Jazz/Blues, and Latin are separate categories', () {
      expect(GenreData.categories, contains('Gospel'));
      expect(GenreData.categories, contains('Jazz/Blues'));
      expect(GenreData.categories, contains('Latin'));
      expect(GenreData.categories, isNot(contains('Gospel/Jazz')));
    });

    test('Gospel includes Praise/Worship and Afro-Gospel', () {
      expect(GenreData.subGenresByCategory['Gospel'], contains('Praise/Worship'));
      expect(GenreData.subGenresByCategory['Gospel'], contains('Afro-Gospel'));
    });

    test('Jazz/Blues sub-genres exclude Gospel', () {
      expect(GenreData.subGenresByCategory['Jazz/Blues'], contains('Fusion'));
      expect(GenreData.subGenresByCategory['Jazz/Blues'], contains('Blues'));
      expect(GenreData.subGenresByCategory['Jazz/Blues'], isNot(contains('Gospel')));
    });

    test('Latin includes Bachata and Reggaeton', () {
      expect(GenreData.subGenresByCategory['Latin'], contains('Bachata'));
      expect(GenreData.subGenresByCategory['Latin'], contains('Reggaeton'));
    });

    test('R&B/Soul does not list Gospel as sub-genre', () {
      expect(
        GenreData.subGenresByCategory['R&B/Soul'],
        isNot(contains('Gospel')),
      );
    });
  });

  group('sunoOutputQa', () {
    test('detects truncated block1 and missing block2', () {
      const raw = '''
BLOCK 1 — PASTE INTO SUNO: STYLE
A Soulful House track at 122 BPM in a dark, hopeful minor key, executing an emotionally thoughtful arc from loss to reflection. The rhythmic foundation is a crisp TR-909 four-on-the-floor grid, with a subordinate Amap
''';
      expect(block1ProbablyTruncated(raw), isTrue);
      expect(unifiedBlock2MissingOutput(raw), isTrue);
      expect(sunoOutputIncomplete(raw), isTrue);
      expect(
        shouldFormatRetryOutput(raw, useV2: true, block2OptOut: false),
        isTrue,
      );
    });
  });

  group('chatCompletionHelpers', () {
    test('extractChatMessageContent parses string and parts array', () {
      expect(
        extractChatMessageContent({'content': 'hello'}),
        'hello',
      );
      expect(
        extractChatMessageContent({
          'content': [
            {'type': 'text', 'text': 'BLOCK 1'},
          ],
        }),
        'BLOCK 1',
      );
    });

    test('applyChatTokenLimits sets max_completion_tokens for gpt and claude', () {
      final payload = <String, dynamic>{'max_tokens': 1200};
      applyChatTokenLimits(payload, 'gpt-5.6-sol', 1200);
      expect(payload['max_completion_tokens'], 1200);
      applyChatTokenLimits(payload, 'claude-sonnet-4-5', 2000);
      expect(payload['max_completion_tokens'], 2000);
    });
  });
}
