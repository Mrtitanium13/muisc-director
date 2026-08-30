// lib/core/suno_prompt_router.dart
// Tag-based genre DNA router for Suno v4.5+ style fields.

import 'package:flutter/foundation.dart';

import '../config/suno_version_prompt_config.dart';

/// Router tier for style-field rendering (distinct from app [SunoVersion] enum).
enum SunoRouterTier {
  v4_5Plus,
  v5Plus,
}

@immutable
final class SunoRouterVersionConfig {
  const SunoRouterVersionConfig({required this.styleCharLimit});

  final int styleCharLimit;
}

const Map<SunoRouterTier, SunoRouterVersionConfig> sunoRouterVersionConfigs = {
  SunoRouterTier.v4_5Plus: SunoRouterVersionConfig(styleCharLimit: 1000),
  SunoRouterTier.v5Plus: SunoRouterVersionConfig(styleCharLimit: 1000),
};

@immutable
final class GenreDNA {
  const GenreDNA({
    this.coreTags = const <String>[],
    this.productionTags = const <String>[],
  });

  final List<String> coreTags;
  final List<String> productionTags;
}

/// Tag-based genre DNA router for Suno v4.5+ style fields.
abstract final class SunoPromptRouterV2 {
  SunoPromptRouterV2._();

  static const Map<String, GenreDNA> genreDnaMap = {
    // Electronic
    'EDM': GenreDNA(
      coreTags: ['anthemic electronic production', 'uplifting energy', 'dancefloor focus'],
      productionTags: ['polished festival mix', 'wide stereo width', 'punchy dynamics'],
    ),
    'House': GenreDNA(
      coreTags: ['four-on-the-floor beat', 'upbeat tempo', 'piano chords'],
      productionTags: ['clean mix', 'pumping synths'],
    ),
    'Tech House': GenreDNA(
      coreTags: ['rolling bassline', 'minimal synth stabs', 'percussive groove'],
      productionTags: ['tight, punchy drums', 'clean sub-bass'],
    ),
    'Big Room': GenreDNA(
      coreTags: ['anthem synth lead', 'huge reverb', 'build-up and drop'],
      productionTags: ['massive stereo width', 'loud compressed sound'],
    ),
    'Trance': GenreDNA(
      coreTags: ['arpeggiated synth melody', 'ethereal pads', 'euphoric feeling'],
      productionTags: ['spacious reverb', 'crisp high-end'],
    ),
    'Dubstep': GenreDNA(
      coreTags: ['wobble bass', 'half-time drum pattern', 'aggressive synth sounds'],
      productionTags: ['heavy sub-bass', 'complex sound design'],
    ),
    'Drum & Bass': GenreDNA(
      coreTags: ['fast breakbeat drums', 'deep rolling bassline'],
      productionTags: ['tight drum production', 'clean and powerful'],
    ),
    'Synthwave': GenreDNA(
      coreTags: ['80s analog synths', 'retro drum machine', 'nostalgic arpeggios'],
      productionTags: ['neon atmosphere', 'analog warmth', 'gated reverb'],
    ),
    'Hardstyle': GenreDNA(
      coreTags: ['distorted kick', 'reverse bass', 'euphoric anthem lead'],
      productionTags: ['aggressive compression', 'massive energy', 'hard dance mix'],
    ),
    'Techno': GenreDNA(
      coreTags: ['repetitive machine groove', 'industrial synth stabs', 'dark atmosphere'],
      productionTags: ['hypnotic mixing', 'raw and driving'],
    ),
    'Ambient': GenreDNA(
      coreTags: ['long sustained pads', 'droning bass', 'minimalist textures'],
      productionTags: ['atmospheric and spacious', 'evolving soundscape'],
    ),
    'Electronic Experimental': GenreDNA(
      coreTags: ['modular synthesis', 'glitch textures', 'abstract rhythms'],
      productionTags: ['unstable and evolving', 'bit-crushed and processed'],
    ),
    // Hip-hop
    'Hip Hop': GenreDNA(
      coreTags: ['boom bap drums', 'sampled melody', 'rhythmic vocal delivery'],
      productionTags: ['warm analog sound', 'gritty texture'],
    ),
    'Trap': GenreDNA(
      coreTags: ['808 bass', 'fast hi-hat rolls', 'dark synth melodies'],
      productionTags: ['heavy bass saturation', 'crisp snares'],
    ),
    'Drill': GenreDNA(
      coreTags: ['sliding 808 bass', 'syncopated drum patterns', 'ominous atmosphere'],
      productionTags: ['sparse mix', 'menacing vibe'],
    ),
    'Boom Bap': GenreDNA(
      coreTags: ['chopped drum break', 'dusty samples', 'lyrical flow'],
      productionTags: ['vinyl warmth', 'lo-fi grit', 'sample-based'],
    ),
    // R&B / soul / funk
    'R&B': GenreDNA(
      coreTags: ['smooth electric piano', 'emotive vocals', 'layered harmonies'],
      productionTags: ['polished production', 'lush reverb'],
    ),
    'Soul': GenreDNA(
      coreTags: ['vintage organ', 'horn section', 'gospel-tinged vocals'],
      productionTags: ['warm tape saturation', 'organic band recording'],
    ),
    'Funk': GenreDNA(
      coreTags: ['slap bass guitar', 'funky guitar riff', 'brass section hits'],
      productionTags: ['tight rhythm section', 'groovy and alive'],
    ),
    'Neo-Soul': GenreDNA(
      coreTags: ['jazz chords', 'wurlitzer electric piano', 'smooth vocal phrasing'],
      productionTags: ['warm and intimate', 'analog tape feel'],
    ),
    // Pop
    'Pop': GenreDNA(
      coreTags: ['catchy vocal hook', 'simple chord progression', 'four-on-the-floor beat'],
      productionTags: [
        'highly polished production',
        'clear, upfront vocals',
        'commercial radio sound',
      ],
    ),
    'Synth Pop': GenreDNA(
      coreTags: ['80s analog synths', 'drum machine beat', 'nostalgic melody'],
      productionTags: ['retro-futuristic vibe', 'gated reverb on drums'],
    ),
    'Mandopop': GenreDNA(
      coreTags: ['emotional ballad melody', 'piano-driven arrangement', 'Mandarin vocal phrasing'],
      productionTags: ['cinematic strings', 'polished pop mix'],
    ),
    'Indie Pop': GenreDNA(
      coreTags: ['jangly guitars', 'intimate vocals', 'quirky melodies'],
      productionTags: ['lo-fi warmth', 'alternative radio sheen'],
    ),
    // Rock / metal
    'Rock': GenreDNA(
      coreTags: ['distorted electric guitar riff', 'live drum kit', 'powerful vocals'],
      productionTags: ['energetic and raw', 'natural room sound'],
    ),
    'Metal': GenreDNA(
      coreTags: ['heavy distorted guitars', 'double-bass drumming', 'aggressive vocals'],
      productionTags: ['powerful and intense', 'tight rhythm section'],
    ),
    'Shoegaze': GenreDNA(
      coreTags: ['wall of distorted, reverbed guitars', 'ethereal, buried vocals'],
      productionTags: ['dreamy atmosphere', 'swirling textures'],
    ),
    'Punk': GenreDNA(
      coreTags: ['fast power chords', 'aggressive vocals', 'minimal production'],
      productionTags: ['raw and punchy', 'garage energy'],
    ),
    // Country / folk / acoustic
    'Acoustic': GenreDNA(
      coreTags: ['acoustic guitar', 'singer-songwriter', 'intimate vocals'],
      productionTags: ['natural and unpolished', 'high dynamic range'],
    ),
    'Country': GenreDNA(
      coreTags: ['acoustic guitar strumming', 'steel guitar slides', 'storytelling lyrics'],
      productionTags: ['warm and clear production', 'twangy sound'],
    ),
    'Folk': GenreDNA(
      coreTags: ['acoustic instruments', 'harmony vocals', 'traditional feel'],
      productionTags: ['organic and raw recording'],
    ),
    'Americana': GenreDNA(
      coreTags: ['roots instrumentation', 'earthy vocals', 'storytelling'],
      productionTags: ['warm and rustic', 'band-in-a-room feel'],
    ),
    'Bluegrass': GenreDNA(
      coreTags: ['fast banjo rolls', 'fiddle leads', 'close harmonies'],
      productionTags: ['bright and dry', 'acoustic clarity'],
    ),
    // Jazz / blues
    'Jazz': GenreDNA(
      coreTags: [
        'walking bassline',
        'swing rhythm',
        'improvisational solos',
        'complex chords',
      ],
      productionTags: ['smooth and sophisticated', 'clean instrument separation'],
    ),
    'Blues': GenreDNA(
      coreTags: ['blues scale guitar', 'shuffle rhythm', 'emotional vocal'],
      productionTags: ['gritty and raw', 'tube warmth'],
    ),
    'Bossa Nova': GenreDNA(
      coreTags: ['nylon-string guitar', 'soft samba rhythm', 'smooth vocals'],
      productionTags: ['intimate and breezy', 'warm jazz room'],
    ),
    // Afro / global
    'Amapiano': GenreDNA(
      coreTags: ['log drum bassline', 'percussive shaker rhythms', 'jazzy piano chords'],
      productionTags: ['deep, raw bass', 'wide atmospheric pads'],
    ),
    'Afrobeats': GenreDNA(
      coreTags: [
        'syncopated drum machine rhythms',
        'light guitar melodies',
        'call and response vocals',
      ],
      productionTags: ['bright, polished mix', 'danceable energy'],
    ),
    'Highlife': GenreDNA(
      coreTags: ['jazzy horn lines', 'palm-wine guitar', 'upbeat Ghanaian groove'],
      productionTags: ['vintage warmth', 'percussive brightness'],
    ),
    // Latin / Caribbean
    'Latin': GenreDNA(
      coreTags: ['syncopated percussion', 'Spanish vocals', 'tropical groove'],
      productionTags: ['bright and rhythmic', 'layered hand percussion'],
    ),
    'Reggaeton': GenreDNA(
      coreTags: ['dembow rhythm', 'Reggaeton beat', 'vocal chops'],
      productionTags: ['heavy low-end', 'club-ready mix'],
    ),
    'Reggae': GenreDNA(
      coreTags: ['one-drop drums', 'offbeat skank guitar', 'dub bass'],
      productionTags: ['warm and spacey', 'analog tape delay'],
    ),
    'Salsa': GenreDNA(
      coreTags: ['piano montuno', 'brass section', 'clave rhythm'],
      productionTags: ['bright and lively', 'Latin club energy'],
    ),
    'Bachata': GenreDNA(
      coreTags: ['bolero rhythm', 'reedy guitar', 'romantic vocals'],
      productionTags: ['warm and intimate', 'tropical ballad mix'],
    ),
    'Cumbia': GenreDNA(
      coreTags: ['guacharaca scrape', 'accordion melodies', 'walking bass'],
      productionTags: ['folk warmth', 'dance groove'],
    ),
    'Tango': GenreDNA(
      coreTags: ['bandoneon', 'dramatic melody', 'Latin ballroom rhythm'],
      productionTags: ['orchestral depth', 'passionate and cinematic'],
    ),
    // Gospel / worship
    'Gospel': GenreDNA(
      coreTags: ['powerful choir', 'Hammond organ', 'testimonial vocals'],
      productionTags: ['church hall reverb', 'uplifting and raw'],
    ),
    'Worship': GenreDNA(
      coreTags: ['open chord piano', 'anthemic chorus', 'congregational vocals'],
      productionTags: ['ambient guitars', 'cinematic lift', 'modern church mix'],
    ),
    // Cinematic / orchestral
    'Cinematic': GenreDNA(
      coreTags: ['orchestral strings', 'epic percussion', 'sweeping melodies'],
      productionTags: ['massive hall reverb', 'wide symphonic sound'],
    ),
    'Orchestral': GenreDNA(
      coreTags: ['full orchestra', 'dynamic swells', 'thematic development'],
      productionTags: ['concert hall acoustics', 'film-score clarity'],
    ),
    'Trailer': GenreDNA(
      coreTags: ['braams', 'epic drums', 'tension pulses'],
      productionTags: ['huge low-end', 'dramatic hits', 'cinematic build'],
    ),
  };

