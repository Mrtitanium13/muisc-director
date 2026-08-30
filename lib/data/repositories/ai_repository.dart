import '../models/user_input_model.dart';
import '../services/openai_service.dart';
import '../../songwriter/models/lyric_result.dart';
import '../../songwriter/models/song_brief.dart';

class AiRepository {
  AiRepository(this._openAI);

  final OpenAIService _openAI;

  Future<String> generatePrompt(
    UserInputModel input, {
    bool preferLightweightModel = false,
  }) =>
      _openAI.generateSunoPromptWithFormatRetry(
        input,
        preferLightweightModel: preferLightweightModel,
      );

  Future<LyricResult> generateSongwriterLyrics(SongBrief brief) =>
      _openAI.generateSongwriterLyrics(brief);
}
