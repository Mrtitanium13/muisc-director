/// Production FX intensity slider (1–3) for Suno Prompt Builder.
class ProductionIntensityConfig {
  ProductionIntensityConfig._();

  static const int minLevel = 1;
  static const int maxLevel = 3;
  static const int defaultLevel = 2;

  static int clampLevel(int value) =>
      value.clamp(minLevel, maxLevel).toInt();

  static String levelLabel(int value) {
    switch (clampLevel(value)) {
      case 1:
        return 'Low';
      case 2:
        return 'Medium';
      case 3:
        return 'High';
      default:
        return 'Medium';
    }
  }

  static String helperText =
      'Genre-specific production FX and arrangement build energy woven into Block 1 prose and Block 2 section tags.';

  static String userBlockDirective(int level) {
    final clamped = clampLevel(level);
    return 'PRODUCTION FX INTENSITY: $clamped (${levelLabel(clamped)}) — apply GENRE FX MATRIX lane below.';
  }
}
