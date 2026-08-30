import '../core/constants/prompt_flow_data.dart';
import '../data/models/melody_directive.dart';
import '../data/models/melody_evolution.dart';

class MelodyConfig {
  MelodyConfig._();

  static const String autoId = 'auto';
  static const String customId = 'custom';

  /// All genre-family keys that melody tokens should cover.
  static const List<String> coveredGenreFamilies = [
    'edm',
    'techno',
    'hardstyle',
    'dnb',
    'synthwave',
    'dubstep',
    'ambient',
    'hiphop',
    'trap',
    'pop',
    'rnb',
    'funk',
    'reggaeton',
    'latin',
    'rock',
    'metal',
    'indie',
    'country',
    'folk',
    'afrobeats',
    'amapiano',
    'cinematic',
    'jazz',
    'blues',
    'worship',
    'reggae',
    'mandopop',
    'world',
  ];

  static const List<MelodyDirective> directives = [
    MelodyDirective(
      id: autoId,
      label: 'Auto (Genre-Informed)',
      description:
          'Intelligently selects a default melodic style based on the main genre choice.',
    ),
    MelodyDirective(
      id: 'hook_led',
      label: 'Hook-Led / Repetitive',
      description:
          'Focuses on a short, catchy, and repeating melodic phrase.',
      defaultToken: 'melodically driven by a repetitive, catchy hook',
      genreTokens: {
        'edm': 'driven by a main synth hook or arpeggio',
        'techno': 'hypnotic repeating synth motif locked to the kick grid',
        'hardstyle': 'driven by a punchy reverse-bass hook and screech motif',
        'dnb': 'driven by a rolling Reese-bass motif with choppy lead hooks',
        'synthwave': 'driven by a gated synth lead hook with neon arpeggio answer',
        'dubstep': 'driven by a heavy wobble motif and drop-hook stab',
        'ambient': 'centered on a sparse repeating motif over evolving pads',
        'pop': 'built around a memorable, repetitive vocal chorus melody',
        'rnb': 'built around a sticky melodic hook with soft vocal ornament',
        'funk': 'built on a repeating syncopated melodic riff',
        'hiphop': 'features a repeating sampled melodic motif or synth line',
        'trap': 'driven by a repeating 808-hook motif and pluck stab',
        'rock': 'built on a powerful, repeating guitar riff',
        'metal': 'built on a crushing repeating riff motif',
        'indie': 'built on a looping guitar or synth motif with intimate vocal hook',
        'amapiano': 'centered on a hypnotic log-drum and keys hook pattern',
        'afrobeats': 'built around a repeating percussive melodic motif',
        'latin': 'built around a montuno or requinto hook motif',
        'reggaeton': 'driven by a dembow-pocket melodic hook',
        'reggae': 'built around a repeating skank-guitar melodic motif',
        'country': 'built around a memorable vocal hook with twang-lead answer',
        'folk': 'built around a repeating acoustic motif and singable refrain',
        'jazz': 'centered on a short head motif with room for variation',
        'blues': 'built on a repeating blues-head motif with call phrasing',
        'worship': 'built around a congregational, repeating praise hook',
        'cinematic': 'driven by a repeating leitmotif across scenes',
        'mandopop': 'built around a memorable Mandarin melodic hook',
        'world': 'built around a chant-ready repeating melodic motif',
      },
    ),
    MelodyDirective(
      id: 'anthemic_soaring',
      label: 'Anthemic / Soaring',
      description: 'A big, emotional, and uplifting melodic line.',
      defaultToken: 'features a big, anthemic, and soaring melody',
      genreTokens: {
        'edm': 'a euphoric, hands-in-the-air supersaw lead melody in the drop',
        'techno': 'a rising melodic techno lead that blooms over the kick',
        'hardstyle': 'a euphoric hardstyle lead melody over reverse-bass drive',
        'dnb': 'a soaring liquid DnB vocal or pad melody over rolling drums',
        'synthwave': 'a wide, nostalgic synth lead climbing through the chorus',
        'dubstep': 'a soaring melodic lead contrasting the heavy drop',
        'ambient': 'a slowly ascending ambient theme over wide pads',
        'rock':
            'a stadium-sized, soaring vocal melody in the chorus with powerful guitar backing',
        'metal': 'a soaring melodic chorus over dense distorted riffs',
        'indie': 'an emotionally wide indie chorus melody with lift',
        'cinematic': 'a sweeping, emotional orchestral theme carried by strings',
        'worship':
            'an uplifting, congregational-friendly melody that builds to a powerful crescendo',
        'pop': 'a wide, stacked vocal chorus melody with triumphant major-key lift',
        'rnb': 'a soaring R&B chorus melody with stacked harmonies',
        'country': 'a big country chorus melody with open-road lift',
        'folk': 'a soaring folk refrain with communal sing-along lift',
        'afrobeats': 'an uplifting afro-pop chorus melody with call-and-response lift',
        'amapiano': 'a soaring piano-house vocal hook over the log-drum groove',
        'latin': 'a soaring Latin chorus melody with brass lift',
        'reggaeton': 'a high-energy dembow chorus melody with stacked vocals',
        'reggae': 'an uplifting reggae chorus melody with horn-section lift',
        'jazz': 'a soaring jazz ballad melody with wide intervals',
        'blues': 'a belted blues climax melody with emotional peak',
        'mandopop': 'a soaring Mandopop chorus with key-change lift energy',
        'world': 'a soaring melismatic world-pop melody with festival lift',
        'hiphop': 'an anthemic sung hook over hard drums',
        'trap': 'a soaring melodic trap hook over 808s',
        'funk': 'a triumphant funk-chorus melody with brass lift',
      },
    ),
    MelodyDirective(
      id: 'conversational_spoken',
      label: 'Conversational / Spoken',
      description:
          'Speech-like, rhythmic delivery. Less singing, more attitude.',
      defaultToken: 'melody follows natural speech cadence with talk-singing phrasing',
      genreTokens: {
        'hiphop': 'rhythmic spoken delivery with pocketed flow over the beat',
        'trap': 'half-spoken trap cadence with melodic ad-lib answers',
        'pop': 'intimate talk-singing verses with sung hook contrast',
        'rnb': 'conversational R&B verses with soft talk-sing transitions',
        'rock': 'dry, spoken-word verses leading into a sung chorus',
        'metal': 'spoken or barked verses contrasting a sung/melodic chorus',
        'indie': 'diary-like spoken phrasing into a melodic indie chorus',
        'country': 'story-led, conversational vocal phrasing with narrative arc',
        'folk': 'storyteller spoken-sung phrasing with intimate diction',
        'jazz': 'cool, understated vocal delivery with rhythmic elasticity',
        'blues': 'talk-sung blues storytelling with spoken asides',
        'edm': 'spoken or chopped vocal phrases riding the groove',
        'techno': 'minimal spoken vocal fragments over hypnotic drums',
        'worship': 'intimate spoken prayer verses into a sung praise hook',
        'latin': 'spoken-sung verses with rhythmic Spanish/English cadence',
        'reggaeton': 'talk-sung dembow verses into a chantable hook',
        'reggae': 'toasting-style spoken cadence into a sung chorus',
        'afrobeats': 'conversational afro-pop verses with chanted hook answers',
        'amapiano': 'talk-sung verses over log-drum pocket with hook lift',
        'cinematic': 'spoken narrative phrases over evolving score beds',
        'world': 'story-forward spoken-sung phrasing with cultural cadence',
        'mandopop': 'intimate spoken verse cadence into melodic Mandarin hooks',
        'funk': 'spoken-funk attitude verses with melodic hook reply',
        'dnb': 'MC-style spoken energy over rolling breaks',
        'hardstyle': 'hyped spoken calls into euphoric sung hooks',
        'dubstep': 'spoken or barked phrases into a melodic drop contrast',
        'synthwave': 'cool half-spoken retro vocal into neon synth hook',
        'ambient': 'whispered spoken fragments over sparse atmospheres',
      },
    ),
    MelodyDirective(
      id: 'syncopated_rhythmic',
      label: 'Syncopated / Rhythmic',
      description:
          'Off-beat, groovy, and rhythm-forward phrasing over a simple tune.',
      defaultToken: 'syncopated, rhythm-first melodic phrasing',
      genreTokens: {
        'pop': 'off-beat vocal rhythm with staccato hook phrasing',
        'rnb': 'behind-the-beat R&B syncopation with pocketed phrasing',
        'funk': 'tight syncopated melodic riffs locked to the groove',
        'hiphop': 'pocketed, syncopated flow riding behind the downbeat',
        'trap': 'triplet-aware syncopated melodic phrases over 808s',
        'jazz': 'swung, syncopated melodic lines with blue-note inflection',
        'blues': 'shuffle-syncopated blues melody with push-pull phrasing',
        'latin': 'clave-aware syncopated vocal and melodic rhythm',
        'reggaeton': 'dembow-syncopated melodic phrasing on the offbeat',
        'reggae': 'offbeat skank-aware melodic phrasing',
        'edm': 'funky, off-grid synth stabs and rhythmic motif repetition',
        'techno': 'syncopated motif stabs over a four-on-the-floor pulse',
        'hardstyle': 'syncopated screech and vocal chops against reverse bass',
        'dnb': 'chopped syncopated motifs over breakbeat motion',
        'afrobeats': 'syncopated afro-pop phrasing locked to percussion',
        'amapiano': 'log-drum-aware syncopated keys and vocal phrasing',
        'rock': 'syncopated riff phrasing with rhythmic vocal accents',
        'metal': 'rhythmic, palm-muted melodic accents with syncopated hits',
        'indie': 'loose syncopated indie vocal phrasing over guitar groove',
        'country': 'syncopated country phrasing with rhythmic story accents',
        'folk': 'light syncopation in acoustic phrasing and refrain',
        'worship': 'rhythmic congregational phrasing with clap-ready accents',
        'cinematic': 'rhythmic ostinato motifs under evolving harmony',
        'mandopop': 'rhythm-forward Mandarin syllable phrasing on hooks',
        'world': 'percussion-first syncopated melodic phrasing',
        'synthwave': 'syncopated gated synth stabs with retro bounce',
        'dubstep': 'syncopated midrange motifs against half-time drops',
        'ambient': 'soft syncopated fragments drifting through space',
      },
    ),
    MelodyDirective(
      id: 'minimal_spatial',
      label: 'Minimal / Spatial',
      description:
          'Few notes, emphasizing space, texture, and atmosphere.',
      defaultToken: 'sparse, atmospheric melody with long sustained notes',
      genreTokens: {
        'edm': 'minimal synth motif with wide reverb tails and negative space',
        'techno': 'ultra-minimal motif with long filter-space between hits',
        'ambient': 'slow-moving ambient fragments with vast reverb space',
        'cinematic': 'slow-moving, ambient melodic fragments over pads',
        'pop': 'intimate, breathy vocal lines with wide inter-note space',
        'rnb': 'sparse quiet-storm melody with long held vowels',
        'jazz': 'restrained, modal melodic statements with room to breathe',
        'blues': 'sparse blues melody with long rests and room tone',
        'hiphop': 'minimal sample-led melody with open pocket space',
        'trap': 'sparse trap melody with empty space around the 808',
        'rock': 'sparse clean-guitar melody with wide stereo space',
        'indie': 'airy indie melody with lots of negative space',
        'folk': 'sparse acoustic melody with intimate room silence',
        'country': 'sparse country melody with open-sky space',
        'worship': 'gentle sparse worship melody with pad space',
        'latin': 'sparse Latin melody with room for percussion',
        'reggaeton': 'minimal dembow-era melody with open low-end space',
        'reggae': 'sparse reggae melody with echo space',
        'afrobeats': 'minimal afro motif with breathing room for percussion',
        'amapiano': 'sparse piano motif with deep log-drum space',
        'hardstyle': 'minimal lead phrase with huge drop-space contrast',
        'dnb': 'sparse liquid motif with wide atmospheric tails',
        'synthwave': 'minimal neon motif with long gated reverb space',
        'dubstep': 'sparse pre-drop motif with huge silence before impact',
        'metal': 'minimal clean motif contrasting heavy sections',
        'mandopop': 'sparse piano-ballad melody with emotional space',
        'world': 'sparse ornamental melody with wide atmospheric space',
        'funk': 'minimal funk motif with rhythmic gaps',
      },
    ),
    MelodyDirective(
      id: 'blues_inflected',
      label: 'Blues / Soul Inflected',
      description:
          'Blue notes, slides, and expressive runs for a soulful feel.',
      defaultToken: 'soulful melody with blues inflection and expressive vocal runs',
      genreTokens: {
        'pop': 'melismatic R&B-style vocal runs on key emotional words',
        'rnb': 'soulful melisma, blue notes, and expressive vocal runs',
        'soul': 'classic soul bends with gospel-leaning vocal runs',
        'funk': 'bluesy funk melody with expressive guitar/vocal slides',
        'rock': 'blues-scale guitar licks answering the vocal line',
        'metal': 'blues-rock bends inside aggressive melodic phrases',
        'indie': 'soul-tinged indie melody with soft blue-note color',
        'country': 'gospel-leaning vocal bends and soulful country phrasing',
        'folk': 'folk melody with bluesy bends and intimate slides',
        'jazz': 'blues-scale improvisation with bent notes and slides',
        'blues': 'classic blues phrasing with bent notes and call-response',
        'worship': 'gospel-inflected vocal runs building toward praise peaks',
        'hiphop': 'soul-sampled melodic inflection with expressive ad-libs',
        'trap': 'bluesy melodic trap runs over dark 808s',
        'edm': 'soulful vocal chops with blues inflection in the hook',
        'latin': 'soulful Latin melody with expressive ornamental runs',
        'reggaeton': 'soulful dembow melody with expressive vocal slides',
        'reggae': 'soulful reggae melody with blue-note guitar answers',
        'afrobeats': 'soulful afro melody with expressive melisma',
        'amapiano': 'soulful vocal runs over warm piano-house harmony',
        'cinematic': 'blues-tinged theme with expressive solo instrument runs',
        'mandopop': 'expressive ornamental runs with soulful emotional peaks',
        'world': 'melismatic world phrasing with blue-note color',
        'hardstyle': 'soulful euphoric lead with expressive pitch bends',
        'dnb': 'soulful liquid melody with bluesy vocal color',
        'synthwave': 'bluesy neon lead bends with retro soul color',
        'dubstep': 'soulful melodic lead contrasting heavy bass drops',
        'techno': 'subtle blues color in sparse techno motifs',
        'ambient': 'soft blues-tinged fragments over pads',
      },
    ),
    MelodyDirective(
      id: 'chromatic_dissonant',
      label: 'Chromatic / Dissonant',
      description:
          'Dark, tense harmony using notes outside the main key.',
      defaultToken: 'chromatic, tense melody with dissonant harmonic color',
      genreTokens: {
        'cinematic': 'orchestral chromatic tension with unresolved leading tones',
        'rock': 'minor-key riff melody with tritone color and aggressive contour',
        'metal': 'dissonant chromatic riffs with tense interval leaps',
        'indie': 'chromatic indie melody with uneasy harmonic color',
        'edm': 'dark, atonal synth lead with chromatic movement in the drop',
        'techno': 'industrial chromatic motifs with unresolved tension',
        'hardstyle': 'dissonant screech melody with chromatic aggression',
        'dnb': 'neurofunk-tinged chromatic motifs over dark breaks',
        'dubstep': 'dissonant midrange growls with chromatic stabs',
        'ambient': 'dissonant ambient clusters with slow chromatic drift',
        'synthwave': 'dark synthwave chromatic lead with noir tension',
        'hiphop': 'dark chromatic sample melody with tense harmony',
        'trap': 'dissonant trap melody with uneasy minor color',
        'pop': 'chromatic pop tension resolving into a brighter hook',
        'rnb': 'dark R&B chromatic color under intimate vocal lines',
        'jazz': 'chromatic jazz lines with altered-tone tension',
        'blues': 'tense blues chromaticism before resolving to tonic',
        'worship': 'brief dissonant tension resolving into major praise lift',
        'country': 'dark country chromatic color for story tension',
        'folk': 'modal folk chromatic color for unease',
        'latin': 'chromatic Latin tension under dramatic vocals',
        'reggaeton': 'dark dembow melody with chromatic edge',
        'reggae': 'minor reggae melody with tense chromatic guitar lines',
        'afrobeats': 'tense afro motif with chromatic color before release',
        'amapiano': 'dark piano motif with chromatic tension over the groove',
        'mandopop': 'dramatic chromatic Mandopop tension before chorus lift',
        'world': 'modal/chromatic world melody with tense ornament',
        'funk': 'chromatic funk stabs with tense harmonic color',
      },
    ),
    MelodyDirective(
      id: 'call_and_response',
      label: 'Call and Response',
      description:
          'A structural pattern where a second phrase answers the first.',
      placement: MelodyPlacement.structural,
      tokens: ['(lead)', '(response)'],
    ),
    MelodyDirective(
      id: 'arpeggiated_sequence',
      label: 'Arpeggiated / Sequenced',
      description:
          'Fast, repeating note sequences like a synth arpeggiator.',
      defaultToken: 'arpeggiated, sequenced melodic pattern',
      genreTokens: {
        'edm': 'driving arpeggiated synth lead with 16th-note motion',
        'techno': 'hypnotic sequenced techno arpeggio under the kick',
        'hardstyle': 'fast sequenced hardstyle arp under euphoric leads',
        'dnb': 'rolling sequenced motifs over breakbeat energy',
        'synthwave': 'classic 80s gated arpeggio sequence driving the groove',
        'dubstep': 'pre-drop arpeggiated tension sequence into the bass drop',
        'ambient': 'slow evolving arpeggiated sequence in deep reverb',
        'pop': 'bright synth arpeggio doubling the vocal hook',
        'rnb': 'soft sequenced keys arpeggio under the vocal melody',
        'cinematic': 'rapid string or synth ostinato underpinning the theme',
        'rock': 'sequenced synth/guitar arpeggio under rock vocals',
        'metal': 'fast sequenced synth/guitar figures under heavy riffs',
        'indie': 'sparkling indie arpeggio sequence under the chorus',
        'hiphop': 'looping sequenced motif under pocketed vocals',
        'trap': 'bright pluck arpeggio sequence over 808 motion',
        'latin': 'sequenced montuno-like arpeggio under Latin vocals',
        'reggaeton': 'plucky sequenced arpeggio over dembow rhythm',
        'reggae': 'light sequenced motif over reggae pocket',
        'afrobeats': 'bright sequenced motif interlocking with percussion',
        'amapiano': 'piano arpeggio sequence locked to log-drum groove',
        'country': 'picked arpeggio figures under country vocal melody',
        'folk': 'fingerpicked arpeggio sequence supporting the melody',
        'jazz': 'arpeggiated jazz figures outlining extended chords',
        'blues': 'arpeggiated blues figures answering the vocal',
        'worship': 'flowing pad/guitar arpeggio under congregational melody',
        'mandopop': 'piano arpeggio sequence under Mandopop vocal lines',
        'world': 'sequenced ornamental figures under world melodies',
        'funk': 'funky sequenced stab arpeggios locked to the groove',
      },
    ),
    MelodyDirective(
      id: customId,
      label: 'Custom',
      description:
          'Write your own melodic description — it is injected into the style prompt.',
    ),
  ];

