/// How to vary melodic emphasis across repeated generations (same form settings).
enum MelodyVariationMode {
  /// Only the chosen melody style / custom line applies.
  none,

  /// Cycle through [kMelodySessionVariationDirectives] in order (persisted).
  rotate,

  /// Pick a different directive each generation.
  random;

  static MelodyVariationMode fromId(String? raw) {
    switch ((raw ?? '').trim().toLowerCase()) {
      case 'rotate':
        return MelodyVariationMode.rotate;
      case 'random':
        return MelodyVariationMode.random;
      default:
        return MelodyVariationMode.none;
    }
  }

  String get id => name;
}
