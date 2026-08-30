import '../constants/song_structure_data.dart';
import 'structural_family_resolver.dart';

export 'final_chorus_mutation_rule.dart';
export 'structural_family_resolver.dart';

/// Modifies optional worship/amapiano module gates.
enum SongIntent { standard, congregational, complex }

/// Inputs for a single structural scaffold build.
class ScaffoldOptions {
  const ScaffoldOptions({
    required this.sunoVersion,
    required this.primaryGenre,
    required this.intent,
    required this.includeDjIntro,
    required this.includeDjOutro,
    required this.targetBars,
  });

  final String sunoVersion;
  final String primaryGenre;
  final SongIntent intent;
  final bool includeDjIntro;
  final bool includeDjOutro;
  final int? targetBars;
}

/// Short alias for readable section-list literals.
class SectionLine extends SongSection {
  SectionLine(SectionKind kind, String label, {super.stagingNote})
      : super(
          kind: kind,
          id: _idFromLabel(label),
          label: label,
        );

  static String _idFromLabel(String label) =>
      label
          .toLowerCase()
          .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
          .replaceAll(RegExp(r'^_|_$'), '');
}

/// Assembles structurally-valid song arcs (genre × version × intent).
class StructureAssembler {
  StructureAssembler._();

  static List<SongSection>? assemble({
    required String sunoVersion,
    String? primaryGenre,
    String? fusionGenre,
    String? commercialLane,
    SongIntent intent = SongIntent.standard,
    bool includeDjIntro = false,
    bool includeDjOutro = false,
    int? targetBars,
  }) {
    final family = StructuralFamilyResolver.resolve(
      primaryGenre: primaryGenre,
      fusionGenre: fusionGenre,
      commercialLane: commercialLane,
    );
    var resolvedIntent = intent;
    if (family == StructuralFamily.worship &&
        resolvedIntent == SongIntent.standard) {
      resolvedIntent = SongIntent.congregational;
    }
    return assembleByFamily(
      family: family,
      opts: ScaffoldOptions(
        sunoVersion: sunoVersion,
        primaryGenre: primaryGenre ?? '',
        intent: resolvedIntent,
        includeDjIntro: includeDjIntro,
        includeDjOutro: includeDjOutro,
        targetBars: targetBars,
      ),
    );
  }

  /// Typed assembly entry for a resolved [StructuralFamily].
  static List<SongSection> assembleByFamily({
    required StructuralFamily family,
    required ScaffoldOptions opts,
  }) {
    final builder = _builders[family]!;
    final raw = builder(opts);
    return _applyDjIntro(raw, opts.includeDjIntro);
  }

  static String canonicalRoadmap(List<SongSection> sections) =>
      sections.map((s) => s.label).join(' → ');

  /// Prepends a note linking [Intro]/[Outro] tags to the DJ Production Brief.
  static String withDjStructureNote(
    String structureString, {
    required bool hasDjIntro,
    required bool hasDjOutro,
  }) {
    if (!hasDjIntro && !hasDjOutro) return structureString;
    return '(Note: The [Intro] and [Outro] tags in this structure refer to the '
        'DJ-friendly rhythmic sections defined in the Production Requirement block. '
        'They are NOT standard musical intros/outros.) $structureString';
  }

  /// Legacy helper — prefer [SunoSyntaxRenderer.renderSections].
  static List<String> toSunoBrackets(
    List<SongSection> sections, {
    required String sunoVersion,
  }) {
    final v55 = sunoVersion.trim().toLowerCase().startsWith('v5.5');
    return sections.map((s) => s.toSunoBracket(v5_5: v55)).toList();
  }

  static List<SongSection> _applyDjIntro(
    List<SongSection> raw,
    bool includeDjIntro,
  ) {
    if (!includeDjIntro || raw.isEmpty) return raw;
    final out = <SongSection>[];
    for (var i = 0; i < raw.length; i++) {
      final s = raw[i];
      if (i == 0 &&
          s.kind == SectionKind.intro &&
          !s.label.contains('mix-in')) {
        out.add(SectionLine(SectionKind.intro, 'Intro — DJ mix-in'));
      } else {
        out.add(s);
      }
    }
    return out;
  }

