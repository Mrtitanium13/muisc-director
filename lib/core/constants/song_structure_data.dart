import 'package:flutter/foundation.dart';

import '../utils/structure_assembler.dart';
import '../utils/suno_syntax_renderer.dart';

/// Canonical section types recognized by Suno across versions.
enum SectionKind {
  intro,
  verse,
  preChorus,
  chorus,
  postChorus,
  hook,
  bridge,
  breakdown,
  buildUp,
  drop,
  dropA,
  dropB,
  mainDrop,
  riser,
  fill,
  atmosphericBreak,
  antiClimax,
  finalChorus,
  vamp,
  spontaneousFlow,
  interlude,
  solo,
  outro,
  end,
  finalDrop,
  unknown,
}

/// Complexity tier for UI sorting / filtering.
enum PresetComplexity { simple, moderate, complex }

/// Immutable section descriptor. [id] is canonical (Suno-safe), [label] is
/// display text, [stagingNote] is optional v5.5 director cue.
///
/// Not `final` — [SectionLine] in structure_assembler extends this type.
@immutable
class SongSection {
  const SongSection({
    required this.kind,
    required this.id,
    required this.label,
    this.stagingNote,
  });

  final SectionKind kind;
  final String id;
  final String label;
  final String? stagingNote;

  /// Render as Suno v5 / v5.5 bracket header.
  String toSunoBracket({bool v5_5 = false}) {
    if (!v5_5 || stagingNote == null || stagingNote!.isEmpty) {
      return '[$label]';
    }
    return '[$label: $stagingNote]';
  }

  @override
  String toString() => label;

  SongSection copyWith({
    SectionKind? kind,
    String? id,
    String? label,
    String? stagingNote,
  }) =>
      SongSection(
        kind: kind ?? this.kind,
        id: id ?? this.id,
        label: label ?? this.label,
        stagingNote: stagingNote ?? this.stagingNote,
      );
}

/// A preset arrangement: metadata + typed section list.
@immutable
final class SongStructurePreset {
  const SongStructurePreset({
    required this.id,
    required this.label,
    required this.description,
    required this.genreAffinity,
    required this.complexity,
    required this.sections,
  });

  final String id;
  final String label;
  final String description;
  final List<String> genreAffinity;
  final PresetComplexity complexity;
  final List<SongSection> sections;

  /// Human-readable roadmap: "Intro → Verse 1 → Chorus → ..."
  String get canonicalRoadmap =>
      sections.isEmpty ? '' : sections.map((s) => s.label).join(' → ');

  bool get hasBridge => sections.any((s) => s.kind == SectionKind.bridge);
  bool get hasDrop => sections.any((s) => _isDropKind(s.kind));
  bool get hasVamp => sections.any((s) => s.kind == SectionKind.vamp);
  bool get hasPreChorus =>
      sections.any((s) => s.kind == SectionKind.preChorus);
  int get sectionCount => sections.length;

  static bool _isDropKind(SectionKind kind) =>
      kind == SectionKind.drop ||
      kind == SectionKind.dropA ||
      kind == SectionKind.dropB ||
      kind == SectionKind.mainDrop ||
      kind == SectionKind.finalDrop;

  bool get isFlexible => id == SongStructureData.flexibleId;
  bool get isCustom => id == SongStructureData.customId;

  /// Render all sections as Suno v5.5 bracket lines.
  List<String> toSunoBrackets({bool v5_5 = false}) =>
      sections.map((s) => s.toSunoBracket(v5_5: v5_5)).toList(growable: false);

  SongStructurePreset copyWith({
    String? id,
    String? label,
    String? description,
    List<String>? genreAffinity,
    PresetComplexity? complexity,
    List<SongSection>? sections,
  }) =>
      SongStructurePreset(
        id: id ?? this.id,
        label: label ?? this.label,
        description: description ?? this.description,
        genreAffinity: genreAffinity ?? this.genreAffinity,
        complexity: complexity ?? this.complexity,
        sections: sections ?? this.sections,
      );

  @override
  String toString() => 'SongStructurePreset($id: $label)';
}

