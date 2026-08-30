import '../../core/constants/suno_dj_mix_directives.dart';
import '../../core/utils/duration_format.dart';
import '../../core/utils/structural_family_resolver.dart';

/// Target track length for Suno generations — drives bar math and section depth.
enum TrackDuration {
  s1_30('1:30', 1.5),
  s2_00('2:00', 2.0),
  s2_30('2:30', 2.5),
  s3_00('3:00', 3.0),
  s3_30('3:30', 3.5),
  s4_00('4:00', 4.0),
  s4_30('4:30', 4.5),
  s5_00('5:00', 5.0),
  s6_00('6:00', 6.0),

  /// [minutes] is `double.nan` for [custom] — ALWAYS use
  /// [TrackDurationConfig.fromUserInput] to resolve effective minutes.
  custom('Custom', double.nan);

  const TrackDuration(this.label, this.minutes);

  final String label;
  final double minutes;
}

enum DurationTier {
  short,
  standard,
  extended,
  club;

  /// Pop-centric fallback — prefer [TrackDurationConfig.sectionDepthInstruction].
  String get sectionDepthInstruction => switch (this) {
        DurationTier.short =>
          '2 verses · 2 choruses · no bridge · no pre-chorus',
        DurationTier.standard =>
          '2 verses · 2 choruses · 1 pre-chorus · 1 bridge',
        DurationTier.extended =>
          '3 verses · 3 choruses · 2 pre-choruses · 1 bridge',
        DurationTier.club =>
          '3 verses · 4 choruses · 2 pre-choruses · bridge · breakdown · extended outro',
      };
}

/// Bar math + compact duration context for the LLM user block.
class TrackDurationConfig {
  TrackDurationConfig({
    required this.displayLabel,
    required this.effectiveMinutes,
    required this.djIntro,
    required this.djOutro,
    required this.family,
    this.bpm,
  }) : _djConfig = djBarConfigFor(family);

  factory TrackDurationConfig.fromUserInput({
    required TrackDuration duration,
    required StructuralFamily family,
    String? trackDurationLabel,
    required bool djIntro,
    required bool djOutro,
    String? bpmRaw,
    String? primaryGenre,
    String? fusionGenre,
  }) {
    final resolvedFamily = family;
    final djAllowed = djMixAllowedForFamily(resolvedFamily);
    final safeIntro = djAllowed && djIntro;
    final safeOutro = djAllowed && djOutro;
    final bpm = int.tryParse((bpmRaw ?? '').trim(), radix: 10);

    final (String label, double minutes) = switch (duration) {
      TrackDuration.custom => () {
          final parsed = parseFlexibleDurationMinutes(trackDurationLabel);
          final safe = parsed ?? 3.0;
          final canonical = formatMinutesToMmSs(safe);
          return (canonical, safe);
        }(),
      _ => (duration.label, duration.minutes),
    };

    return TrackDurationConfig(
      displayLabel: label,
      effectiveMinutes: minutes,
      djIntro: safeIntro,
      djOutro: safeOutro,
      family: resolvedFamily,
      bpm: bpm,
    );
  }

  final String displayLabel;
  final double effectiveMinutes;
  final bool djIntro;
  final bool djOutro;
  final StructuralFamily family;
  final int? bpm;

  final DjIntroConfig _djConfig;

  int get introBarReserve => djIntro ? _djConfig.introBars : 0;
  int get outroBarReserve => djOutro ? _djConfig.outroBars : 0;

  /// Total bars at 4/4: (minutes × BPM) ÷ 4
  int get totalBars {
    if (bpm == null || bpm! <= 0) return 0;
    return ((effectiveMinutes * bpm!) / 4).round();
  }

  int get djBarCount => introBarReserve + outroBarReserve;

  int get songContentBars {
    if (bpm == null || bpm! <= 0) return 0;
    return (totalBars - djBarCount).clamp(0, 9999);
  }

