// Shared types for the Music Prompt Router (Stage 1 classify → Stage 2 model).

class RoutingKeys {
  RoutingKeys._();

  static const genAfricanMainstream = 'GEN_AFRICAN_MAINSTREAM';
  static const genAfricanPidgin = 'GEN_AFRICAN_PIDGIN';
  static const genEastAsian = 'GEN_EAST_ASIAN';
  static const genLatin = 'GEN_LATIN';
  static const genWesternPop = 'GEN_WESTERN_POP';
  static const genEuropeanLingual = 'GEN_EUROPEAN_LINGUAL';
  static const genSea = 'GEN_SEA';
  static const genMiddleEastern = 'GEN_MIDDLE_EASTERN';
  static const hybridMultiGenre = 'HYBRID_MULTI_GENRE';
  static const hybridCultural = 'HYBRID_CULTURAL';

  static const all = {
    genAfricanMainstream,
    genAfricanPidgin,
    genEastAsian,
    genLatin,
    genWesternPop,
    genEuropeanLingual,
    genSea,
    genMiddleEastern,
    hybridMultiGenre,
    hybridCultural,
  };
}

typedef RoutingKey = String;

class ModelKeys {
  ModelKeys._();

  static const claudeSonnet = 'claude-sonnet';
  static const gpt5 = 'gpt-5';
  static const glm = 'glm';
  static const mistral = 'mistral';
  static const qwen = 'qwen';
}

typedef ModelKey = String;

typedef AfricanPidginSubVariant =
    String; // lagos_standard | rivers_state | igbo | ibibio

typedef EastAsianSubVariant = String;

class GenreSlot {
  const GenreSlot({
    required this.genre,
    this.microGenre,
    this.weight = 1.0,
    this.bpm,
    this.key,
    this.mood,
    this.instruments = const [],
    this.language,
    this.regionTags = const [],
  });

  final String genre;
  final String? microGenre;
  final double weight;
  final int? bpm;
  final String? key;
  final String? mood;
  final List<String> instruments;
  final String? language;
  final List<String> regionTags;
}

class HybridResolution {
  const HybridResolution({
    required this.dominant,
    required this.secondary,
    required this.tempoStrategy,
    required this.structureStrategy,
    required this.vocabularyMerge,
  });

  final GenreSlot dominant;
  final List<GenreSlot> secondary;
  final String tempoStrategy;
  final String structureStrategy;
  final String vocabularyMerge;
}

class Stage1Classification {
  const Stage1Classification({
    required this.routingKey,
    required this.isHybrid,
    required this.primarySlot,
    this.secondarySlots = const [],
    required this.dominantMood,
    required this.estimatedBpm,
    required this.dominantLanguage,
    this.languagesDetected = const [],
    this.hybridResolution,
    this.pidginSubVariant,
    this.eastAsianSubVariant,
    this.structuralTemplateHint,
  });

  final RoutingKey routingKey;
  final bool isHybrid;
  final GenreSlot primarySlot;
  final List<GenreSlot> secondarySlots;
  final String dominantMood;
  final int estimatedBpm;
  final String dominantLanguage;
  final List<String> languagesDetected;
  final HybridResolution? hybridResolution;
  final AfricanPidginSubVariant? pidginSubVariant;
  final EastAsianSubVariant? eastAsianSubVariant;
  final String? structuralTemplateHint;
}

class Stage2RoutingPlan {
  const Stage2RoutingPlan({
    required this.classification,
    required this.primaryModelKey,
    required this.userBlockAppend,
    this.qaWarnings = const [],
  });

  final Stage1Classification classification;
  final ModelKey primaryModelKey;
  final String userBlockAppend;
  final List<String> qaWarnings;
}
