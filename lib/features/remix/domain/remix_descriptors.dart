import 'dart:convert';

/// Neutral musical DNA for Layer 4.8 — never contains song title or artist.
class RemixDescriptors {
  const RemixDescriptors({
    required this.targetGenre,
    required this.tempoFeel,
    required this.tonalCenter,
    required this.harmonicCharacter,
    required this.melodicContour,
    required this.rhythmicCharacter,
    required this.textureBrief,
    required this.emotionalLane,
    required this.sourceFingerprint,
  });

  final String targetGenre;
  final String tempoFeel;
  final String tonalCenter;
  final String harmonicCharacter;
  final String melodicContour;
  final String rhythmicCharacter;
  final String textureBrief;
  final String emotionalLane;

  /// Non-reversible short hash of title|artist for logs — not human-readable names.
  final String sourceFingerprint;

  /// Resolve descriptors from form context. Title/artist gate activation and
  /// fingerprint only — they never appear in [toUserBlockDna].
  factory RemixDescriptors.resolve({
    required String title,
    required String artist,
    required String targetGenre,
    String bpm = '',
    String keyRoot = '',
    String scale = '',
    String vibe = '',
  }) {
    final genre =
        targetGenre.trim().isEmpty ? 'unspecified' : targetGenre.trim();
    final bpmTrim = bpm.trim();
    final key = [
      keyRoot.trim(),
      scale.trim(),
    ].where((s) => s.isNotEmpty).join(' ');
    final vibeBrief = _vibeClip(vibe);

    return RemixDescriptors(
      targetGenre: genre,
      tempoFeel: bpmTrim.isEmpty
          ? 'Match the locked reference pulse and pocket; do not invent a conflicting tempo story.'
          : 'Anchor near $bpmTrim BPM while preserving the locked reference groove feel.',
      tonalCenter: key.isEmpty
          ? 'Preserve the locked reference tonal center and cadence destinations.'
          : 'Prefer $key as the working center while preserving the locked reference cadence logic.',
      harmonicCharacter:
          'Lock the reference chord progression and phrase boundaries; do not substitute a new harmonic story.',
      melodicContour:
          'Preserve topline interval contour and hook shape; re-voice with $genre instruments/leads.',
      rhythmicCharacter:
          'Preserve syncopated lead/vocal rhythm mapped into a $genre pocket.',
      textureBrief:
          'Override drums, bass role, pads/leads, and mix aesthetic to idiomatic $genre textures only.',
      emotionalLane: vibeBrief.isEmpty
          ? 'Keep the emotional arc of the locked reference without naming it.'
          : 'Emotional lane (operator vibe, name-free): $vibeBrief',
      sourceFingerprint: fingerprint(title, artist),
    );
  }

  static String fingerprint(String title, String artist) {
    final raw = '${title.trim().toLowerCase()}|${artist.trim().toLowerCase()}';
    if (raw.length < 3) return 'none';
    // FNV-1a 32-bit — stable, non-reversible enough for logs.
    var hash = 0x811c9dc5;
    for (final c in utf8.encode(raw)) {
      hash ^= c;
      hash = (hash * 0x01000193) & 0xffffffff;
    }
    return hash.toRadixString(16).padLeft(8, '0');
  }

  static String _vibeClip(String vibe) {
    final t = vibe.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (t.isEmpty) return '';
    if (t.length <= 160) return t;
    return '${t.substring(0, 157).trimRight()}…';
  }

  /// LLM-facing DNA block — guaranteed free of catalog title/artist strings.
  String toUserBlockDna() {
    return (
      'REFERENCE DNA (descriptor-only — no catalog titles or artist names in context):\n'
      '- Target genre textures: $targetGenre\n'
      '- Tempo / pulse: $tempoFeel\n'
      '- Tonal center: $tonalCenter\n'
      '- Harmonic brief: $harmonicCharacter\n'
      '- Melodic brief: $melodicContour\n'
      '- Rhythmic brief: $rhythmicCharacter\n'
      '- Texture brief: $textureBrief\n'
      '- Emotional lane: $emotionalLane\n'
      '- Source lock id (opaque): $sourceFingerprint\n'
      'Operator lock: a specific catalog reference is held client-side only. '
      'Reproduce its chord cadence, topline contour, and lead rhythm as '
      'session-musician DNA — never invent, print, or hint at a song title or artist.'
    );
  }
}