  static const Map<String, String> _genreAliases = {
    // Electronic
    'progressive house': 'House',
    'melodic house': 'House',
    'deep house': 'House',
    'soulful house': 'House',
    'future house': 'House',
    'disco house': 'House',
    'big room house': 'Big Room',
    'euphoric hardstyle': 'Hardstyle',
    'rawstyle': 'Hardstyle',
    'frenchcore': 'Hardstyle',
    'happy hardcore': 'Hardstyle',
    'uplifting trance': 'Trance',
    'melodic techno': 'Techno',
    'acid techno': 'Techno',
    'minimal techno': 'Techno',
    'hard techno': 'Techno',
    'melodic dubstep': 'Dubstep',
    'riddim': 'Dubstep',
    'brostep': 'Dubstep',
    'liquid dnb': 'Drum & Bass',
    'drum and bass': 'Drum & Bass',
    'drum & bass': 'Drum & Bass',
    'neurofunk': 'Drum & Bass',
    'jungle': 'Drum & Bass',
    'retrowave': 'Synthwave',
    'vaporwave': 'Synthwave',
    'dark ambient': 'Ambient',
    'ambient score': 'Ambient',
    'idm': 'Electronic Experimental',
    'glitch': 'Electronic Experimental',
    'industrial': 'Electronic Experimental',
    'breakcore': 'Electronic Experimental',
    'witch house': 'Electronic Experimental',
    'experimental': 'Electronic Experimental',
    'modular': 'Electronic Experimental',
    // Hip-hop
    'boom bap': 'Boom Bap',
    'jazz rap': 'Boom Bap',
    'lo-fi hip hop': 'Hip Hop',
    'conscious hip hop': 'Hip Hop',
    'underground hip hop': 'Hip Hop',
    'drill': 'Drill',
    'uk drill': 'Drill',
    'ny drill': 'Drill',
    'melodic trap': 'Trap',
    'phonk': 'Trap',
    'rage': 'Hip Hop',
    'jersey club': 'Hip Hop',
    'memphis rap': 'Boom Bap',
    'trap': 'Trap',
    // R&B / soul / funk
    'contemporary r&b': 'R&B',
    'contemporary rnb': 'R&B',
    '90s r&b': 'R&B',
    'neo-soul': 'Neo-Soul',
    'neo soul': 'Neo-Soul',
    'soul': 'Soul',
    'trap soul': 'R&B',
    'funk': 'Funk',
    'p-funk': 'Funk',
    'gogo': 'Funk',
    'motown': 'Soul',
    // Pop
    'mainstream pop': 'Pop',
    'dance pop': 'Pop',
    'electropop': 'Pop',
    'k-pop': 'Pop',
    'j-pop': 'Pop',
    'c-pop': 'Mandopop',
    'mandopop': 'Mandopop',
    'synth pop': 'Synth Pop',
    'indie pop': 'Indie Pop',
    'bedroom pop': 'Indie Pop',
    'shoegaze': 'Shoegaze',
    'dream pop': 'Indie Pop',
    'post-rock': 'Rock',
    // Rock / metal
    'indie rock': 'Rock',
    'alt rock': 'Rock',
    'alternative rock': 'Rock',
    'hard rock': 'Rock',
    'punk': 'Punk',
    'pop punk': 'Punk',
    'grunge': 'Rock',
    'britpop': 'Rock',
    'heavy metal': 'Metal',
    'metalcore': 'Metal',
    // Country / folk
    'modern country': 'Country',
    'country pop': 'Country',
    'americana': 'Americana',
    'bluegrass': 'Bluegrass',
    'singer-songwriter': 'Acoustic',
    'indie folk': 'Folk',
    'folk': 'Folk',
    'sertanejo': 'Country',
    // Jazz / blues
    'smooth jazz': 'Jazz',
    'bebop': 'Jazz',
    'vocal jazz': 'Jazz',
    'latin jazz': 'Jazz',
    'blues': 'Blues',
    'delta blues': 'Blues',
    'chicago blues': 'Blues',
    'electric blues': 'Blues',
    // Afro / global
    'amapiano': 'Amapiano',
    'amapiano-vinahouse': 'Amapiano',
    'vinahouse': 'Amapiano',
    'afro house': 'Amapiano',
    'afrobeats': 'Afrobeats',
    'afro-swing': 'Afrobeats',
    'afro rap': 'Afrobeats',
    'highlife': 'Highlife',
    'bongo flava': 'Afrobeats',
    'gengetone': 'Afrobeats',
    'azonto': 'Afrobeats',
    // Latin / Caribbean
    'latin pop': 'Latin',
    'salsa': 'Salsa',
    'bachata': 'Bachata',
    'cumbia': 'Cumbia',
    'dembow': 'Reggaeton',
    'reggaeton': 'Reggaeton',
    'latin trap': 'Reggaeton',
    'baile funk': 'Latin',
    'perreo': 'Reggaeton',
    'guaracha': 'Latin',
    'champeta': 'Latin',
    'moombahton': 'Latin',
    'soca': 'Latin',
    'calypso': 'Latin',
    'merengue': 'Latin',
    'vallenato': 'Latin',
    'tango': 'Tango',
    'reggae': 'Reggae',
    'dancehall': 'Reggae',
    'dub': 'Reggae',
    'ska': 'Reggae',
    'rocksteady': 'Reggae',
    // Worship / gospel
    'praise and worship': 'Worship',
    'praise/worship': 'Worship',
    'modern worship': 'Worship',
    'contemporary gospel': 'Gospel',
    'gospel': 'Gospel',
    'ccm': 'Worship',
    'worship ballad': 'Worship',
    // Cinematic
    'film score': 'Cinematic',
    'soundtrack': 'Cinematic',
    'orchestral': 'Orchestral',
    'trailer': 'Trailer',
    'cinematic': 'Cinematic',
  };