  /// Family-aware tier; caps [DurationTier.club] for non-club arc families.
  DurationTier tierFor({required StructuralFamily family}) {
    final m = effectiveMinutes;
    final natural = switch (m) {
      < 2.25 => DurationTier.short,
      < 3.25 => DurationTier.standard,
      < 4.25 => DurationTier.extended,
      _ => DurationTier.club,
    };
    final clubCapable = {
      StructuralFamily.edmProgressiveHouse,
      StructuralFamily.edmTrance,
      StructuralFamily.edmTechno,
      StructuralFamily.edmHardstyle,
      StructuralFamily.edmDrumAndBass,
      StructuralFamily.edmBigRoom,
      StructuralFamily.trap,
      StructuralFamily.hiphop,
      StructuralFamily.boom_bap,
      StructuralFamily.amapiano,
      StructuralFamily.popRadio,
      StructuralFamily.popStandard,
      StructuralFamily.worship,
    };
    if (natural == DurationTier.club && !clubCapable.contains(family)) {
      return DurationTier.extended;
    }
    return natural;
  }

  @Deprecated('Use tierFor(family: family) instead')
  DurationTier get tier => tierFor(family: family);

  /// Genre- and tier-aware section depth blueprint.
  String get sectionDepthInstruction =>
      sectionDepthFor(family: family, tier: tierFor(family: family));

  static String sectionDepthFor({
    required StructuralFamily family,
    required DurationTier tier,
  }) {
    return switch (family) {
      StructuralFamily.jazzStandard => switch (tier) {
          DurationTier.short =>
            'A-section head · B-section middle eight · head out',
          DurationTier.standard =>
            '2 A-sections · B-section · head return · instrumental solo · head out',
          DurationTier.extended || DurationTier.club =>
            'A-section head · repeat · B-section · extended solo · head return · head out',
        },
      StructuralFamily.cinematic => switch (tier) {
          DurationTier.short => 'Intro · Theme A · Coda',
          DurationTier.standard =>
            'Intro · Theme A · Development · Climax · Coda',
          DurationTier.extended || DurationTier.club =>
            'Intro · Theme A · Development expansion · Climax peak · Coda resolve',
        },
      StructuralFamily.worship => switch (tier) {
          DurationTier.short => 'Verse · Chorus · Verse · Chorus',
          DurationTier.standard =>
            'Verse · Chorus · Verse · Chorus · Bridge · Final Chorus',
          DurationTier.extended =>
            'Verse · Chorus · Verse · Chorus · Bridge · Final Chorus · extended outro',
          DurationTier.club =>
            'Verse · Chorus · Bridge · Vamp · Spontaneous Flow · Final Chorus',
        },
      StructuralFamily.edmProgressiveHouse ||
      StructuralFamily.edmTrance ||
      StructuralFamily.edmTechno ||
      StructuralFamily.edmHardstyle ||
      StructuralFamily.edmDrumAndBass ||
      StructuralFamily.edmBigRoom =>
        _edmSectionDepth(tier),
      StructuralFamily.trap => switch (tier) {
          DurationTier.short => 'Intro · Hook · Verse · Hook',
          DurationTier.standard =>
            'Intro · Hook · Verse · Hook · beat-switch Bridge · Hook',
          DurationTier.extended || DurationTier.club =>
            'Intro · Hook · 2 Verses · beat-switch Bridge · Hook · extended outro',
        },
      StructuralFamily.hiphop || StructuralFamily.boom_bap => switch (tier) {
          DurationTier.short => 'Intro · Verse · Hook · Verse · Hook',
          DurationTier.standard =>
            'Intro · Verse · Hook · Verse · Hook · Bridge · Hook',
          DurationTier.extended || DurationTier.club =>
            'Intro · 2 Verses · 3 Hooks · beat-switch Bridge · Outro',
        },
      StructuralFamily.amapiano => switch (tier) {
          DurationTier.short => 'Intro · Verse · Chorus · Verse · Chorus',
          DurationTier.standard =>
            'Intro · Verse · Chorus · Verse · Chorus · Breakdown · Final Chorus',
          DurationTier.extended || DurationTier.club =>
            'Intro · Verse · Chorus · Verse · Bridge · Chorus · Breakdown · Final Chorus',
        },
      StructuralFamily.folk => switch (tier) {
          DurationTier.short => 'Verse · Chorus · Verse · Chorus',
          DurationTier.standard =>
            'Intro · Verse · Chorus · Instrumental Interlude · Verse · Chorus · Bridge · Final Chorus',
          DurationTier.extended || DurationTier.club =>
            'Verse · Chorus · Instrumental Interlude · Verse · Chorus · Bridge · Final Chorus · Outro',
        },
      StructuralFamily.mandopop => switch (tier) {
          DurationTier.short => 'Verse · Pre-Chorus · Chorus · Verse · Chorus',
          DurationTier.standard =>
            'Intro · Verse · Pre-Chorus · Chorus · Verse · Pre-Chorus · Chorus · Bridge · Final Chorus',
          DurationTier.extended || DurationTier.club =>
            'Verse · Pre-Chorus · Chorus · Verse · Bridge · Final Chorus · erhu coda',
        },
      StructuralFamily.popRadio => switch (tier) {
          DurationTier.short => 'Verse · Chorus · Verse · Chorus',
          DurationTier.standard =>
            'Verse · Chorus · Verse · Chorus · short tag outro',
          DurationTier.extended || DurationTier.club =>
            'Verse · Chorus · Verse · Chorus · hook repeat · hard-hitting tag outro',
        },
      StructuralFamily.popStandard => switch (tier) {
          DurationTier.short =>
            '2 verses · 2 choruses · no bridge · no pre-chorus',
          DurationTier.standard =>
            '2 verses · 2 choruses · 1 pre-chorus · 1 bridge',
          DurationTier.extended =>
            '3 verses · 3 choruses · 2 pre-choruses · 1 bridge · final chorus',
          DurationTier.club =>
            '3 verses · 4 choruses · 2 pre-choruses · bridge · breakdown · extended outro',
        },
    };
  }

