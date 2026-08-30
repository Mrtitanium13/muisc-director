/// How melodic emphasis evolves section-to-section within one song.
enum MelodyEvolution {
  /// Motifs stay locked: Verse 1 ≈ Verse 2, Chorus 1 ≈ Chorus 2.
  /// Best for loop-based / hypnotic tracks (EDM, techno, amapiano, etc.).
  strict,

  /// Later hooks grow in energy/layers while keeping the core motif.
  /// Best for pop, R&B, rock, worship, cinematic lifts.
  progressive,

  /// Bridge / mid-song section introduces a deliberate melodic shift.
  /// Best for story-driven, experimental, jazz, folk, and contrast arcs.
  highContrast,
}

extension MelodyEvolutionIds on MelodyEvolution {
  String get id => name;

  String get label => switch (this) {
        MelodyEvolution.strict => 'Strict (Loop / Hypnotic)',
        MelodyEvolution.progressive => 'Progressive (Build / Lift)',
        MelodyEvolution.highContrast => 'High Contrast (Shift / Surprise)',
      };

  static MelodyEvolution fromId(String? raw) {
    switch ((raw ?? '').trim().toLowerCase()) {
      case 'progressive':
      case 'rotate':
        return MelodyEvolution.progressive;
      case 'highcontrast':
      case 'high_contrast':
      case 'random':
        return MelodyEvolution.highContrast;
      case 'strict':
      case 'none':
      default:
        return MelodyEvolution.strict;
    }
  }
}
