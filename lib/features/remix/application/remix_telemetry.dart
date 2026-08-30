import 'package:flutter/foundation.dart';

import 'package:music_director/features/remix/domain/remix_descriptors.dart';
import 'package:music_director/features/remix/domain/remix_mode.dart';

/// Privacy-safe remix observability — never logs raw title/artist.
abstract final class RemixTelemetry {
  RemixTelemetry._();

  static void emit(Map<String, Object?> fields) {
    final parts = <String>[
      for (final e in fields.entries)
        if (e.value != null) '${e.key}=${e.value}',
    ];
    debugPrint('[remix] ${parts.join(' ')}');
  }

  static Map<String, Object?> activationFields({
    required RemixMode mode,
    required bool nearActivation,
    required String genre,
    required String songGenerationType,
    String title = '',
    String artist = '',
    bool blockInjected = false,
  }) {
    return {
      'event': 'activation',
      'mode': mode.name,
      'near': nearActivation,
      'genre': genre.trim().isEmpty ? 'unset' : genre.trim(),
      'gen': songGenerationType,
      'block_v': remixBlockVersion,
      'fp': (title.trim().length >= 2 && artist.trim().length >= 2)
          ? RemixDescriptors.fingerprint(title, artist)
          : 'none',
      'injected': blockInjected,
    };
  }

  static void activation({
    required RemixMode mode,
    required bool nearActivation,
    required String genre,
    required String songGenerationType,
    String title = '',
    String artist = '',
    bool blockInjected = false,
  }) {
    emit(
      activationFields(
        mode: mode,
        nearActivation: nearActivation,
        genre: genre,
        songGenerationType: songGenerationType,
        title: title,
        artist: artist,
        blockInjected: blockInjected,
      ),
    );
  }

  static Map<String, Object?> postProcessFields({
    required RemixMode mode,
    required String songGenerationType,
    required int strippedLyricLines,
    required int stagingInjected,
    required bool leakHit,
    String title = '',
    String artist = '',
  }) {
    return {
      'event': 'post_process',
      'mode': mode.name,
      'gen': songGenerationType,
      'strip_n': strippedLyricLines,
      'staging_n': stagingInjected,
      'leak': leakHit,
      'block_v': remixBlockVersion,
      'fp': (title.trim().length >= 2 && artist.trim().length >= 2)
          ? RemixDescriptors.fingerprint(title, artist)
          : 'none',
    };
  }

  static void postProcess({
    required RemixMode mode,
    required String songGenerationType,
    required int strippedLyricLines,
    required int stagingInjected,
    required bool leakHit,
    String title = '',
    String artist = '',
  }) {
    emit(
      postProcessFields(
        mode: mode,
        songGenerationType: songGenerationType,
        strippedLyricLines: strippedLyricLines,
        stagingInjected: stagingInjected,
        leakHit: leakHit,
        title: title,
        artist: artist,
      ),
    );
  }
}
