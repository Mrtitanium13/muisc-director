import 'dart:typed_data';

Future<String> createPlaybackSource({
  String? filePath,
  Uint8List? bytes,
  required String fileName,
}) async =>
    throw UnsupportedError('Unsupported platform');

void revokePlaybackSource(String source) {}