/// Immutable data source for song structure presets.
abstract final class SongStructureData {
  SongStructureData._();

  /// AI-picks-one arc; must stay internally consistent.
  static const String flexibleId = 'flexible';

  /// User-authored roadmap (text or bracketed outline).
  static const String customId = 'custom';

  // ────────────────────────── Shared sections ──────────────────────────

  static const SongSection _intro = SongSection(
    kind: SectionKind.intro,
    id: 'intro',
    label: 'Intro',
  );
  static const SongSection _verse1 = SongSection(
    kind: SectionKind.verse,
    id: 'verse1',
    label: 'Verse 1',
  );
  static const SongSection _verse2 = SongSection(
    kind: SectionKind.verse,
    id: 'verse2',
    label: 'Verse 2',
  );
  static const SongSection _verse3 = SongSection(
    kind: SectionKind.verse,
    id: 'verse3',
    label: 'Verse 3',
  );
  static const SongSection _preChorus = SongSection(
    kind: SectionKind.preChorus,
    id: 'preChorus',
    label: 'Pre-Chorus',
  );
  static const SongSection _chorus = SongSection(
    kind: SectionKind.chorus,
    id: 'chorus',
    label: 'Chorus',
  );
  static const SongSection _hook = SongSection(
    kind: SectionKind.hook,
    id: 'hook',
    label: 'Hook',
  );
  static const SongSection _bridge = SongSection(
    kind: SectionKind.bridge,
    id: 'bridge',
    label: 'Bridge',
  );
  static const SongSection _breakdown = SongSection(
    kind: SectionKind.breakdown,
    id: 'breakdown',
    label: 'Breakdown',
  );
  static const SongSection _buildUp = SongSection(
    kind: SectionKind.buildUp,
    id: 'buildUp',
    label: 'Build-up',
  );
  static const SongSection _drop = SongSection(
    kind: SectionKind.drop,
    id: 'drop',
    label: 'Drop',
  );
  static const SongSection _mainDrop = SongSection(
    kind: SectionKind.mainDrop,
    id: 'mainDrop',
    label: 'Main Drop',
  );
  static const SongSection _finalDrop = SongSection(
    kind: SectionKind.finalDrop,
    id: 'finalDrop',
    label: 'Final Drop',
  );
  static const SongSection _finalChorus = SongSection(
    kind: SectionKind.finalChorus,
    id: 'finalChorus',
    label: 'Final Chorus',
  );
  static const SongSection _vamp = SongSection(
    kind: SectionKind.vamp,
    id: 'vamp',
    label: 'Vamp',
  );
  static const SongSection _spontaneousFlow = SongSection(
    kind: SectionKind.spontaneousFlow,
    id: 'spontaneousFlow',
    label: 'Spontaneous Flow',
  );
  static const SongSection _interlude = SongSection(
    kind: SectionKind.interlude,
    id: 'interlude',
    label: 'Interlude',
  );
  static const SongSection _solo = SongSection(
    kind: SectionKind.solo,
    id: 'solo',
    label: 'Solo',
  );
  static const SongSection _antiClimax = SongSection(
    kind: SectionKind.antiClimax,
    id: 'antiClimax',
    label: 'Anti-Climax',
  );
  static const SongSection _outro = SongSection(
    kind: SectionKind.outro,
    id: 'outro',
    label: 'Outro',
  );

  // ────────────────────────── Presets ──────────────────────────