  static const Map<
      StructuralFamily,
      List<SongSection> Function(ScaffoldOptions)> _builders = {
    StructuralFamily.popStandard: _buildPopStandard,
    StructuralFamily.popRadio: _buildPopRadio,
    StructuralFamily.edmProgressiveHouse: _buildEdmProgressiveHouse,
    StructuralFamily.edmTrance: _buildEdmTrance,
    StructuralFamily.edmTechno: _buildEdmTechno,
    StructuralFamily.edmHardstyle: _buildEdmHardstyle,
    StructuralFamily.edmDrumAndBass: _buildEdmDrumAndBass,
    StructuralFamily.edmBigRoom: _buildEdmBigRoom,
    StructuralFamily.hiphop: _buildHipHop,
    StructuralFamily.worship: _buildWorship,
    StructuralFamily.amapiano: _buildAmapiano,
    StructuralFamily.cinematic: _buildCinematic,
    StructuralFamily.folk: _buildFolk,
    StructuralFamily.jazzStandard: _buildJazzStandard,
    StructuralFamily.mandopop: _buildMandopop,
    StructuralFamily.trap: _buildTrap,
    StructuralFamily.boom_bap: _buildBoomBap,
  };

  static List<SongSection> _buildPopStandard(ScaffoldOptions o) => [
        SectionLine(SectionKind.intro, 'Intro'),
        SectionLine(SectionKind.verse, 'Verse 1'),
        SectionLine(SectionKind.preChorus, 'Pre-Chorus'),
        SectionLine(SectionKind.chorus, 'Chorus'),
        SectionLine(SectionKind.verse, 'Verse 2'),
        SectionLine(SectionKind.preChorus, 'Pre-Chorus'),
        SectionLine(SectionKind.chorus, 'Chorus'),
        SectionLine(SectionKind.bridge, 'Bridge'),
        SectionLine(SectionKind.finalChorus, 'Final Chorus'),
        if (o.includeDjOutro)
          SectionLine(SectionKind.outro, 'Outro — mix-out')
        else
          SectionLine(SectionKind.outro, 'Outro'),
        SectionLine(SectionKind.end, 'End'),
      ];

  static List<SongSection> _buildPopRadio(ScaffoldOptions o) => [
        SectionLine(SectionKind.verse, 'Verse 1'),
        SectionLine(SectionKind.chorus, 'Chorus'),
        SectionLine(SectionKind.verse, 'Verse 2'),
        SectionLine(SectionKind.chorus, 'Chorus'),
        if (o.includeDjOutro)
          SectionLine(SectionKind.outro, 'Outro — mix-out')
        else
          SectionLine(SectionKind.outro, 'Outro'),
        SectionLine(SectionKind.end, 'End'),
      ];

  static List<SongSection> _buildEdmProgressiveHouse(ScaffoldOptions o) => [
        SectionLine(SectionKind.intro, 'Intro'),
        SectionLine(SectionKind.verse, 'Verse'),
        SectionLine(SectionKind.buildUp, 'Build-up'),
        SectionLine(SectionKind.dropA, 'Drop A'),
        SectionLine(SectionKind.breakdown, 'Breakdown'),
        SectionLine(SectionKind.buildUp, 'Build-up 2'),
        SectionLine(SectionKind.dropB, 'Drop B'),
        if (o.includeDjOutro)
          SectionLine(SectionKind.outro, 'Outro — DJ loop-out')
        else
          SectionLine(SectionKind.outro, 'Outro'),
        SectionLine(SectionKind.end, 'End'),
      ];

  static List<SongSection> _buildEdmTrance(ScaffoldOptions o) => [
        SectionLine(SectionKind.intro, 'Intro'),
        SectionLine(SectionKind.buildUp, 'Build-up'),
        SectionLine(SectionKind.dropA, 'Drop A'),
        SectionLine(SectionKind.atmosphericBreak, 'Atmospheric Break'),
        SectionLine(
          SectionKind.buildUp,
          'Build-up 2',
          stagingNote: 'euphoric riser',
        ),
        SectionLine(SectionKind.finalDrop, 'Final Drop'),
        if (o.includeDjOutro)
          SectionLine(SectionKind.outro, 'Outro — DJ loop-out')
        else
          SectionLine(SectionKind.outro, 'Outro'),
        SectionLine(SectionKind.end, 'End'),
      ];

  static List<SongSection> _buildEdmTechno(ScaffoldOptions o) => [
        SectionLine(SectionKind.intro, 'Intro'),
        SectionLine(SectionKind.buildUp, 'Build-up'),
        SectionLine(SectionKind.mainDrop, 'Main Drop'),
        SectionLine(SectionKind.breakdown, 'Breakdown'),
        SectionLine(SectionKind.buildUp, 'Build-up 2'),
        SectionLine(SectionKind.mainDrop, 'Main Drop 2'),
        if (o.includeDjOutro)
          SectionLine(SectionKind.outro, 'Outro — DJ loop-out')
        else
          SectionLine(SectionKind.outro, 'Outro'),
        SectionLine(SectionKind.end, 'End'),
      ];

