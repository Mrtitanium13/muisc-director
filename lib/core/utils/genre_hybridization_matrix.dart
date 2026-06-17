/// Dual-genre split-DNA routing — SUNO V4 §1 Layer 3 Hybridization Law.
class GenreHybridizationMatrix {
  GenreHybridizationMatrix._();

  static bool _fusionActive(String fusion) {
    final f = fusion.trim().toLowerCase();
    if (f.isEmpty) return false;
    return f != 'none' && f != 'n/a' && f != 'na' && f != '-' && f != '—';
  }

  /// Injects dominant/subordinate roles when Primary + Fusion are both set.
  static String userBlockDirective({
    required String primaryGenre,
    String subGenreFusion = '',
  }) {
    final primary = primaryGenre.trim();
    final fusion = subGenreFusion.trim();
    if (primary.isEmpty || !_fusionActive(fusion)) return '';

    return [
      'DUAL-GENRE HYBRIDIZATION (mandatory — Split-DNA routing):',
      'Genre A DOMINANT ($primary): BPM, drum architecture, structural block tags, climax grid.',
      'Genre B SUBORDINATE ($fusion): signature instruments, vocal texture, regional vocabulary — '
          'only in low-density sections (Intro, Verse 1, Breakdown).',
      'Hybridization drop rule: at [The Release], [Main Climax], [Drop], or peak chorus, '
          'subordinate acoustic/organic elements must be sidechained, filtered, delayed, or loop-mutated '
          "to lock into Genre A's kick grid — never raw acoustic fighting the electronic climax.",
      'Subordinate tag accent rule: name Genre B texture once in Intro or Verse 1 only — '
          'do not repeat acoustic/subordinate instrument labels in Verse 2, Bridge, or breaks.',
      'Amapiano primary: log drum = FM synthesized bass — never tag as live/acoustic log drum.',
      'Full law: SUNO V4 Master Production Architecture §1 Layer 3 Dual-Genre Hybridization Law.',
    ].join('\n');
  }
}
