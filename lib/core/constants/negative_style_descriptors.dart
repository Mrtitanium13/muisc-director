/// Part G — Suno-readable negative style phrases for the Avoid field.
class NegativeStyleDescriptors {
  NegativeStyleDescriptors._();

  /// Chip label -> phrase appended to Avoid (character-only, no gear SKUs).
  static const List<(String label, String avoidPhrase)> chips = [
    ('No autotune', 'no pitch correction, natural vocal'),
    ('Dry vocal', 'dry intimate vocal, minimal reverb'),
    ('Organic drums', 'organic drums, no quantized beats'),
    ('Solo vocal', 'solo vocal, no harmonies'),
    ('No filler ad-libs', 'no filler ad-libs, focused vocal'),
    ('Raw / demo', 'raw production, unpolished, demo-like'),
    ('No genre drift', 'focused, cohesive, no genre shifts'),
    ('Big chorus', 'anthemic, powerful stacked chorus'),
    ('Abrupt end', 'abrupt end, no fade'),
    ('Natural dynamics', 'natural dynamics, no squashed mix'),
    ('Tight low end', 'tight sub, separated kick and bass'),
    ('Smooth highs', 'smooth high end, no harshness'),
    ('Analog warmth', 'analog warmth, tube saturation'),
  ];

  static String mergeIntoAvoid(String current, String phrase) {
    final t = current.trim();
    if (t.isEmpty) return phrase;
    if (t.toLowerCase().contains(phrase.toLowerCase())) return t;
    return '$t, $phrase';
  }
}