  static List<SongSection> _buildEdmHardstyle(ScaffoldOptions o) => [
        SectionLine(SectionKind.intro, 'Intro'),
        SectionLine(SectionKind.buildUp, 'Build-up'),
        SectionLine(SectionKind.antiClimax, 'Anti-Climax'),
        SectionLine(
          SectionKind.mainDrop,
          'Main Drop',
          stagingNote: 'distorted hardstyle kick',
        ),
        SectionLine(
          SectionKind.breakdown,
          'Breakdown',
          stagingNote: 'melodic synth lead',
        ),
        SectionLine(SectionKind.finalDrop, 'Final Drop'),
        if (o.includeDjOutro)
          SectionLine(SectionKind.outro, 'Outro — DJ loop-out')
        else
          SectionLine(SectionKind.outro, 'Outro'),
        SectionLine(SectionKind.end, 'End'),
      ];

  static List<SongSection> _buildEdmDrumAndBass(ScaffoldOptions o) => [
        SectionLine(SectionKind.intro, 'Intro'),
        SectionLine(SectionKind.buildUp, 'Build-up'),
        SectionLine(SectionKind.dropA, 'Drop A'),
        SectionLine(SectionKind.breakdown, 'Breakdown'),
        SectionLine(SectionKind.buildUp, 'Build-up 2'),
        SectionLine(SectionKind.finalDrop, 'Final Drop'),
        if (o.includeDjOutro)
          SectionLine(SectionKind.outro, 'Outro — DJ loop-out')
        else
          SectionLine(SectionKind.outro, 'Outro'),
        SectionLine(SectionKind.end, 'End'),
      ];

  static List<SongSection> _buildEdmBigRoom(ScaffoldOptions o) => [
        SectionLine(SectionKind.intro, 'Intro'),
        SectionLine(SectionKind.buildUp, 'Build-up'),
        SectionLine(SectionKind.mainDrop, 'Main Drop'),
        SectionLine(SectionKind.breakdown, 'Breakdown'),
        SectionLine(SectionKind.riser, 'Riser'),
        SectionLine(SectionKind.finalDrop, 'Final Drop'),
        if (o.includeDjOutro)
          SectionLine(SectionKind.outro, 'Outro — DJ loop-out')
        else
          SectionLine(SectionKind.outro, 'Outro'),
        SectionLine(SectionKind.end, 'End'),
      ];

  static List<SongSection> _buildHipHop(ScaffoldOptions o) => [
        SectionLine(SectionKind.intro, 'Intro'),
        SectionLine(SectionKind.verse, 'Verse 1'),
        SectionLine(SectionKind.hook, 'Hook'),
        SectionLine(SectionKind.verse, 'Verse 2'),
        SectionLine(SectionKind.hook, 'Hook'),
        SectionLine(SectionKind.bridge, 'Bridge'),
        SectionLine(SectionKind.hook, 'Hook'),
        SectionLine(SectionKind.outro, 'Outro'),
        SectionLine(SectionKind.end, 'End'),
      ];

  static List<SongSection> _buildWorship(ScaffoldOptions o) => [
        SectionLine(SectionKind.intro, 'Intro'),
        SectionLine(SectionKind.verse, 'Verse 1'),
        SectionLine(SectionKind.chorus, 'Chorus'),
        SectionLine(SectionKind.verse, 'Verse 2'),
        SectionLine(SectionKind.chorus, 'Chorus'),
        SectionLine(SectionKind.bridge, 'Bridge'),
        if (o.intent == SongIntent.congregational) ...[
          SectionLine(SectionKind.vamp, 'Vamp'),
          SectionLine(
            SectionKind.spontaneousFlow,
            'Spontaneous Worship / Flow',
          ),
        ],
        SectionLine(SectionKind.finalChorus, 'Final Chorus'),
        SectionLine(SectionKind.outro, 'Outro'),
        SectionLine(SectionKind.end, 'End'),
      ];