  static const Set<String> _electronicGenreKeys = {
    'EDM',
    'House',
    'Tech House',
    'Big Room',
    'Trance',
    'Dubstep',
    'Drum & Bass',
    'Synthwave',
    'Hardstyle',
    'Techno',
    'Ambient',
    'Electronic Experimental',
  };

  static const Set<String> _rockGenreKeys = {'Rock', 'Metal', 'Shoegaze', 'Punk'};

  static const Set<String> _hiphopPopGenreKeys = {
    'Hip Hop',
    'Trap',
    'Drill',
    'R&B',
    'Funk',
    'Amapiano',
    'Afrobeats',
    'Pop',
    'Synth Pop',
    'Indie Pop',
    'Soul',
    'Neo-Soul',
    'Boom Bap',
  };

  static const Set<String> _acousticGenreKeys = {
    'Acoustic',
    'Country',
    'Folk',
    'Americana',
    'Bluegrass',
    'Jazz',
    'Blues',
    'Bossa Nova',
    'Cinematic',
    'Orchestral',
    'Trailer',
  };

  static const Set<String> _electronicLaneIds = {
    'edm',
    'hardstyle',
    'techno',
    'dnb',
    'synthwave',
    'dubstep',
    'ambient',
    'electronic_experimental',
  };

  static const Set<String> _hiphopPopLaneIds = {
    'hiphop',
    'trap',
    'boom_bap',
    'reggaeton',
    'pop',
    'rnb',
    'funk',
    'soul',
    'neo_soul',
    'amapiano',
    'afrobeats',
  };

