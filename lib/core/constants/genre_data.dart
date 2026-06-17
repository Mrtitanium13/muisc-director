/// Genre categories, sub-genres, BPM hints, and quick-pick chips.
class GenreData {
  GenreData._();

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
      'Amapiano',
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
      'Latin Pop',
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

  /// Display label -> suggested BPM range text.
  static const Map<String, String> bpmHintByGenre = {
    'Hardstyle': '150–162 BPM',
    'Rawstyle': '150–200 BPM',
    'Hard Bounce': '128–145 BPM',
    'Hard Techno': '138–152 BPM',
    'Techno': '128–135 BPM',
    'Acid Techno': '128–135 BPM',
    'EDM Bounce': '128–138 BPM',
    'Melodic Techno': '128–138 BPM',
    'Melodic House': '122–128 BPM',
    'Big Room': '128 BPM',
    'Big Room Techno': '138–148 BPM',
    'Progressive House': '124–132 BPM',
    'Soulful House': '118–124 BPM',
    'Nu-Disco': '110–120 BPM',
    'Future Funk': '110–120 BPM',
    'Disco House': '110–120 BPM',
    'Vinahouse': '128–140 BPM',
    'Amapiano': '100–116 BPM',
    'Amapiano-Vinahouse': '110–120 BPM',
    'Afro House': '118–126 BPM',
    'UK Garage': '130–135 BPM',
    'Jersey Club': '135–140 BPM',
    'Gqom': '124–128 BPM',
    'Trap Soul': '70–85 BPM half-time',
    'Dembow': '95–105 BPM',
    'Chillhop': '70–90 BPM',
    'Dream Pop': '90–100 BPM',
    'Indie Folk': '80–110 BPM',
    'Singer-Songwriter': '70–100 BPM',
    'Synthwave': '100–130 BPM',
    'Retrowave': '100–130 BPM',
    'Uplifting Trance': '138 BPM',
    'Melodic Dubstep': '140 BPM half-time',
    'Liquid DnB': '174 BPM',
    'Future House': '125–128 BPM',
    'Hip Hop': '85–115 BPM',
    'Boom Bap': '80–95 BPM',
    'Trap': '130–160 BPM half-time',
    'Melodic Trap': '130–150 BPM',
    'Drill': '138–145 BPM half-time',
    'UK Drill': '138–145 BPM',
    'NY Drill': '140–145 BPM',
    'Phonk': '130–160 BPM',
    'Afro-Swing': '100–115 BPM',
    'Lo-Fi Hip Hop': '60–90 BPM',
    'Deep House': '120–128 BPM',
    'Tech House': '124–126 BPM',
    'Future Bass': '150–160 BPM',
    'Trance': '128–145 BPM',
    'Drum & Bass': '160–175 BPM',
    'Dubstep': '140–150 BPM half-time',
    'Neo-Soul': '70–90 BPM',
    'Contemporary R&B': '80–100 BPM',
    '90s R&B': '90–105 BPM',
    'New Jack Swing': '90–105 BPM',
    'Quiet Storm': '60–80 BPM',
    'Gospel': '65–120 BPM',
    'Traditional Gospel': '80–95 BPM',
    'Praise/Worship': '65–110 BPM',
    'Modern Worship': '70–90 BPM',
    'Worship Ballad': '60–75 BPM',
    'Contemporary Gospel': '85–100 BPM',
    'Afro-Gospel': '100–118 BPM',
    'Southern Gospel': '80–110 BPM',
    'CCM': '90–120 BPM',
    'Afrobeats': '100–115 BPM',
    'Highlife': '80–120 BPM',
    'Fuji': '110–130 BPM',
    'K-Pop': '100–140 BPM',
    'C-Pop': '85–130 BPM',
    'Electropop': '110–128 BPM',
    'Dance Pop': '110–128 BPM',
    'Bedroom Pop': '80–110 BPM',
    'Hyperpop': '130–180 BPM',
    'Reggaeton': '90–100 BPM',
    'Bachata': '130–140 BPM',
    'Salsa': '180–220 BPM',
    'Bossa Nova': '120–140 BPM',
    'Cumbia': '90–130 BPM',
    'Brazilian Funk': '130–150 BPM',
    'Sertanejo': '130–150 BPM',
    'Forró': '110–130 BPM',
    'Reggae': '60–80 BPM',
    'Dancehall': '90–105 BPM',
    'Soca': '100–140 BPM',
    'Pop': '100–130 BPM',
    'Mainstream Pop': '90–120 BPM',
    'Rock': '100–160 BPM',
    'Indie Rock': '110–140 BPM',
    'Pop Punk': '150–180 BPM',
    'Metalcore': '130–200 BPM',
    'Shoegaze': '90–100 BPM',
    'Country': '80–108 BPM',
    'Modern Country': '90–130 BPM',
    'Outlaw Country': '80–110 BPM',
    'Americana': '80–120 BPM',
    'Bluegrass': '120–180 BPM',
    'Metal': '120–200 BPM',
    'Jazz': '60–200 BPM',
    'Vocal Jazz': '100–180 BPM',
    'Smooth Jazz': '90–120 BPM',
    'Nu-Jazz': '90–110 BPM',
    'Blues': '60–120 BPM',
    'Chicago Blues': '80–100 BPM',
    'Cinematic': '40–180 BPM',
    'Film Score': '60–120 BPM',
    'Ambient': '50–80 BPM free',
    'Vaporwave': '80–100 BPM',
    'Industrial': '120–150 BPM',
    'House': '120–128 BPM',
    'Funk': '95–115 BPM',
    'Soul': '70–110 BPM',
    'Latin Pop': '90–120 BPM',
    'Folk': '80–120 BPM',
    'City Pop': '100–120 BPM',
    'Bollywood': '100–160 BPM',
    'Punjabi': '110–140 BPM',
    'Bhangra': '110–140 BPM',
    'Middle Eastern': '80–130 BPM',
    'Fusion': '90–140 BPM',
    'Big Band': '120–200 BPM',
    'Orchestral': '40–120 BPM',
    'Ambient Score': '40–100 BPM',
    'Cloud Rap': '130–150 BPM',
    'Jazz Rap': '80–110 BPM',
    'Alternative': '90–150 BPM',
    'Punk': '140–200 BPM',
    'Synth Pop': '110–130 BPM',
    'New Wave': '110–130 BPM',
    'Pop / Max Martin': '100–128 BPM',
    'J-Pop': '85–135 BPM',
    'Mandopop': '85–135 BPM',
    'Dub': '60–90 BPM',
  };

