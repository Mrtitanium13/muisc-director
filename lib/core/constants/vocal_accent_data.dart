import 'dialect_style_data.dart';

/// Preset **singing / rap delivery accents** (pronunciation & cadence — style only, not voice cloning).
class VocalAccentData {
  VocalAccentData._();

  static const accentVsDialectConstraint =
      'ACCENT VS. DIALECT CONSTRAINT: When a regional accent or delivery style is specified, '
      'write lyrics in clear, standard English. You are strictly forbidden from translating '
      'text into slang, broken dialects, or patois (completely ban words like dey, na, wahala, '
      'gonna in lyric lines). Let vocal performance style remain purely phonetic in staging '
      'tags; the written lyric text must stay pristine, high-end, and universally legible.';

  static const regionalTagDedupConstraint =
      'ZERO REGIONAL TAG DUPLICATION: Regional delivery modifiers, vocal textures, or accent '
      'descriptors must appear once per section inside the single staging bracket — never '
      'repeat the same regional/accent phrase across consecutive brackets, section headers, '
      'or lyric lines. Block 1 carries primary vocal-accent prose; Block 2 tags reference '
      'delivery phonetically without re-stacking identical regional labels every section.';

  /// First entry is “not specified” (`null` in UI).
  static const List<String?> dropdownValues = [
    null,
    'West African (Nigeria)',
    'West African (Ghana)',
    'West African (general)',
    'Caribbean',
    'American (General)',
    'American (Southern)',
    'British (England)',
    'Scottish',
    'Irish',
    'Australian / New Zealand',
    'Indian English',
    'French English',
    'Spanish / Latin American English',
    'South African English',
    'East African (general)',
  ];

  static String menuLabel(String? value) {
    if (value == null || value.isEmpty) {
      return 'Not specified — infer from genre & language';
    }
    return value;
  }

  /// Drops unknown persisted values so [DropdownButtonFormField] stays valid.
  static String? coerceStored(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    return dropdownValues.contains(raw) ? raw : null;
  }

  /// Strong user-block directive when an accent is selected (style only — not cloning).
  static String userBlockDirective({
    required String? accent,
    String vocalSpec = '',
    String language = 'English',
    String dialectStyleId = DialectStyleData.standardEnglishId,
  }) {
    final a = (accent ?? '').trim();
    if (a.isEmpty) return '';
    final spec = vocalSpec.trim();
    final lang = language.trim().isEmpty ? 'English' : language.trim();
    final specLine = spec.isNotEmpty ? '\n- Lead vocal type: $spec' : '';
    final pidgin = DialectStyleData.isNigerianPidgin(dialectStyleId);
    final lyricLine = pidgin
        ? '- Block 2 lyrics: User selected Nigerian Pidgin dialect — Pidgin grammar applies in lyric lines; accent delivery still lives in staging tags.'
        : '- Block 2 lyrics: Write in clear, standard English only — accent is phonetic delivery in staging tags, NOT slang or dialect in the written lines.';
    return '''
VOCAL ACCENT / DELIVERY (USER-SELECTED — NON-NEGOTIABLE):
- Accent: $a
- Language context: $lang$specLine
- Block 1: Weave this regional pronunciation and cadence into the vocal production description (style/delivery only — never impersonate a real person).
- Block 2 staging: Include accent delivery tags in each section's single staging bracket (e.g. "$a Delivery", close-mic proximity) — do not duplicate the same regional label in lyric lines.
$lyricLine
- Preserve singability; accent is delivery style, not a dialect caricature.
'''.trim();
  }

  /// Post-process context for theme / humanize / compress passes.
  static String postProcessContextLine(
    String? accent, {
    String dialectStyleId = DialectStyleData.standardEnglishId,
  }) {
    final a = (accent ?? '').trim();
    if (a.isEmpty) return '';
    if (DialectStyleData.isNigerianPidgin(dialectStyleId)) {
      return 'VOCAL ACCENT (staging tags only): $a — lyric dialect is Nigerian Pidgin.';
    }
    return 'VOCAL ACCENT (staging tags only — lyrics stay standard English): $a';
  }

  /// Stage 3 constraint when accent is set and dialect is standard English.
  static String accentVsDialectConstraintLine(
    String? accent, {
    String dialectStyleId = DialectStyleData.standardEnglishId,
  }) {
    if ((accent ?? '').trim().isEmpty) return '';
    if (DialectStyleData.isNigerianPidgin(dialectStyleId)) return '';
    return accentVsDialectConstraint;
  }

  /// Stage 5 dedup constraint when regional delivery is active.
  static String regionalTagDedupConstraintLine({
    String? accent,
    String dialectStyleId = DialectStyleData.standardEnglishId,
  }) {
    if ((accent ?? '').trim().isEmpty &&
        !DialectStyleData.isNigerianPidgin(dialectStyleId)) {
      return '';
    }
    return regionalTagDedupConstraint;
  }

  static String postProcessCompactLine(
    String? accent, {
    String dialectStyleId = DialectStyleData.standardEnglishId,
  }) {
    final a = (accent ?? '').trim();
    if (a.isEmpty) return '';
    if (DialectStyleData.isNigerianPidgin(dialectStyleId)) {
      return 'ACCENT:$a|staging-only|lyrics=Pidgin';
    }
    return 'ACCENT:$a|staging-only|lyrics=standard English';
  }

  static String accentVsDialectCompactLine(
    String? accent, {
    String dialectStyleId = DialectStyleData.standardEnglishId,
  }) {
    if ((accent ?? '').trim().isEmpty) return '';
    if (DialectStyleData.isNigerianPidgin(dialectStyleId)) return '';
    return 'RULE:accent-only|lyrics=standard English|no dey/na/wahala in lines';
  }

  static String regionalTagDedupCompactLine({
    String? accent,
    String dialectStyleId = DialectStyleData.standardEnglishId,
  }) {
    if ((accent ?? '').trim().isEmpty &&
        !DialectStyleData.isNigerianPidgin(dialectStyleId)) {
      return '';
    }
    return 'RULE:regional-tag-once|one accent phrase per section bracket';
  }
}