  static const Map<MelodyEvolution, String> evolutionDescriptions = {
    MelodyEvolution.strict:
        'Motifs stay locked across matching sections (Verse 1 ≈ Verse 2, '
        'Chorus 1 ≈ Chorus 2 / Drop 1 ≈ Drop 2). Best for loop-based and '
        'hypnotic genres across EDM, techno, amapiano, trap, reggae, and more.',
    MelodyEvolution.progressive:
        'Later hooks grow in energy and layers while the core melody stays. '
        'Standard for pop, R&B, rock, worship, cinematic, Mandopop, and most '
        'song-form genres that need a lift into the final chorus.',
    MelodyEvolution.highContrast:
        'Bridge, Verse 2, or a mid-song section introduces a deliberate melodic '
        'or rhythmic shift before returning. Great for story-driven, jazz, folk, '
        'experimental, and contrast-heavy arrangements in any genre.',
  };

  /// Recommended evolution mode for a primary/fusion genre pair.
  static MelodyEvolution recommendedEvolutionForGenre({
    String? primaryGenre,
    String? fusionGenre,
  }) {
    final family = resolveMelodyGenreFamily(
      primaryGenre: primaryGenre,
      fusionGenre: fusionGenre,
    );
    return switch (family) {
      'edm' ||
      'techno' ||
      'hardstyle' ||
      'dnb' ||
      'dubstep' ||
      'synthwave' ||
      'ambient' ||
      'amapiano' ||
      'trap' ||
      'reggaeton' ||
      'reggae' ||
      'funk' =>
        MelodyEvolution.strict,
      'jazz' ||
      'blues' ||
      'folk' ||
      'indie' ||
      'world' ||
      'electronic_experimental' =>
        MelodyEvolution.highContrast,
      _ => MelodyEvolution.progressive,
    };
  }

