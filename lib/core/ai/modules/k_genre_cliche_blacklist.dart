// Per-genre cliché phrase packs (T1 full enforcement, T2 warn-then-fail).

/// Severity tier for a cliché pack.
enum ClichePackTier { tier1, tier2 }

/// A single cliché pack: canonical key, forbidden phrases, and tier.
class ClichePack {
  final String key;
  final Set<String> phrases;
  final ClichePackTier tier;

  const ClichePack(this.key, this.phrases, this.tier);
}

// -----------------------------------------------------------------------------
// Cliché packs
// -----------------------------------------------------------------------------

const Map<String, ClichePack> kClichePacks = {
  'worship_gospel': ClichePack(
    'worship_gospel',
    {
      'i acknowledge you in all my ways',
      'kitchen counter',
      'trust the path you make',
      'guide my steps',
      'fall on my knees',
      'fall on my knees and pray',
      'you are worthy',
      'worthy of praise',
      'holy holy holy',
      'open the floodgates',
      'pour out your spirit',
      'in your presence',
      'lift your name on high',
      'i surrender all',
      'all to you i surrender',
      'you are good all the time',
      'good all the time',
      'mountains move',
      'breakthrough is coming',
      'chains are breaking',
      'set a fire down in my soul',
      'spirit lead me',
      'guide my feet',
      'trust in your plan',
      'your timing is perfect',
      'blessed assurance',
      'amazing grace default',
      'how great thou art',
      '10,000 reasons',
    },
    ClichePackTier.tier1,
  ),
  'country': ClichePack(
    'country',
    {
      'dirt road',
      'gravel road',
      'back road',
      'country road',
      "mama's cooking",
      "mama's house",
      "daddy's truck",
      'old chevrolet',
      'sweet tea on the porch',
      'pickup truck',
      'lifted truck',
      'boots and jeans',
      'boots on the dashboard',
      'whiskey in a glass',
      'shot of whiskey',
      'small town',
      'hometown',
      'one-stoplight town',
      'friday night football',
      'friday nights',
      'by the river',
      'down by the creek',
      'fishing hole',
      'bonfire',
      'fire pit',
      'god flag freedom',
      'she left me for a nashville star',
      'crickets singing',
      'fireflies',
      'porch swing',
      'i grew up',
      "ain't nothing like",
      'tennessee',
      'georgia',
      'alabama',
    },
    ClichePackTier.tier1,
  ),
  'hip_hop': ClichePack(
    'hip_hop',
    {
      'started from the bottom',
      'came up from',
      'came up',
      'i made it',
      'real ones only',
      'fake friends',
      'snakes in',
      'on god',
      'no cap',
      'got the drip',
      'the opps',
      'pull up to the spot',
      'got the keys',
      'on the block',
      'trap house',
      'young and rich',
      'flexing on my ex',
      "they don't know the struggle",
      'on my mama',
      'countin my bands',
      "countin' my bands",
      'racks on racks',
      'racks on my',
      'grind never stops',
      'hustle culture',
      'sheesh',
      'skrrt',
    },
    ClichePackTier.tier1,
  ),
  'rnb_contemp': ClichePack(
    'rnb_contemp',
    {
      '2 am',
      '2am',
      'three am',
      'three am thoughts',
      'late-night text',
      'late night text',
      'sheets still warm',
      'bed still smells',
      'body on mine',
      'body like that',
      'bedroom eyes',
      "can't get you out my head",
      "got me feelin'",
      'i need you tonight',
      'baby please',
      'baby girl',
      'baby boy',
      'let me love you right',
    },
    ClichePackTier.tier1,
  ),
  'mandopop': ClichePack(
    'mandopop',
    {
      '下着雨又想起你',
      '眼泪流了下来',
      '心碎的声音',
      '忘不了你',
      '你说过的话',
      '分手的季节',
      '爱过你',
      '寂寞的夜',
      '回忆涌上心头',
      '离开我',
    },
    ClichePackTier.tier1,
  ),
  'kpop': ClichePack(
    'kpop',
    {
      'oh na na',
      'yeah yeah yeah',
      'hey hey hey',
      'come on and dance',
      'dancing in the moonlight',
      'i love you i need you',
      'one more time',
      'feel the rhythm',
      'lose control tonight',
      'we run this town',
      'party till the morning',
    },
    ClichePackTier.tier1,
  ),
  'afrobeats_pidgin': ClichePack(
    'afrobeats_pidgin',
    {
      'wahala no dey finish',
      'no shaking',
      'no wahala',
      'shey you go marry me',
      'na you be the one',
      'money dey talk',
      'chop life',
      'who dey there',
      'see the way e be',
      'i no see the reason',
      'abeg forgive me',
      'my person',
      'e no go end',
    },
    ClichePackTier.tier1,
  ),
  'reggae_dancehall': ClichePack(
    'reggae_dancehall',
    {
      'one love',
      'positive vibrations',
      'irie feeling',
      'jah bless',
      'babylon fall',
      'chill and draw',
      'bless up',
      'big up',
      'cool meditation',
    },
    ClichePackTier.tier1,
  ),
  'pop_mainstream': ClichePack(
    'pop_mainstream',
    {
      'put your hands up',
      'dance all night',
      'light up the sky',
      "nothing's gonna stop us",
      'hands in the air',
      "we're gonna be forever",
      'never let you go',
      "tonight's the night",
      'living in the moment',
      'feel the beat',
      'let the music take control',
      'we run this town',
    },
    ClichePackTier.tier2,
  ),
  'rock_alt': ClichePack(
    'rock_alt',
    {
      "i'm so tired of",
      "can't get no satisfaction",
      "i'll be your hero",
      'burning bright',
      "we're young and reckless",
      'rebel without a cause',
      'screaming in the dark',
    },
    ClichePackTier.tier2,
  ),
  'latin_pop': ClichePack(
    'latin_pop',
    {
      'mi amor',
      'mi vida',
      'corazón',
      'corazon',
      'baila conmigo',
      'ritmos de la noche',
      'fuego y llamas',
      'como te quiero',
    },
    ClichePackTier.tier2,
  ),
  'edm_vocal': ClichePack(
    'edm_vocal',
    {
      'i feel it in my soul',
      "we're going higher",
      'hands up to the sky',
      'let me feel your love tonight',
      'frequency',
      'static tension',
      'vibrations',
      'dissolving',
      'galaxies',
      'starlight',
      'seismic',
      'neon flicker',
      'infinite skies',
      'blinding light',
      'we own the night',
      'ghosts pulling near',
      'strobe light flash',
    },
    ClichePackTier.tier2,
  ),
  'hardstyle_vocal': ClichePack(
    'hardstyle_vocal',
    {
      'we own the night',
      'ghosts pulling near',
      'strobe light flash',
      'hollows out my chest cavity',
      'destroy the grid',
      'face the distortion',
      'absolute power',
      'final warning',
      'drop the hammer',
    },
    ClichePackTier.tier1,
  ),
  'big_room_fusion_vocal': ClichePack(
    'big_room_fusion_vocal',
    {
      'hands up to the sky',
      'put your hands up',
      'feel the beat',
      'when the drop hits',
      'raise your hands',
      "we're going higher",
      'let me feel your love tonight',
      'infinite skies',
      'blinding light',
      'lights go down',
      'i feel it in my soul',
      'frequency',
      'galaxies',
      'starlight',
      'neon flicker',
      'we own the night',
    },
    ClichePackTier.tier2,
  ),
};

