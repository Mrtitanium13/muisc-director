import 'dart:typed_data';

/// Loaded audio for analysis / playback (file path on mobile/desktop, bytes on web).
class AudioSession {
  const AudioSession({
    this.path,
    this.bytes,
    required this.name,
  }) : assert(
          path != null || bytes != null,
          'Provide path or bytes',
        );

  final String? path;
  final Uint8List? bytes;
  final String name;

  bool get isWebBytes => bytes != null;
}