  /// Quick Start row: [0] = chip label (may include emoji), [1] = canonical genre value.
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

  /// Canonical sub-genre strings for remix merge (labels stripped).
  static List<String> get quickPickGenres =>
      quickPickRows.map((e) => e.$2).toList();

  /// Default remix target when opening the Audio Analyser (must exist in [remixTargetGenres]).
  static const String remixTargetDefault = 'Techno';

  /// Target genres for remix / genre-flip: all sub-genres from [subGenresByCategory] plus
  /// [quickPickGenres] (e.g. broad **Cinematic**), deduped and A→Z.
  static List<String> get remixTargetGenres {
    final merged = <String>{};
    for (final list in subGenresByCategory.values) {
      merged.addAll(list);
    }
    merged.addAll(quickPickGenres);
    final out = merged.toList()
      ..sort(
        (a, b) => a.toLowerCase().compareTo(b.toLowerCase()),
      );
    return List<String>.unmodifiable(out);
  }

  /// Quick chips: **production / sonic** tags only — no celebrity names (many platforms flag them).
  /// Users can still type their own project codename or initials in the text field.
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
    'Trap': ['808 slides & rolls', 'dark plugg mood', 'melodic trap leads'],
    'Drill': ['sliding 808 patterns', 'tense minor pads', 'machinegun hi-hat rolls'],
    'Phonk': ['Memphis cowbell', 'distorted 808 kick', 'dark detuned saws'],
    'Afro-Swing': ['log drum + 808 hybrid', 'M1 piano stab', 'talking drum pocket'],
    'Techno': ['hypnotic 4/4 drive', 'filtered low-end builds', 'warehouse space'],
    'Melodic Techno': ['analog lead hooks', 'rolling sub groove', 'acid 303 squelch'],
    'Deep House': ['U87 soulful vocal', 'Rhodes stab + Juno pad', 'tight sidechain'],
    'Progressive House': ['supersaw euphoria', 'sidechain pumping', 'festival build'],
    'Future Bass': ['vocal chop lead', 'bright supersaw pluck', 'glitchy hats'],
    'Nu-Disco': ['LinnDrum groove', 'Juno-106 bass', 'string machine stabs'],
    'Amapiano': ['log drum bounce', 'piano stabs', 'shaker & perc layers'],
    'Amapiano-Vinahouse': ['log-drum sub pocket', 'đàn tranh motif', 'breathy SM7B vocal'],
    'Vinahouse': [
      'offbeat bounce groove',
      'pentatonic đàn tranh hook',
      'traditional sample layer',
    ],
    'Chillhop': ['SP-1200 swung pocket', 'Rhodes tape sat', 'vinyl crackle bed'],
    'Dream Pop': ['shimmer reverb wash', 'breathy intimate vocal', 'ribbon guitar stereo'],
    'Indie Folk': ['KM184 + ribbon acoustic', 'brushed kit room', 'dry intimate vocal'],
    'Synthwave': ['gated LinnDrum snare', 'Prophet 5 lead', '80s neon pad'],
    'UK Garage': ['shuffled 2-step groove', 'chopped vocal stab', 'sub wobble bass'],
    'Jersey Club': ['bed squeak sample', 'hard kick pattern', 'chopped vocal'],
    'Gqom': ['minimal punchy kick', 'tribal percussion', 'warehouse sub'],
    'Trap Soul': ['breathy C-800G vocal', 'deep 808 half-time', 'sparse Rhodes pad'],
    'Dembow': ['dembow kick grid', '808 sub pocket', 'rolling hats'],
    'R&B': ['stacked harmonies', 'tape-warm keys', 'intimate dry vocal'],
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