  static const Set<String> _rockLaneIds = {'rock', 'metal', 'indie', 'punk'};

  static const Set<String> _acousticOrchestralLaneIds = {
    'country',
    'folk',
    'cinematic',
    'jazz',
    'worship',
    'mandopop',
    'blues',
    'gospel',
    'latin',
    'reggae',
    'acoustic_orchestral',
  };

  static SunoRouterTier routerTierFromSunoVersion(String sunoVersion) {
    final tier = SunoPromptVersionConfig.tierFromString(sunoVersion);
    return switch (tier) {
      SunoPromptTier.v5 || SunoPromptTier.v5_5Pro => SunoRouterTier.v5Plus,
      _ => SunoRouterTier.v4_5Plus,
    };
  }

  /// Resolves primary + fusion sub-genres into canonical [genreDnaMap] keys.
  static List<String> resolveGenreKeys({
    required String primaryGenre,
    String subGenreFusion = '',
  }) {
    final keys = <String>[];
    for (final raw in [primaryGenre, subGenreFusion]) {
      final key = _canonicalGenreKey(raw);
      if (key != null && !keys.contains(key)) keys.add(key);
    }
    return keys;
  }

  static String? _canonicalGenreKey(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;
    if (genreDnaMap.containsKey(trimmed)) return trimmed;

    final alias = _genreAliases[trimmed.toLowerCase()];
    if (alias != null) return alias;

    final lower = trimmed.toLowerCase();
    for (final key in genreDnaMap.keys) {
      final keyLower = key.toLowerCase();
      if (lower.contains(keyLower) || keyLower.contains(lower)) return key;
    }
    return trimmed;
  }

