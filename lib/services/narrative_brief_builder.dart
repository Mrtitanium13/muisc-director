import '../core/suno_prompt_router.dart';
import '../data/models/narrative_template.dart';

/// Builds genre-aware narrative briefs for Path C lyric generation.
class NarrativeBriefBuilder {
  NarrativeBriefBuilder._();

  /// This map is the "Creative Brain" of the lyricist AI.
  /// Sub-genres not listed here (e.g. Deep House) fall back to a parent template.
  static const Map<String, NarrativeTemplate> _narrativeTemplates = {
    // ── DIGITAL & EDM ──────────────────────────────────────────────────────
    'House': NarrativeTemplate(
      r'Write the lyrics for an uplifting, soulful House track with a ${mood} mood. '
      r'The lyrics should be positive and energetic, focusing on themes of ${themes} like love, unity, and the feeling of release on the dance floor. '
      r'The chorus MUST be a simple, powerful, and repetitive hook that is easy to sing along to.',
    ),
    'Techno': NarrativeTemplate(
      r'Write sparse, hypnotic, and repetitive lyrics for a Techno track with a ${mood} mood. '
      r'Focus on rhythm and texture rather than a clear story. Use short, impactful phrases or single words that can be chanted. '
      r'The lyrics should feel like another percussive instrument in the mix, exploring themes of ${themes}.',
    ),
    'Trance': NarrativeTemplate(
      r'Write euphoric, anthemic, and emotionally soaring lyrics for a Trance track with a ${mood} mood. '
      r'Use grand, uplifting language about themes of ${themes} like ascension, connection, love, or cosmic journeys. '
      r'The chorus should feel like an emotional peak, a moment of pure release and euphoria.',
    ),
    'Dubstep': NarrativeTemplate(
      r'Write aggressive, high-energy, and impactful lyrics for a Dubstep track with a ${mood} mood. '
      r'Use hard-hitting words and a confident, confrontational tone. '
      r'The lyrics should match the song drop structure, building tension in the verses and exploding in the chorus. '
      r'Good themes for ${themes} include power, chaos, futuristic rebellion, or intense emotion.',
    ),
    'Drum & Bass': NarrativeTemplate(
      r'Write fast-paced, rhythmic, and soulful lyrics for a Drum & Bass track with a ${mood} mood. '
      r'The lyrics should flow smoothly over a high-speed beat, almost like a conversation. '
      r'Explore themes of ${themes} like city life, romance, introspection at high speed, or escape.',
    ),

    // ── STREET & URBAN ─────────────────────────────────────────────────────
    'Hip Hop': NarrativeTemplate(
      r'Write lyrics for a classic Hip Hop track with a ${mood} mood. '
      r'Focus on strong storytelling, clever wordplay, and a confident, rhythmic delivery. '
      r'The story should be clear and compelling, exploring themes of ${themes} like ambition, struggle, social commentary, or personal triumphs.',
    ),
    'Trap': NarrativeTemplate(
      r'Write lyrics for a modern Trap track with a ${mood} mood. '
      r'Use a confident, often braggadocious tone. The lyrics should be catchy and rhythmic, with memorable ad-libs. '
      r'Focus on modern themes of ${themes} such as success, ambition, luxury, the nightlife, or overcoming obstacles.',
    ),
    'R&B': NarrativeTemplate(
      r'Write smooth, emotive, and sensual lyrics for a contemporary R&B track with a ${mood} mood. '
      r'The lyrics should be intimate and personal, exploring the complexities of love, desire, vulnerability, and relationships. '
      r'Focus on themes of ${themes} and use a conversational yet poetic style.',
    ),
    'Funk': NarrativeTemplate(
      r'Write fun, groovy, and rhythmic lyrics for a Funk track with a ${mood} mood. '
      r'The main goal is to make people dance and feel good. Use playful language, call-and-response sections, and a confident, charismatic voice. '
      r'The themes for ${themes} should revolve around partying, unity, love, and celebrating life.',
    ),
    'Amapiano': NarrativeTemplate(
      r'Write lyrics for a smooth, confident Amapiano track with a ${mood} mood. '
      r'The tone should be cool and charismatic. The lyrics often describe a scene, a vibe, or a dance. '
      r'Focus on themes of ${themes} like nightlife, attraction, and the feeling of the groove. Use a mix of conversational language and catchy hooks.',
    ),
    'Afrobeats': NarrativeTemplate(
      r'Write vibrant, melodic, and danceable lyrics for an Afrobeats track with a ${mood} mood. '
      r'The lyrics should be joyful and easy to sing along to, often with a mix of English and local dialects (like Pidgin). '
      r'Focus on themes of ${themes} like celebration, love, good times, and cultural pride.',
    ),

    // ── MAINSTREAM POP ─────────────────────────────────────────────────────
    'Pop': NarrativeTemplate(
      r'Write lyrics for a catchy, mainstream Pop song with a ${mood} mood. '
      r'The lyrics must be direct, relatable, and emotionally clear. The chorus MUST be an unforgettable, infectious hook. '
      r'Focus on universal themes of ${themes} like love, empowerment, heartbreak, or celebration.',
    ),
    'K-Pop': NarrativeTemplate(
      r'Write lyrics for a dynamic, high-energy K-Pop track with a ${mood} mood. '
      r'The song should have a mix of confident verses and an explosive, catchy chorus. It should also include a distinct pre-chorus that builds anticipation. '
      r'Lyrics often blend languages and focus on themes of ${themes} with a highly polished and aspirational feel.',
    ),
    'Synth Pop': NarrativeTemplate(
      r'Write nostalgic, melodic lyrics for a Synth Pop song with a ${mood} mood. '
      r'The story often involves romance, youth, or a bittersweet feeling, fitting an 80s-inspired retro-futuristic sound. '
      r'Use poetic and evocative language to touch on themes of ${themes} like dreams, memories, or city lights.',
    ),

    // ── ROCK & METAL ───────────────────────────────────────────────────────
    'Rock': NarrativeTemplate(
      r'Write powerful, anthemic lyrics for a Rock song with a ${mood} mood. '
      r'Use strong, direct language and vivid imagery. The chorus should be big, memorable, and easy to shout along with. '
      r'Focus on classic themes of ${themes} like freedom, rebellion, love, resilience, or overcoming challenges.',
    ),
    'Indie Rock': NarrativeTemplate(
      r'Write introspective and observational lyrics for an Indie Rock song with a ${mood} mood. '
      r'The story should feel personal, using everyday details to hint at bigger emotions. '
      r'Use figurative language but keep it grounded and relatable. The chorus can be a simple, repeating phrase that captures the core feeling. '
      r'Explore themes of ${themes} with an honest, often world-weary voice.',
    ),
    'Punk': NarrativeTemplate(
      r'Write fast, aggressive, and direct lyrics for a Punk Rock song with a ${mood} mood. '
      r'The tone should be rebellious, urgent, and often anti-establishment. Use simple, hard-hitting language and short, punchy phrases. '
      r'Focus on themes of ${themes} like social critique, frustration, individuality, and non-conformity.',
    ),
    'Metal': NarrativeTemplate(
      r'Write epic, intense, and powerful lyrics for a Metal track with a ${mood} mood. '
      r'Use strong, often dark or fantastical imagery. The lyrics should match the music aggression and technicality. '
      r'Explore themes of ${themes} like mythology, battle, inner demons, societal critique, or historical events.',
    ),

    // ── ORGANIC & ACOUSTIC ─────────────────────────────────────────────────
    'Country': NarrativeTemplate(
      r'Write an honest, storytelling Country song with a ${mood} mood. '
      r'The story is the most important part. It should feel authentic and grounded in real-life experiences, good or bad. '
      r'Use simple, direct language to talk about themes of ${themes} like family, hometowns, love, work, or loss.',
    ),
    'Folk': NarrativeTemplate(
      r'Write narrative-driven, poetic lyrics for a Folk song with a ${mood} mood. '
      r'The story is central. Use rich imagery, often drawing from nature, history, or tradition. '
      r'The tone is typically sincere and thoughtful, exploring themes of ${themes} like travel, social change, love, and time.',
    ),
    'Blues': NarrativeTemplate(
      r'Write raw, emotional lyrics for a classic Blues song with a ${mood} mood. '
      r'The lyrics should express hardship, struggle, love, or loss with a raw, honest voice. '
      r'Often uses a traditional AAB verse structure (the first line is stated twice, followed by a rhyming third line). '
      r'Focus on core themes of ${themes} with a sense of resilience.',
    ),
    'Singer-Songwriter': NarrativeTemplate(
      r'Write deeply personal and introspective lyrics for a Singer-Songwriter track with a ${mood} mood. '
      r'The lyrics should feel like a direct confession or a page from a diary. '
      r'Use specific, personal details to explore universal emotions related to themes of ${themes}. The tone is intimate and vulnerable.',
    ),

    // ── JAZZ, REGGAE & SOPHISTICATED ───────────────────────────────────────
    'Jazz': NarrativeTemplate(
      r'Write smooth, sophisticated, and poetic lyrics for a vocal Jazz track with a ${mood} mood. '
      r'The mood is often romantic, wistful, or coolly observant. Use clever wordplay and romantic, often bittersweet imagery. '
      r'The lyrics should flow gracefully and naturally with a complex melody, exploring themes of ${themes}.',
    ),
    'Reggae': NarrativeTemplate(
      r'Write lyrics for a Reggae track with a ${mood} mood, with a focus on rhythm, melody, and message. '
      r'The tone can be socially conscious, spiritual, joyful, or about love and unity ("One Love"). '
      r'The lyrics should have a relaxed, conversational flow, touching on themes of ${themes} like justice, peace, and connection to nature.',
    ),

    // ── CINEMATIC & AMBIENT ────────────────────────────────────────────────
    'Cinematic': NarrativeTemplate(
      r'Write sparse, epic, and highly atmospheric lyrics for a Cinematic track with a ${mood} mood. '
      r'The words should act as another layer of texture, not a driving narrative. Use powerful, evocative single words or short phrases. '
      r'The feeling should be grand and mysterious, hinting at themes of ${themes} like wonder, destiny, or immense scale.',
    ),
    'Ambient': NarrativeTemplate(
      r'Write extremely minimal, ethereal, and abstract lyrics for an Ambient track. '
      r'The lyrics should be more like scattered thoughts, whispers, or a mantra than a structured song. '
      r'Focus on creating a ${mood} mood or feeling, not telling a story. The words should blend into the soundscape.',
    ),

    // ── SPIRITUAL & WORSHIP ────────────────────────────────────────────────
    'Gospel': NarrativeTemplate(
      r'Write powerful, soulful, and uplifting lyrics for a Gospel song with a ${mood} mood. '
      r'The lyrics should tell a story of testimony—overcoming hardship through faith, giving thanks for blessings, or celebrating deliverance. '
      r'Focus on themes of ${themes} like grace, redemption, hope, and divine strength. '
      r'The chorus should be a strong, declarative, and joyful statement of faith that a full choir can sing with passion.',
    ),
    'Praise & Worship': NarrativeTemplate(
      r'Write lyrics for a modern Praise & Worship song intended for congregational singing with a ${mood} mood. '
      r'The lyrics must be a direct address of adoration, reverence, and surrender to God. Use "You" and "I" language. '
      r'The focus is on creating an atmosphere of worship, not complex storytelling. Use simple, heartfelt, and powerful language. '
      r'Explore themes of ${themes} like divine majesty, faithfulness, holiness, and love. The song should build emotionally, often leading to a powerful bridge of declaration.',
    ),

    // ── LATIN & GLOBAL RHYTHMS ─────────────────────────────────────────────
    'Reggaeton': NarrativeTemplate(
      r'Write lyrics for a confident, rhythmic, and dance-focused Reggaeton track with a ${mood} mood. '
      r'The tone is often flirty, boastful, and full of street-wise energy. The lyrics should lock into the "dembow" rhythm. '
      r'Focus on themes of ${themes} like dancing, nightlife, attraction, and celebration. Use a mix of Spanish and slang for authenticity.',
    ),
    'Bossa Nova': NarrativeTemplate(
      r'Write gentle, poetic, and romantic lyrics for a Bossa Nova track with a ${mood} mood. '
      r'The mood should be soft, intimate, and slightly melancholic or wistful ("saudade"). '
      r'Use imagery from nature, like the sun, sea, and rain, to describe feelings of love. The tone is sophisticated and understated. '
      r'Focus on themes of ${themes} with a quiet, personal voice.',
    ),
    'Bollywood': NarrativeTemplate(
      r'Write highly expressive, dramatic, and melodic lyrics for a Bollywood (Filmi) song with a ${mood} mood. '
      r'The lyrics are part of a larger story, often a movie scene. They should be grand and poetic, expressing heightened emotions. '
      r'Use rich metaphors to explore themes of ${themes} like epic romance, tragic heartbreak, celebration, or destiny. The chorus should be a soaring, memorable melody.',
    ),
  };