  static String _edmSectionDepth(DurationTier tier) => switch (tier) {
        DurationTier.short => 'Intro · Build-Up · Drop',
        DurationTier.standard =>
          'Intro · Build-Up · Drop · Breakdown · Final Drop',
        DurationTier.extended =>
          'Intro · Build-Up · Drop · Breakdown · Build-Up · Final Drop · Outro',
        DurationTier.club =>
          'Intro · extended Build-Up · Drop · Breakdown · Final Drop · DJ outro',
      };

  String toPromptContext({bool verbose = false}) =>
      verbose ? _verbosePromptContext() : _compactPromptContext();

  String _compactPromptContext() {
    final tier = tierFor(family: family);
    final lines = <String>[
      'Target duration: $displayLabel · Tier: ${tier.name}',
    ];

    if (bpm != null && bpm! > 0) {
      lines.add('BPM: $bpm · Total bars (4/4): $totalBars');
    } else {
      lines.add('BPM: infer from genre');
    }

    if (djIntro || djOutro) {
      final djBits = <String>[];
      if (djIntro) {
        djBits.add(
          '${_djConfig.introBars}-bar mix-in (filtered kicks, filter sweep)',
        );
      }
      if (djOutro) {
        djBits.add(
          '${_djConfig.outroBars}-bar mix-out (lead strip, gradual decay)',
        );
      }
      lines.add('DJ: ${djBits.join(' · ')}');
    } else {
      lines.add('DJ: off');
    }

    if (bpm != null && bpm! > 0 && songContentBars > 0) {
      lines.add(
        'Song body: $songContentBars bars · Depth: $sectionDepthInstruction',
      );
    } else {
      lines.add('Depth: $sectionDepthInstruction');
    }

    return lines.join('\n');
  }

  String _verbosePromptContext() {
    final tier = tierFor(family: family);
    final buf = StringBuffer()
      ..writeln('TARGET DURATION (user): $displayLabel')
      ..writeln('DURATION TIER: ${tier.name}')
      ..writeln('SECTION DEPTH (guideline): $sectionDepthInstruction');

    if (bpm != null && bpm! > 0) {
      buf
        ..writeln('BPM (for bar math): $bpm')
        ..writeln('TOTAL BARS (4/4): $totalBars')
        ..writeln(
          'DJ INTRO: ${djIntro ? 'YES — ${_djConfig.introBars}-bar mix-in (filtered kicks + percs, gradual filter opening into first chorus)' : 'NO'}',
        )
        ..writeln(
          'DJ OUTRO: ${djOutro ? 'YES — ${_djConfig.outroBars}-bar mix-out (lead strip, hats/ride sustain, gradual decay)' : 'NO'}',
        );
    } else {
      buf.writeln('BPM: unspecified — infer reasonable bar layout from genre.');
      buf.writeln(
        'DJ INTRO: ${djIntro ? 'YES — ${_djConfig.introBars}-bar mix-in (filtered kicks, gradual filter opening)' : 'NO'}',
      );
      buf.writeln(
        'DJ OUTRO: ${djOutro ? 'YES — ${_djConfig.outroBars}-bar mix-out (lead strip, gradual decay)' : 'NO'}',
      );
    }

    return buf.toString().trim();
  }
}
