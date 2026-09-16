/// Canonical Suno model targets for prompt routing and UI defaults.
///
/// Suno retired pre-v6 models (Sep 2026). UI chips are v6 / v6-wild / v6-mini.
/// Legacy strings (v4.5 / v5.0 / v5.5) remain parseable and map onto density
/// profiles so engines and saved prompts keep working.
enum SunoDensityProfile {
  /// Section names only (legacy v4.5).
  minimal,

  /// One staging descriptor (v6-mini / legacy v5.0).
  hybrid,

  /// Rich director notes (v6 / v6-wild / legacy v5.5).
  rich,
}

enum SunoVersion {
  v6('v6'),
  v6Wild('v6-wild'),
  v6Mini('v6-mini'),

  /// Legacy — not shown in UI; density alias only.
  v4_5('v4.5'),
  v5('v5.0'),
  v5_5('v5.5');

  const SunoVersion(this.value);

  final String value;

  /// Preferred default for new projects (flagship v6).
  static const SunoVersion preferred = SunoVersion.v6;

  static const String preferredValue = 'v6';

  /// Chips shown in the prompt generator.
  static const List<String> uiValues = ['v6', 'v6-wild', 'v6-mini'];

  bool get isUiSelectable =>
      this == SunoVersion.v6 ||
      this == SunoVersion.v6Wild ||
      this == SunoVersion.v6Mini;

  /// True when prompts should invite exploratory / textured output.
  static bool isWildIntent(String raw) {
    final v = raw.trim().toLowerCase();
    return v == 'v6-wild' || v == 'v6wild';
  }

  /// Density profile used by bracket/matrix engines.
  static SunoDensityProfile densityProfileFor(String raw) {
    final v = raw.trim().toLowerCase();
    if (v == 'v4.5') return SunoDensityProfile.minimal;
    if (v == 'v6-mini' ||
        v == 'v6mini' ||
        v == 'v5.0' ||
        v == 'v5' ||
        v == 'suno_v5') {
      return SunoDensityProfile.hybrid;
    }
    // v6, v6-wild, v5.5*, unknown → rich (safe default)
    return SunoDensityProfile.rich;
  }

  /// Legacy density key (`v4.5` / `v5.0` / `v5.5`) for engines that still branch
  /// on pre-v6 version strings.
  static String densityKeyFor(String raw) {
    switch (densityProfileFor(raw)) {
      case SunoDensityProfile.minimal:
        return 'v4.5';
      case SunoDensityProfile.hybrid:
        return 'v5.0';
      case SunoDensityProfile.rich:
        return 'v5.5';
    }
  }

  static bool isRichDensity(String raw) =>
      densityProfileFor(raw) == SunoDensityProfile.rich;

  static bool isMinimalDensity(String raw) =>
      densityProfileFor(raw) == SunoDensityProfile.minimal;

  static bool isHybridDensity(String raw) =>
      densityProfileFor(raw) == SunoDensityProfile.hybrid;

  /// Map retired / legacy saved values onto a current UI chip.
  static String migrateToUiValue(String raw) {
    final v = raw.trim().toLowerCase();
    if (v.isEmpty) return preferredValue;
    if (v == 'v6') return 'v6';
    if (v == 'v6-wild' || v == 'v6wild') return 'v6-wild';
    if (v == 'v6-mini' || v == 'v6mini') return 'v6-mini';
    // Retired models → flagship v6 (soft cut).
    return preferredValue;
  }

  static SunoVersion? tryParse(String raw) {
    final v = raw.trim().toLowerCase();
    if (v == 'v6') return SunoVersion.v6;
    if (v == 'v6-wild' || v == 'v6wild') return SunoVersion.v6Wild;
    if (v == 'v6-mini' || v == 'v6mini') return SunoVersion.v6Mini;
    if (v == 'v4.5') return SunoVersion.v4_5;
    if (v == 'v5.0' || v == 'v5') return SunoVersion.v5;
    if (v.startsWith('v5.5')) return SunoVersion.v5_5;
    return null;
  }

  /// Short intent line for LLM user blocks (empty for unknown).
  static String modelIntentDirective(String raw) {
    final v = raw.trim().toLowerCase();
    if (v == 'v6-wild' || v == 'v6wild') {
      return 'SUNO MODEL INTENT (v6-wild): Exploratory / textured. Prefer unexpected '
          'but musical arrangement turns within valid metatags; keep structure coherent. '
          'Invite variance without junk tags — user may refine later on flagship v6.';
    }
    if (v == 'v6-mini' || v == 'v6mini') {
      return 'SUNO MODEL INTENT (v6-mini): Lean hybrid staging. Prioritize clear section '
          'structure over dense director essays; keep Block 1 concise within the fixed cap.';
    }
    if (v == 'v6' || densityProfileFor(raw) == SunoDensityProfile.rich) {
      return 'SUNO MODEL INTENT (v6): Precise and polished. Strong Style adherence, '
          'genre-accurate rich director notes, clean Full-arc structure.';
    }
    if (densityProfileFor(raw) == SunoDensityProfile.hybrid) {
      return 'SUNO MODEL INTENT (hybrid density): One primary staging descriptor per '
          'bracket; balanced lyric/structure depth.';
    }
    if (densityProfileFor(raw) == SunoDensityProfile.minimal) {
      return 'SUNO MODEL INTENT (minimal density): Section-name brackets only; put '
          'production cues in Block 1 prose.';
    }
    return '';
  }
}
