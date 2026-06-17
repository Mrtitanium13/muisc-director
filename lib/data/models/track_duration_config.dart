import '../../core/utils/duration_format.dart';

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
  /// Use [UserInputModel.trackDurationLabel] / custom field text; [minutes] is unused.
  custom('Custom', 0);

  const TrackDuration(this.label, this.minutes);

  final String label;
  final double minutes;
}

enum DurationTier {
  short,
  standard,
  extended,
  club;

  String get sectionDepthInstruction {
    switch (this) {
      case DurationTier.short:
        return '2 verses · 2 choruses · no bridge · no pre-chorus · sections ~8 bars each';
      case DurationTier.standard:
        return '2 verses · 2 choruses · 1 pre-chorus · 1 bridge · sections ~8–16 bars each';
      case DurationTier.extended:
        return '3 verses · 3 choruses · 2 pre-choruses · 1 bridge · sections ~16 bars each';
      case DurationTier.club:
        return '3 verses · 4 choruses · 2 pre-choruses · 1 bridge · 1 breakdown · 1 build · extended outro · sections ~16–32 bars each';
    }
  }
}

/// Bar math + prompt injection for SECTION 3 (duration + DJ intro/outro).
class TrackDurationConfig {
  const TrackDurationConfig({
    required this.displayLabel,
    required this.effectiveMinutes,
    required this.djIntro,
    required this.djOutro,
    this.bpm,
  });

  factory TrackDurationConfig.fromUserInput({
    required TrackDuration duration,
    String? trackDurationLabel,
    required bool djIntro,
    required bool djOutro,
    String? bpmRaw,
  }) {
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
      djIntro: djIntro,
      djOutro: djOutro,
      bpm: bpm,
    );
  }

  final String displayLabel;
  final double effectiveMinutes;
  final bool djIntro;
  final bool djOutro;
  final int? bpm;

  /// Total bars at 4/4: (minutes × BPM) ÷ 4
  int get totalBars {
    if (bpm == null || bpm! <= 0) return 0;
    return ((effectiveMinutes * bpm!) / 4).round();
  }

  int get djBarCount => (djIntro ? 16 : 0) + (djOutro ? 16 : 0);

  int get songContentBars {
    if (bpm == null || bpm! <= 0) return 0;
    return (totalBars - djBarCount).clamp(0, 9999);
  }

  DurationTier get tier {
    final m = effectiveMinutes;
    if (m < 2.25) return DurationTier.short;
    if (m < 3.25) return DurationTier.standard;
    if (m < 4.25) return DurationTier.extended;
    return DurationTier.club;
  }

  String toPromptContext() {
    final buf = StringBuffer()
      ..writeln('TARGET DURATION (user): $displayLabel')
      ..writeln('DURATION TIER: ${tier.name}')
      ..writeln('SECTION DEPTH (guideline): ${tier.sectionDepthInstruction}');

    if (bpm != null && bpm! > 0) {
      buf
        ..writeln('BPM (for bar math): $bpm')
        ..writeln('TOTAL BARS (4/4): $totalBars')
        ..writeln(
          'DJ INTRO: ${djIntro ? 'YES — 16 bars · filtered kicks + percs · filter sweep in (see SECTION 3)' : 'NO'}',
        )
        ..writeln(
          'DJ OUTRO: ${djOutro ? 'YES — 16 bars · filtered kicks + percs · filter sweep out (see SECTION 3)' : 'NO'}',
        );
      if (djIntro || djOutro) {
        buf
          ..writeln('DJ BARS RESERVED: $djBarCount')
          ..writeln('SONG CONTENT BARS (for main body): $songContentBars');
      }
    } else {
      buf
        ..writeln('BPM: unspecified — infer reasonable bar layout from genre; still honor duration tier.')
        ..writeln(
          'DJ INTRO: ${djIntro ? 'YES — apply SECTION 3 [DJ Intro] block' : 'NO'}',
        )
        ..writeln(
          'DJ OUTRO: ${djOutro ? 'YES — apply SECTION 3 [DJ Outro] block' : 'NO'}',
        );
    }

    buf.writeln(
      'Scale Block 2 section count and bar depth to fill the target duration at the stated BPM; '
      'when DJ Intro/Outro are on, place those tag-only sections first/last in Block 2.',
    );

    return buf.toString().trim();
  }
}
