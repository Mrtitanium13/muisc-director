// Version-aware prompt limits for Suno v3.5 through v5.5 Pro.
// Adapts style field length, engineering term complexity, and bracket word caps.

/// Prompt routing tier aligned with Suno model generations.
enum SunoPromptTier {
  v3_5,
  v4,
  v4_5Pro,
  v5,
  v5_5Pro,
}

class SunoPromptVersionConfig {
  const SunoPromptVersionConfig({
    required this.styleCharLimit,
    required this.allowComplexEngineeringTerms,
    required this.structuralTagWordLimit,
  });

  final int styleCharLimit;
  final bool allowComplexEngineeringTerms;
  final int structuralTagWordLimit;

  /// Simplifies engineering jargon for older models (v3/v3.5).
  String simplifyTerm(String term) {
    final lower = term.toLowerCase();
    if (lower.contains('brickwall')) return 'loud compressed master';
    if (lower.contains('sidechain')) return 'pumping synths';
    if (lower.contains('transparent hard limiting')) return 'loud clean master';
    if (lower.contains('ribbon mic')) return 'warm vocal mic';
    if (lower.contains('sub-bass drone')) return 'deep bass bed';
    return term;
  }

  String buildStyleField(String baseTags) {
    final parts = baseTags
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .map((s) => allowComplexEngineeringTerms ? s : simplifyTerm(s))
        .toList();
    var joined = parts.join(', ');
    if (joined.length > styleCharLimit) {
      joined = joined.substring(0, styleCharLimit - 3).trimRight();
      if (joined.endsWith(',')) {
        joined = joined.substring(0, joined.length - 1);
      }
      joined = '$joined...';
    }
    return joined;
  }

  String cleanStructuralTag(String rawTag) {
    final inner = rawTag
        .replaceAll('[', '')
        .replaceAll(']', '')
        .trim();
    if (inner.isEmpty) return '[]';
    final words = inner.split(RegExp(r'\s+')).take(structuralTagWordLimit).join(' ');
    return '[$words]';
  }

  static SunoPromptTier tierFromString(String raw) {
    final v = raw.trim().toLowerCase();
    if (v.contains('v3.5') || v == 'v3' || v == 'suno_v3.5') {
      return SunoPromptTier.v3_5;
    }
    // v6 family (current) + legacy v5.5 → richest tier
    if (v == 'v6' ||
        v == 'v6-wild' ||
        v == 'v6wild' ||
        v.startsWith('v5.5') ||
        v == 'suno_v5.5_pro') {
      return SunoPromptTier.v5_5Pro;
    }
    // v6-mini + legacy v5 → v5 tier
    if (v == 'v6-mini' ||
        v == 'v6mini' ||
        v.contains('v5') ||
        v == 'suno_v5') {
      return SunoPromptTier.v5;
    }
    if (v.contains('v4.5') || v == 'suno_v4.5') return SunoPromptTier.v4_5Pro;
    if (v.contains('v4') || v == 'suno_v4') return SunoPromptTier.v4;
    // Unknown → treat as flagship-rich
    return SunoPromptTier.v5_5Pro;
  }

  static SunoPromptVersionConfig forVersion(String sunoVersion) {
    return profiles[tierFromString(sunoVersion)] ?? profiles[SunoPromptTier.v4_5Pro]!;
  }

  static const Map<SunoPromptTier, SunoPromptVersionConfig> profiles = {
    SunoPromptTier.v3_5: SunoPromptVersionConfig(
      styleCharLimit: 120,
      allowComplexEngineeringTerms: false,
      structuralTagWordLimit: 6,
    ),
    SunoPromptTier.v4: SunoPromptVersionConfig(
      styleCharLimit: 150,
      allowComplexEngineeringTerms: true,
      structuralTagWordLimit: 8,
    ),
    SunoPromptTier.v4_5Pro: SunoPromptVersionConfig(
      styleCharLimit: 170,
      allowComplexEngineeringTerms: true,
      structuralTagWordLimit: 9,
    ),
    SunoPromptTier.v5: SunoPromptVersionConfig(
      styleCharLimit: 200,
      allowComplexEngineeringTerms: true,
      structuralTagWordLimit: 10,
    ),
    SunoPromptTier.v5_5Pro: SunoPromptVersionConfig(
      styleCharLimit: 200,
      allowComplexEngineeringTerms: true,
      structuralTagWordLimit: 10,
    ),
  };
}
