import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'api_connectivity.dart';

/// Human-readable text for snackbars — prefers FastAPI `detail` and OpenAI `error.message`.
String dioErrorMessage(Object error) {
  if (error is ApiConnectivityException) return error.message;
  if (error is! DioException) return error.toString();

  final connectionHint = _connectionErrorHint(error);
  if (connectionHint != null) return connectionHint;

  final timeoutHint = _timeoutHint(error);
  if (timeoutHint != null) return timeoutHint;

  final code = error.response?.statusCode;
  final data = error.response?.data;

  if (data is Map) {
    final detail = data['detail'];
    if (detail is String && detail.isNotEmpty) {
      return detail;
    }
    if (detail is List && detail.isNotEmpty) {
      final first = detail.first;
      if (first is Map) {
        final msg = first['msg'];
        if (msg != null) return msg.toString();
      }
      return first.toString();
    }

    final openAiMsg = _openAiNestedMessage(data);
    if (openAiMsg != null) {
      return _hintForOpenAiFailure(code, data, openAiMsg);
    }
  }

  if (code == 404) {
    final uri = error.requestOptions.uri;
    final host = uri.host.toLowerCase();
    if (host.contains('laozhang.ai') || host.contains('openrouter.ai')) {
      return '404: MD_API_BASE_URL must be your Music Director server (uvicorn/Railway), '
          'not api.laozhang.ai. Put your LaoZhang key in Settings → LaoZhang API key, or Railway OPENAI_API_KEY.';
    }
    if (uri.path == '/' || uri.path.isEmpty) {
      return '404: Opening the server root in a browser always fails. '
          'Use GET /health to test. The app calls POST /generate-prompt and POST /analyze.';
    }
    return 'API path not found (404): ${uri.path} on $host. '
        'Base URL in Settings should be host only (e.g. http://127.0.0.1:8080). '
        'Restart uvicorn from server/ or redeploy Railway. Test GET /health.';
  }
  if (code == 504) {
    return 'Server timed out (504). Hybrid generation can take 1–4 minutes — '
        'retry, or set PROMPT_PIPELINE=single on the server. Use a shorter track for /analyze.';
  }
  if (code == 503) {
    final detail = data is Map ? data['detail']?.toString() : null;
    if (detail != null && detail.isNotEmpty) {
      return detail;
    }
    return 'Server unavailable (503). Save a LaoZhang or OpenRouter key in Settings '
        '(used when the server has no OPENAI_API_KEY), or set OPENAI_API_KEY in the server terminal / Railway.';
  }
  if (code == 502) {
    return 'Upstream error (502). Check OPENAI_API_KEY and OPENAI_MODEL on the server '
        '(LaoZhang default; OPENROUTER_ONLY=true for OpenRouter).';
  }
  if (code == 401 || code == 403) {
    return 'API rejected the request ($code). Check your LaoZhang or OpenRouter key in Settings '
        'or use MD_API_BASE_URL for Railway.';
  }

  final msg = error.message;
  if (msg != null && msg.isNotEmpty) return msg;
  return error.toString();
}

String? _openAiNestedMessage(Map<dynamic, dynamic> data) {
  final err = data['error'];
  if (err is Map && err['message'] != null) {
    return err['message'].toString();
  }
  return null;
}

String _hintForOpenAiFailure(int? code, Map<dynamic, dynamic> data, String apiMessage) {
  final err = data['error'];
  String? errCode;
  if (err is Map && err['code'] != null) {
    errCode = err['code'].toString();
  }

  final lower = apiMessage.toLowerCase();
  final invalidKey = errCode == 'invalid_api_key' ||
      lower.contains('incorrect api key') ||
      lower.contains('invalid api key');

  if (code == 401 && invalidKey) {
    return 'Invalid API key (401). Save a LaoZhang key (api.laozhang.ai) or OpenRouter key '
        '(sk-or-v1-…) in Settings when MD_API_BASE_URL is empty. Or set MD_API_BASE_URL '
        'to use your Railway backend.';
  }

  if (apiMessage.length > 220) {
    return '${apiMessage.substring(0, 217)}…';
  }
  return apiMessage;
}

String? _timeoutHint(DioException error) {
  if (error.type != DioExceptionType.connectionTimeout &&
      error.type != DioExceptionType.sendTimeout &&
      error.type != DioExceptionType.receiveTimeout) {
    return null;
  }
  final path = error.requestOptions.uri.path;
  if (path.contains('generate-prompt')) {
    return 'Prompt generation timed out (hybrid draft + polish can take 2–5 minutes). '
        'Keep the API server running and retry. For a faster pass, set PROMPT_PIPELINE=single '
        'on the server. Local: cd server → uvicorn app.main:app --host 0.0.0.0 --port 8080';
  }
  if (path.contains('analyze')) {
    return 'Audio analysis timed out. Use a shorter clip (under ~2 minutes), keep the server '
        'running, and retry. Local: cd server → uvicorn app.main:app --host 0.0.0.0 --port 8080';
  }
  final host = error.requestOptions.uri.host.toLowerCase();
  if (host.contains('laozhang.ai')) {
    return 'LaoZhang request timed out. Retry, or set MD_API_BASE_URL to your server and '
        'put OPENAI_API_KEY on the server instead.';
  }
  if (host.contains('openrouter.ai')) {
    return 'OpenRouter request timed out. Retry, or use MD_API_BASE_URL + Railway/local server.';
  }
  return 'Request timed out. On a real phone use your PC Wi‑Fi IP (e.g. http://192.168.1.10:8080), '
      'not 127.0.0.1. Ensure uvicorn is running: cd server → uvicorn app.main:app --host 0.0.0.0 --port 8080';
}

String? _connectionErrorHint(DioException error) {
  if (error.type != DioExceptionType.connectionError &&
      error.type != DioExceptionType.unknown) {
    return null;
  }
  final blob = '${error.message ?? ''} ${error.error ?? ''}'.toLowerCase();
  if (!blob.contains('connection refused') &&
      !blob.contains('failed host lookup') &&
      !blob.contains('network is unreachable') &&
      !blob.contains('127.0.0.1') &&
      !blob.contains('10.0.2.2')) {
    return null;
  }

  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    return 'Cannot reach the API server. Physical phone: http://192.168.x.x:8080 (PC ipconfig IPv4, same Wi‑Fi). '
        'Emulator: http://10.0.2.2:8080. Server: uvicorn … --host 0.0.0.0 --port 8080. '
        'Windows: run server\\open_firewall.ps1 as Administrator if health works on PC but not on phone.';
  }
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
    return 'Cannot reach the API server. Simulator: http://127.0.0.1:8080. Real device: your Mac\'s '
        'LAN IP. Ensure uvicorn is running on port 8080.';
  }
  return 'Cannot reach the API server at the configured URL. Start it with: '
      'cd server && uvicorn app.main:app --host 127.0.0.1 --port 8080';
}
