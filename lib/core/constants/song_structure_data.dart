/// Preset song arrangements — user selection is sent to the AI as a hard roadmap.
class SongStructurePreset {
  const SongStructurePreset({
    required this.id,
    required this.label,
    required this.sectionOrder,
  });

  final String id;
  final String label;

  /// Section journey in fixed order (empty = flexible / special-cased).
  final String sectionOrder;
}

/// Song structure presets + text injected into the user block for prompt generation.
class SongStructureData {
  SongStructureData._();

  /// Default: AI picks one arc but must stay self-consistent in prose.
  static const String flexibleId = 'flexible';

  /// User-defined order in [songStructureCustom] on the form.
  static const String customId = 'custom';

  static const List<SongStructurePreset> presets = [
    SongStructurePreset(
      id: flexibleId,
      label: 'Flexible',
      sectionOrder: '',
    ),
    SongStructurePreset(
      id: 'standard_pop',
      label: 'Standard pop',
      sectionOrder:
          'Intro → Verse → Chorus → Verse → Chorus → Bridge → Final chorus → Outro',
    ),
    SongStructurePreset(
      id: 'radio_edit',
      label: 'Radio edit',
      sectionOrder: 'Verse → Chorus → Verse → Chorus → Outro',
    ),
    SongStructurePreset(
      id: 'edm_drop',
      label: 'EDM build & drop',
      sectionOrder:
          'Intro → Build-up → Drop → Breakdown → Build-up → Final drop → Outro',
    ),
    SongStructurePreset(
      id: 'hiphop',
      label: 'Hip-hop',
      sectionOrder:
          'Intro → Verse → Hook → Verse → Hook → Bridge → Hook → Outro',
    ),
    SongStructurePreset(
      id: 'rnb_ballad',
      label: 'R&B / ballad',
      sectionOrder:
          'Verse → Pre-chorus → Chorus → Verse → Chorus → Bridge → Final chorus → Outro',
    ),
    SongStructurePreset(
      id: 'aaba',
      label: 'AABA (jazz / standards)',
      sectionOrder: 'A section → A → B → A (with natural transitions)',
    ),
    SongStructurePreset(
      id: 'verse_chorus_loop',
      label: 'Verse–chorus loop',
      sectionOrder: 'Verse → Chorus (repeat this cycle; optional short intro/outro)',
    ),
    SongStructurePreset(
      id: customId,
      label: 'Custom',
      sectionOrder: '',
    ),
  ];

  static SongStructurePreset? presetById(String id) {
    for (final p in presets) {
      if (p.id == id) return p;
    }
    return null;
  }

  /// Line(s) for the model user block — structure must match generated prose.
  static String userBlockDirective({
    required String presetId,
    required String customNotes,
  }) {
    final custom = customNotes.trim();
    if (presetId == customId) {
      if (custom.isEmpty) {
        return 'Song structure: CUSTOM was selected but no outline was given — '
            'use a single clear Verse–Chorus arc; describe sections in order and '
            'do not contradict that order in the prompt. '
            'If the user pastes a bracketed roadmap next time, prefer bracketed '
            '[Section] lines with optional (staging notes) so SUNO STRUCTURE is not '
            'mistaken for singable lyrics.';
      }
      final bracketed = RegExp(r'\[[^\]]+\]').hasMatch(custom);
      if (bracketed) {
        return 'Song structure (REQUIRED — user outline uses bracketed [Section] '
            'headers with optional (staging notes). Output SUNO STRUCTURE in the '
            'same bracketed layout and section order; refine or expand notes as '
            'needed but do not collapse the roadmap into a single prose paragraph): '
            '$custom';
      }
      return 'Song structure (REQUIRED — describe the track following this exact '
          'section order in flowing prose, with no reordering or extra sections): '
          '$custom';
    }
    if (presetId.isEmpty || presetId == flexibleId) {
      return 'Song structure: Choose ONE coherent arrangement. Describe the track '
          'section-by-section in chronological order (intro through outro). The '
          'prompt must be internally consistent — the same section sequence from '
          'start to finish, with no contradictions.';
    }
    final preset = presetById(presetId);
    final order = preset?.sectionOrder ?? '';
    if (order.isEmpty) {
      return userBlockDirective(presetId: flexibleId, customNotes: '');
    }
    return 'Song structure (REQUIRED — the generated prompt must follow this exact '
        'section roadmap in order; describe each part in prose without skipping or '
        'reordering): $order';
  }
}