  static const List<SongStructurePreset> presets = [
    SongStructurePreset(
      id: flexibleId,
      label: 'Flexible',
      description: 'AI picks one coherent arc (intro-through-outro).',
      genreAffinity: [],
      complexity: PresetComplexity.simple,
      sections: [],
    ),
    SongStructurePreset(
      id: customId,
      label: 'Custom',
      description: 'You write the roadmap — prose or bracketed [Sections].',
      genreAffinity: [],
      complexity: PresetComplexity.complex,
      sections: [],
    ),
    SongStructurePreset(
      id: 'standard_pop',
      label: 'Standard pop',
      description: 'Radio-ready verse–chorus with bridge lift.',
      genreAffinity: [
        'Pop',
        'Dance Pop',
        'Electropop',
        'Indie Pop',
        'Synth Pop',
      ],
      complexity: PresetComplexity.moderate,
      sections: [
        _intro,
        _verse1,
        _chorus,
        _verse2,
        _chorus,
        _bridge,
        _finalChorus,
        _outro,
      ],
    ),
    SongStructurePreset(
      id: 'radio_edit',
      label: 'Radio edit',
      description: 'Aggressive 2-min hook-forward cut.',
      genreAffinity: [
        'Pop',
        'Dance Pop',
        'Electropop',
      ],
      complexity: PresetComplexity.simple,
      sections: [_verse1, _chorus, _verse2, _chorus, _outro],
    ),
    SongStructurePreset(
      id: 'pop_with_prechorus',
      label: 'Pop with pre-chorus lift',
      description: 'Max-Martin symmetry: tension release before every hook.',
      genreAffinity: [
        'Pop',
        'Pop / Max Martin',
        'Dance Pop',
        'K-Pop',
        'J-Pop',
      ],
      complexity: PresetComplexity.moderate,
      sections: [
        _intro,
        _verse1,
        _preChorus,
        _chorus,
        _verse2,
        _preChorus,
        _chorus,
        _bridge,
        _finalChorus,
        _outro,
      ],
    ),
    SongStructurePreset(
      id: 'edm_drop',
      label: 'EDM build & drop',
      description: 'Tension/rise/drop cycle with breakdown reset.',
      genreAffinity: [
        'EDM',
        'Progressive House',
        'Future Bass',
        'Big Room',
        'Trance',
        'Melodic Techno',
        'Electro House',
        'Festival EDM',
      ],
      complexity: PresetComplexity.moderate,
      sections: [
        _intro,
        _buildUp,
        _drop,
        _breakdown,
        _buildUp,
        _drop,
        _outro,
      ],
    ),
    SongStructurePreset(
      id: 'edm_verse_drop',
      label: 'EDM verse-to-drop',
      description: 'Verse-driven build into anthem drops.',
      genreAffinity: [
        'EDM',
        'Future Bass',
        'Melodic Dubstep',
      ],
      complexity: PresetComplexity.moderate,
      sections: [
        _intro,
        _verse1,
        _buildUp,
        _drop,
        _verse2,
        _buildUp,
        _drop,
        _finalDrop,
        _outro,
      ],
    ),
    SongStructurePreset(
      id: 'dnb_roller',
      label: 'Drum & bass roller',
      description: 'Continuous breakbeat energy with liquid breakdowns.',
      genreAffinity: [
        'DnB',
        'Drum & Bass',
        'Drum and Bass',
        'Jungle',
        'Liquid Funk',
        'Neurofunk',
      ],
      complexity: PresetComplexity.moderate,
      sections: [
        _intro,
        _verse1,
        _drop,
        _verse2,
        _drop,
        _breakdown,
        _buildUp,
        _finalDrop,
        _outro,
      ],
    ),
    SongStructurePreset(
      id: 'hardstyle_anthem',
      label: 'Hardstyle anthem',
      description: 'Mid-intro, reverse bass, euphoric climax, outro.',
      genreAffinity: [
        'Hardstyle',
        'Rawstyle',
        'Frenchcore',
        'Happy Hardcore',
      ],
      complexity: PresetComplexity.moderate,
      sections: [
        _intro,
        _buildUp,
        _drop,
        _breakdown,
        _buildUp,
        _mainDrop,
        _finalDrop,
        _outro,
      ],
    ),
    SongStructurePreset(
      id: 'amapiano',
      label: 'Amapiano',
      description: 'Log-drum groove with lazy verses and percussive lift.',
      genreAffinity: [
        'Amapiano',
        'Amapiano-Vinahouse',
        'Afro House',
        'Vinahouse',
      ],
      complexity: PresetComplexity.moderate,
      sections: [
        _intro,
        _verse1,
        _chorus,
        _verse2,
        _chorus,
        _breakdown,
        _chorus,
        _outro,
      ],
    ),
    SongStructurePreset(
      id: 'hiphop',
      label: 'Hip-hop',
      description: 'Verse-led with recurring hook anchor.',
      genreAffinity: [
        'Hip Hop',
        'Hip-Hop',
        'Boom Bap',
        'Trap',
        'Lo-Fi Hip Hop',
        'Underground Hip Hop',
      ],
      complexity: PresetComplexity.moderate,
      sections: [
        _intro,
        _verse1,
        _hook,
        _verse2,
        _hook,
        _bridge,
        _hook,
        _outro,
      ],
    ),
    SongStructurePreset(
      id: 'trap_banger',
      label: 'Trap banger',
      description: 'Hook-first with beat-switch energy lift.',
      genreAffinity: [
        'Trap',
        'Drill',
        'Phonk',
        'Cloud Rap',
      ],
      complexity: PresetComplexity.simple,
      sections: [
        _intro,
        _hook,
        _verse1,
        _hook,
        _verse2,
        _drop,
        _hook,
        _outro,
      ],
    ),
    SongStructurePreset(
      id: 'rnb_ballad',
      label: 'R&B / ballad',
      description: 'Romantic arc with pre-chorus tension.',
      genreAffinity: [
        'R&B/Soul',
        'Contemporary R&B',
        'Neo-Soul',
        'Neo Soul',
        'Trap Soul',
      ],
      complexity: PresetComplexity.moderate,
      sections: [
        _verse1,
        _preChorus,
        _chorus,
        _verse2,
        _chorus,
        _bridge,
        _finalChorus,
        _outro,
      ],
    ),
    SongStructurePreset(
      id: 'mandopop_ballad',
      label: 'Mandopop ballad',
      description: 'Piano-driven with emotional chorus lift.',
      genreAffinity: [
        'Mandopop',
        'C-Pop',
        'K-Pop',
      ],
      complexity: PresetComplexity.moderate,
      sections: [
        _intro,
        _verse1,
        _preChorus,
        _chorus,
        _verse2,
        _preChorus,
        _chorus,
        _bridge,
        _finalChorus,
        _outro,
      ],
    ),
    SongStructurePreset(
      id: 'reggaeton',
      label: 'Reggaeton / Latin',
      description: 'Dembow-driven verse-hook cycle with percussive breakdown.',
      genreAffinity: [
        'Reggaeton',
        'Dembow',
        'Bachata',
        'Latin Pop',
        'Salsa',
        'Cumbia',
        'Latin Trap',
      ],
      complexity: PresetComplexity.moderate,
      sections: [
        _intro,
        _verse1,
        _chorus,
        _verse2,
        _chorus,
        _breakdown,
        _chorus,
        _outro,
      ],
    ),
    SongStructurePreset(
      id: 'worship',
      label: 'Praise & Worship',
      description: 'Congregational arc with vamp + spontaneous flow.',
      genreAffinity: [
        'Gospel',
        'Praise/Worship',
        'Modern Worship',
        'Contemporary Gospel',
      ],
      complexity: PresetComplexity.complex,
      sections: [
        _intro,
        _verse1,
        _chorus,
        _verse2,
        _chorus,
        _bridge,
        _vamp,
        _spontaneousFlow,
        _finalChorus,
        _outro,
      ],
    ),
    SongStructurePreset(
      id: 'aaba',
      label: 'AABA (jazz / standards)',
      description: 'Classic 32-bar song-form with middle-eight contrast.',
      genreAffinity: [
        'Jazz/Blues',
        'Vocal Jazz',
        'Bebop',
        'Smooth Jazz',
        'Bossa Nova',
        'Latin Jazz',
      ],
      complexity: PresetComplexity.simple,
      sections: [
        SongSection(kind: SectionKind.verse, id: 'a1', label: 'A section'),
        SongSection(kind: SectionKind.verse, id: 'a2', label: 'A section'),
        SongSection(
          kind: SectionKind.bridge,
          id: 'b',
          label: 'B section (middle eight)',
        ),
        SongSection(
          kind: SectionKind.verse,
          id: 'a3',
          label: 'A section (return)',
        ),
      ],
    ),
    SongStructurePreset(
      id: 'verse_chorus_loop',
      label: 'Verse–chorus loop',
      description: 'Repeat cycle; optional short intro/outro.',
      genreAffinity: [
        'Folk',
        'Indie Folk',
        'Singer-Songwriter',
        'Americana',
        'Country',
      ],
      complexity: PresetComplexity.simple,
      sections: [
        _intro,
        _verse1,
        _chorus,
        _verse2,
        _chorus,
        _verse1,
        _chorus,
        _outro,
      ],
    ),
    SongStructurePreset(
      id: 'country_story',
      label: 'Country story song',
      description: 'Verse-driven narrative with lift chorus and solo bridge.',
      genreAffinity: [
        'Country',
        'Modern Country',
        'Americana',
        'Bluegrass',
        'Sertanejo',
      ],
      complexity: PresetComplexity.moderate,
      sections: [
        _intro,
        _verse1,
        _verse2,
        _chorus,
        _verse3,
        _chorus,
        _solo,
        _finalChorus,
        _outro,
      ],
    ),
    SongStructurePreset(
      id: 'rock_alt',
      label: 'Rock / alternative',
      description: 'Dynamic loud-quiet arc with bridge and final build.',
      genreAffinity: [
        'Rock',
        'Alt Rock',
        'Alternative',
        'Indie Rock',
        'Pop Punk',
        'Grunge',
        'Shoegaze',
        'Britpop',
      ],
      complexity: PresetComplexity.moderate,
      sections: [
        _intro,
        _verse1,
        _chorus,
        _verse2,
        _chorus,
        _bridge,
        _buildUp,
        _finalChorus,
        _outro,
      ],
    ),
    SongStructurePreset(
      id: 'funk_soul',
      label: 'Funk / soul',
      description: 'Groove verse, hook chorus, vamp outro.',
      genreAffinity: [
        'Funk',
        'Soul',
        'Motown',
        'P-Funk',
        'Gogo',
      ],
      complexity: PresetComplexity.moderate,
      sections: [
        _intro,
        _verse1,
        _chorus,
        _verse2,
        _chorus,
        _breakdown,
        _vamp,
        _chorus,
        _outro,
      ],
    ),
    SongStructurePreset(
      id: 'blues_shuffle',
      label: 'Blues shuffle',
      description: '12-bar cycles with solo and turnaround outro.',
      genreAffinity: [
        'Blues',
        'Delta Blues',
        'Chicago Blues',
        'Electric Blues',
        'Blues Rock',
      ],
      complexity: PresetComplexity.simple,
      sections: [
        _verse1,
        _verse2,
        _solo,
        _verse3,
        _finalChorus,
        _outro,
      ],
    ),
    SongStructurePreset(
      id: 'cinematic',
      label: 'Cinematic',
      description: 'Theme development → climax → coda.',
      genreAffinity: [
        'Cinematic',
        'Ambient',
        'Film Score',
        'Orchestral',
        'Trailer',
      ],
      complexity: PresetComplexity.complex,
      sections: [
        _intro,
        SongSection(kind: SectionKind.verse, id: 'themeA', label: 'Theme A'),
        SongSection(
          kind: SectionKind.interlude,
          id: 'development',
          label: 'Development',
        ),
        SongSection(kind: SectionKind.drop, id: 'climax', label: 'Climax'),
        SongSection(kind: SectionKind.outro, id: 'coda', label: 'Coda'),
      ],
    ),
    SongStructurePreset(
      id: 'reggae',
      label: 'Reggae / dancehall',
      description: 'One-drop groove with dub breakdown and chant hook.',
      genreAffinity: [
        'Reggae',
        'Dancehall',
        'Dub',
        'Ska',
        'Rocksteady',
      ],
      complexity: PresetComplexity.moderate,
      sections: [
        _intro,
        _verse1,
        _chorus,
        _verse2,
        _chorus,
        _breakdown,
        _hook,
        _chorus,
        _outro,
      ],
    ),
    SongStructurePreset(
      id: 'experimental',
      label: 'Experimental / electronic',
      description: 'Freeform arc with interludes and anti-climax moments.',
      genreAffinity: [
        'Experimental',
        'IDM',
        'Glitch',
        'Ambient',
        'Industrial',
        'Modular',
        'Noise',
      ],
      complexity: PresetComplexity.complex,
      sections: [
        _intro,
        _verse1,
        _interlude,
        _breakdown,
        _buildUp,
        _drop,
        _antiClimax,
        _interlude,
        _finalDrop,
        _outro,
      ],
    ),
  ];