  static List<SongSection> _buildAmapiano(ScaffoldOptions o) => [
        SectionLine(SectionKind.intro, 'Intro'),
        SectionLine(SectionKind.verse, 'Verse 1'),
        SectionLine(SectionKind.chorus, 'Chorus'),
        SectionLine(SectionKind.verse, 'Verse 2'),
        if (o.intent == SongIntent.complex)
          SectionLine(SectionKind.bridge, 'Bridge'),
        SectionLine(SectionKind.chorus, 'Chorus'),
        SectionLine(SectionKind.breakdown, 'Breakdown'),
        SectionLine(SectionKind.finalChorus, 'Final Chorus'),
        SectionLine(SectionKind.outro, 'Outro'),
        SectionLine(SectionKind.end, 'End'),
      ];

  static List<SongSection> _buildCinematic(ScaffoldOptions o) => [
        SectionLine(SectionKind.intro, 'Intro'),
        SectionLine(SectionKind.verse, 'Theme A'),
        SectionLine(SectionKind.interlude, 'Development'),
        SectionLine(SectionKind.drop, 'Climax'),
        SectionLine(SectionKind.outro, 'Coda'),
        SectionLine(SectionKind.end, 'End'),
      ];

  static List<SongSection> _buildFolk(ScaffoldOptions o) => [
        SectionLine(SectionKind.intro, 'Intro'),
        SectionLine(SectionKind.verse, 'Verse 1'),
        SectionLine(SectionKind.chorus, 'Chorus'),
        SectionLine(SectionKind.interlude, 'Instrumental Interlude'),
        SectionLine(SectionKind.verse, 'Verse 2'),
        SectionLine(SectionKind.chorus, 'Chorus'),
        SectionLine(SectionKind.bridge, 'Bridge'),
        SectionLine(SectionKind.finalChorus, 'Final Chorus'),
        SectionLine(SectionKind.outro, 'Outro'),
        SectionLine(SectionKind.end, 'End'),
      ];

  static List<SongSection> _buildJazzStandard(ScaffoldOptions o) => [
        SectionLine(SectionKind.verse, 'A Section (Head)'),
        SectionLine(SectionKind.verse, 'A Section'),
        SectionLine(SectionKind.bridge, 'B Section (Middle Eight)'),
        SectionLine(SectionKind.verse, 'A Section (Head Return)'),
        SectionLine(SectionKind.solo, 'Instrumental Solo'),
        SectionLine(SectionKind.outro, 'Head Out'),
        SectionLine(SectionKind.end, 'End'),
      ];

  static List<SongSection> _buildMandopop(ScaffoldOptions o) => [
        SectionLine(SectionKind.intro, 'Intro'),
        SectionLine(SectionKind.verse, 'Verse 1'),
        SectionLine(SectionKind.preChorus, 'Pre-Chorus'),
        SectionLine(SectionKind.chorus, 'Chorus'),
        SectionLine(SectionKind.verse, 'Verse 2'),
        SectionLine(SectionKind.preChorus, 'Pre-Chorus'),
        SectionLine(SectionKind.chorus, 'Chorus'),
        SectionLine(SectionKind.bridge, 'Bridge'),
        SectionLine(SectionKind.finalChorus, 'Final Chorus'),
        SectionLine(SectionKind.outro, 'Outro'),
        SectionLine(SectionKind.end, 'End'),
      ];

  // boom_bap: SectionKind.hook + label "Chorus" — classic 90s form vocabulary;
  // SunoSyntaxRenderer also overrides hook → Chorus at render time for safety.
  static List<SongSection> _buildBoomBap(ScaffoldOptions o) => [
        SectionLine(SectionKind.intro, 'Intro'),
        SectionLine(SectionKind.verse, 'Verse 1'),
        SectionLine(SectionKind.hook, 'Chorus'),
        SectionLine(SectionKind.verse, 'Verse 2'),
        SectionLine(SectionKind.hook, 'Chorus'),
        SectionLine(SectionKind.interlude, 'Break'),
        SectionLine(SectionKind.hook, 'Chorus'),
        SectionLine(SectionKind.outro, 'Outro (ad-lib fade)'),
        SectionLine(SectionKind.end, 'End'),
      ];

  static List<SongSection> _buildTrap(ScaffoldOptions o) => [
        SectionLine(SectionKind.intro, 'Intro'),
        SectionLine(SectionKind.hook, 'Hook'),
        SectionLine(SectionKind.verse, 'Verse 1'),
        SectionLine(SectionKind.hook, 'Hook'),
        SectionLine(SectionKind.verse, 'Verse 2'),
        SectionLine(SectionKind.bridge, 'Bridge (beat-switch)'),
        SectionLine(SectionKind.hook, 'Hook'),
        SectionLine(SectionKind.outro, 'Outro'),
        SectionLine(SectionKind.end, 'End'),
      ];
}
