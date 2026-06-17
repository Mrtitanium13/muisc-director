/// Strips paths, fixes `https` → `http` on LAN/local hosts, removes trailing slashes.
String normalizeApiBaseUrl(String baseUrl) {
  var s = baseUrl.trim().replaceAll(RegExp(r'/+$'), '');
  if (s.isEmpty) return s;

  // Allow "192.168.1.7:8080" without scheme.
  if (!s.contains('://') && RegExp(r'^[\d.a-zA-Z-]+(:\d+)?$').hasMatch(s)) {
    s = 'http://$s';
  }
  const suffixes = [
    '/generate-prompt',
    '/analyze',
    '/health',
    '/api/v1',
    '/api',
    '/v1',
  ];
  for (final suffix in suffixes) {
    if (s.toLowerCase().endsWith(suffix)) {
      s = s.substring(0, s.length - suffix.length);
      s = s.replaceAll(RegExp(r'/+$'), '');
    }
  }

  final uri = Uri.tryParse(s);
  if (uri == null || !uri.hasScheme || uri.host.isEmpty) return s;

  var scheme = uri.scheme.toLowerCase();
  var host = uri.host;
  if (isLocalOrLanHost(host) && scheme == 'https') {
    scheme = 'http';
  }

  return Uri(
    scheme: scheme,
    host: host,
    port: uri.hasPort ? uri.port : null,
  ).toString().replaceAll(RegExp(r'/+$'), '');
}

bool isLocalOrLanHost(String host) {
  final h = host.toLowerCase();
  if (h == 'localhost' || h == '127.0.0.1' || h == '10.0.2.2') return true;
  final parts = h.split('.');
  if (parts.length != 4) return false;
  final a = int.tryParse(parts[0]);
  final b = int.tryParse(parts[1]);
  if (a == null || b == null) return false;
  if (a == 10) return true;
  if (a == 192 && b == 168) return true;
  if (a == 172 && b >= 16 && b <= 31) return true;
  return false;
}

/// `.1` on 192.168.x.x / 10.x.x.x is often the router, not the dev PC.
bool isLikelyRouterGateway(String host) {
  if (!isLocalOrLanHost(host) || host == '127.0.0.1' || host == '10.0.2.2') {
    return false;
  }
  final parts = host.split('.');
  if (parts.length != 4) return false;
  return parts[3] == '1';
}

String? validateMusicDirectorApiBaseUrl(String baseUrl) {
  final s = normalizeApiBaseUrl(baseUrl);
  if (s.isEmpty) {
    return 'Enter your server URL (e.g. http://192.168.1.10:8080).';
  }
  final uri = Uri.tryParse(s);
  if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
    return 'Invalid URL. Example: http://192.168.1.10:8080 or https://your-app.up.railway.app';
  }

  final host = uri.host.toLowerCase();
  if (host.contains('laozhang.ai') ||
      host.contains('openrouter.ai') ||
      host.contains('api.openai.com')) {
    return 'Do not use the LLM provider URL here. Use your Music Director server '
        '(uvicorn or Railway), e.g. http://192.168.1.10:8080.';
  }
  if (s.contains('/chat/completions')) {
    return 'MD_API_BASE_URL must be the server root only, not /chat/completions.';
  }

  if (isLikelyRouterGateway(host)) {
    return '$host is usually your Wi‑Fi router, not your PC. '
        'On Windows run ipconfig and use IPv4 Address (e.g. 192.168.5.42), with http not https.';
  }

  if (isLocalOrLanHost(host) && uri.scheme != 'http') {
    return 'Local dev URL must start with http:// (e.g. http://$host:${uri.port}).';
  }

  return null;
}