  // ────────────────────────── Lookup caches ──────────────────────────

  static final Map<String, SongStructurePreset> _byId = {
    for (final p in presets) p.id: p,
  };

  static final Map<String, List<SongStructurePreset>> _byGenre =
      _buildGenreIndex();

  static Map<String, List<SongStructurePreset>> _buildGenreIndex() {
    final map = <String, List<SongStructurePreset>>{};
    for (final p in presets) {
      for (final g in p.genreAffinity) {
        final key = g.toLowerCase();
        map.putIfAbsent(key, () => <SongStructurePreset>[]).add(p);
      }
    }
    return {
      for (final e in map.entries)
        e.key: List<SongStructurePreset>.unmodifiable(e.value),
    };
  }

  // ────────────────────────── Public API ──────────────────────────

  static SongStructurePreset? presetById(String id) => _byId[id];

  /// All preset IDs.
  static List<String> get presetIds =>
      List.unmodifiable(presets.map((p) => p.id));

  /// Arrangement dropdown: user-authored options first, then genre presets.
  static List<SongStructurePreset> get arrangementDropdownPresets =>
      List.unmodifiable(presets);

  /// Presets whose [genreAffinity] contains [genre] (case-insensitive).
  static List<SongStructurePreset> presetsForGenre(String genre) {
    final needle = genre.trim().toLowerCase();
    if (needle.isEmpty) return const [];
    return List.unmodifiable(_byGenre[needle] ?? const []);
  }

