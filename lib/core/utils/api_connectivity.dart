import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../utils/api_base_url_normalize.dart';
import '../network/dio_client.dart';
import 'api_base_url_resolver.dart';

/// True when [error] is a failed reachability call to the local/Railway Music Director server.
bool isMusicDirectorServerConnectionFailure(Object error) {
  if (error is ApiConnectivityException) return true;
  if (error is! DioException) return false;
  return error.type == DioExceptionType.connectionTimeout ||
      error.type == DioExceptionType.connectionError ||
      error.type == DioExceptionType.receiveTimeout;
}

/// Thrown before a long LLM request when the Music Director server is unreachable.
class ApiConnectivityException implements Exception {
  ApiConnectivityException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Fast check that [baseUrl] responds to GET /health (fails in ~8s, not minutes).
Future<void> assertMusicDirectorServerReachable(String baseUrl) async {
  final resolved = resolveDeviceApiBaseUrl(normalizeApiBaseUrl(baseUrl));
  if (resolved == null || resolved.isEmpty) {
    throw ApiConnectivityException('Invalid MD_API_BASE_URL.');
  }

  final loopbackHint = mobileLoopbackMisconfigurationHint(resolved);
  if (loopbackHint != null) {
    throw ApiConnectivityException(loopbackHint);
  }

  final dio = Dio(
    BaseOptions(
      baseUrl: resolved,
      connectTimeout: const Duration(seconds: 8),
      receiveTimeout: const Duration(seconds: 8),
    ),
  );

  try {
    final res = await dio.get<Map<String, dynamic>>(ApiPaths.health);
    if (res.statusCode != 200) {
      throw ApiConnectivityException(
        'Server at $resolved returned ${res.statusCode}. Check uvicorn is running.',
      );
    }
  } on DioException catch (e) {
    throw ApiConnectivityException(_dioProbeMessage(e, resolved));
  }
}

/// Warn when a phone cannot reach loopback / emulator-only hosts.
String? mobileLoopbackMisconfigurationHint(String resolvedBase) {
  if (kIsWeb) return null;
  final uri = Uri.tryParse(resolvedBase);
  if (uri == null) return null;
  final host = uri.host.toLowerCase();
  final isMobile = defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;
  if (!isMobile) return null;

  if (host == '127.0.0.1' || host == 'localhost') {
    return loopbackApiHint(resolvedBase);
  }
  // 10.0.2.2 only works on Android emulator — not on a physical device.
  if (defaultTargetPlatform == TargetPlatform.android && host == '10.0.2.2') {
    return 'http://10.0.2.2 only works on the Android emulator. On a real phone, '
        'set MD_API_BASE_URL to your PC\'s Wi‑Fi IP (e.g. http://192.168.1.10:8080) '
        'or use Railway. Start server: cd server → uvicorn app.main:app --host 0.0.0.0 --port 8080';
  }
  return null;
}

/// Result of Settings **Test** / preflight (health + optional generate route probe).
class MusicDirectorConnectionTestResult {
  const MusicDirectorConnectionTestResult({
    required this.resolvedBaseUrl,
    required this.healthStatus,
    this.generateRouteOk = false,
  });

  final String resolvedBaseUrl;
  final String healthStatus;
  final bool generateRouteOk;

  String get successMessage =>
      'Connected ($healthStatus at $resolvedBaseUrl). '
      '${generateRouteOk ? "POST /generate-prompt is available." : "Health OK — set OPENAI_API_KEY on the server for generate."} '
      'Use host only in Settings (not /health).';
}

/// Validates URL, checks GET /health (~8s max), probes POST /generate-prompt for 404 only.
Future<MusicDirectorConnectionTestResult> runMusicDirectorConnectionTest(
  String rawBaseUrl,
) async {
  final normalized = normalizeApiBaseUrl(rawBaseUrl.trim());
  final validationErr = validateMusicDirectorApiBaseUrl(normalized);
  if (validationErr != null) {
    throw ApiConnectivityException(validationErr);
  }

  final resolved = resolveDeviceApiBaseUrl(normalized);
  if (resolved == null || resolved.isEmpty) {
    throw ApiConnectivityException('Invalid MD_API_BASE_URL.');
  }

  final loopbackHint = mobileLoopbackMisconfigurationHint(resolved);
  if (loopbackHint != null) {
    throw ApiConnectivityException(loopbackHint);
  }

  final dio = Dio(
    BaseOptions(
      baseUrl: resolved,
      connectTimeout: const Duration(seconds: 8),
      receiveTimeout: const Duration(seconds: 8),
      sendTimeout: const Duration(seconds: 8),
    ),
  );

  String status = 'ok';
  try {
    final health = await dio.get<Map<String, dynamic>>(ApiPaths.health);
    if (health.statusCode != 200) {
      throw ApiConnectivityException(
        'Server at $resolved returned ${health.statusCode} on /health.',
      );
    }
    status = health.data?['status']?.toString() ?? 'ok';
  } on DioException catch (e) {
    throw ApiConnectivityException(_dioProbeMessage(e, resolved));
  }

  var generateOk = false;
  try {
    await dio.post<Map<String, dynamic>>(
      ApiPaths.generatePrompt,
      data: {
        'suno_version': 'v6',
        'primary_genre': 'test',
        'vibe': 'test',
      },
      options: Options(
        headers: const {'Content-Type': 'application/json'},
        validateStatus: (code) => code != null && code < 500,
      ),
    );
    generateOk = true;
  } on DioException catch (e) {
    final code = e.response?.statusCode;
    if (code == 404) {
      throw ApiConnectivityException(
        'Server returned 404 for POST /generate-prompt. '
        'Restart uvicorn from server/ or redeploy Railway (root directory: server/).',
      );
    }
    if (code == 503 || code == 502 || code == 401) {
      generateOk = false;
    } else {
      throw ApiConnectivityException(_dioProbeMessage(e, resolved));
    }
  }

  return MusicDirectorConnectionTestResult(
    resolvedBaseUrl: resolved,
    healthStatus: status,
    generateRouteOk: generateOk,
  );
}

String _dioProbeMessage(DioException e, String resolved) {
  final code = e.response?.statusCode;
  if (code == 404) {
    return 'Server not found at $resolved (404). Use host only — test /health in a browser.';
  }
  if (e.type == DioExceptionType.connectionTimeout ||
      e.type == DioExceptionType.connectionError ||
      e.type == DioExceptionType.receiveTimeout) {
    final uri = Uri.tryParse(resolved);
    final host = uri?.host ?? '';
    final buf = StringBuffer('Cannot reach $resolved. ');
    if (uri?.scheme == 'https' && isLocalOrLanHost(host)) {
      buf.write('Use http:// not https:// for local uvicorn. ');
    }
    if (isLikelyRouterGateway(host)) {
      buf.write(
        '$host is usually your router — run ipconfig on your PC and use IPv4 Address. ',
      );
    }
    buf.write(
      'PC: server must listen on 0.0.0.0:8080 (cd server → uvicorn … --host 0.0.0.0). '
      'Phone and PC must be on the same Wi‑Fi. On Windows, allow port 8080: run server\\open_firewall.ps1 as Administrator. '
      'Settings → Test connection after fixing firewall.',
    );
    return buf.toString();
  }
  return e.message ?? 'Cannot reach Music Director server at $resolved';
}