  /// Retrieves descriptive DNA tags for one or more genres (fusion-safe).
  static List<String> getDnaTagsForGenres(List<String> genres) {
    final tags = <String>{};
    for (final genre in genres) {
      final dna = genreDnaMap[genre];
      if (dna != null) {
        tags.addAll(dna.coreTags);
        tags.addAll(dna.productionTags);
      } else if (genre.toString().trim().isNotEmpty) {
        tags.add(genre.toString().trim().toLowerCase());
      }
    }
    return tags.toList();
  }

  /// Builds a style field from accumulated tags.
  static String buildStyleFieldFromTags({
    required List<String> tags,
    SunoRouterTier version = SunoRouterTier.v5Plus,
    bool asSentence = true,
  }) {
    final cleaned =
        tags.map((t) => t.toString().trim()).where((t) => t.isNotEmpty).toList();
    if (cleaned.isEmpty) return '';

    final config = sunoRouterVersionConfigs[version]!;

    final String prompt;
    if (asSentence && cleaned.length > 1) {
      prompt =
          'A track in the style of ${cleaned.first}, featuring ${cleaned.skip(1).join(', ')}.';
    } else if (asSentence) {
      prompt = 'A track in the style of ${cleaned.first}.';
    } else {
      prompt = cleaned.join(', ');
    }

    if (prompt.length <= config.styleCharLimit) return prompt;

    var cutIndex = prompt.lastIndexOf(',', config.styleCharLimit);
    if (cutIndex <= 0) cutIndex = config.styleCharLimit;
    return prompt.substring(0, cutIndex).trimRight();
  }

