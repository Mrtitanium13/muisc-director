import '../constants/song_structure_data.dart';
import 'final_chorus_mutation_rule.dart';
import 'structural_family_resolver.dart';
import 'suno_sonic_lexicon.dart';
import 'genre_structural_profile.dart';

/// Version-dispatched Suno bracket renderer.
class SunoSyntaxRenderer {
  SunoSyntaxRenderer._();

  static const int v55StagingCap = 60;
  static const int v5StagingCap = 30;

  static String renderSections(
    List<SongSection> sections,
    String sunoVersion, {
    StructuralFamily? family,
  }) {
    final v = sunoVersion.trim().toLowerCase();
    return sections
        .asMap()
        .entries
        .map(
          (e) => _renderSection(
            e.value,
            v,
            family: family,
            sectionIndex: e.key,
            allSections: sections,
          ),
        )
        .join('\n');
  }

  /// Public single-section render entry for tests and UI preview.
  static String renderSection(
    SongSection s,
    String sunoVersion, {
    StructuralFamily? family,
    int sectionIndex = 0,
    List<SongSection>? allSections,
  }) {
    final v = sunoVersion.trim().toLowerCase();
    return _renderSection(
      s,
      v,
      family: family,
      sectionIndex: sectionIndex,
      allSections: allSections,
    );
  }

  static String _renderSection(
    SongSection s,
    String version, {
    StructuralFamily? family,
    int sectionIndex = 0,
    List<SongSection>? allSections,
  }) {
    if (s.kind == SectionKind.end) return '[End]';

    final sections = allSections ?? [s];
    final ctx = _stagingContext(sections, sectionIndex, s);
    final label = GenreStructuralProfile.displayLabel(s, family);

    if ((s.kind == SectionKind.finalChorus ||
            s.kind == SectionKind.finalDrop) &&
        family != null) {
      final mutation = FinalChorusMutationRule.mutationFor(family);
      final staging = FinalChorusMutationRule.directiveFor(
        mutation: mutation,
        sunoVersion: version,
        inline: true,
      );
      return _applyVersionRules(
        label: label,
        staging: staging.isEmpty
            ? GenreStructuralProfile.defaultStaging(family, ctx)
            : staging,
        version: version,
      );
    }

    return _applyVersionRules(
      label: label,
      staging:
          s.stagingNote ?? GenreStructuralProfile.defaultStaging(family, ctx),
      version: version,
    );
  }

  static StagingContext _stagingContext(
    List<SongSection> sections,
    int sectionIndex,
    SongSection s,
  ) {
    final slice = sections.take(sectionIndex + 1);
    return StagingContext(
      kind: s.kind,
      label: s.label,
      verseOrdinal: slice.where((x) => x.kind == SectionKind.verse).length,
      hookOrdinal: slice.where((x) => x.kind == SectionKind.hook).length,
      chorusOrdinal: slice.where((x) => x.kind == SectionKind.chorus).length,
      dropOrdinal: slice
          .where(
            (x) =>
                x.kind == SectionKind.drop ||
                x.kind == SectionKind.dropA ||
                x.kind == SectionKind.dropB ||
                x.kind == SectionKind.mainDrop ||
                x.kind == SectionKind.finalDrop,
          )
          .length,
      buildUpOrdinal: slice.where((x) => x.kind == SectionKind.buildUp).length,
    );
  }

  static String _applyVersionRules({
    required String label,
    required String staging,
    required String version,
  }) {
    final reformulated = SunoStagingReformulator.reformulate(staging);
    if (reformulated.isEmpty) return '[$label]';
    final v = version.toLowerCase();

    if (v == 'v4.5') return '[$label]';
    if (v.startsWith('v5.5')) {
      final clean = _capStaging(_sanitiseStaging(reformulated), v55StagingCap);
      return clean.isEmpty ? '[$label]' : '[$label: $clean]';
    }
    final firstDescriptor = reformulated.split(',').first.trim();
    final clean = _capStaging(_sanitiseStaging(firstDescriptor), v5StagingCap);
    return clean.isEmpty ? '[$label]' : '[$label: $clean]';
  }

  static String _capStaging(String staging, int maxChars) {
    if (staging.length <= maxChars) return staging;
    var trimmed = staging;
    while (trimmed.length > maxChars && trimmed.contains(',')) {
      trimmed = trimmed.substring(0, trimmed.lastIndexOf(',')).trim();
    }
    if (trimmed.length > maxChars) {
      trimmed = trimmed.substring(0, maxChars).trim();
    }
    return trimmed;
  }

  static String _sanitiseStaging(String s) {
    const banned = [
      'eq',
      'compression',
      'bus routing',
      'sidechain',
      'mastering',
      'limiter',
      'automation',
      'daw',
      'plugin',
      'vst',
    ];
    var out = s;
    for (final b in banned) {
      out = out.replaceAll(RegExp(b, caseSensitive: false), '').trim();
    }
    return out
        .replaceAll(RegExp(r',\s*,'), ',')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static String syntaxDocBlock(String sunoVersion) {
    final v = sunoVersion.trim().toLowerCase();
    if (v == 'v4.5') {
      return 'v4.5 syntax: [Brackets] = section names ONLY (1–2 words). '
          '(Parentheses) = vocal delivery 1–3 words. '
          'NO production cues in brackets — Block 1 prose only.';
    }
    if (v.startsWith('v5.5')) {
      return 'v5.5 PRO syntax (preferred): [Brackets] = cinematic director\'s notes '
          '(multi-descriptor). (Parentheses) = granular vocal/phonetic cues including '
          '(sigh), (chuckles), (trailing off...). Cross-rules: no nested brackets; '
          'no DAW jargon in brackets; always [End].';
    }
    return 'v5 syntax: [Brackets] = section + ONE staging descriptor. '
        '(Parentheses) = vocal cues + phonetics + brief ad-libs. '
        'Cross-rules: no nested brackets; no mix notes in parens; always [End].';
  }

  /// Returns section labels that fail canonical vocabulary check.
  static List<String> validateCanonical(List<SongSection> sections) {
    return sections
        .where((s) => !SongStructureData.isCanonicalSection(s.label))
        .map((s) => s.label)
        .toList();
  }
}
