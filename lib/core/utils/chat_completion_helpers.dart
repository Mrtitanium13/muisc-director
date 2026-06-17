/// Parse OpenAI-compatible chat completion bodies (LaoZhang / OpenRouter).
String? extractChatMessageContent(dynamic message) {
  if (message is! Map) return null;
  final content = message['content'];
  if (content is String) return content;
  if (content is List) {
    final buf = StringBuffer();
    for (final part in content) {
      if (part is! Map) continue;
      final type = part['type']?.toString();
      if (type == 'text' || type == 'output_text') {
        final text = part['text']?.toString();
        if (text != null && text.isNotEmpty) buf.write(text);
      }
    }
    final joined = buf.toString();
    return joined.isEmpty ? null : joined;
  }
  return null;
}

/// Mirror server `prompt_pipeline._chat` token kwargs for gateway quirks.
void applyChatTokenLimits(Map<String, dynamic> payload, String model, int maxTok) {
  final m = model.toLowerCase();
  if (m.contains('gemini') || m.startsWith('gpt') || m.contains('claude')) {
    payload['max_completion_tokens'] = maxTok;
  }
}

String describeEmptyChatResponse({
  required String model,
  String? finishReason,
  Object? refusal,
}) {
  final parts = <String>['Empty response from $model on LaoZhang/OpenRouter.'];
  if (finishReason != null && finishReason.isNotEmpty) {
    parts.add('finish_reason=$finishReason.');
  }
  if (refusal != null && refusal.toString().isNotEmpty) {
    parts.add('refusal=${refusal.toString()}.');
  }
  if (finishReason == 'length') {
    parts.add('Output hit max_tokens — retrying with fallback model.');
  } else {
    parts.add(
      'Check API key/balance at api.laozhang.ai, or retry (app will fall back to Gemini Pro).',
    );
  }
  return parts.join(' ');
}
