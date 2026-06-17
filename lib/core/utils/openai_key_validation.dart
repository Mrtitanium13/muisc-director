/// True if [key] looks like an [OpenRouter](https://openrouter.ai) key.
bool looksLikeOpenRouterKey(String key) {
  final t = key.trim();
  if (t.isEmpty) return false;
  return t.startsWith('sk-or-v1') ||
      t.startsWith('sk-or-') ||
      t.toLowerCase().contains('openrouter');
}

/// Snackbar text after saving a LaoZhang key.
String laozhangKeySavedMessage(String key) {
  final t = key.trim();
  if (t.isEmpty) return 'LaoZhang API key cleared';
  if (looksLikeOpenRouterKey(t)) {
    return 'Warning: this looks like an OpenRouter key — save it under OpenRouter instead.';
  }
  return 'LaoZhang key saved (api.laozhang.ai). Select LaoZhang below for on-device generation.';
}

/// Snackbar text after saving an OpenRouter key.
String openRouterKeySavedMessage(String key) {
  final t = key.trim();
  if (t.isEmpty) return 'OpenRouter API key cleared';
  if (!looksLikeOpenRouterKey(t) && t.length > 8) {
    return 'OpenRouter key saved. Select OpenRouter below for on-device generation.';
  }
  return 'OpenRouter key saved (openrouter.ai). Select OpenRouter below for on-device generation.';
}
