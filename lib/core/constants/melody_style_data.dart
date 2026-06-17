/// Preset melody approaches + session directives optimized for dual-genre hybrid runs.
class MelodyStyleOption {
  const MelodyStyleOption({
    required this.id,
    required this.label,
    required this.promptLine,
  });

  final String id;
  final String label;

  /// Injected after `MELODY DIRECTION:` for the model.
  final String promptLine;
}

class MelodyStyleData {
  MelodyStyleData._();

  static const String autoId = 'auto';
  static const String customId = 'custom';

  static const List<MelodyStyleOption> presets = [
    MelodyStyleOption(
      id: autoId,
      label: 'Auto (genre-default)',
      promptLine: '',
    ),
    MelodyStyleOption(
      id: 'hybrid_split_dna',
      label: 'Hybrid / Split-DNA Melody',
      promptLine:
          'Enforce strict Split-DNA routing: Verses inherit Genre B (subordinate) organic cadence, phrasing, and intimacy; High-energy peaks (Chorus/Drops) strictly inherit Genre A (dominant) rhythmic quantization economy and grid limits.',
    ),
    MelodyStyleOption(
      id: 'hook_led',
      label: 'Hook-led / Mantra Core',
      promptLine:
          'Prioritize a short, memorable melodic hook; verses stay rhythmically simpler; chorus doubles or varies the hook using semantic mutation.',
    ),
    MelodyStyleOption(
      id: 'conversational',
      label: 'Conversational / speech-like',
      promptLine:
          'Melody follows natural speech rhythm with an organic mid-line breath pocket; narrow pitch range; syllabic phrasing; subtle lifts at line ends.',
    ),
    MelodyStyleOption(
      id: 'anthemic',
      label: 'Anthemic / wide stack',
      promptLine:
          'Wide-interval lifts, sustained held notes on emotional peaks, full vocal stacks, and singalong-friendly contour in choruses.',
    ),
    MelodyStyleOption(
      id: 'minimal_spatial',
      label: 'Minimalist Spatial / Mono-Mantra',
      promptLine:
          'Ethereal low-density lines; strict two-line maximum per section; enforce massive space with vocal phrases followed by long instrumental gaps; hypnotic looping simplicity.',
    ),
    MelodyStyleOption(
      id: 'syncopated_loop',
      label: 'Syncopated / Rhythmic Pocket',
      promptLine:
          'Treat the vocal as a minimalist percussion instrument; melody lands behind the beat using syncopated phrasing, repeating 1-to-2 bar loops, and rhythmic background chants.',
    ),
    MelodyStyleOption(
      id: 'blues_gospel_inflection',
      label: 'Bluesy / gospel inflection',
      promptLine:
          'Blue notes, vocal bends, targeted melisma on key testimony words, high-energy call-and-response dynamics without copying any artist.',
    ),
    MelodyStyleOption(
      id: 'chromatic_tension',
      label: 'Chromatic tension',
      promptLine:
          'Passing tones and brief chromatic side-steps resolving to strong degrees; heavy tension–release in electronic or cinematic cadences.',
    ),
    MelodyStyleOption(
      id: 'call_response',
      label: 'Call & response',
      promptLine:
          'Alternate lead phrase and explosive answering phrase; clear two-bar question/answer feel using vocal or instrumental echoes.',
    ),
  ];

  static MelodyStyleOption? presetById(String id) {
    for (final p in presets) {
      if (p.id == id) return p;
    }
    return null;
  }

  /// Optional block for the user message (null if nothing to add).
  static String? composeUserBlock({
    required String melodyStyleId,
    required String melodyCustomNotes,
    String? sessionVariationDirective,
  }) {
    final buf = StringBuffer();
    final base = _baseDirectionLine(
      melodyStyleId: melodyStyleId,
      melodyCustomNotes: melodyCustomNotes,
    );
    if (base != null) {
      buf.writeln(base);
    }
    final v = sessionVariationDirective?.trim();
    if (v != null && v.isNotEmpty) {
      buf.writeln(
        'MELODY SESSION VARIATION (this prompt only): $v',
      );
    }
    final out = buf.toString().trim();
    return out.isEmpty ? null : out;
  }

  static String? _baseDirectionLine({
    required String melodyStyleId,
    required String melodyCustomNotes,
  }) {
    final id = melodyStyleId.trim().isEmpty ? autoId : melodyStyleId.trim();
    if (id == customId) {
      final t = melodyCustomNotes.trim();
      if (t.isEmpty) return null;
      return 'MELODY DIRECTION (custom): $t';
    }
    if (id == autoId) return null;
    final p = presetById(id);
    if (p == null || p.promptLine.isEmpty) return null;
    return 'MELODY DIRECTION: ${p.promptLine}';
  }
}

/// Extra melodic angles for **rotate** / **random** session modes.
/// Hardened against genre-contamination via strict conditional routing instructions.
const List<String> kMelodySessionVariationDirectives = [
  'Lean into stepwise motion and small skips; save leaps for high-energy hook moments.',
  'Use a 2–4 note rhythmic motif in verses; explode interval range and vocal stacks in the chorus.',
  'Phrase endings: mostly downward resolution; one upward lift before the final climax block.',
  'Hum-friendly contour: favor singable arcs under an octave per phrase; avoid busy runs.',
  'Syncopated entrances: melody lands slightly behind the beat in low-density sections; snaps firmly on-beat during the main drop or chorus.',
  'Question–answer phrasing: four-bar vocal call, four-bar answer handled by backing chants or matching synths.',
  'Reserve melisma or vocal decoration for exactly one keyword per section; keep all other syllables tightly locked to the grid.',
  'Bridge melody: contrasting rhythm using longer, sustained notes while the underlying synth or drum programming gets busier.',
  'Electronic Hybrid Modifier: If the track features Electronic/Techno elements, mutate all acoustic melodic hooks into sidechained, filtered vocal textures during high-energy sections.',
];
