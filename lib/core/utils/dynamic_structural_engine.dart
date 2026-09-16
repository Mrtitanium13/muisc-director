import '../constants/song_structure_data.dart';
import '../constants/suno_version.dart';
import 'density_budget_enforcer.dart';
import 'structure_assembler.dart';
import 'suno_syntax_renderer.dart';

export 'genre_structural_profile.dart';
export 'density_budget_enforcer.dart';
export 'final_chorus_mutation_rule.dart';
export 'structural_family_resolver.dart';
export 'structure_assembler.dart';
export 'suno_syntax_renderer.dart';

/// Dynamic Structural Engine — genre-pruned Block 2 section assembly (Suno-optimized).
///
/// Pipeline: resolve family → assemble typed [SongSection] list → render brackets
/// → enforce density budget → emit deterministic directive string.
abstract final class DynamicStructuralEngine {
  DynamicStructuralEngine._();

  /// Max fraction of Block 2 char budget for bracket headers (≥70% for lyrics).
  static const double structuralDensityCap = 0.30;

  static const int sunoLyricsFieldCap = 2500;

  static int get structuralPreambleCap =>
      (sunoLyricsFieldCap * structuralDensityCap).floor();

  /// Backwards-compatible facade for prompt assemblers.
  static String userBlockDirective({
    String primaryGenre = '',
    String subGenreFusion = '',
    String sunoVersion = SunoVersion.preferredValue,
    List<SongSection>? userProvidedSections,
    String? commercialLane,
    SongIntent intent = SongIntent.standard,
    bool includeDjIntro = false,
    bool includeDjOutro = false,
  }) {
    if (userProvidedSections != null && userProvidedSections.isNotEmpty) {
      final userRendered = SunoSyntaxRenderer.renderSections(
        userProvidedSections,
        sunoVersion,
      );
      return _emitDirective(
        sunoVersion: sunoVersion,
        profile: 'user_defined',
        roadmap: '[USER-DEFINED ROADMAP]',
        renderedSections: userRendered,
      );
    }

    final family = StructuralFamilyResolver.resolve(
      primaryGenre: primaryGenre,
      fusionGenre: subGenreFusion,
      commercialLane: commercialLane,
    );

    final sections = assembleSections(
      family: family,
      sunoVersion: sunoVersion,
      intent: intent,
      includeDjIntro: includeDjIntro,
      includeDjOutro: includeDjOutro,
    );

    final rendered = SunoSyntaxRenderer.renderSections(
      sections,
      sunoVersion,
      family: family,
    );

    final hasFinalMutation = sections.any(
      (s) =>
          s.kind == SectionKind.finalChorus || s.kind == SectionKind.finalDrop,
    );
    final mutation = FinalChorusMutationRule.mutationFor(family);
    final mutationHint = hasFinalMutation
        ? FinalChorusMutationRule.directiveFor(
            mutation: mutation,
            sunoVersion: sunoVersion,
          )
        : '';

    const renderMarker = '<<RENDERED>>';
    final profileLabel = _profileLabel(family);
    final headerShell = _emitDirective(
      sunoVersion: sunoVersion,
      profile: profileLabel,
      roadmap: _roadmapString(sections),
      renderedSections: renderMarker,
      mutationHint: mutationHint,
      folkNoDrop: family == StructuralFamily.folk,
    );
    final preambleBudget = structuralPreambleCap;
    final preambleShell = headerShell.split('SHIP GATE').first;
    final overhead = preambleShell.length - renderMarker.length;

    var roadmap = _roadmapString(sections);
    var effectiveMutationHint = mutationHint;
    var renderCap = (preambleBudget - overhead).clamp(0, preambleBudget);
    var pruned = '';
    var candidate = '';
    var preambleLen = preambleBudget + 1;

    for (var pass = 0; pass < 24 && preambleLen > preambleBudget; pass++) {
      pruned = DensityBudgetEnforcer.enforce(
        renderedSections: rendered,
        cap: renderCap,
        sunoVersion: sunoVersion,
      );
      candidate = _emitDirective(
        sunoVersion: sunoVersion,
        profile: profileLabel,
        roadmap: roadmap,
        renderedSections: pruned,
        mutationHint: effectiveMutationHint,
        folkNoDrop: family == StructuralFamily.folk,
      );
      preambleLen = _preambleLength(candidate);
      if (preambleLen <= preambleBudget) return candidate;

      if (renderCap > 0) {
        renderCap =
            (renderCap - (preambleLen - preambleBudget)).clamp(0, renderCap);
        continue;
      }
      if (effectiveMutationHint.isNotEmpty) {
        effectiveMutationHint = '';
        continue;
      }
      if (!roadmap.contains('...')) {
        roadmap = _abbreviatedRoadmap(sections);
        continue;
      }
      if (!roadmap.contains('-section arc')) {
        roadmap = '${sections.length}-section arc';
        continue;
      }
    }

    return candidate;
  }