  /// Filter presets by complexity tier.
  static List<SongStructurePreset> presetsForComplexity(
    PresetComplexity complexity,
  ) {
    return presets
        .where((p) => p.complexity == complexity)
        .toList(growable: false);
  }

  /// Returns true if a preset ID is known (including flexible/custom).
  static bool isKnownPresetId(String id) => _byId.containsKey(id);

  /// Canonical Suno section vocabulary gate (spec §1 cross-version rules).
  static bool isCanonicalSection(String label) {
    final n = label.toLowerCase().trim();
    if (n.isEmpty) return false;

    const banned = [
      'hook drop',
      'chorus drop',
      'beat drop',
      'pre-drop',
      'post-drop hook',
    ];
    if (banned.any(n.contains)) return false;

    if (n == 'end') return true;

    const allowed = [
      'intro',
      'verse',
      'pre-chorus',
      'chorus',
      'post-chorus',
      'bridge',
      'breakdown',
      'build-up',
      'build up',
      'drop',
      'drop a',
      'drop b',
      'main drop',
      'riser',
      'fill',
      'atmospheric break',
      'anti-climax',
      'anti climax',
      'final chorus',
      'final drop',
      'hook',
      'vamp',
      'spontaneous flow',
      'spontaneous worship',
      'instrumental interlude',
      'instrumental solo',
      'interlude',
      'outro',
      'theme a',
      'development',
      'climax',
      'coda',
      'a section',
      'b section',
      'head out',
      'head return',
      'middle eight',
      'mix-out',
      'dj loop-out',
      'mix-in',
      'beat-switch',
      'break',
      'dj scratch',
    ];
    return allowed.any((a) => n.startsWith(a) || n.contains(a));
  }

