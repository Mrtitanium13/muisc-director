class LyricQaScore {
  const LyricQaScore({
    required this.scores,
    required this.weightedTotal,
    required this.ship,
    this.qualityStatus = 'degraded',
    this.violations = const [],
    this.forbiddenHits = const [],
    this.hardFails = const [],
  });

  final Map<String, num> scores;
  final double weightedTotal;
  final bool ship;
  final String qualityStatus;
  final List<String> violations;
  final List<String> forbiddenHits;
  final List<String> hardFails;

  factory LyricQaScore.fromJson(Map<String, dynamic> json) {
    final rawScores = json['scores'];
    final scores = <String, num>{};
    if (rawScores is Map) {
      rawScores.forEach((k, v) {
        if (v is num) scores['$k'] = v;
      });
    }
    final lint = json['lint'];
    final hardFails = <String>[];
    if (lint is Map && lint['hard_fails'] is List) {
      hardFails.addAll((lint['hard_fails'] as List).map((e) => '$e'));
    }
    return LyricQaScore(
      scores: scores,
      weightedTotal: (json['weighted_total'] as num?)?.toDouble() ?? 0,
      ship: json['ship'] == true,
      qualityStatus: '${json['quality_status'] ?? (json['ship'] == true ? 'passed' : 'degraded')}',
      violations: (json['violations'] as List?)?.map((e) => '$e').toList() ??
          const [],
      forbiddenHits:
          (json['forbidden_hits'] as List?)?.map((e) => '$e').toList() ??
              const [],
      hardFails: hardFails,
    );
  }
}

class LyricResult {
  const LyricResult({
    required this.lyrics,
    this.title,
    this.qa,
    this.mode = 'full_song',
    this.ideas = const [],
    this.sections = const [],
    this.metadata = const {},
    this.raw = const {},
  });

  final String lyrics;
  final String? title;
  final LyricQaScore? qa;
  final String mode;
  final List<String> ideas;
  final List<Map<String, dynamic>> sections;
  final Map<String, dynamic> metadata;
  final Map<String, dynamic> raw;

  factory LyricResult.fromJson(Map<String, dynamic> json) {
    final ideasRaw = json['ideas'];
    final ideas = ideasRaw is List
        ? ideasRaw.map((e) => '$e').where((e) => e.trim().isNotEmpty).toList()
        : const <String>[];
    final sectionsRaw = json['sections'];
    final sections = <Map<String, dynamic>>[];
    if (sectionsRaw is List) {
      for (final s in sectionsRaw) {
        if (s is Map) sections.add(Map<String, dynamic>.from(s));
      }
    }
    final meta = json['metadata'];
    return LyricResult(
      lyrics: '${json['lyrics'] ?? ''}',
      title: json['title']?.toString(),
      qa: LyricQaScore.fromJson(json),
      mode: '${json['mode'] ?? 'full_song'}',
      ideas: ideas,
      sections: sections,
      metadata: meta is Map
          ? Map<String, dynamic>.from(meta)
          : const {},
      raw: json,
    );
  }
}