  /// Optional **named** reference chips (same matching rules as [sonicReferenceChipsForGenre]).
  /// Suno and other hosts may flag or block some names — use at your discretion.
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

  static String? bpmHintForLabel(String? label) {
    if (label == null || label.isEmpty) return null;
    final direct = bpmHintByGenre[label];
    if (direct != null) return direct;
    final lower = label.toLowerCase();
    for (final e in bpmHintByGenre.entries) {
      if (lower.contains(e.key.toLowerCase())) return e.value;
    }
    return null;
  }

  /// Parent category tab that contains [subGenre], or null if unknown.
  static String? categoryForSubGenre(String? subGenre) {
    if (subGenre == null || subGenre.isEmpty) return null;
    for (final e in subGenresByCategory.entries) {
      if (e.value.contains(subGenre)) return e.key;
    }
    return null;
  }

  /// Name-free tags for chips; matches longest sub-genre key contained in [genre] label.
  static List<String> sonicReferenceChipsForGenre(String? genre) {
    if (genre == null) return suggestedSonicReferenceChips['default']!;
    for (final e in suggestedSonicReferenceChips.entries) {
      if (e.key != 'default' &&
          genre.toLowerCase().contains(e.key.toLowerCase())) {
        return e.value;
      }
    }
    return suggestedSonicReferenceChips['default']!;
  }

  /// Optional artist-name chips; same key matching as [sonicReferenceChipsForGenre].
  static List<String> optionalArtistNameChipsForGenre(String? genre) {
    if (genre == null) return optionalArtistNameChipsByGenre['default']!;
    for (final e in optionalArtistNameChipsByGenre.entries) {
      if (e.key != 'default' &&
          genre.toLowerCase().contains(e.key.toLowerCase())) {
        return e.value;
      }
    }
    return optionalArtistNameChipsByGenre['default']!;
  }
}
