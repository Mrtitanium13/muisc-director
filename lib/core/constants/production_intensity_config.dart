import 'prompt_flow_data.dart';

/// Production FX intensity slider (1–3) for Suno Prompt Builder.
abstract final class ProductionIntensityConfig {
  ProductionIntensityConfig._();

  static const int minLevel = 1;
  static const int maxLevel = 3;
  static const int defaultLevel = 2;

  static const String helperText =
      'Controls how much genre-specific production FX and arrangement build energy '
      'is woven into Block 1 prose and Block 2 section tags.';

  static const String _lowInstruction = '''
LOW (1): Subtle, almost invisible production.
- Use sparse FX mentions: gentle reverb, soft compression, minimal layering.
- Keep arrangement language restrained; prioritize vocal performance and song form.
- Avoid hype build/drop language unless the genre absolutely requires it.''';

  static const String _mediumInstruction = '''
MEDIUM (2): Balanced genre-appropriate production.
- Use standard FX and arrangement tokens for the genre (sidechain, delay tails, vocal stacks, modulations).
- Mention section energy changes (build, lift, breakdown) where they serve the song.
- Keep FX in service of the lyric/melody, not overwhelming.''';

  static const String _highInstruction = '''
HIGH (3): Maximum production spectacle and arrangement detail.
- Dense FX vocabulary: filter sweeps, risers, impacts, sub drops, layered SFX, automation.
- Explicit build/drop/contrast staging in every section where genre permits.
- Treat Block 1 as a producer brief and Block 2 tags as a fully notated arrangement.''';

  static const Map<int, ({String label, String instruction})> _bands = {
    1: (label: 'Low', instruction: _lowInstruction),
    2: (label: 'Medium', instruction: _mediumInstruction),
    3: (label: 'High', instruction: _highInstruction),
  };

  static int clampLevel(int value) => value.clamp(minLevel, maxLevel).toInt();

  static ({String label, String instruction}) bandFor(int value) {
    return _bands[clampLevel(value)] ?? _bands[defaultLevel]!;
  }

  static String levelLabel(int value) => bandFor(value).label;

  static String levelInstruction(int value) => bandFor(value).instruction;

  /// Dropdown option helpers for Flutter form binding.
  static List<Option> get options => [
        for (var i = minLevel; i <= maxLevel; i++)
          Option(
            value: i.toString(),
            label: '$i — ${levelLabel(i)}',
          ),
      ];

  static Option optionFor(int value) {
    final clamped = clampLevel(value);
    return Option(
      value: clamped.toString(),
      label: '$clamped — ${levelLabel(clamped)}',
    );
  }

  static int? parseOptionValue(String? value) {
    if (value == null || value.isEmpty) return null;
    return int.tryParse(value);
  }

  /// Injected into the Suno user block.
  static String userBlockDirective(int level) {
    final clamped = clampLevel(level);
    final band = bandFor(clamped);
    return '''
PRODUCTION FX INTENSITY: $clamped/$maxLevel (${band.label})

${band.instruction}

Apply the GENRE FX MATRIX at this intensity level in both Block 1 prose and Block 2 section tags.'''.trim();
  }
}
