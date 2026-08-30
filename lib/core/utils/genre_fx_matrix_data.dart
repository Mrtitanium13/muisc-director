// GENERATED from tools/genre_fx_matrix.json — do not edit by hand.
// Rebuild: python tools/gen_genre_fx_matrix_dart.py
// ignore_for_file: constant_identifier_names
//
// Data shape: profile[genre][tier] -> { style: String, lyrics: String }
// primaryAnchors[genre] -> golden anchor tags for FX injection
// Genre count: 27 | Required families: afrobeats, amapiano, ambient, boom_bap, cinematic, country, dnb, dubstep, edm, folk, hardstyle, hiphop, indie, jazz, latin, mandopop, metal, pop, reggae, reggaeton, rnb, rock, synthwave, techno, trap, world, worship
//
// Convention: tier '1' lyric_injections are empty (low-intensity = style only).

class GenreFxMatrixData {
  GenreFxMatrixData._();
  static const List<String> DEFAULT_ANCHORS = ['[Chorus]'];
  static const Map<String, List<String>> primaryAnchors = {
    'afrobeats': ["[Chorus]"],
    'amapiano': ["[Log Drum Verse]"],
    'ambient': ["[Atmospheric Swell]"],
    'boom_bap': ["[Hook]"],
    'cinematic': ["[Climax]", "[Orchestral Climax]"],
    'country': ["[Chorus]"],
    'dnb': ["[Drop: Double Time]"],
    'dubstep': ["[Drop: Heavy Bass Impact]"],
    'edm': ["[Drop]", "[Build]"],
    'folk': ["[Chorus]"],
    'hardstyle': ["[Monologue]", "[Drop: Reverse Bass]"],
    'hiphop': ["[Hook]", "[Chorus]"],
    'indie': ["[Chorus]"],
    'jazz': ["[Solo]"],
    'latin': ["[Mambo: Full Horn Section In]"],
    'mandopop': ["[Chorus]"],
    'metal': ["[Breakdown]"],
    'pop': ["[Chorus]"],
    'reggae': ["[Chorus]"],
    'reggaeton': ["[Drop: Dembow Total]"],
    'rnb': ["[Chorus]"],
    'rock': ["[Chorus]"],
    'synthwave': ["[Chorus: High Energy Arpeggio]", "[Bridge]"],
    'techno': ["[Drop: Heavy Kick]"],
    'trap': ["[Hook]"],
    'world': ["[Chorus]"],
    'worship': ["[Chorus Lift]", "[Chorus]"],
  };
  static const Map<String, String> lyricEngineDirectives = {
    'afrobeats': "Syncopated West African pop phrasing, call-and-response hooks, dance-floor gratitude and celebration. Keep lines short, rhythmic, and chant-ready.",
    'amapiano': "",
    'ambient': "Sparse, imagistic lines or instrumental-only bracket tags. Avoid narrative density; favor texture words and spatial mood.",
    'boom_bap': "Story-first bars with concrete detail, internal rhyme, and sample-era authenticity. No motivational poster lines.",
    'cinematic': "Arc-driven imagery with rising stakes; orchestral section tags. Favor cinematic verbs over abstract emotion labels.",
    'country': "Narrative storytelling, concrete place names, family and road imagery. Twang-friendly vowels; avoid generic Nashville clichés.",
    'dnb': "Minimal vocal topline or chop-ready phrases; high-energy chants and breathless build cues. No slow ballad phrasing in drops.",
    'dubstep': "Pre-drop tension phrases, chop cells, and bass-drop mantras. Avoid flowing poetry in drop sections.",
    'edm': "Festival-ready hooks, build/release cues, and anthem repetition. Keep drop sections chant-simple.",
    'folk': "Intimate first-person narrative, acoustic-room honesty, nature and relationship detail.",
    'hardstyle': "",
    'hiphop': "Punchy internal rhyme, vivid street/detail imagery, strong hook repetition. No empty flex filler.",
    'indie': "Understated emotional specificity, conversational phrasing, imperfect rhyme welcome.",
    'jazz': "Sophisticated but singable lines; room for scat/solo sections. Favor mood over plot.",
    'latin': "Romantic or celebratory Spanish/English blend as user language dictates; percussive syllable feel.",
    'mandopop': "Melodic, cinematic Mandarin or bilingual hooks; key-change lift language in final chorus.",
    'metal': "Aggressive declarative lines, breakdown chants, scream-ready syllables. No soft pop metaphors in heavy sections.",
    'pop': "Relatable love/loss/celebration themes, accessible AABB/ABAB hooks, memorable post-chorus earworms.",
    'reggae': "Laid-back behind-the-beat phrasing, conscious or romantic themes, patois-friendly hooks when dialect allows; leave space for echo trails.",
    'reggaeton': "Dembow-pocket phrasing, romantic or party energy, short hook loops for drop stacking.",
    'rnb': "Sensual specificity, conversational ad-libs, velvet tone in verse; stacked harmonies in chorus.",
    'rock': "Anthemic chorus lines, raw emotional honesty, guitar-solo section tags when instrumental breaks apply.",
    'synthwave': "Retro-futurist nostalgia, neon mood without sci-fi cliché spam, 80s cinematic brevity.",
    'techno': "Minimal vocal fragments or hypnotic mantra loops; industrial realism over festival poetry.",
    'trap': "808-pocket phrasing, dark mood, triplet-friendly syllable counts, hook-first repetition.",
    'world': "Bollywood, Bhangra, Punjabi, Filmi, and Middle Eastern phrasing — rhythmic hooks, melisma-friendly vowels, celebratory or romantic imagery.",
    'worship': "Themes of grace, redemption, and worship. Call-and-response phrasing, uplifting vocabulary, biblical allusion when natural — avoid secular metaphors in climax sections.",
  };
  static const Map<String, Map<String, Map<String, String>>> profiles = {
    'afrobeats': {
      '1': {'style': "relaxed west african percussion, smooth synth bass", 'lyrics': ""},
      '2': {'style': "vibrant shaker loops, log drum accents, syncopated vocal chops", 'lyrics': "[Log Drum Break]"},
      '3': {'style': "heavy syncopated log drum drops, rapid talking drum rolls, bright call-and-response vocal echo stacks, ultra-danceable afro-pop groove drops", 'lyrics': "[Percussion Breakdown]\n[Log Drum Build]\n[Drop: Heavy Log Drums]"},
    },
    'amapiano': {
      '1': {'style': "soft shaker pulse, atmospheric pad, log drum tease", 'lyrics': ""},
      '2': {'style': "log drum pattern lock, group chant accents, rising hats", 'lyrics': "[Log Drum Verse]"},
      '3': {'style': "heavy log drum bass variation, full groove peak, percussive breakdown, group chant accent flood", 'lyrics': "[Breakdown: Log Drum Isolates]\n[Chant Accents Build]\n[Drop: Full Groove Peak]"},
    },
    'ambient': {
      '1': {'style': "soft atmospheric textures, infinitely long reverb", 'lyrics': ""},
      '2': {'style': "evolving modular synth pads, tape hiss texture, swelling delay trails", 'lyrics': "[Atmospheric Swell]"},
      '3': {'style': "ethereal field recordings, slow sweeping low-pass filters, shimmering deep granular delay, reverse reverb swells, vast organic soundscapes", 'lyrics': "[Deep Spatial Evolution]\n[Ethereal Texture Fade]"},
    },
    'boom_bap': {
      '1': {'style': "dusted vinyl crackle, warm close-mic vocal pocket", 'lyrics': ""},
      '2': {'style': "crisp horn flash, wider vocal doubles, swung 16th feel", 'lyrics': "[Ad-lib Accents]\n[Hook Lift]"},
      '3': {'style': "heavy boom bap break pressure, dramatic DJ scratch cut, dense drum loop, vocal urgency peak", 'lyrics': "[DJ Scratch Break]\n[Ad-lib Flood]\n[Hook: Maximum Pocket]"},
    },
    'cinematic': {
      '1': {'style': "soft orchestral strings, gentle piano spacing", 'lyrics': ""},
      '2': {'style': "dramatic orchestral brass hits, rising string staccatos, ticking clock tension", 'lyrics': "[Dramatic Crescendo]"},
      '3': {'style': "thunderous taiko drum ensemble drops, epic choir vocal chords, soaring heroic brass peaks, massive sub-bass impact booms, blockbuster cinematic trailer scales", 'lyrics': "[Tension Building Sub-Bass]\n[Epic Orchestral Crescendo]\n[Coda: Full Grand Scale Resolve]"},
    },
    'country': {
      '1': {'style': "warm acoustic guitar strumming, clean mix", 'lyrics': ""},
      '2': {'style': "twangy pedal steel guitar swells, driving acoustic drum fills, organic banjo picking", 'lyrics': "[Key Change Transition]"},
      '3': {'style': "roaring southern rock electric guitar riffs, anthemic stadium country drum rolls, blazing fast fiddle solos, driving double-time acoustic finish", 'lyrics': "[Guitar and Fiddle Duel]\n[Big Drum Fill]\n[Chorus: Upbeat Stadium Country]"},
    },
    'dnb': {
      '1': {'style': "liquid drum and bass, rolling transitions", 'lyrics': ""},
      '2': {'style': "174 BPM, amen break drum fills, rushing white noise riser, reese bass swell", 'lyrics': "[Rising Groove Build]\n[Drop: Double Time]"},
      '3': {'style': "174 BPM, rapid complex amen break drum fills, intense sub-bass glides, massive rushing white noise risers, aggressive reese bass swell", 'lyrics': "[Breakdown: Drums Cut Out]\n[Accelerating Snare Fill]\n[Drop: Maximum Amen Break Energy]"},
    },
    'dubstep': {
      '1': {'style': "subtle sub-bass weight, minimal glitching", 'lyrics': ""},
      '2': {'style': "wobble bass drops, pre-drop vocal sample cue, pitch-shifting risers", 'lyrics': "[Pre-Drop Tension]\n[Drop: Heavy Bass Impact]"},
      '3': {'style': "aggressive tearout growls, complex LFO wobble bass modulation, mechanical metal screech FX, explosive sub-bass drops, intense rhythmic glitching", 'lyrics': "[Build: Accelerating Triplets]\n[Pre-Drop Vocal Silence]\n[Drop: Maximum Wobble Bass Chaos]"},
    },
    'edm': {
      '1': {'style': "smooth transitions, subtle synth swells", 'lyrics': ""},
      '2': {'style': "dramatic risers, white noise sweeps, festival drop, dancing ducking-kick pulse, low-saturated four-on-the-floor that breathes with the pads", 'lyrics': "[Rising Energy Build]\n[Drop: Festival Impact]"},
      '3': {'style': "massive white noise sweeps, explosive snare roll builds, heavy ducking-kick impact, pumping groove that lifts with the drop, chaotic drop impact, peak-time energy", 'lyrics': "[Pre-Chorus]\n[Rising Energy Build]\n[Accelerating Snare Roll]\n[Drop: Full Impact]"},
    },
    'folk': {
      '1': {'style': "intimate solo fingerstyle acoustic guitar, close natural room mic", 'lyrics': ""},
      '2': {'style': "soft cello swells, layered acoustic vocal harmonies, organic foot stomps", 'lyrics': "[Harmonies In]"},
      '3': {'style': "sweeping orchestral string swells, thunderous cinematic acoustic foot-stomp hits, soaring emotional vocal harmony cascades, mandolin tremolo picking swells", 'lyrics': "[Bridge: Whispered Intimate]\n[Crescendo: Orchestral Folk Swell]"},
    },
    'hardstyle': {
      '1': {'style': "distorted reverse-bass kick foundation, euphoric supersaw pads, 150 BPM festival grid", 'lyrics': ""},
      '2': {'style': "reverse-bass kick swells, layered snare-clap builds, anthem supersaw leads, dense anthem punch", 'lyrics': "[Rising Energy Build]\n[Drop: Reverse Bass]"},
      '3': {'style': "massive reverse-bass kick impact, accelerating snare roll, distorted supersaw anthem, rawstyle aggression, festival main-stage saturation", 'lyrics': "[Monologue]\n[Pre-Chorus]\n[Accelerating Snare Roll]\n[Drop: Reverse Bass Impact]"},
    },
    'hiphop': {
      '1': {'style': "subtle hi-hat rolls, dusty head-nod groove", 'lyrics': ""},
      '2': {'style': "808 slides, crisp snare fills, sudden beat break", 'lyrics': "[Drum Fill]"},
      '3': {'style': "rapid stuttering hi-hat rolls, aggressive heavy 808 bass glides, vintage vinyl scratch FX, unexpected sudden intense beat switch", 'lyrics': "[Vinyl Scratch Break]\n[Beat Switch]\n[808 Bass Drop]"},
    },
    'indie': {
      '1': {'style': "lo-fi bedroom pop aesthetic, jangly clean guitars", 'lyrics': ""},
      '2': {'style': "vintage spring reverb swells, driving indie basslines, organic tambourine shakes", 'lyrics': "[Instrumental Outro Fade]"},
      '3': {'style': "swirling psychedelic shoegaze guitar walls, massive tape-delay oscillation swells, emotional quiet-loud dynamic explosions, unpolished garage rock drum fills", 'lyrics': "[Bridge: Quiet Intimate Guitars]\n[Explosive Guitars In]\n[Chorus: Wall of Sound]"},
    },
    'jazz': {
      '1': {'style': "smoky late-night jazz lounge mood, soft brushed drums", 'lyrics': ""},
      '2': {'style': "walking bassline transitions, smooth saxophone melody solos, crisp drum stick clicks", 'lyrics': "[Saxophone Solo]"},
      '3': {'style': "fast uptempo bebop swing drum fills, intricate walking double-bass lines, chaotic free-jazz horn improvisation breaks, complex extended piano chord modulations", 'lyrics': "[Drum Solo Break]\n[Full Band Swing In]"},
    },
    'latin': {
      '1': {'style': "classic acoustic salsa groove, soft hand percussion", 'lyrics': ""},
      '2': {'style': "bright brass stabs, driving conga drum fills, energetic cowbell syncopation", 'lyrics': "[Descarga Percusion]"},
      '3': {'style': "explosive horn section flares, hyper-accelerated timbale drum fills, high-energy call-and-response montuno hooks, driving carnival percussion drops", 'lyrics': "[Solo de Timbales]\n[Mambo: Full Horn Section In]"},
    },
    'mandopop': {
      '1': {'style': "intimate vocal, subtle erhu undertone, spare piano", 'lyrics': ""},
      '2': {'style': "guzheng shimmer, string pad layer, rising vocal delivery", 'lyrics': "[Pre-Chorus Build]"},
      '3': {'style': "full key-change lift, soaring erhu lead line, orchestral string swell, dramatic vocal belt", 'lyrics': "[Bridge: Erhu Statement]\n[Key Change]\n[Chorus: Full String Swell Peak]"},
    },
    'metal': {
      '1': {'style': "distorted rhythm guitars, steady double-bass foundation", 'lyrics': ""},
      '2': {'style': "rapid double-bass drum fills, screaming pinch harmonics, sudden heavy breakdown", 'lyrics': "[Breakdown]"},
      '3': {'style': "crushing down-tuned djent guitar chugs, lightning-fast blast beats, brutal bass drops, catastrophic slam breakdown, screaming guitar solo", 'lyrics': "[Pre-Breakdown: Guitars Cut Out]\n[Bass Drop Shockwave]\n[Breakdown: Heavy Slam Djent]"},
    },
    'pop': {
      '1': {'style': "polished modern mix, smooth dynamic scaling", 'lyrics': ""},
      '2': {'style': "uplifting vocal riser, finger snap accents, anthemic chorus swell", 'lyrics': "[Pre-Chorus Build]\n[Chorus]"},
      '3': {'style': "explosive pop drop, massive layered vocal harmonies, high-energy synth stabs, sudden dramatic silence break, mainstage stadium chorus scale", 'lyrics': "[Pre-Chorus: Tension Rises]\n[Dramatic Beat Pause]\n[Chorus: Explosive Pop Hook]"},
    },
    'reggae': {
      '1': {'style': "warm one-drop groove, spring reverb skank, round bass weight", 'lyrics': ""},
      '2': {'style': "dub delay throws, offbeat organ bubble, echoing snare drops", 'lyrics': "[Dub Echo Break]"},
      '3': {'style': "heavy dub echo cascades, thunderous one-drop drum and bass weight, spring reverb splashes, sound-system sub pressure, crowd chant call-and-response", 'lyrics': "[Breakdown: Bass and Drums Isolate]\n[Delay Throw Build]\n[Drop: Full One-Drop Return]"},
    },
    'reggaeton': {
      '1': {'style': "classic dembow rhythm loop, warm acoustic guitar touches", 'lyrics': ""},
      '2': {'style': "syncopated snare rolls, airhorn accents, pumping reggaeton sub-bass", 'lyrics': "[El Bajo Rompe]"},
      '3': {'style': "aggressive driving dembow beat drops, sharp laser siren FX, sudden club beat drops, vocal stutter vocal chops, deep sub-bass modulation", 'lyrics': "[Cambio de Ritmo]\n[Build: Fuego Energy]\n[Drop: Dembow Total]"},
    },
    'rnb': {
      '1': {'style': "velvet-pressed vocal tone, soft-knee sung intimacy, warm Rhodes chords", 'lyrics': ""},
      '2': {'style': "velvet bassline glides, subtle finger snap breaks, smooth vocal echo trails", 'lyrics': "[Bridge: Vocal Ad-libs]"},
      '3': {'style': "sensual late-night sub-bass swells, intricate acoustic drum fills, luxurious layered vocal harmony stacks, neo-soul chord transitions", 'lyrics': "[Sensual Bridge Break]\n[Vocal Run Climaxes]\n[Chorus: Deep Groove Soul]"},
    },
    'rock': {
      '1': {'style': "warm overdriven guitar rhythm, natural room drums", 'lyrics': ""},
      '2': {'style': "driving drum fills, soaring guitar feedback, punchy anthemic chorus", 'lyrics': "[Drum Roll Transition]"},
      '3': {'style': "screaming Marshall amp guitar solos, thunderous double-kick drum rolls, crashing cymbal accents, explosive stadium rock chorus impact", 'lyrics': "[Bridge: Guitar Feedback Swell]\n[Massive Drum Fill]\n[Chorus: High Energy Stadium Rock]"},
    },
    'synthwave': {
      '1': {'style': "80s vintage analog warmth", 'lyrics': ""},
      '2': {'style': "cinematic risers, retro tom-drum fill, neon laser sweep", 'lyrics': "[Retro Synth Arpeggio Break]"},
      '3': {'style': "dramatic 80s outrun cinematic risers, massive gated snare fills, classic retro tom-drum rolls, roaring analog synth swells", 'lyrics': "[Bridge: Retro Ambient Pads]\n[Gated Drum Fill]\n[Chorus: High Energy Arpeggio]"},
    },
    'techno': {
      '1': {'style': "minimal transitions, hypnotic rhythm", 'lyrics': ""},
      '2': {'style': "industrial sub-bass drops, modular synth swells, dark noise risers", 'lyrics': "[Filter Sweep Break]\n[Drop: Heavy Kick]"},
      '3': {'style': "aggressive industrial modular screech, rushing white noise sweeps, dark modular filter sweeps, heavy laser FX, hypnotic build-up", 'lyrics': "[Industrial Breakdown]\n[Accelerating Percussion Build]\n[Drop: Driving Sub-Bass and Kick]"},
    },
    'trap': {
      '1': {'style': "clean 808 foundation, basic rolling hi-hats", 'lyrics': ""},
      '2': {'style': "pitch-shifting 808 glides, fast triplet snare rolls, laser hit effects", 'lyrics': "[Hook: Beats Stutter Build]\n[Hook: Full Trap Pocket]"},
      '3': {'style': "heavy maximalist 808 bass distortion, rapid machine-gun hi-hat stutter rolls, brass hit accents, cinematic orchestral hits, aggressive trap energy", 'lyrics': "[Intense Hi-Hat Build]\n[808 Slide Accent]\n[Hook: Aggressive Trap Beat]"},
    },
    'world': {
      '1': {'style': "warm hand percussion, subtle string or reed ornament, intimate melodic lead", 'lyrics': ""},
      '2': {'style': "bright dhol or tabla accents, sitar or oud color, syncopated dance groove, layered vocal ornaments", 'lyrics': "[Percussion Break]"},
      '3': {'style': "festival percussion drops, soaring melismatic vocal runs, full string and reed ensemble swell, high-energy cinematic world-pop climax", 'lyrics': "[Breakdown: Hand Percussion Isolates]\n[Hook Chant Build]\n[Chorus: Full Ensemble Peak]"},
    },
    'worship': {
      '1': {'style': "warm pad swell, close-mic tender vocal, sparse arrangement", 'lyrics': ""},
      '2': {'style': "drums lift in, wider vocal harmonies, worship lift", 'lyrics': "[Chorus Lift]"},
      '3': {'style': "full gospel choir belt, hands-up climax, congregational vamp, dynamic peak", 'lyrics': "[Bridge: Congregational Vamp]\n[Spontaneous Flow]\n[Chorus: Full Choir Climax]"},
    },
  };


