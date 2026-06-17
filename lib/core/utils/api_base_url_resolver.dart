import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// When `true` in `.env`, rewrite Android loopback to `10.0.2.2` (emulator only).
bool androidEmulatorHostRewriteEnabled() {
  if (!dotenv.isInitialized) return false;
  final v = dotenv.env['MD_ANDROID_EMULATOR']?.trim().toLowerCase();
  return v == 'true' || v == '1' || v == 'yes' || v == 'on';
}

/// Rewrites `localhost` / `127.0.0.1` for **Android emulator** only when opted in.
///
/// - **Android emulator:** set `MD_ANDROID_EMULATOR=true` in `.env` → `10.0.2.2`
/// - **Physical Android phone:** use PC LAN IP (e.g. `http://192.168.1.10:8080`) — no rewrite
/// - **iOS simulator / desktop:** `127.0.0.1` works as-is
String? resolveDeviceApiBaseUrl(String? baseUrl) {
  final raw = baseUrl?.trim();
  if (raw == null || raw.isEmpty) return null;

  final uri = Uri.tryParse(raw);
  if (uri == null || !uri.hasScheme) return raw;

  final host = uri.host.toLowerCase();
  final isLoopback = host == '127.0.0.1' || host == 'localhost';
  if (!isLoopback) return raw;

  if (kIsWeb) return raw;

  if (defaultTargetPlatform == TargetPlatform.android &&
      androidEmulatorHostRewriteEnabled()) {
    return uri.replace(host: '10.0.2.2').toString();
  }

  return raw;
}

/// Short hint when [baseUrl] still points at loopback on a mobile build.
String loopbackApiHint(String? baseUrl) {
  final raw = baseUrl?.trim() ?? '';
  if (raw.isEmpty) return '';
  final uri = Uri.tryParse(raw);
  if (uri == null) return '';
  final host = uri.host.toLowerCase();
  if (host != '127.0.0.1' && host != 'localhost' && host != '10.0.2.2') {
    return '';
  }
  if (defaultTargetPlatform == TargetPlatform.android) {
    return 'Android: use http://10.0.2.2:8080 (emulator) or your PC LAN IP on a real device. '
        'Start the server: cd server && uvicorn app.main:app --host 0.0.0.0 --port 8080';
  }
  if (defaultTargetPlatform == TargetPlatform.iOS) {
    return 'iOS simulator: http://127.0.0.1:8080 works. On a real iPhone use your Mac\'s LAN IP.';
  }
  return 'Start the API: cd server && uvicorn app.main:app --reload --port 8080';
}
