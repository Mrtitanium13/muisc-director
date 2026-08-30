/// Dual-genre split-DNA routing — GENRE HYBRIDIZATION & CULTURAL ROUTING MATRIX PART 1.
class GenreHybridizationMatrix {
  GenreHybridizationMatrix._();

  static bool fusionActive(String fusion) {
    final f = fusion.trim().toLowerCase();
    if (f.isEmpty) return false;
    return f != 'none' && f != 'n/a' && f != 'na' && f != '-' && f != '—';
  }

  static bool _fusionActive(String fusion) => fusionActive(fusion);

  /// Injects dominant/subordinate roles when Primary + Fusion are both set.
  static String userBlockDirective({
    required String primaryGenre,
    String subGenreFusion = '',
  }) {
    final primary = primaryGenre.trim();
    final fusion = subGenreFusion.trim();
    if (primary.isEmpty || !_fusionActive(fusion)) return '';

    return [
      'GENRE HYBRIDIZATION & CULTURAL ROUTING MATRIX — PART 1 (Split-DNA; _fusionActive=true):',
      'Genre A DOMINANT primaryGenre=$primary: global BPM, drum grid, structural block tags, '
          'line symmetry, main climax grid (Section II + Section IV).',
      'Genre B SUBORDINATE subGenreFusion=$fusion: signature instruments, vocal texture, '
          'dialect/patois, regional vocabulary — Intro, Verse 1, Breakdown only.',
      'Subordinate tag accent rule: name Genre B texture exactly once in Intro OR Verse 1 — '
          'never repeat in later sections.',
      'Hybridization drop rule: at [The Release], [Main Climax], [Drop], or peak chorus, '
          'sidechain/filter/delay/loop-mutate subordinate organic elements into Genre A kick grid — '
          'never raw acoustic competing with electronic climax.',
      'Amapiano primary exception: log drum = FM synthesized bass — never live/acoustic/organic.',
      'Lyric imagery: apply PART 2 Anti-Repetition + Regional Daily Life matrix for West African lanes.',
      'Full law: SUNO V4 Master Production Architecture Layer 3 + GENRE HUMANIZATION ENGINE § SECTION V.',
    ].join('\n');
  }
}
