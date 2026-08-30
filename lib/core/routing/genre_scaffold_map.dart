import '../constants/genre_data.dart';
import 'music_prompt_routing.dart';

/// Intro/outro bar scaffold families for all 157 unique app genres (Rule A6).
enum ScaffoldType {
  clubExtended,
  clubStandard,
  clubTight,
  radioShort,
  radioWide,
  narrativeWide,
  ambientLong,
}

class GenreScaffoldSpec {
  const GenreScaffoldSpec({
    required this.type,
    required this.introBars,
    required this.outroBars,
  });

  final ScaffoldType type;
  final int introBars;
  final int outroBars;
}

/// Master genre → intro/outro scaffold dispatch (157 unique genres, Rule A6).
class GenreScaffoldMap {
  GenreScaffoldMap._();

  static String normalizeGenre(String genre) => genre.toLowerCase().trim();

  static final Map<String, GenreScaffoldSpec> _specs = _buildSpecs();

  static Map<String, GenreScaffoldSpec> _buildSpecs() {
    final m = <String, GenreScaffoldSpec>{};

    void put(String genre, ScaffoldType type, {int? intro, int? outro}) {
      final key = normalizeGenre(genre);
      final bars = _defaultBars(key, type, intro: intro, outro: outro);
      m[key] = GenreScaffoldSpec(
        type: type,
        introBars: bars.$1,
        outroBars: bars.$2,
      );
    }

    void putAll(
      Iterable<String> genres,
      ScaffoldType type, {
      int? intro,
      int? outro,
    }) {
      for (final g in genres) {
        put(g, type, intro: intro, outro: outro);
      }
    }

    // ── clubExtended (32/32) ──
    putAll(const [
      'House',
      'Deep House',
      'Soulful House',
      'Tech House',
      'Progressive House',
      'Melodic House',
      'Techno',
      'Hard Techno',
      'Melodic Techno',
      'Acid Techno',
      'Trance',
      'Uplifting Trance',
      'Vinahouse',
      'Afro House',
      'Amapiano-Vinahouse',
      'Gqom',
      'Amapiano',
    ], ScaffoldType.clubExtended);

    // ── clubStandard (24/24 default; DnB 32/24) ──
    putAll(const [
      'Big Room',
      'Big Room Techno',
      'Dubstep',
      'Melodic Dubstep',
      'Liquid DnB',
      'Future House',
      'Hardstyle',
      'Rawstyle',
      'EBM',
    ], ScaffoldType.clubStandard);
    put('Drum & Bass', ScaffoldType.clubStandard, intro: 32, outro: 24);

    // ── clubTight (16/16–24) ──
    putAll(const [
      'Future Bass',
      'Hard Bounce',
      'EDM Bounce',
      'Nu-Disco',
      'Future Funk',
      'Disco House',
      'UK Garage',
      'Jersey Club',
      'Dance Pop',
      'Brazilian Funk',
    ], ScaffoldType.clubTight);

    // ── radioShort ──
    putAll(const [
      'Pop',
      'Mainstream Pop',
      'Pop / Max Martin',
      'Electropop',
      'Bedroom Pop',
      'K-Pop',
      'J-Pop',
      'Synth Pop',
      'Contemporary R&B',
      'New Jack Swing',
      'Trap Soul',
      'Trap',
      'Drill',
      'UK Drill',
      'NY Drill',
      'Dembow',
      'Dancehall',
      'Soca',
      'Fuji',
      'New Wave',
      'Gospel',
      'Traditional Gospel',
      'Contemporary Gospel',
      'Urban Gospel',
      'Praise/Worship',
      'Modern Worship',
      'Pop Worship',
      'CCM',
      'Southern Gospel',
      'Country Gospel',
      'Country',
      'Modern Country',
      'Bluegrass',
    ], ScaffoldType.radioShort);
    put('Hyperpop', ScaffoldType.radioShort, intro: 2, outro: 6);
    put('Punk', ScaffoldType.radioShort, intro: 2, outro: 6);
    put('Death Metal', ScaffoldType.radioShort, intro: 4, outro: 8);
    put('Pop Punk', ScaffoldType.radioShort, intro: 4, outro: 10);

    // Dual-path defaults (overridden at runtime by vibe hint)
    put('Reggaeton', ScaffoldType.radioShort, intro: 4, outro: 16);
    put('Afrobeats', ScaffoldType.radioWide, intro: 8, outro: 16);

    // ── radioWide ──
    putAll(const [
      'Hip Hop',
      'Boom Bap',
      'Melodic Trap',
      'Phonk',
      'Afro-Swing',
      'Afro Rap',
      'R&B',
      '90s R&B',
      'Indie Pop',
      'C-Pop',
      'Mandopop',
      'Latin Pop',
      'Rock',
      'Alt Rock',
      'Alternative',
      'Metalcore',
      'Indie Folk',
      'Worship Ballad',
      'Bebop',
      'Delta Blues',
      'City Pop',
      'Punjabi',
    ], ScaffoldType.radioWide);

    // ── narrativeWide ──
    putAll(const [
      'Cloud Rap',
      'Jazz Rap',
      'Neo-Soul',
      'Soul',
      'Quiet Storm',
      'Funk',
      'Indie Rock',
      'Emo',
      'Hard Rock',
      'Classic Rock',
      'Metal',
      'Heavy Metal',
      'Outlaw Country',
      'Americana',
      'Folk-Rock',
      'Singer-Songwriter',
      'Afro-Gospel',
      'Jazz',
      'Vocal Jazz',
      'Smooth Jazz',
      'Jazz Fusion',
      'Fusion',
      'Nu-Jazz',
      'Acid Jazz',
      'Big Band',
      'Blues',
      'Chicago Blues',
      'Bachata',
      'Salsa',
      'Bossa Nova',
      'Cumbia',
      'Vallenato',
      'Sertanejo',
      'Forró',
      'Reggae',
      'Roots Reggae',
      'Highlife',
      'Bhangra',
      'Folk',
      'Bollywood',
      'Filmi',
      'Middle Eastern',
      'Trailer',
      'Industrial',
    ], ScaffoldType.narrativeWide);

    // ── ambientLong ──
    putAll(const [
      'Lo-Fi Hip Hop',
      'Chillhop',
      'Post-Rock',
      'Shoegaze',
      'Dream Pop',
      'Dub',
      'Orchestral',
      'Film Score',
      'Cinematic',
      'Ambient',
      'Dark Ambient',
      'Ambient Score',
      'Vaporwave',
      'Synthwave',
      'Retrowave',
    ], ScaffoldType.ambientLong);

    assert(
      _validateCoverage(m),
      'GenreScaffoldMap must cover all ${GenreData.subGenresByCategory.values.expand((e) => e).length} genres exactly once',
    );
    return m;
  }