/// T1 packs — cliché hits fail QA on first occurrence.
final Set<String> kTier1ClichePacks = {
  for (final e in kClichePacks.entries)
    if (e.value.tier == ClichePackTier.tier1) e.key,
};

/// T2 packs — warn on first hit; fail when the same genre is generated
/// twice in a session.
final Set<String> kTier2ClichePacks = {
  for (final e in kClichePacks.entries)
    if (e.value.tier == ClichePackTier.tier2) e.key,
};

/// Backwards-compatible phrase-map view (prefer [kClichePacks] / [resolveClichePack]).
Map<String, Set<String>> get kGenreClicheBlacklist => {
      for (final e in kClichePacks.entries) e.key: e.value.phrases,
    };

// -----------------------------------------------------------------------------
// Genre → pack resolution
// -----------------------------------------------------------------------------

class _GenreMapping {
  final String packKey;
  final List<String> keywords;
  final List<String>? alsoRequires;

  const _GenreMapping(
    this.packKey,
    this.keywords, {
    this.alsoRequires,
  });
}

/// Resolution is longest-keyword-match (see [clichePackKeyFor]); list order
/// only breaks ties between keywords of equal length.
final List<_GenreMapping> _genreMappings = [
  _GenreMapping('worship_gospel', _normAll(['gospel', 'worship', 'ccm', 'praise', 'hymn'])),
  _GenreMapping(
    'country',
    _normAll(['country', 'americana', 'bluegrass', 'folk rock', 'indie folk']),
  ),
  _GenreMapping(
    'hip_hop',
    _normAll([
      'hip hop',
      'boom bap',
      'trap',
      'drill',
      'phonk',
      'afro-swing',
      'afro rap',
      'lo-fi hip hop',
      'chillhop',
      'cloud rap',
      'jazz rap',
    ]),
  ),
  _GenreMapping(
    'rnb_contemp',
    _normAll(['r&b', 'rnb', 'neo-soul', 'soul', 'trap soul', 'quiet storm']),
  ),
  _GenreMapping('mandopop', _normAll(['mandopop', 'c-pop', 'cantopop'])),
  // Include bare kpop/jpop so "Kpop" resolves here, not via a false "pop" hit.
  _GenreMapping('kpop', _normAll(['k-pop', 'kpop', 'j-pop', 'jpop'])),
  _GenreMapping('afrobeats_pidgin', _normAll(['afrobeats', 'highlife', 'fuji'])),
  _GenreMapping('reggae_dancehall', _normAll(['reggae', 'dancehall', 'dub'])),
  _GenreMapping(
    'pop_mainstream',
    _normAll([
      'pop',
      'electropop',
      'dance pop',
      'indie pop',
      'synth pop',
      'hyperpop',
      'bedroom pop',
      'mainstream pop',
    ]),
  ),
  _GenreMapping(
    'rock_alt',
    _normAll(['rock', 'alt', 'indie', 'punk', 'emo', 'metal']),
  ),
  _GenreMapping(
    'latin_pop',
    _normAll([
      'latin pop',
      'reggaeton',
      'bachata',
      'salsa',
      'cumbia',
      'vallenato',
      'sertanejo',
      'forró',
      'forro',
    ]),
  ),
  // Same two-group guard as before: progressive/big-room lane AND festival/big room.
  _GenreMapping(
    'big_room_fusion_vocal',
    _normAll(['big room fusion', 'big room house', 'progressive house']),
    alsoRequires: _normAll(['big room', 'festival anthem']),
  ),
  _GenreMapping(
    'hardstyle_vocal',
    _normAll([
      'hardstyle',
      'rawstyle',
      'euphoric hardstyle',
      'hard bounce',
      'edm bounce',
    ]),
  ),
  _GenreMapping(
    'edm_vocal',
    _normAll([
      'edm',
      'house',
      'techno',
      'trance',
      'dubstep',
      'future bass',
      'amapiano',
      'gqom',
      'uk garage',
      'ukg',
      'afrohouse',
    ]),
  ),
];

