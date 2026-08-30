import 'package:dio/dio.dart';

import '../utils/api_base_url_normalize.dart';

export '../utils/api_base_url_normalize.dart'
    show normalizeApiBaseUrl, validateMusicDirectorApiBaseUrl;

/// FastAPI routes on the Music Director backend (see `server/app/main.py`).
abstract final class ApiPaths {
  static const analyze = '/analyze';
  static const generatePrompt = '/generate-prompt';
  static const generateLyrics = '/generate-lyrics';
  static const songwriterStatus = '/songwriter/status';
  static const health = '/health';
}

/// Timeouts for [ApiPaths.analyze] (multipart upload + Gemini on server).
class AnalyzeTimeouts {
  AnalyzeTimeouts._();

  static const connect = Duration(seconds: 120);
  static const send = Duration(minutes: 5);
  static const receive = Duration(minutes: 5);
}

/// Timeouts for [ApiPaths.generatePrompt] (Gemini 2.5 Flash draft + polish).
class PromptGenerationTimeouts {
  PromptGenerationTimeouts._();

  static const connect = Duration(seconds: 90);
  static const send = Duration(minutes: 2);
  /// Hybrid draft + polish on the server can exceed 4 minutes.
  static const receive = Duration(minutes: 7);
}

/// Timeouts for [ApiPaths.generateLyrics] (multi-stage songwriter pipeline).
class SongwriterTimeouts {
  SongwriterTimeouts._();

  static const connect = Duration(seconds: 90);
  static const send = Duration(minutes: 2);
  /// Full song = up to 12 sequential LLM stages; keep above server budget.
  static const receive = Duration(minutes: 15);
}

/// Dio scoped to the Music Director API (`baseUrl` + relative [ApiPaths]).
Dio createMusicDirectorApiDio(String baseUrl) {
  return Dio(
    BaseOptions(
      baseUrl: normalizeApiBaseUrl(baseUrl),
      connectTimeout: AnalyzeTimeouts.connect,
      receiveTimeout: PromptGenerationTimeouts.receive,
      sendTimeout: AnalyzeTimeouts.send,
    ),
  );
}

/// Shared Dio for OpenRouter / LaoZhang chat completions (full URL per request).
Dio createDio() {
  return Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 60),
      receiveTimeout: PromptGenerationTimeouts.receive,
      sendTimeout: const Duration(minutes: 2),
      headers: const {'Content-Type': 'application/json'},
    ),
  );
}

Options analyzeRequestOptions() => Options(
      connectTimeout: AnalyzeTimeouts.connect,
      sendTimeout: AnalyzeTimeouts.send,
      receiveTimeout: AnalyzeTimeouts.receive,
    );

Options promptGenerationRequestOptions() => Options(
      connectTimeout: PromptGenerationTimeouts.connect,
      sendTimeout: PromptGenerationTimeouts.send,
      receiveTimeout: PromptGenerationTimeouts.receive,
      headers: const {'Content-Type': 'application/json'},
    );

Options songwriterRequestOptions() => Options(
      connectTimeout: SongwriterTimeouts.connect,
      sendTimeout: SongwriterTimeouts.send,
      receiveTimeout: SongwriterTimeouts.receive,
      headers: const {'Content-Type': 'application/json'},
    );
