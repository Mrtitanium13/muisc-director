import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/api_constants.dart';
import '../../core/network/dio_client.dart';
import '../../core/utils/api_connectivity.dart';
import '../models/audio_analysis_model.dart';

/// Calls FastAPI [ApiPaths.analyze] when a base URL is configured; otherwise mock.
class AudioAnalyzerService {
  AudioAnalyzerService(this._prefs);

  final SharedPreferences _prefs;

  Future<AudioAnalysisModel> analyze({
    String? filePath,
    Uint8List? bytes,
    required String filename,
  }) async {
    final base = ApiConstants.resolveAnalyzeBase(_prefs);
    if (base == null || base.isEmpty) {
      return _mock(filePath: filePath, filename: filename);
    }

    await assertMusicDirectorServerReachable(base);

    final MultipartFile part;
    if (bytes != null) {
      part = MultipartFile.fromBytes(bytes, filename: filename);
    } else if (filePath != null) {
      part = await MultipartFile.fromFile(filePath, filename: p.basename(filePath));
    } else {
      throw StateError('No file or bytes');
    }

    final formData = FormData.fromMap({'file': part});
    final api = createMusicDirectorApiDio(base);
    final res = await api.post<Map<String, dynamic>>(
      ApiPaths.analyze,
      data: formData,
      options: analyzeRequestOptions(),
    );
    final data = res.data;
    if (data == null) {
      throw DioException(
        requestOptions: res.requestOptions,
        error: 'Empty analysis response',
      );
    }
    return AudioAnalysisModel.fromJson(data);
  }

  AudioAnalysisModel _mock({String? filePath, required String filename}) {
    final seed = filePath ?? filename;
    final hash = seed.hashCode.abs() % 40;
    return AudioAnalysisModel(
      analyzerSummary: AudioAnalysisModel.fallbackAnalyzerSummary,
      title: 'Demo Track',
      artist: 'Demo Artist',
      album: 'Session',
      releaseDate: 'Custom',
      success: false,
      bpm: 118 + (hash % 25).toDouble(),
      keyScale: 'F# Minor',
      energy: 'High (${72 + hash % 20}/100)',
      genre: 'Demo · API not configured',
      moodTags: const ['Placeholder', 'Connect', 'MD_API_BASE_URL'],
      loudness: '-7.2 LUFS',
      instruments: const ['Synthesizer', 'Sub Bass', 'Hi-Hats', 'Pads'],
      tempoFeel: 'Syncopated groove',
      chordComplexity: 'Moderate',
      confidenceOverall: 'Medium',
      analysisMode: 'demo',
    );
  }
}
