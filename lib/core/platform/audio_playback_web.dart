// Web-only playback via blob URLs (package:web migration can wait).
// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:html' as html;
import 'dart:typed_data';

String? _lastBlobUrl;

Future<String> createPlaybackSource({
  String? filePath,
  Uint8List? bytes,
  required String fileName,
}) async {
  if (filePath != null) {
    throw UnsupportedError('filePath not used on web');
  }
  if (bytes == null) {
    throw StateError('No audio data');
  }
  if (_lastBlobUrl != null) {
    html.Url.revokeObjectUrl(_lastBlobUrl!);
    _lastBlobUrl = null;
  }
  final blob = html.Blob([bytes]);
  _lastBlobUrl = html.Url.createObjectUrlFromBlob(blob);
  return _lastBlobUrl!;
}

void revokePlaybackSource(String source) {
  if (source.startsWith('blob:')) {
    html.Url.revokeObjectUrl(source);
  }
  if (source == _lastBlobUrl) {
    _lastBlobUrl = null;
  }
}
