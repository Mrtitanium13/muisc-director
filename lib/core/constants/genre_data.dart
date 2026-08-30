/// Lightweight genre metadata bundle for melody auto-mode and UI hints.
class GenreMelodyInfo {
  const GenreMelodyInfo({
    required this.label,
    this.bpmHint,
    this.defaultMelodyDirectiveId = 'hook_led',
  });

  final String label;
  final String? bpmHint;
  final String defaultMelodyDirectiveId;
}

/// Genre categories, sub-genres, BPM hints, and quick-pick chips.
///
/// Public API is preserved for backward compatibility. Internal lookup
/// algorithms are hardened against substring-order bugs and derivations are
/// cached to prevent repeated recomputation.
class GenreData {
  GenreData._();

  /// Debug / test entry — duplicate subgenre labels across categories fail.
  static bool? _integrityCache;

  static bool validateIntegrity() {
    return _integrityCache ??= _validateIntegrity();
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // RAW TAXONOMY DATA
  // ─────────────────────────────────────────────────────────────────────────────

  static const List<String> categories = [
    'EDM',
    'Hip Hop',
    'R&B/Soul',
    'Pop',
    'Rock/Metal',
    'Country',
    'Gospel',
    'Jazz/Blues',
    'Latin',
    'Reggae/Dub',
    'Afro/World',
    'Cinematic',
  ];

  static const Map<String, List<String>> subGenresByCategory = {
    'EDM': [
      'House',
      'Deep House',
      'Soulful House',
      'Tech House',
      'Progressive House',
      'Melodic House',
      'Big Room',
      'Techno',
      'Hard Techno',
      'Melodic Techno',
      'Acid Techno',
      'Big Room Techno',
      'Trance',
      'Uplifting Trance',
      'Dubstep',
      'Melodic Dubstep',
      'Drum & Bass',
      'Liquid DnB',
      'Future Bass',
      'Future House',
      'Hardstyle',
      'Rawstyle',
      'Hard Bounce',
      'EDM Bounce',
      'Nu-Disco',
      'Future Funk',
      'Disco House',
      'Vinahouse',
      'Afro House',
      'Amapiano-Vinahouse',
      'UK Garage',
      'Jersey Club',
    ],
    'Hip Hop': [
      'Hip Hop',
      'Boom Bap',
      'Trap',
      'Melodic Trap',
      'Drill',
      'UK Drill',
      'NY Drill',
      'Lo-Fi Hip Hop',
      'Chillhop',
      'Cloud Rap',
      'Phonk',
      'Jazz Rap',
      'Afro-Swing',
      'Afro Rap',
    ],
    'R&B/Soul': [
      'R&B',
      'Contemporary R&B',
      'Neo-Soul',
      'Soul',
      '90s R&B',
      'New Jack Swing',
      'Quiet Storm',
      'Trap Soul',
      'Funk',
    ],
    'Pop': [
      'Pop',
      'Mainstream Pop',
      'Pop / Max Martin',
      'Electropop',
      'Dance Pop',
      'Bedroom Pop',
      'Indie Pop',
      'K-Pop',
      'J-Pop',
      'C-Pop',
      'Mandopop',
      'Synth Pop',
      'Hyperpop',
    ],
    'Rock/Metal': [
      'Rock',
      'Indie Rock',
      'Alt Rock',
      'Alternative',
      'Pop Punk',
      'Emo',
      'Punk',
      'Hard Rock',
      'Classic Rock',
      'Metal',
      'Heavy Metal',
      'Metalcore',
      'Death Metal',
      'Post-Rock',
      'Shoegaze',
      'Dream Pop',
    ],
    'Country': [
      'Country',
      'Modern Country',
      'Outlaw Country',
      'Americana',
      'Folk-Rock',
      'Bluegrass',
      'Indie Folk',
      'Singer-Songwriter',
    ],
    'Gospel': [
      'Gospel',
      'Traditional Gospel',
      'Contemporary Gospel',
      'Urban Gospel',
      'Praise/Worship',
      'Modern Worship',
      'Worship Ballad',
      'CCM',
      'Pop Worship',
      'Afro-Gospel',
      'Southern Gospel',
      'Country Gospel',
    ],
    'Jazz/Blues': [
      'Jazz',
      'Vocal Jazz',
      'Bebop',
      'Smooth Jazz',
      'Jazz Fusion',
      'Fusion',
      'Nu-Jazz',
      'Acid Jazz',
      'Big Band',
      'Blues',
      'Chicago Blues',
      'Delta Blues',
    ],
    'Latin': [
      'Reggaeton',
      'Dembow',
      'Latin Pop',
      'Bachata',
      'Salsa',
      'Bossa Nova',
      'Cumbia',
      'Vallenato',
      'Brazilian Funk',
      'Sertanejo',
      'Forró',
    ],
    'Reggae/Dub': [
      'Reggae',
      'Roots Reggae',
      'Dub',
      'Dancehall',
      'Soca',
    ],
    'Afro/World': [
      'Afrobeats',
      'Highlife',
      'Fuji',
      'Gqom',
      'Amapiano',
      'City Pop',
      'Bollywood',
      'Filmi',
      'Punjabi',
      'Bhangra',
      'Folk',
      'Middle Eastern',
    ],
    'Cinematic': [
      'Orchestral',
      'Film Score',
      'Cinematic',
      'Trailer',
      'Ambient',
      'Dark Ambient',
      'Ambient Score',
      'Vaporwave',
      'New Wave',
      'Industrial',
      'EBM',
      'Synthwave',
      'Retrowave',
    ],
  };

  // ─────────────────────────────────────────────────────────────────────────────
  // BPM HINTS
  // ─────────────────────────────────────────────────────────────────────────────

  static const Map<String, String> bpmHintByGenre = {
    'Hardstyle': '150–162 BPM',
    'Rawstyle': '150–200 BPM',
    'Hard Bounce': '128–145 BPM',
    'Hard Techno': '138–152 BPM',
    'Techno': '128–135 BPM',
    'Acid Techno': '128–135 BPM',
    'EDM Bounce': '128–138 BPM',
    'Melodic Techno': '128–138 BPM',
    'House': '120–128 BPM',
    'Deep House': '120–128 BPM',
    'Tech House': '124–126 BPM',
    'Melodic House': '122–128 BPM',
    'Afro House': '118–126 BPM',
    'Soulful House': '118–124 BPM',
    'Progressive House': '124–132 BPM',
    'Future House': '125–128 BPM',
    'Disco House': '110–120 BPM',
    'Nu-Disco': '110–120 BPM',
    'Future Funk': '110–120 BPM',
    'Big Room': '128 BPM',
    'Big Room Techno': '138–148 BPM',
    'Vinahouse': '128–140 BPM',
    'Trance': '128–145 BPM',
    'Uplifting Trance': '138 BPM',
    'Dubstep': '140–150 BPM half-time',
    'Melodic Dubstep': '140 BPM half-time',
    'Future Bass': '150–160 BPM',
    'Drum & Bass': '160–175 BPM',
    'Liquid DnB': '174 BPM',
    'UK Garage': '130–135 BPM',
    'Jersey Club': '135–140 BPM',
    'Gqom': '124–128 BPM',
    'Amapiano': '100–116 BPM',
    'Amapiano-Vinahouse': '110–120 BPM',
    'Afrobeats': '100–115 BPM',
    'Afro-Swing': '100–115 BPM',
    'Afro Rap': '95–115 BPM',
    'Highlife': '80–120 BPM',
    'Fuji': '110–130 BPM',
    'Hip Hop': '85–115 BPM',
    'Boom Bap': '80–95 BPM',
    'Trap': '130–160 BPM half-time',
    'Melodic Trap': '130–150 BPM',
    'Drill': '138–145 BPM half-time',
    'UK Drill': '138–145 BPM',
    'NY Drill': '140–145 BPM',
    'Phonk': '130–160 BPM',
    'Cloud Rap': '130–150 BPM',
    'Lo-Fi Hip Hop': '60–90 BPM',
    'Chillhop': '70–90 BPM',
    'Jazz Rap': '80–110 BPM',
    'R&B': '80–110 BPM',
    'Contemporary R&B': '80–100 BPM',
    '90s R&B': '90–105 BPM',
    'New Jack Swing': '90–105 BPM',
    'Quiet Storm': '60–80 BPM',
    'Trap Soul': '70–85 BPM half-time',
    'Neo-Soul': '70–90 BPM',
    'Soul': '70–110 BPM',
    'Funk': '95–115 BPM',
    'Pop': '100–130 BPM',
    'Mainstream Pop': '90–120 BPM',
    'Pop / Max Martin': '100–128 BPM',
    'Electropop': '110–128 BPM',
    'Dance Pop': '110–128 BPM',
    'Bedroom Pop': '80–110 BPM',
    'Indie Pop': '90–125 BPM',
    'Synth Pop': '110–130 BPM',
    'Hyperpop': '130–180 BPM',
    'K-Pop': '100–140 BPM',
    'J-Pop': '85–135 BPM',
    'C-Pop': '85–130 BPM',
    'Mandopop': '85–135 BPM',
    'Latin Pop': '90–120 BPM',
    'City Pop': '100–120 BPM',
    'Rock': '100–160 BPM',
    'Indie Rock': '110–140 BPM',
    'Alt Rock': '110–140 BPM',
    'Alternative': '90–150 BPM',
    'Pop Punk': '150–180 BPM',
    'Emo': '140–180 BPM',
    'Punk': '140–200 BPM',
    'Hard Rock': '110–140 BPM',
    'Classic Rock': '100–140 BPM',
    'Metal': '120–200 BPM',
    'Heavy Metal': '120–180 BPM',
    'Metalcore': '130–200 BPM',
    'Death Metal': '150–250 BPM',
    'Post-Rock': '70–130 BPM',
    'Shoegaze': '90–100 BPM',
    'Dream Pop': '90–100 BPM',
    'Country': '80–108 BPM',
    'Modern Country': '90–130 BPM',
    'Outlaw Country': '80–110 BPM',
    'Americana': '80–120 BPM',
    'Folk-Rock': '90–130 BPM',
    'Bluegrass': '120–180 BPM',
    'Indie Folk': '80–110 BPM',
    'Singer-Songwriter': '70–100 BPM',
    'Folk': '80–120 BPM',
    'Gospel': '65–120 BPM',
    'Traditional Gospel': '80–95 BPM',
    'Contemporary Gospel': '85–100 BPM',
    'Urban Gospel': '80–110 BPM',
    'Praise/Worship': '65–110 BPM',
    'Modern Worship': '70–90 BPM',
    'Worship Ballad': '60–75 BPM',
    'CCM': '90–120 BPM',
    'Pop Worship': '70–110 BPM',
    'Afro-Gospel': '100–118 BPM',
    'Southern Gospel': '80–110 BPM',
    'Country Gospel': '80–120 BPM',
    'Jazz': '60–200 BPM',
    'Vocal Jazz': '100–180 BPM',
    'Bebop': '140–240 BPM',
    'Smooth Jazz': '90–120 BPM',
    'Jazz Fusion': '90–140 BPM',
    'Fusion': '90–140 BPM',
    'Nu-Jazz': '90–110 BPM',
    'Acid Jazz': '90–120 BPM',
    'Big Band': '120–200 BPM',
    'Blues': '60–120 BPM',
    'Chicago Blues': '80–100 BPM',
    'Delta Blues': '60–100 BPM',
    'Reggaeton': '90–100 BPM',
    'Dembow': '95–105 BPM',
    'Bachata': '130–140 BPM',
    'Salsa': '180–220 BPM',
    'Bossa Nova': '120–140 BPM',
    'Cumbia': '90–130 BPM',
    'Vallenato': '100–130 BPM',
    'Brazilian Funk': '130–150 BPM',
    'Sertanejo': '130–150 BPM',
    'Forró': '110–130 BPM',
    'Reggae': '60–80 BPM',
    'Roots Reggae': '60–80 BPM',
    'Dub': '60–90 BPM',
    'Dancehall': '90–105 BPM',
    'Soca': '100–140 BPM',
    'Bollywood': '100–160 BPM',
    'Filmi': '90–140 BPM',
    'Punjabi': '110–140 BPM',
    'Bhangra': '110–140 BPM',
    'Middle Eastern': '80–130 BPM',
    'Cinematic': '40–180 BPM',
    'Film Score': '60–120 BPM',
    'Orchestral': '40–120 BPM',
    'Ambient': '50–80 BPM free',
    'Dark Ambient': '40–80 BPM free',
    'Ambient Score': '40–100 BPM',
    'Trailer': '80–140 BPM',
    'Vaporwave': '80–100 BPM',
    'New Wave': '110–130 BPM',
    'Industrial': '120–150 BPM',
    'EBM': '120–140 BPM',
    'Synthwave': '100–130 BPM',
    'Retrowave': '100–130 BPM',
  };

  // ─────────────────────────────────────────────────────────────────────────────
  // QUICK PICK ROWS
  // ─────────────────────────────────────────────────────────────────────────────

  static const List<(String, String)> quickPickRows = [
    ('Hip Hop', 'Hip Hop'),
    ('Pop', 'Pop'),
    ('Boom Bap', 'Boom Bap'),
    ('Trap', 'Trap'),
    ('Drill', 'Drill'),
    ('Phonk', 'Phonk'),
    ('Amapiano', 'Amapiano'),
    ('Afrobeats', 'Afrobeats'),
    ('Hardstyle', 'Hardstyle'),
    ('Techno', 'Techno'),
    ('Melodic Techno', 'Melodic Techno'),
    ('Progressive House', 'Progressive House'),
    ('Deep House', 'Deep House'),
    ('Future Bass', 'Future Bass'),
    ('Reggaeton', 'Reggaeton'),
    ('Country', 'Country'),
    ('🌟 K-Pop', 'K-Pop'),
    ('🎌 J-Pop', 'J-Pop'),
    ('🎵 Mandopop', 'Mandopop'),
    ('✨ Hitmaker · Max Martin', 'Pop / Max Martin'),
    ('🔥 Gospel', 'Gospel'),
    ('🙏 Praise & Worship', 'Praise/Worship'),
    ('Hard Techno', 'Hard Techno'),
    ('EDM Bounce', 'EDM Bounce'),
    ('🇻🇳 Vinahouse', 'Vinahouse'),
    ('R&B', 'R&B'),
    ('Neo-Soul', 'Neo-Soul'),
    ('Reggae', 'Reggae'),
    ('Bachata', 'Bachata'),
    ('Hyperpop', 'Hyperpop'),
    ('Jazz', 'Jazz'),
    ('Rock', 'Rock'),
    ('Metal', 'Metal'),
    ('Cinematic', 'Cinematic'),
  ];

  static final List<String> quickPickGenres = List<String>.unmodifiable(
    quickPickRows.map((e) => e.$2).toList(),
  );

  static const String remixTargetDefault = 'Techno';

  static final List<String> remixTargetGenres = _buildRemixTargetGenres();

  static List<String> _buildRemixTargetGenres() {
    final merged = <String>{};
    for (final list in subGenresByCategory.values) {
      merged.addAll(list);
    }
    merged.addAll(quickPickGenres);
    final out = merged.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return List<String>.unmodifiable(out);
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // SONIC REFERENCE CHIPS
  // ─────────────────────────────────────────────────────────────────────────────

  static const Map<String, List<String>> suggestedSonicReferenceChips = {
    'Lo-Fi Hip Hop': [
      'dusty swing pocket',
      'vinyl/warm noise bed',
      'sparse melodic loop',
    ],
    'Hip Hop': [
      'swing-heavy drum pocket',
      'tight low-end · kick–808 interplay',
      'vocal-forward verse · hook lift',
    ],
    'Boom Bap': ['cratedigger drum break', 'jazzy horn sample loop', 'gritty MPC swing'],
    'Trap': ['808 slides & rolls', 'dark plugg mood', 'melodic trap leads'],
    'Melodic Trap': ['emotional pluck melody', 'airy 808 half-time', 'auto-tune vulnerability'],
    'Drill': ['sliding 808 patterns', 'tense minor pads', 'machinegun hi-hat rolls'],
    'UK Drill': ['uk slide 808', 'dark vocal sample stab', 'syncopated hat triplets'],
    'NY Drill': ['bronx bounce drill', 'gritty sample chop', 'aggressive vocal pocket'],
    'Phonk': ['Memphis cowbell', 'distorted 808 kick', 'dark detuned saws'],
    'Cloud Rap': ['hazy reverb tail', 'washed-out sample bed', 'languid vocal drawl'],
    'Afro-Swing': ['log drum + 808 hybrid', 'M1 piano stab', 'talking drum pocket'],
    'Jazz Rap': ['upright bass pocket', 'brush kit swing', 'rhodes vamp loop'],
    'House': ['four-on-the-floor swing', 'chunky bassline', 'diva vocal stab'],
    'Deep House': ['U87 soulful vocal', 'Rhodes stab + Juno pad', 'tight sidechain'],
    'Tech House': ['minimal spoken vocal', 'rolling sub groove', 'tight clap pattern'],
    'Progressive House': [
      'Ryos-style supersaw lead',
      'sidechain reez bass pump',
      'pre-shifted clap build',
      'mainstage fusion drop',
    ],
    'Big Room': [
      'cinematic hybrid supersaw',
      'ducking-kick sidechain pump',
      'hardstyle final drop kick',
      '148 BPM narrative arc',
    ],
    'Melodic House': ['airy pluck lead', 'warm filtered bass', 'emotional riser'],
    'Techno': ['hypnotic 4/4 drive', 'filtered low-end builds', 'warehouse space'],
    'Hard Techno': ['punishing kick', 'distorted stab screeches', 'relentless momentum'],
    'Melodic Techno': ['analog lead hooks', 'rolling sub groove', 'acid 303 squelch'],
    'Trance': ['euphoric supersaw', 'long tension build', 'anthemic breakdown'],
    'Uplifting Trance': ['trance arp lead', 'massive white-noise riser', 'emotional major key lift'],
    'Dubstep': ['grimey wobble bass', 'half-time snare crack', 'dark sub drop'],
    'Hardstyle': [
      'distorted reverse-bass kick',
      'Euro-dance supersaw hook',
      'hyper snare roll build',
      'pitch-shifted vocal chop',
    ],
    'Rawstyle': ['raw distorted kick', 'dark screech lead', 'industrial mid-bass'],
    'Future Bass': ['vocal chop lead', 'bright supersaw pluck', 'glitchy hats'],
    'Drum & Bass': ['fast breakbeat chop', 'reese bass growl', 'high-energy rush'],
    'Nu-Disco': ['LinnDrum groove', 'Juno-106 bass', 'string machine stabs'],
    'Vinahouse': [
      'offbeat bounce groove',
      'pentatonic đàn tranh hook',
      'traditional sample layer',
    ],
    'Amapiano': ['log drum bounce', 'piano stabs', 'shaker & perc layers'],
    'Amapiano-Vinahouse': ['log-drum sub pocket', 'đàn tranh motif', 'breathy SM7B vocal'],
    'Afro House': ['shaker-driven groove', 'soulful chant vocal', 'warm log-drum pocket'],
    'UK Garage': ['shuffled 2-step groove', 'chopped vocal stab', 'sub wobble bass'],
    'Jersey Club': ['bed squeak sample', 'hard kick pattern', 'chopped vocal'],
    'Gqom': ['minimal punchy kick', 'tribal percussion', 'warehouse sub'],
    'Chillhop': ['SP-1200 swung pocket', 'Rhodes tape sat', 'vinyl crackle bed'],
    'Dream Pop': ['shimmer reverb wash', 'breathy intimate vocal', 'ribbon guitar stereo'],
    'Indie Folk': ['KM184 + ribbon acoustic', 'brushed kit room', 'dry intimate vocal'],
    'Synthwave': ['gated LinnDrum snare', 'Prophet 5 lead', '80s neon pad'],
    'Trap Soul': ['breathy C-800G vocal', 'deep 808 half-time', 'sparse Rhodes pad'],
    'Dembow': ['dembow kick grid', '808 sub pocket', 'rim & clap layers'],
    'R&B': ['stacked harmonies', 'tape-warm keys', 'intimate dry vocal'],
    'Neo-Soul': ['warm Rhodes extensions', 'fingerstyle bass glide', 'behind-the-beat pocket'],
    'Quiet Storm': ['long plate reverb', 'fretless bass glide', 'late-night Rhodes'],
    'Pop / Max Martin': [
      'melodic symmetry A-A-B-A',
      'percussive verse · legato chorus vowels',
      '≤8s ear-candy motion',
    ],
    'Pop': [
      'radio-sized hook',
      'verse–pre–chorus lift polish',
      'wide but controlled low-end',
    ],
    'Hyperpop': ['bit-crushed vocal', 'glitchy 808 chops', 'chaotic detuned leads'],
    'K-Pop': ['group vocal stacks', 'dramatic pre-chorus', 'EDM-pop chorus lift'],
    'J-Pop': ['bright mix lift', 'hooky syllable rhythm', 'band-forward chorus'],
    'Mandopop': ['piano ballad foundation', 'Mandarin melodic phrasing', 'emotional chorus lift'],
    'City Pop': ['DX7 e-piano', 'Juno-106 pad', '80s Tokyo funk guitar'],
    'Country': ['acoustic strum pocket', 'twang-forward leads', 'story-first vocal tone'],
    'Bachata': ['requinto nylon intimacy', 'bongo + güira pocket', 'romantic U87 vocal'],
    'Reggaeton': ['dembow 808 pattern', 'congas + timbales', 'bright pluck synth'],
    'Folk': ['fingerpicked intimacy', 'dry room acoustic', 'lyric-led phrasing'],
    'Praise/Worship': ['SATB choir swell', 'ambient guitar wash', 'verse-to-chorus dynamic build'],
    'Worship Ballad': ['intimate U87 vocal', 'fingerpicked acoustic', 'prayerful dynamics'],
    'Afro-Gospel': ['call-and-response choir', 'kora motif', 'log drum 808 hybrid'],
    'Shoegaze': ['reverb-drenched guitars', 'breathy vocal wash', 'room-mic drums'],
    'Blues': ['smoky room character', 'vintage Fender amp SM57', 'raw U47 vocal'],
    'Ambient': ['granular textures', 'long convolution reverb', 'modular pads'],
    'default': ['your project codename', 'era + region vibe', 'target mix: warm / bright'],
  };

  static const Map<String, List<String>> optionalArtistNameChipsByGenre = {
    'Trap': ['Metro Boomin', 'Future', '21 Savage'],
    'Techno': ['Adam Beyer', 'Charlotte de Witte', 'Richie Hawtin'],
    'Melodic Techno': ['Stephan Bodzin', 'Tale Of Us', 'Maceo Plex'],
    'Amapiano': ['Kabza De Small', 'DJ Maphorisa', 'Focalistic'],
    'Afrobeats': ['Burna Boy', 'Wizkid', 'Davido'],
    'R&B': ['Frank Ocean', 'SZA', 'Daniel Caesar'],
    'K-Pop': ['BTS', 'BLACKPINK', 'NewJeans'],
    'Mandopop': ['Jay Chou', 'JJ Lin', 'G.E.M.'],
    'Vinahouse': ['Hoaprox', 'Masew', 'DJ Trang Moon'],
    'Praise/Worship': ['Hillsong Worship', 'Bethel Music', 'Elevation Worship'],
    'Bachata': ['Romeo Santos', 'Prince Royce', 'Aventura'],
    'default': ['Artist A', 'Artist B'],
  };

  /// Category-level default melody directive when no sub-genre override exists.
  static const Map<String, String> defaultMelodyDirectiveByCategory = {
    'EDM': 'hook_led',
    'Hip Hop': 'syncopated_rhythmic',
    'R&B/Soul': 'syncopated_rhythmic',
    'Pop': 'hook_led',
    'Rock/Metal': 'hook_led',
    'Country': 'hook_led',
    'Gospel': 'anthemic_soaring',
    'Jazz/Blues': 'blues_inflected',
    'Latin': 'syncopated_rhythmic',
    'Reggae/Dub': 'syncopated_rhythmic',
    'Afro/World': 'hook_led',
    'Cinematic': 'minimal_spatial',
  };

  /// Sub-genre overrides — longest match wins (same algorithm as BPM hints).
  static const Map<String, String> defaultMelodyDirectiveByGenre = {
    'Amapiano': 'hook_led',
    'Trance': 'anthemic_soaring',
    'Uplifting Trance': 'anthemic_soaring',
    'Progressive House': 'hook_led',
    'Big Room': 'anthemic_soaring',
    'Melodic Techno': 'arpeggiated_sequence',
    'Synthwave': 'arpeggiated_sequence',
    'Future Bass': 'arpeggiated_sequence',
    'Lo-Fi Hip Hop': 'minimal_spatial',
    'Chillhop': 'minimal_spatial',
    'Quiet Storm': 'minimal_spatial',
    'Folk': 'conversational_spoken',
    'Indie Folk': 'conversational_spoken',
    'Folk-Rock': 'conversational_spoken',
    'Film Score': 'chromatic_dissonant',
    'Orchestral': 'minimal_spatial',
    'Praise/Worship': 'anthemic_soaring',
    'Gospel': 'anthemic_soaring',
    'Blues': 'blues_inflected',
    'Jazz': 'syncopated_rhythmic',
    'Trap': 'syncopated_rhythmic',
    'Drill': 'syncopated_rhythmic',
    'Metal': 'hook_led',
    'Hard Rock': 'anthemic_soaring',
  };

  static const String defaultMelodyDirectiveId = 'hook_led';

  // ─────────────────────────────────────────────────────────────────────────────
  // CACHED LOOKUP INDEXES
  // ─────────────────────────────────────────────────────────────────────────────

  static final List<String> _melodyDirectiveKeysLongestFirst =
      _sortedKeysLongestFirst(defaultMelodyDirectiveByGenre.keys);

  static final Map<String, String> _subGenreToCategory = _buildSubGenreIndex();

  static final List<String> _bpmKeysLongestFirst =
      _sortedKeysLongestFirst(bpmHintByGenre.keys);

  static final List<MapEntry<String, List<String>>> _sonicEntriesLongestFirst =
      _sortedMapEntriesLongestFirst(suggestedSonicReferenceChips);

  static final List<MapEntry<String, List<String>>> _artistEntriesLongestFirst =
      _sortedMapEntriesLongestFirst(optionalArtistNameChipsByGenre);

  static Map<String, String> _buildSubGenreIndex() {
    final out = <String, String>{};
    for (final entry in subGenresByCategory.entries) {
      for (final sub in entry.value) {
        out.putIfAbsent(sub, () => entry.key);
      }
    }
    return out;
  }

  static List<String> _sortedKeysLongestFirst(Iterable<String> keys) {
    final out = keys.toList()
      ..sort((a, b) => b.length.compareTo(a.length));
    return out;
  }

  static List<MapEntry<String, List<String>>> _sortedMapEntriesLongestFirst(
    Map<String, List<String>> map,
  ) {
    final out = map.entries.where((e) => e.key != 'default').toList()
      ..sort((a, b) => b.key.length.compareTo(a.key.length));
    return out;
  }

  static bool _validateIntegrity() {
    if (!subGenresByCategory.keys.toSet().containsAll(categories)) return false;
    if (subGenresByCategory.length != categories.length) return false;
    for (final list in subGenresByCategory.values) {
      if (list.isEmpty) return false;
    }
    final seen = <String>{};
    for (final list in subGenresByCategory.values) {
      for (final sub in list) {
        if (!seen.add(sub)) return false;
      }
    }
    if (!remixTargetGenres.contains(remixTargetDefault)) return false;
    return true;
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // PUBLIC API
  // ─────────────────────────────────────────────────────────────────────────────

  static String? bpmHintForLabel(String? label) {
    assert(validateIntegrity(), 'GenreData integrity check failed — see console.');
    if (label == null || label.isEmpty) return null;
    final direct = bpmHintByGenre[label];
    if (direct != null) return direct;
    final lower = label.toLowerCase();
    for (final key in _bpmKeysLongestFirst) {
      final keyLower = key.toLowerCase();
      if (lower == keyLower || lower.contains(keyLower)) {
        return bpmHintByGenre[key];
      }
    }
    return null;
  }

  /// Resolves the default [MelodyDirective] id for auto mode from a genre label.
  static String defaultMelodyDirectiveIdForLabel(String? label) {
    if (label == null || label.trim().isEmpty) return defaultMelodyDirectiveId;

    final trimmed = label.trim();
    final direct = defaultMelodyDirectiveByGenre[trimmed];
    if (direct != null) return direct;

    final lower = trimmed.toLowerCase();
    for (final key in _melodyDirectiveKeysLongestFirst) {
      final keyLower = key.toLowerCase();
      if (lower == keyLower || lower.contains(keyLower)) {
        return defaultMelodyDirectiveByGenre[key]!;
      }
    }

    final category = categoryForSubGenre(trimmed);
    if (category != null) {
      return defaultMelodyDirectiveByCategory[category] ?? defaultMelodyDirectiveId;
    }

    return defaultMelodyDirectiveId;
  }

  /// Genre metadata for melody auto-mode and related UI.
  static GenreMelodyInfo infoForLabel(String? label) {
    final resolved = label?.trim() ?? '';
    return GenreMelodyInfo(
      label: resolved,
      bpmHint: bpmHintForLabel(label),
      defaultMelodyDirectiveId: defaultMelodyDirectiveIdForLabel(label),
    );
  }

  static String? categoryForSubGenre(String? subGenre) {
    if (subGenre == null || subGenre.isEmpty) return null;
    return _subGenreToCategory[subGenre];
  }

  static List<String> sonicReferenceChipsForGenre(String? genre) {
    if (genre == null) return suggestedSonicReferenceChips['default']!;
    final lower = genre.toLowerCase();
    for (final entry in _sonicEntriesLongestFirst) {
      if (lower.contains(entry.key.toLowerCase())) return entry.value;
    }
    return suggestedSonicReferenceChips['default']!;
  }

  static List<String> optionalArtistNameChipsForGenre(String? genre) {
    if (genre == null) return optionalArtistNameChipsByGenre['default']!;
    final lower = genre.toLowerCase();
    for (final entry in _artistEntriesLongestFirst) {
      if (lower.contains(entry.key.toLowerCase())) return entry.value;
    }
    return optionalArtistNameChipsByGenre['default']!;
  }
}
