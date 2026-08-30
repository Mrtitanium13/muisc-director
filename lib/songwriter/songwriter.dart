import '../core/constants/songwriter_prompts_data.dart';
import 'models/song_brief.dart';

export 'models/song_brief.dart';
export 'models/lyric_result.dart';
export 'services/songwriter_model_router.dart';
export 'qa/forbidden_phrase_scrubber.dart';

/// Helper: build a [SongBrief] from common form fields.
SongBrief songBriefFromForm({
  required String genre,
  String subgenre = '',
  String mood = '',
  String theme = '',
  String story = '',
  String language = 'English',
  int energy = 50,
  String perspective = 'I',
  String mode = 'full_song',
  String qualityMode = 'balanced',
  bool allowCliches = false,
  String inputLyrics = '',
  String vocalStyle = '',
  String audience = '',
  String bpm = '',
  List<String> emotionalArc = const [],
}) {
  return SongBrief(
    genre: genre,
    subgenre: subgenre,
    mood: mood,
    theme: theme,
    story: story,
    language: language,
    energy: energy,
    perspective: perspective,
    mode: mode,
    qualityMode: qualityMode,
    allowCliches: allowCliches,
    inputLyrics: inputLyrics,
    vocalStyle: vocalStyle,
    audience: audience,
    bpm: bpm,
    emotionalArc: emotionalArc,
  );
}

List<Map<String, dynamic>> songwriterOutputModes() {
  final cfg = SongwriterPromptsData.config('output_modes');
  final modes = cfg['modes'];
  if (modes is! List) return const [];
  return modes
      .whereType<Map>()
      .map((e) => Map<String, dynamic>.from(e))
      .toList();
}

List<String> songwriterQualityModes() {
  final cfg = SongwriterPromptsData.config('quality_modes');
  final modes = cfg['modes'];
  if (modes is! Map) {
    return const ['fast', 'balanced', 'premium', 'debug'];
  }
  return modes.keys.map((e) => '$e').toList();
}