  /// Composes user vibe + genre DNA + extra tokens into one style field.
  static String composeStyleField({
    required String userVibe,
    required List<String> genreKeys,
    List<String> additionalTokens = const <String>[],
    required String sunoVersion,
  }) {
    final genreTags = getDnaTagsForGenres(genreKeys);
    final version = routerTierFromSunoVersion(sunoVersion);
    final trimmedVibe = userVibe.trim();

    final tagPool = <String>{
      ...genreTags,
      ...additionalTokens.map((t) => t.toString().trim()).where((t) => t.isNotEmpty),
    }.toList();

    if (trimmedVibe.isEmpty) {
      return buildStyleFieldFromTags(
        tags: tagPool,
        version: version,
        asSentence: version == SunoRouterTier.v5Plus,
      );
    }

    if (tagPool.isEmpty) {
      return _truncate(trimmedVibe, version);
    }

    return buildStyleFieldFromTags(
      tags: [trimmedVibe, ...tagPool],
      version: version,
      asSentence: false,
    );
  }

  /// Melody auto-mode family key (`MelodyComposerService` contract).
  static String resolveMelodyEngineFamilyKey({
    required String primaryGenre,
    String subGenreFusion = '',
    String genreFxLaneId = '',
  }) {
    final lane = genreFxLaneId.trim().toLowerCase();
    if (lane.isNotEmpty) {
      if (_electronicLaneIds.contains(lane)) return 'electronic';
      if (_hiphopPopLaneIds.contains(lane)) return 'hiphop_pop';
      if (_rockLaneIds.contains(lane)) return 'rock_metal';
      if (_acousticOrchestralLaneIds.contains(lane)) return 'acoustic_orchestral';
    }

    final keys = resolveGenreKeys(
      primaryGenre: primaryGenre,
      subGenreFusion: subGenreFusion,
    );
    for (final key in keys) {
      final family = _melodyFamilyForGenreKey(key);
      if (family != null) return family;
    }
    return 'hiphop_pop';
  }