  static bool _validateCoverage(Map<String, GenreScaffoldSpec> m) {
    final expected = <String>{};
    for (final list in GenreData.subGenresByCategory.values) {
      for (final g in list) {
        expected.add(normalizeGenre(g));
      }
    }
    if (m.length != expected.length) return false;
    for (final key in expected) {
      if (!m.containsKey(key)) return false;
    }
    return true;
  }

  static (int, int) _defaultBars(
    String key,
    ScaffoldType type, {
    int? intro,
    int? outro,
  }) {
    if (intro != null && outro != null) return (intro, outro);
    return switch (type) {
      ScaffoldType.clubExtended => (32, 32),
      ScaffoldType.clubStandard => (24, 24),
      ScaffoldType.clubTight => (16, 20),
      ScaffoldType.radioShort => _radioShortBars(key),
      ScaffoldType.radioWide => (8, 16),
      ScaffoldType.narrativeWide => (12, 20),
      ScaffoldType.ambientLong => (24, 32),
    };
  }

  static (int, int) _radioShortBars(String key) {
    if (key == 'hyperpop' || key == 'punk') return (2, 6);
    if (key.contains('drill') || key == 'trap' || key == 'dembow') {
      return (4, 8);
    }
    if (key.contains('gospel') ||
        key.contains('worship') ||
        key == 'ccm' ||
        key.contains('country gospel')) {
      return (4, 12);
    }
    if (key == 'reggaeton') return (4, 16);
    return (4, 8);
  }

  static final RegExp _afrobeatsClubHint = RegExp(
    r'club|extended\s*mix|dj\s*set|log\s*drum|perreo',
    caseSensitive: false,
  );

  static final RegExp _reggaetonClubHint = RegExp(
    r'club|remix|dj|perreo|dembow\s*heavy',
    caseSensitive: false,
  );

  static ScaffoldType resolveScaffoldType(String genre, {String? vibeHint}) {
    final l = normalizeGenre(genre);
    final hint = (vibeHint ?? '').toLowerCase();

    if (l.contains('afrobeats') && !l.contains('afro-gospel')) {
      return _afrobeatsClubHint.hasMatch(hint)
          ? ScaffoldType.clubStandard
          : ScaffoldType.radioWide;
    }
    if (l.contains('reggaeton')) {
      return _reggaetonClubHint.hasMatch(hint)
          ? ScaffoldType.clubTight
          : ScaffoldType.radioShort;
    }

    return _specs[l]?.type ?? _inferFallback(l);
  }

  static ScaffoldType _inferFallback(String g) {
    if (_isClubFamily(g)) return ScaffoldType.clubExtended;
    if (_isRadioFamily(g)) return ScaffoldType.radioWide;
    return ScaffoldType.radioWide;
  }

  static bool _isClubFamily(String g) => [
        'amapiano',
        'house',
        'techno',
        'gqom',
        'vinahouse',
        'trance',
        'drum & bass',
        'dubstep',
        'hardstyle',
      ].any(g.contains);

  static bool _isRadioFamily(String g) => [
        'pop',
        'r&b',
        'country',
        'gospel',
        'ballad',
        'k-pop',
        'j-pop',
        'mandopop',
      ].any(g.contains);