  /// Sub-genre labels → parent narrative template key.
  static const Map<String, String> _subGenreParentKeys = {
    'deep house': 'House',
    'soulful house': 'House',
    'tech house': 'Techno',
    'progressive house': 'House',
    'melodic house': 'House',
    'future house': 'House',
    'disco house': 'House',
    'afro house': 'House',
    'big room': 'House',
    'hardstyle': 'House',
    'hard techno': 'Techno',
    'melodic techno': 'Techno',
    'acid techno': 'Techno',
    'uplifting trance': 'Trance',
    'melodic dubstep': 'Dubstep',
    'liquid dnb': 'Drum & Bass',
    'boom bap': 'Hip Hop',
    'uk drill': 'Trap',
    'ny drill': 'Trap',
    'drill': 'Trap',
    'melodic trap': 'Trap',
    'contemporary r&b': 'R&B',
    'neo-soul': 'R&B',
    'soul': 'R&B',
    'trap soul': 'R&B',
    'mainstream pop': 'Pop',
    'dance pop': 'Pop',
    'electropop': 'Pop',
    'bedroom pop': 'Pop',
    'indie pop': 'Pop',
    'latin pop': 'Pop',
    'hyperpop': 'Pop',
    'j-pop': 'Pop',
    'c-pop': 'Pop',
    'mandopop': 'Pop',
    'synthwave': 'Synth Pop',
    'retrowave': 'Synth Pop',
    'indie rock': 'Indie Rock',
    'alt rock': 'Indie Rock',
    'alternative': 'Indie Rock',
    'hard rock': 'Rock',
    'classic rock': 'Rock',
    'pop punk': 'Punk',
    'emo': 'Punk',
    'heavy metal': 'Metal',
    'metalcore': 'Metal',
    'shoegaze': 'Indie Rock',
    'dream pop': 'Indie Rock',
    'modern country': 'Country',
    'outlaw country': 'Country',
    'americana': 'Folk',
    'bluegrass': 'Country',
    'indie folk': 'Folk',
    'singer-songwriter': 'Singer-Songwriter',
    'acoustic': 'Singer-Songwriter',
    'chicago blues': 'Blues',
    'delta blues': 'Blues',
    'vocal jazz': 'Jazz',
    'smooth jazz': 'Jazz',
    'jazz fusion': 'Jazz',
    'roots reggae': 'Reggae',
    'dub': 'Reggae',
    'dancehall': 'Reggae',
    'film score': 'Cinematic',
    'trailer': 'Cinematic',
    'dark ambient': 'Ambient',
    'traditional gospel': 'Gospel',
    'contemporary gospel': 'Gospel',
    'southern gospel': 'Gospel',
    'country gospel': 'Gospel',
    'urban gospel': 'Gospel',
    'praise/worship': 'Praise & Worship',
    'modern worship': 'Praise & Worship',
    'worship ballad': 'Praise & Worship',
    'pop worship': 'Praise & Worship',
    'ccm': 'Praise & Worship',
    'dembow': 'Reggaeton',
    'filmi': 'Bollywood',
    'bhangra': 'Bollywood',
    'punjabi': 'Bollywood',
  };