List<String> _normAll(List<String> keywords) =>
    keywords.map(normalizeClicheGenre).toList(growable: false);

/// Returns the cliché pack key for [genre], or `null` if no pack applies.
///
/// Canonical pack keys resolve directly; otherwise the most specific
/// (longest) matching keyword wins so e.g. "latin pop" resolves to the
/// latin_pop pack rather than the broader pop match.
String? clichePackKeyFor(String genre) {
  final g = normalizeClicheGenre(genre);
  for (final entry in kClichePacks.entries) {
    if (g == normalizeClicheGenre(entry.key)) return entry.key;
  }

  String? bestKey;
  var bestLength = -1;
  for (final mapping in _genreMappings) {
    if (mapping.alsoRequires != null &&
        !_containsAny(g, mapping.alsoRequires!)) {
      continue;
    }
    for (final keyword in mapping.keywords) {
      if (!_hasPhrase(g, keyword)) continue;
      if (keyword.length <= bestLength) continue;
      bestLength = keyword.length;
      bestKey = mapping.packKey;
    }
  }
  return bestKey;
}

/// Returns the phrase set for [genre], or `null` if no pack applies.
Set<String>? clichePackFor(String genre) => resolveClichePack(genre)?.phrases;

/// Returns the fully resolved pack (phrases + tier) for [genre].
ClichePack? resolveClichePack(String genre) {
  final key = clichePackKeyFor(genre);
  if (key == null) return null;
  return kClichePacks[key];
}

// -----------------------------------------------------------------------------
// Helpers
// -----------------------------------------------------------------------------

/// Public so QA / tests share the same folding rules.
String normalizeClicheGenre(String genre) {
  var s = genre.toLowerCase();
  for (var i = 0; i < 3; i++) {
    final next = s.replaceAll('&amp;', '&');
    if (next == s) break;
    s = next;
  }
  s = _stripDiacritics(s);
  return s
      .replaceAll(RegExp(r'[^\w\s&]+'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

String _stripDiacritics(String input) {
  const map = {
    'à': 'a', 'á': 'a', 'â': 'a', 'ã': 'a', 'ä': 'a', 'å': 'a',
    'è': 'e', 'é': 'e', 'ê': 'e', 'ë': 'e',
    'ì': 'i', 'í': 'i', 'î': 'i', 'ï': 'i',
    'ò': 'o', 'ó': 'o', 'ô': 'o', 'õ': 'o', 'ö': 'o',
    'ù': 'u', 'ú': 'u', 'û': 'u', 'ü': 'u',
    'ý': 'y', 'ÿ': 'y',
    'ç': 'c', 'ñ': 'n',
  };
  final buf = StringBuffer();
  for (final unit in input.runes) {
    final ch = String.fromCharCode(unit);
    buf.write(map[ch] ?? ch);
  }
  return buf.toString();
}

bool _containsAny(String blob, List<String> needles) =>
    needles.any((n) => _hasPhrase(blob, n));

/// Whole-phrase match — "pop" will not match inside "kpop".
bool _hasPhrase(String blob, String phrase) {
  if (phrase.isEmpty) return false;
  final escaped = RegExp.escape(phrase);
  return RegExp('(?:^|[^a-zA-Z0-9&])$escaped(?:[^a-zA-Z0-9&]|\$)')
      .hasMatch(blob);
}