  static String? _melodyFamilyForGenreKey(String key) {
    if (_electronicGenreKeys.contains(key)) return 'electronic';
    if (_rockGenreKeys.contains(key)) return 'rock_metal';
    if (_hiphopPopGenreKeys.contains(key)) return 'hiphop_pop';
    if (_acousticGenreKeys.contains(key)) return 'acoustic_orchestral';
    return null;
  }

  /// Comma-separated descriptive tags for runtime FX/style injection.
  static String styleTagsFor({
    required String primaryGenre,
    String subGenreFusion = '',
    String sunoVersion = 'v4.5',
  }) {
    final keys = resolveGenreKeys(
      primaryGenre: primaryGenre,
      subGenreFusion: subGenreFusion,
    );
    final tags = getDnaTagsForGenres(keys);
    if (tags.isEmpty) return '';
    final version = routerTierFromSunoVersion(sunoVersion);
    return buildStyleFieldFromTags(
      tags: tags,
      version: version,
      asSentence: false,
    );
  }

  /// LLM user-block directive aligned with the direct-to-Suno style field.
  static String userBlockDirective({
    required String primaryGenre,
    String subGenreFusion = '',
    String sunoVersion = 'v4.5',
  }) {
    final keys = resolveGenreKeys(
      primaryGenre: primaryGenre,
      subGenreFusion: subGenreFusion,
    );
    final tags = getDnaTagsForGenres(keys);
    if (tags.isEmpty) return '';

    return 'GENRE STYLE (align Block 1 producer prose and Block 2 lyric mood with the '
        'same descriptive tags as the Suno style field): '
        'Write lyrics for a song with the following vibe and style: ${tags.join(', ')}.';
  }

  static String _truncate(String text, SunoRouterTier version) {
    final limit = sunoRouterVersionConfigs[version]!.styleCharLimit;
    if (text.length <= limit) return text;
    var cutIndex = text.lastIndexOf(',', limit);
    if (cutIndex <= 0) cutIndex = limit;
    return text.substring(0, cutIndex).trimRight();
  }
}