  /// Golden anchors for FX injection priority (from genre_fx_matrix.json).

  static List<String> getAnchors({required String family}) {

    final key = family.trim().toLowerCase();

    final direct = primaryAnchors[key];

    if (direct != null && direct.isNotEmpty) {

      return List<String>.from(direct);

    }

    final fallbackKey = _anchorFallbackFamily(key);

    if (fallbackKey != null) {

      final fallback = primaryAnchors[fallbackKey];

      if (fallback != null && fallback.isNotEmpty) {

        return List<String>.from(fallback);

      }

    }

    return List<String>.from(DEFAULT_ANCHORS);

  }



  /// Returns [style, lyrics] pair for the given family + tier.

  /// Falls back to the nearest sibling lane if the family is missing,

  /// or to empty strings if nothing matches.

  static ({String style, String lyrics}) getFx({

    required String family,

    String tier = '1',

  }) {

    final row = profiles[family] ?? _fallbackFamily(family);

    final tierMap = row?[tier] ?? row?['2'] ?? row?['1'];

    if (tierMap == null) {

      return (style: '', lyrics: '');

    }

    return (

      style: tierMap['style'] ?? '',

      lyrics: tierMap['lyrics'] ?? '',

    );

  }



  static String? _anchorFallbackFamily(String family) {

    const fallbacks = <String, String>{

      'boom_bap': 'hiphop',

      'amapiano': 'afrobeats',

      'worship': 'pop',

      'mandopop': 'pop',

    };

    return fallbacks[family];

  }



  static Map<String, Map<String, String>>? _fallbackFamily(

    String family,

  ) {

    const fallbacks = <String, String>{

      'boom_bap': 'hiphop',

      'amapiano': 'afrobeats',

      'worship': 'pop',

      'mandopop': 'pop',

    };

    final target = fallbacks[family];

    if (target == null) return null;

    return profiles[target];

  }

  static String getLyricEngineDirectives({required String family}) {
    final key = family.trim().toLowerCase();
    final direct = lyricEngineDirectives[key];
    if (direct != null && direct.isNotEmpty) {
      return direct;
    }
    final fallbackKey = _anchorFallbackFamily(key);
    if (fallbackKey != null) {
      final fallback = lyricEngineDirectives[fallbackKey];
      if (fallback != null && fallback.isNotEmpty) {
        return fallback;
      }
    }
    return '';
  }
}
