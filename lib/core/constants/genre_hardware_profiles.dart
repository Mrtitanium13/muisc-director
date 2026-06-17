import 'genre_hardware_profiles_data.dart';

/// Part E v2.1 genre-specific hardware defaults for Block 1 injection.
class GenreHardwareProfiles {
  GenreHardwareProfiles._();

  static Map<String, dynamic>? resolveProfile(
    String primary,
    String fusion,
  ) {
    final blob = '${primary.trim()} ${fusion.trim()}'.toLowerCase();
    Map<String, dynamic>? best;
    var bestLen = 0;
    for (final row in GenreHardwareProfilesData.profiles) {
      final keys = row['keywords'] as List<dynamic>? ?? [];
      for (final raw in keys) {
        final kw = raw.toString().toLowerCase();
        if (kw.isNotEmpty && blob.contains(kw) && kw.length > bestLen) {
          best = row;
          bestLen = kw.length;
        }
      }
    }
    return best;
  }

  static String userBlockDirective({
    required String primaryGenre,
    String subGenreFusion = '',
    bool djIntro = false,
    bool djOutro = false,
  }) {
    final p = resolveProfile(primaryGenre, subGenreFusion);
    final id = p?['id'] as String? ?? 'DEFAULT';
    final style = p?['style_descriptors'] as String? ??
        'polished producer mix with genre-appropriate LUFS and named gear chain';
    final lead = p?['lead_vocal'] as String? ?? 'Neumann U87 or SM7B';
    final chain = p?['vocal_chain'] as String? ?? '1073 -> 1176 -> LA-2A -> plate';
    final drums = p?['drums'] as String? ?? 'genre-appropriate kit or drum machine';
    final bass = p?['bass'] as String? ?? 'DI + amp or sub synth';
    final keys = p?['keys_synths'] as String? ?? 'Rhodes, piano, or synth pads';
    final outboard = p?['outboard'] as String? ?? 'SSL G bus glue';
    final monitoring = p?['monitoring'] as String? ?? 'Genelec + NS10';
    final room = p?['room'] as String? ?? 'controlled studio';
    final vibe = p?['vibe'] as String? ?? 'release-ready, −9 to −11 LUFS';

    final lines = <String>[
      'GENRE HARDWARE DEFAULTS (Part E v2.1 — mandatory in Block 1 unless user overrides):',
      'Profile: [$id]',
      'Style descriptors (weave naturally into Block 1 prose): $style',
      'Lead vocal mic + chain: $lead | Chain: $chain',
      'Drums: $drums',
      'Bass: $bass',
      'Keys / synths: $keys',
      'Outboard / bus: $outboard',
      'Monitoring: $monitoring',
      'Room / tracking: $room',
      'Vibe / loudness: $vibe (include −1.0 dBTP true-peak ceiling in Block 1).',
    ];
    if (djIntro && djOutro) {
      lines.add(
        'DJ phrasing (mandatory in Block 1): sixteen-bar filtered drum intro, sixteen-bar '
        'stripped percussion outro, beatmatch-clean sixteen-bar phrasing throughout.',
      );
    } else if (djIntro) {
      lines.add(
        'DJ phrasing (mandatory in Block 1): sixteen-bar filtered drum intro, '
        'beatmatch-clean sixteen-bar phrasing, gradual filter opening before main groove.',
      );
    } else if (djOutro) {
      lines.add(
        'DJ phrasing (mandatory in Block 1): sixteen-bar stripped percussion outro, '
        'beatmatch-clean sixteen-bar phrasing, long mix-out tail without a hard stop.',
      );
    }
    lines.add(
      'Do not omit hardware, LUFS intent, dBTP ceiling, mix moves, or style-descriptor '
      'language from Block 1 — Suno uses this for loudness, texture, and club/DJ polish.',
    );
    return lines.join('\n');
  }
}
