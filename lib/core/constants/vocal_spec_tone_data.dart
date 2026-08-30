/// Vocal **spec** (who / arrangement) vs **tone** (timbre / delivery).
///
/// Vocal accent is handled separately via [VocalAccentData].
class VocalSpecToneData {
  VocalSpecToneData._();

  // ---------------------------------------------------------------------------
  // Constants
  // ---------------------------------------------------------------------------

  static const String maleLeadSpec = 'Male Lead';
  static const String femaleLeadSpec = 'Female Lead';
  static const String dualLeadSpec = 'Dual Lead';
  static const String rapVocalSpaceSpec = 'Rap Vocal Space';
  static const String gospelChoirSpec = 'Gospel Choir';
  static const String childrensChoirSpec = "Children's Choir";
  static const String vocalChantsOnlySpec = 'Vocal Chants Only';
  static const String unisonStacksSpec = 'Unison Stacks';
  static const String instrumentalOnlySpec = 'Instrumental Only';

  /// Lead / choir / chant arrangement chips (form VOCAL SPEC).
  static const List<String> vocalSpecs = [
    maleLeadSpec,
    femaleLeadSpec,
    dualLeadSpec,
    rapVocalSpaceSpec,
    gospelChoirSpec,
    childrensChoirSpec,
    vocalChantsOnlySpec,
    unisonStacksSpec,
    instrumentalOnlySpec,
  ];

  static const Set<String> _choirSpecs = {
    gospelChoirSpec,
    childrensChoirSpec,
  };

  /// Specs whose routing is primarily a Block 2 (lyrics/staging) directive.
  static const Set<String> _block2OverrideSpecs = {
    instrumentalOnlySpec,
    vocalChantsOnlySpec,
    unisonStacksSpec,
    rapVocalSpaceSpec,
    ..._choirSpecs,
  };

  // ---------------------------------------------------------------------------
  // Predicates
  // ---------------------------------------------------------------------------

  static bool isInstrumentalOnly(String? spec) =>
      (spec ?? '').trim() == instrumentalOnlySpec;

  static bool isKnownSpec(String? spec) =>
      spec != null && vocalSpecs.contains(spec);

  static bool isCustomSpec(String? raw) {
    final spec = coerceSpec(raw);
    return spec != null && !isKnownSpec(spec);
  }

  /// Whether this spec means no lead-vocal lyric lines should be generated.
  static bool suppressesLeadLyrics(String? spec) => isInstrumentalOnly(spec);

  /// Whether this spec routes primarily to Block 2 rather than Block 1 prose.
  static bool routesToBlock2(String? spec) =>
      _block2OverrideSpecs.contains(coerceSpec(spec));

  static bool isChoir(String? spec) => _choirSpecs.contains(coerceSpec(spec));

  static bool isRapForward(String? spec) =>
      coerceSpec(spec) == rapVocalSpaceSpec;

  // ---------------------------------------------------------------------------
  // Normalization
  // ---------------------------------------------------------------------------

  /// Matches a raw string to a canonical chip, or returns the trimmed raw value
  /// if it is a custom spec.
  static String? coerceSpec(String? raw) {
    if (raw == null) return null;
    final t = raw.trim();
    if (t.isEmpty) return null;
    final lower = t.toLowerCase();
    for (final v in vocalSpecs) {
      if (v.toLowerCase() == lower) return v;
    }
    return t;
  }

  /// Trims and collapses internal whitespace for free-text tone values.
  static String? normalizeTone(String? raw) {
    if (raw == null) return null;
    final t = raw.trim();
    if (t.isEmpty) return null;
    return t.replaceAll(RegExp(r'\s+'), ' ');
  }

  // ---------------------------------------------------------------------------
  // Prompt rendering
  // ---------------------------------------------------------------------------

  /// Single-line user block prefix (accent handled separately).
  static String userBlockLine({
    required String? vocalSpec,
    required String? vocalTone,
  }) {
    final spec = (vocalSpec ?? '').trim();
    final tone = (vocalTone ?? '').trim();
    final parts = <String>[
      if (spec.isNotEmpty) 'spec=$spec',
      if (tone.isNotEmpty) 'tone=$tone',
    ];
    return parts.isEmpty ? 'Vocal:' : 'Vocal: ${parts.join(' · ')}';
  }

  /// Expanded routing directive when spec or tone is set.
  ///
  /// [primaryGenre] and [subGenreFusion] are accepted for signature stability
  /// with callers that already hold genre context, but this block stays focused
  /// on user chip routing; genre-specific prose is appended by genre
  /// directives elsewhere.
  static String userBlockDirective({
    required String? vocalSpec,
    required String? vocalTone,
    String primaryGenre = '',
    String subGenreFusion = '',
  }) {
    final spec = coerceSpec(vocalSpec);
    final tone = normalizeTone(vocalTone);
    final hasSpec = spec != null && spec.isNotEmpty;
    final hasTone = tone != null && tone.isNotEmpty;
    if (!hasSpec && !hasTone) return '';

    final buf = StringBuffer('''
VOCAL SPEC & TONE (USER-SELECTED — NON-NEGOTIABLE):
- **Vocal spec** = lead singer / choir / chant arrangement (form chip). **Vocal tone** = timbre / delivery / processing mix (optional dropdown or custom text). **Vocal accent** is a separate field — see VOCAL ACCENT block when present.
''');

    if (hasSpec) {
      buf.writeln('- user_vocal_spec: $spec');
      buf.writeln('- ${_routingForSpec(spec)}');
    }

    if (hasTone) {
      buf.writeln('- user_vocal_tone: $tone');
      buf.writeln(
        '- Block 1: embed tone as mix / timbre / delivery texture in vocal prose. '
        'Block 2: reflect tone in staging bracket tags — do not paste tone label as a lyric theme.',
      );
    }

    return buf.toString().trim();
  }

  static String _routingForSpec(String spec) => switch (spec) {
        instrumentalOnlySpec =>
          'Block 2: **instrumental-only** — bracket sections and production tags only; '
          'no lead-vocal lyric lines, hooks, or sung verses.',
        vocalChantsOnlySpec =>
          'Block 2: chant-first — short repetitive loops on `[Chant]` headers; '
          'minimal narrative verse density; hookable syllable stacks.',
        unisonStacksSpec =>
          'Block 2: unison-stack delivery — thick doubled lead lines; '
          'staging may reference stacked unison; avoid complex independent harmony parts in lyrics.',
        rapVocalSpaceSpec =>
          'Block 2: rap-forward pocket — rhythmic density, internal rhyme, '
          'clear downbeat phrasing; sung sections only when genre lane expects them.',
        gospelChoirSpec || childrensChoirSpec =>
          'Block 2: choir / group vocal staging — call-and-response or sectional '
          'group tags where natural; lead lines optional per genre lane.',
        _ =>
          'Block 1: weave spec into vocal production prose (gender/role/line-up only — '
          'never impersonate a real person).',
      };
}
