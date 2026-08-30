/// Dynamic theme → lyric directive mapping for Gospel lanes.
///
/// Appended to the user request only when the user selects or describes a theme.
class GospelThemeDirectives {
  GospelThemeDirectives._();

  static const themeForgiveness = 'forgiveness';
  static const themeGratitude = 'gratitude';
  static const themeSpiritualWarfare = 'spiritual_warfare';

  static const _forgivenessMarkers = [
    'forgive',
    'forgiveness',
    'redemption',
    'prodigal',
    'reconcil',
    'mercy',
    'guilt',
    'repent',
    'mistake',
    'return home',
    'second chance',
  ];

  static const _gratitudeMarkers = [
    'gratitude',
    'grateful',
    'thankful',
    'thanksgiving',
    'blessing',
    'counting blessings',
    'overflowing',
    'harvest praise',
    'celebrat',
  ];

  static const _warfareMarkers = [
    'warfare',
    'spiritual war',
    'victory',
    'deliverance',
    'break chains',
    'breakthrough',
    'armor',
    'weapons of praise',
    'walls falling',
    'stand firm',
    'overcome',
  ];

  static const Map<String, String> themeDirectives = {
    themeForgiveness: '''
THEME DIRECTIVES for Forgiveness:
- Focus on redemption, washing away guilt, and reconciliation.
- Feel free to use the 'Prodigal Son' paradigm or an overwhelming embrace framework.
- Contrast the weight of past mistakes with the lightness of being forgiven.''',
    themeGratitude: '''
THEME DIRECTIVES for Gratitude/Praise:
- Focus on counting blessings, thanking God for life, breath, and unseen protection.
- Use imagery of harvest, overflowing cups, or a song rising from the heart.
- Avoid heavy themes of guilt or running away; keep the tone celebratory or deeply humbled.''',
    themeSpiritualWarfare: '''
THEME DIRECTIVES for Warfare/Victory:
- Focus on overcoming obstacles, breaking chains, and standing firm in faith.
- Use imagery of valleys, armor, weapons of praise, and walls falling down.
- Tone should be authoritative, driving, and triumphant.''',
  };

  static const Map<String, String> themeLabels = {
    themeForgiveness: 'Forgiveness',
    themeGratitude: 'Gratitude/Praise',
    themeSpiritualWarfare: 'Warfare/Victory',
  };

  /// Resolve free-text [lyricThemeNotes] and [vibe] to a theme key, if any.
  static String? resolveThemeKey({
    String lyricThemeNotes = '',
    String vibe = '',
  }) {
    final blob = '${lyricThemeNotes.trim()} ${vibe.trim()}'.toLowerCase();
    if (blob.trim().isEmpty) return null;

    if (_forgivenessMarkers.any(blob.contains)) return themeForgiveness;
    if (_gratitudeMarkers.any(blob.contains)) return themeGratitude;
    if (_warfareMarkers.any(blob.contains)) return themeSpiritualWarfare;

    // Broad praise/gratitude when vibe explicitly signals celebration without guilt.
    if (blob.contains('praise') &&
        !blob.contains('warfare') &&
        !_forgivenessMarkers.any(blob.contains)) {
      return themeGratitude;
    }

    return null;
  }

  /// Theme directive block appended to the user request when a theme matches.
  static String directiveBlock({
    String lyricThemeNotes = '',
    String vibe = '',
  }) {
    final key = resolveThemeKey(
      lyricThemeNotes: lyricThemeNotes,
      vibe: vibe,
    );
    if (key != null) {
      return themeDirectives[key] ?? '';
    }
    final custom = lyricThemeNotes.trim();
    if (custom.isNotEmpty) {
      return 'THEME NOTES:\n- Honor the user theme: $custom';
    }
    return '';
  }
}