  static GenreScaffoldSpec specFor(String genre, {String? vibeHint}) {
    final l = normalizeGenre(genre);
    final type = resolveScaffoldType(genre, vibeHint: vibeHint);
    final hint = (vibeHint ?? '').toLowerCase();

    if (l.contains('afrobeats') && !l.contains('afro-gospel')) {
      if (_afrobeatsClubHint.hasMatch(hint)) {
        return const GenreScaffoldSpec(
          type: ScaffoldType.clubStandard,
          introBars: 16,
          outroBars: 24,
        );
      }
      return const GenreScaffoldSpec(
        type: ScaffoldType.radioWide,
        introBars: 8,
        outroBars: 16,
      );
    }
    if (l.contains('reggaeton')) {
      if (_reggaetonClubHint.hasMatch(hint)) {
        return const GenreScaffoldSpec(
          type: ScaffoldType.clubTight,
          introBars: 16,
          outroBars: 24,
        );
      }
      return const GenreScaffoldSpec(
        type: ScaffoldType.radioShort,
        introBars: 4,
        outroBars: 16,
      );
    }

    final base = _specs[l];
    if (base != null && base.type == type) return base;
    final bars = _defaultBars(l, type);
    return GenreScaffoldSpec(type: type, introBars: bars.$1, outroBars: bars.$2);
  }

  static GenreScaffoldSpec specForClassification(
    Stage1Classification c, {
    String? vibeHint,
  }) {
    final hint = vibeHint ?? c.dominantMood;
    return specFor(c.primarySlot.genre, vibeHint: hint);
  }

  static String buildIntroOutroInstruction(
    String genre, {
    String? vibeHint,
  }) {
    final spec = specFor(genre, vibeHint: vibeHint);
    return _instructionForSpec(spec, genre);
  }

  static String buildIntroOutroInstructionForClassification(
    Stage1Classification c, {
    String? vibeHint,
  }) {
    final spec = specForClassification(c, vibeHint: vibeHint);
    final genre = c.primarySlot.genre;
    if (c.isHybrid && c.secondarySlots.isNotEmpty) {
      final sec = c.secondarySlots.map((s) => s.genre).join(' + ');
      return '${_instructionForSpec(spec, genre)}\n'
          'HYBRID SCAFFOLD: dominant genre "$genre" owns intro/outro bar plan; '
          'secondary ($sec) adapts texture only — do NOT apply secondary intro length.';
    }
    return _instructionForSpec(spec, genre);
  }

  static String _instructionForSpec(GenreScaffoldSpec spec, String genre) {
    final intro = spec.introBars;
    final outro = spec.outroBars;
    return switch (spec.type) {
      ScaffoldType.clubExtended =>
        'RULE A6 SCAFFOLD ($genre / clubExtended): '
        'INTRO: $intro bars (mix-in ready). Bar plan: shaker/pad 1-8, '
        'bass enter bar 9, percussion layers 17-24, vocal tease 25-32. '
        'OUTRO: $outro bars (instrumental tail, percussion fade).',
      ScaffoldType.clubStandard =>
        'RULE A6 SCAFFOLD ($genre / clubStandard): '
        'INTRO: $intro bars (tight DJ mix-in). Build layers compactly. '
        'OUTRO: $outro bars instrumental tail.',
      ScaffoldType.clubTight =>
        'RULE A6 SCAFFOLD ($genre / clubTight): '
        'INTRO: $intro bars (modern club entry). Punchy build. '
        'OUTRO: $outro bars.',
      ScaffoldType.radioShort =>
        'RULE A6 SCAFFOLD ($genre / radioShort): '
        'INTRO: $intro bars. Hook-tease or genre-native opener '
        '(organ swell for gospel, fingerpick for folk, Rhodes for R&B). '
        'OUTRO: $outro bars. No 32-bar scaffolding — radio format.',
      ScaffoldType.radioWide =>
        'RULE A6 SCAFFOLD ($genre / radioWide): '
        'INTRO: $intro bars with room for musical feel. '
        'OUTRO: $outro bars, often fade tail.',
      ScaffoldType.narrativeWide =>
        'RULE A6 SCAFFOLD ($genre / narrativeWide): '
        'INTRO: $intro bars — establish mood/texture before head. '
        'OUTRO: $outro bars — live-tail or gradual fade.',
      ScaffoldType.ambientLong =>
        'RULE A6 SCAFFOLD ($genre / ambientLong): '
        'INTRO: $intro bars — long atmospheric build. '
        'OUTRO: $outro bars — extended atmospheric tail.',
    };
  }

  static bool expectsClubExtendedBars(String genre, {String? vibeHint}) =>
      resolveScaffoldType(genre, vibeHint: vibeHint) == ScaffoldType.clubExtended;

  static bool expectsRadioShortBars(String genre, {String? vibeHint}) =>
      resolveScaffoldType(genre, vibeHint: vibeHint) == ScaffoldType.radioShort;
}
