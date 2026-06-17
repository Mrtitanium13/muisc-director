import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

Future<String> createPlaybackSource({
  String? filePath,
  Uint8List? bytes,
  required String fileName,
}) async {
  if (filePath != null && filePath.isNotEmpty) {
    return filePath;
  }
  if (bytes == null) {
    throw StateError('No audio data');
  }
  final dir = await getTemporaryDirectory();
  final safe = fileName.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
  final f = File(p.join(dir.path, 'md_play_$safe'));
  await f.writeAsBytes(bytes, flush: true);
  return f.path;
}

void revokePlaybackSource(String source) {
  if (source.startsWith('blob:')) return;
  try {
    final f = File(source);
    if (f.path.contains('md_play_') && f.existsSync()) {
      f.deleteSync();
    }
  } catch (_) {}
}
