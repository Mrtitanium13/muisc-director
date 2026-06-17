import '../models/audio_analysis_model.dart';
import '../models/audio_session.dart';
import '../services/audio_analyzer_service.dart';

class AudioRepository {
  AudioRepository(this._analyzer);

  final AudioAnalyzerService _analyzer;

  Future<AudioAnalysisModel> analyze(AudioSession session) {
    return _analyzer.analyze(
      filePath: session.path,
      bytes: session.bytes,
      filename: session.name,
    );
  }
}