  /// Generates the structure-lock line for the LLM user block.
  static String userBlockDirective({
    required String presetId,
    required String customNotes,
    String sunoVersion = 'v5.5',
    String primaryGenre = '',
    String subGenreFusion = '',
    String? commercialLane,
    SongIntent intent = SongIntent.standard,
    bool includeDjIntro = false,
    bool includeDjOutro = false,
  }) {
    if (presetId == customId) {
      final trimmed = customNotes.trim();
      if (trimmed.isEmpty) {
        return _flexibleDirective(
          sunoVersion: sunoVersion,
          primaryGenre: primaryGenre,
          subGenreFusion: subGenreFusion,
          commercialLane: commercialLane,
          intent: intent,
          includeDjIntro: includeDjIntro,
          includeDjOutro: includeDjOutro,
        );
      }
      final hasBrackets = RegExp(r'\[[^\]]+\]').hasMatch(trimmed);
      final mode = hasBrackets
          ? 'use bracketed [Section: staging] headers in this exact order; '
              'expand staging notes freely, do not collapse to prose'
          : 'follow this section order exactly in prose; no reordering or skipping';
      return StructureAssembler.withDjStructureNote(
        'STRUCTURE_LOCK (MANDATORY — $mode): $trimmed',
        hasDjIntro: includeDjIntro,
        hasDjOutro: includeDjOutro,
      );
    }

    if (presetId.isEmpty || presetId == flexibleId) {
      return _flexibleDirective(
        sunoVersion: sunoVersion,
        primaryGenre: primaryGenre,
        subGenreFusion: subGenreFusion,
        commercialLane: commercialLane,
        intent: intent,
        includeDjIntro: includeDjIntro,
        includeDjOutro: includeDjOutro,
      );
    }

    final preset = presetById(presetId);
    if (preset == null || preset.sections.isEmpty) {
      return _flexibleDirective(
        sunoVersion: sunoVersion,
        primaryGenre: primaryGenre,
        subGenreFusion: subGenreFusion,
        commercialLane: commercialLane,
        intent: intent,
        includeDjIntro: includeDjIntro,
        includeDjOutro: includeDjOutro,
      );
    }
    return StructureAssembler.withDjStructureNote(
      'STRUCTURE_LOCK (MANDATORY — ${preset.label}): ${preset.canonicalRoadmap}',
      hasDjIntro: includeDjIntro,
      hasDjOutro: includeDjOutro,
    );
  }