  static const _genericTemplate = NarrativeTemplate(
    r'Write the lyrics for a song. The mood is ${mood}. The main themes are ${themes}.',
  );

  /// Builds a clean narrative brief for the lyricist LLM.
  static String build({
    required String primaryGenre,
    String? subGenreFusion,
    required String mood,
    required List<String> themes,
  }) {
    final template = _resolveTemplate(
      primaryGenre: primaryGenre,
      subGenreFusion: subGenreFusion,
    );
    final resolvedMood =
        mood.trim().isEmpty ? 'unspecified' : mood.trim();
    return template.build(mood: resolvedMood, themes: themes);
  }

  /// Parses theme strings from free-text lyric theme notes.
  static List<String> themesFromNotes(String lyricThemeNotes) {
    final notes = lyricThemeNotes.trim();
    if (notes.isEmpty) return const [];
    return notes
        .split(RegExp(r'[,;•\n]+'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }

  static NarrativeTemplate _resolveTemplate({
    required String primaryGenre,
    String? subGenreFusion,
  }) {
    final fusion = subGenreFusion?.trim() ?? '';

    for (final raw in [fusion, primaryGenre]) {
      final hit = _lookupKey(raw);
      if (hit != null) return _narrativeTemplates[hit]!;
    }

    for (final raw in [fusion, primaryGenre]) {
      final parent = _parentKeyFor(raw);
      if (parent != null) return _narrativeTemplates[parent]!;
    }

    final routerKeys = SunoPromptRouterV2.resolveGenreKeys(
      primaryGenre: primaryGenre,
      subGenreFusion: fusion,
    );
    for (final key in routerKeys.reversed) {
      final hit = _lookupKey(key);
      if (hit != null) return _narrativeTemplates[hit]!;

      final parent = _parentKeyFor(key);
      if (parent != null) return _narrativeTemplates[parent]!;
    }

    return _genericTemplate;
  }

  static String? _parentKeyFor(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;
    final lower = trimmed.toLowerCase();
    if (_subGenreParentKeys.containsKey(lower)) {
      return _subGenreParentKeys[lower];
    }
    for (final entry in _subGenreParentKeys.entries) {
      if (lower.contains(entry.key)) return entry.value;
    }
    return null;
  }

  static String? _lookupKey(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;
    if (_narrativeTemplates.containsKey(trimmed)) return trimmed;

    final lower = trimmed.toLowerCase();
    for (final key in _narrativeTemplates.keys) {
      if (key.toLowerCase() == lower) return key;
    }
    return null;
  }
}
