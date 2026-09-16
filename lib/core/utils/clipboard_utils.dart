import 'package:flutter/services.dart';

Future<void> copyToClipboard(String text) async {
  await Clipboard.setData(ClipboardData(text: text));
}

/// Returns clipboard text, or null when empty / unavailable.
Future<String?> pasteFromClipboard() async {
  final data = await Clipboard.getData(Clipboard.kTextPlain);
  final text = data?.text;
  if (text == null || text.trim().isEmpty) return null;
  return text;
}