  /// Typed assembly entry for tests and UI preview panels.
  static List<SongSection> assembleSections({
    required StructuralFamily family,
    String sunoVersion = SunoVersion.preferredValue,
    SongIntent intent = SongIntent.standard,
    bool includeDjIntro = false,
    bool includeDjOutro = false,
  }) {
    var resolvedIntent = intent;
    if (family == StructuralFamily.worship &&
        resolvedIntent == SongIntent.standard) {
      resolvedIntent = SongIntent.congregational;
    }
    return StructureAssembler.assembleByFamily(
      family: family,
      opts: ScaffoldOptions(
        sunoVersion: sunoVersion,
        primaryGenre: '',
        intent: resolvedIntent,
        includeDjIntro: includeDjIntro,
        includeDjOutro: includeDjOutro,
        targetBars: null,
      ),
    );
  }

  static int _preambleLength(String directive) {
    final parts = directive.split('SHIP GATE');
    return parts.isEmpty ? 0 : parts.first.length;
  }

  static String _emitDirective({
    required String sunoVersion,
    required String profile,
    required String roadmap,
    required String renderedSections,
    String mutationHint = '',
    bool folkNoDrop = false,
  }) {
    final v = SunoVersion.densityKeyFor(sunoVersion);
    final maxArc = v == 'v5.5'
        ? 'v5.5_max_arc=true (full ~4-min single-pass allowed)'
        : 'v5.5_max_arc=false';
    final syntax = SunoSyntaxRenderer.syntaxDocBlock(sunoVersion);
    final folkNote = folkNoDrop ? ' — STRICTLY NO [Drop] modules.' : '';
    final mutationBlock = mutationHint.isEmpty ? '' : '$mutationHint\n';
    return '''DYNAMIC STRUCTURAL ENGINE (Block 2 — assembled & pruned, never static):
$syntax
$maxArc
Resolved structural family: $profile
Section roadmap: $roadmap$folkNote
RENDERED BRACKET LAYOUT (use these exact bracket lines, in this order):
$renderedSections
${mutationBlock}SHIP GATE: output ONLY the structure + performable lyrics through [End]. No meta-commentary. No DAW jargon. No nested brackets. Vocal/phonetic cues go in (parentheses) only. Structure/staging goes in [brackets] only.'''
        .trim();
  }

  static String _roadmapString(List<SongSection> sections) =>
      sections.map((s) => s.label).join(' → ');

  static String _profileLabel(StructuralFamily family) =>
      StructuralFamilyResolver.laneHintFor(family)
          .toLowerCase()
          .replaceAll(' ', '_')
          .replaceAll('/', '_');

  static String _abbreviatedRoadmap(List<SongSection> sections) {
    if (sections.length <= 4) return _roadmapString(sections);
    return '${sections.first.label} → ... (${sections.length} sections) → ${sections.last.label}';
  }
}
