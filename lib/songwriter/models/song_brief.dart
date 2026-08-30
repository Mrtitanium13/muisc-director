/// Structured brief for the multi-stage songwriter pipeline.
class SongBrief {
  const SongBrief({
    required this.genre,
    this.subgenre = '',
    this.mood = '',
    this.theme = '',
    this.story = '',
    this.language = 'English',
    this.energy = 50,
    this.perspective = 'I',
    this.mode = 'full_song',
    this.qualityMode = 'balanced',
    this.allowCliches = false,
    this.inputLyrics = '',
    this.emotionalArc = const [],
    this.vocalStyle = '',
    this.audience = '',
    this.bpm = '',
    this.contentRating = 'clean',
    this.hookStyle = '',
    this.variationCount = 3,
    this.artistInspiration = const [],
    this.constraints = const [],
    this.codeSwitching = const {},
    this.extra = const {},
  });

  final String genre;
  final String subgenre;
  final String mood;
  final String theme;
  final String story;
  final String language;
  final int energy;
  final String perspective;
  final String mode;
  final String qualityMode;
  final bool allowCliches;
  final String inputLyrics;
  final List<String> emotionalArc;
  final String vocalStyle;
  final String audience;
  final String bpm;
  final String contentRating;
  final String hookStyle;
  final int variationCount;
  final List<String> artistInspiration;
  final List<String> constraints;
  final Map<String, dynamic> codeSwitching;
  final Map<String, dynamic> extra;

  Map<String, dynamic> toJson() => {
        'genre': genre,
        'subgenre': subgenre,
        'mood': mood,
        'theme': theme,
        'story': story,
        'language': language,
        'energy': energy,
        'perspective': perspective,
        'mode': mode,
        'quality_mode': qualityMode,
        'allow_cliches': allowCliches,
        'input_lyrics': inputLyrics,
        'emotional_arc': emotionalArc,
        'vocal_style': vocalStyle,
        'audience': audience,
        'bpm': bpm,
        'content_rating': contentRating,
        'hook_style': hookStyle,
        'variation_count': variationCount,
        'artist_inspiration': artistInspiration,
        'constraints': constraints,
        'code_switching': codeSwitching,
        'extra': extra,
      };
}
