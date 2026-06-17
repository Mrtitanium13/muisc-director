/// Studio-isolated vs live-arena staging for Block 2 arrangement tags.

enum AudioEnvironmentMode {
  studioIsolated,
  livePerformance,
}

class AudioEnvironmentOption {
  const AudioEnvironmentOption({
    required this.id,
    required this.label,
    required this.promptDirective,
    required this.mode,
  });

  final String id;
  final String label;

  /// Injected into generation user block + Stage 4 (humanize) + Stage 5 (compress).
  final String promptDirective;
  final AudioEnvironmentMode mode;
}

class AudioEnvironmentData {
  AudioEnvironmentData._();

  static const String studioIsolatedId = 'studio_isolated';
  static const String livePerformanceId = 'live_performance';

  static const List<AudioEnvironmentOption> options = [
    AudioEnvironmentOption(
      id: studioIsolatedId,
      label: 'Pristine Studio (No Crowd)',
      mode: AudioEnvironmentMode.studioIsolated,
      promptDirective:
          'CRITICAL DIRECTIVE: Enforce strict studio isolation. Utilize words like '
          '"Dead-room isolation, Pristine studio environment, Zero audience noise". '
          'Strictly ban any live applause or crowd sounds. '
          'For vocal stacks use "Isolated multi-tracked vocal doubles" — never '
          '"Studio Harmonic Backing" or "Harmonic Overlays". '
          'Ban tape hiss / vinyl crackle in Intro, Verse 1, and Outro brackets.',
    ),
    AudioEnvironmentOption(
      id: livePerformanceId,
      label: 'Live Arena (Crowd & Cheers)',
      mode: AudioEnvironmentMode.livePerformance,
      promptDirective:
          'CRITICAL DIRECTIVE: Simulate an epic, high-energy live stadium concert. '
          'Force heavy crowd participation using words like "Thunderous stadium crowd cheering, '
          'Loud audience applause, Large outdoor stage reverb, Crowd singing along loudly" '
          'inside the bracket layers.',
    ),
  ];

  static String coerceId(String? raw) {
    final t = (raw ?? '').trim();
    if (t == livePerformanceId) return livePerformanceId;
    return studioIsolatedId;
  }

  static AudioEnvironmentOption optionForId(String? raw) {
    final id = coerceId(raw);
    return options.firstWhere(
      (o) => o.id == id,
      orElse: () => options.first,
    );
  }

  static bool isLivePerformance(String? raw) =>
      coerceId(raw) == livePerformanceId;

  static String? postProcessContextLine(String? modeId) {
    return optionForId(modeId).promptDirective;
  }

  static String postProcessCompactLine(String? modeId) {
    if (isLivePerformance(modeId)) {
      return 'ENV:live-arena|stadium crowd cheering|chorus sing-along|ovation outro';
    }
    return 'ENV:studio|dead-room isolation|zero crowd/applause';
  }

  static String userBlockDirective(String? modeId) {
    final opt = optionForId(modeId);
    return 'AUDIO ENVIRONMENT (${opt.label}):\n${opt.promptDirective}';
  }
}