  static String _flexibleDirective({
    required String sunoVersion,
    required String primaryGenre,
    required String subGenreFusion,
    String? commercialLane,
    SongIntent intent = SongIntent.standard,
    bool includeDjIntro = false,
    bool includeDjOutro = false,
  }) {
    final family = StructuralFamilyResolver.resolve(
      primaryGenre: primaryGenre,
      fusionGenre: subGenreFusion,
      commercialLane: commercialLane,
    );
    var resolvedIntent = intent;
    if (family == StructuralFamily.worship &&
        resolvedIntent == SongIntent.standard) {
      resolvedIntent = SongIntent.congregational;
    }
    final sections = StructureAssembler.assembleByFamily(
      family: family,
      opts: ScaffoldOptions(
        sunoVersion: sunoVersion,
        primaryGenre: primaryGenre,
        intent: resolvedIntent,
        includeDjIntro: includeDjIntro,
        includeDjOutro: includeDjOutro,
        targetBars: null,
      ),
    );
    if (sections.isEmpty) {
      return 'STRUCTURE_LOCK (FLEXIBLE): choose one coherent arc; describe '
          'intro → outro in chronological order; no contradictions.';
    }

    final roadmap = StructureAssembler.canonicalRoadmap(sections);
    final brackets = SunoSyntaxRenderer.renderSections(
      sections,
      sunoVersion,
      family: family,
    );
    final mutation = FinalChorusMutationRule.directiveFor(
      mutation: FinalChorusMutationRule.mutationFor(family),
      sunoVersion: sunoVersion,
    );
    return StructureAssembler.withDjStructureNote(
      'STRUCTURE_LOCK (MANDATORY — assembled arc): $roadmap\n'
      '$mutation\n'
      'Bracket roadmap:\n$brackets',
      hasDjIntro: includeDjIntro,
      hasDjOutro: includeDjOutro,
    );
  }
}
