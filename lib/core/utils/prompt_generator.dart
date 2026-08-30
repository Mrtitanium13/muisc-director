import '../../data/models/audio_analysis_model.dart';

/// Industry-standard vocal production shorthand Suno maps well in bracket tags.
const String kThickVocalCoreModifiers =
    'Thick multi-tracked vocal doubles, warm vocal saturation, ultra-close-mic '
    'intimateness, high-compression proximity effect, detailed chest resonance, '
    'crispy upfront presence, dedicated low-mid vocal warmth pocket, forward in '
    'the mix, compressed lead, pristine high-end air boost, zero distant karaoke '
    'room reverb, never thin distant or buried';

/// Injects thick vocal presence + structural layout tags for Suno STYLE fields.
String generateThickVocalPrompt({
  required String baseUserPrompt,
  required int bpm,
  required String keyScale,
  bool forceThickPresence = true,
}) {
  final style = baseUserPrompt.trim().isEmpty
      ? AudioAnalysisModel.fallbackAnalyzerSummary
      : baseUserPrompt.trim();
  final key = keyScale.trim().isEmpty ? 'C Major' : keyScale.trim();
  final safeBpm = bpm.clamp(40, 220);

  final coreVocalModifiers = forceThickPresence ? kThickVocalCoreModifiers : '';

  final buffer = StringBuffer()..writeln('[Master Style: $style]');

  if (coreVocalModifiers.isNotEmpty) {
    buffer.writeln(
      '[Production Layout: $coreVocalModifiers, $key, $safeBpm BPM, '
      'Analog SSL console master glue]',
    );
  } else {
    buffer.writeln(
      '[Production Layout: $key, $safeBpm BPM, Analog SSL console master glue]',
    );
  }

  return buffer.toString().trim();
}

/// Derives the master-style line from analyzer genre + compact vocal profile.
String baseStyleFromAnalysis(AudioAnalysisModel analysis) {
  final genre = analysis.genre?.trim();
  final profile = analysis.compactProfile;
  if (genre != null && genre.isNotEmpty) {
    return '$genre, $profile';
  }
  return profile;
}

/// Prepends Suno bracket layout tags before the full analyzer constraint block.
String buildAnalyzerPromptWithThickVocals(
  AudioAnalysisModel analysis, {
  bool forceThickPresence = true,
}) {
  final bpm = analysis.bpm?.round() ?? 120;
  final keyScale = analysis.keyScale ?? 'C Major';
  final thickLayout = generateThickVocalPrompt(
    baseUserPrompt: baseStyleFromAnalysis(analysis),
    bpm: bpm,
    keyScale: keyScale,
    forceThickPresence: forceThickPresence,
  );
  return '$thickLayout\n\n${analysis.toPromptSummary()}';
}