  /// Fine-grained keyword → melody token family. Checked BEFORE the umbrella
  /// [GenreFamily] resolver so genre-specific melody tokens (techno, metal,
  /// world, …) are actually reachable instead of collapsing into umbrella
  /// families (edm / rock / pop).
  static const Map<String, List<String>> _fineGrainedFamilyRules = {
    'techno': ['techno'],
    'synthwave': ['synthwave', 'retrowave', 'outrun', 'vaporwave'],
    'dubstep': ['dubstep', 'brostep', 'riddim', 'melodic dubstep'],
    'trap': ['trap', 'drill', 'phonk'],
    'metal': ['metal', 'djent', 'metalcore', 'deathcore'],
    'indie': [
      'indie rock',
      'garage rock',
      'indie pop',
      'bedroom pop',
      'dream pop',
      'shoegaze',
      'indie sleaze',
    ],
    'mandopop': ['mandopop', 'c pop', 'cpop'],
    'world': [
      'world',
      'bollywood',
      'mena',
      'middle eastern',
      'bhangra',
      'filmi',
      'punjabi',
    ],
    'reggaeton': ['reggaeton', 'dembow', 'perreo'],
    'latin': ['salsa', 'bachata', 'cumbia', 'merengue', 'tango', 'mambo'],
    'ambient': ['ambient', 'soundscape'],
  };

  /// Maps UI primary/fusion genre labels → melody token family key.
  static String resolveMelodyGenreFamily({
    String? primaryGenre,
    String? fusionGenre,
  }) {
    final blob =
        '${primaryGenre ?? ''} ${fusionGenre ?? ''}'.trim().toLowerCase();
    if (blob.isNotEmpty) {
      final normalized = blob
          .replaceAll(RegExp(r'[-/&+]+'), ' ')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();
      // Guard: trap-soul sings R&B melody, not trap.
      if (RegExp(r'\btrap soul\b').hasMatch(normalized)) return 'rnb';
      for (final entry in _fineGrainedFamilyRules.entries) {
        for (final token in entry.value) {
          if (_containsToken(normalized, token)) return entry.key;
        }
      }
    }
    return PromptFlowData.resolveVibeGenreFamily(
      primaryGenre: primaryGenre,
      fusionGenre: fusionGenre,
    );
  }

  static bool _containsToken(String blob, String token) {
    final words = token.split(' ').map(RegExp.escape).join(r'\s+');
    return RegExp('(?<![a-z0-9])$words(?![a-z0-9])').hasMatch(blob);
  }

  /// Builds the explicit LLM melody-evolution instruction block.
  static String buildMelodyEvolutionPlan(MelodyEvolution evolution) {
    final buffer = StringBuffer()
      ..writeln(
        '[MELODY EVOLUTION PLAN]: The song MUST follow this melodic development:',
      );

    switch (evolution) {
      case MelodyEvolution.strict:
        buffer.writeln(
          '- Repetition: Matching sections stay melodically locked '
          '(Verse 1 ≈ Verse 2, Chorus/Drop/Hook repeats stay consistent). '
          'Use arrangement/FX growth if needed — not a new motif.',
        );
      case MelodyEvolution.progressive:
        buffer.writeln(
          '- Development: The first hook/chorus/drop introduces the main melody. '
          'Later returns MUST build on it with harmony layers, counter-melody, '
          'wider range, or more intense instrumentation.',
        );
      case MelodyEvolution.highContrast:
        buffer.writeln(
          '- Contrast: Bridge, Verse 2, Breakdown, or a mid-song section MUST '
          'introduce a new contrasting melodic idea or chord color before '
          'returning to the final hook/chorus/drop.',
        );
    }

    return buffer.toString().trim();
  }

  /// Maps legacy preset ids from the old melody_style_data.dart.
  static String normalizeDirectiveId(String id) {
    return switch (id.trim().toLowerCase()) {
      'anthemic' => 'anthemic_soaring',
      'conversational' => 'conversational_spoken',
      'syncopated_loop' => 'syncopated_rhythmic',
      'blues_gospel_inflection' => 'blues_inflected',
      'chromatic_tension' => 'chromatic_dissonant',
      'call_response' => 'call_and_response',
      'hybrid_split_dna' => 'hook_led',
      'custom notes' || 'custom_notes' => customId,
      '' => autoId,
      _ => id.trim().toLowerCase(),
    };
  }

  static MelodyDirective getDirectiveById(String id) {
    final normalized = normalizeDirectiveId(id);
    return directives.firstWhere(
      (d) => d.id == normalized,
      orElse: () => directives.first,
    );
  }

  static MelodyDirective? directiveById(String id) {
    final normalized = normalizeDirectiveId(id);
    for (final d in directives) {
      if (d.id == normalized) return d;
    }
    return null;
  }
}
