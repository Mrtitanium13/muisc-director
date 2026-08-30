/// Dimensions that contribute to a lyric's “concrete / humanized” score.
enum MeaningfulnessDimension {
  sensory('sensory imagery (≥3 senses)'),
  properNoun('proper noun / named person or place'),
  specificNumber('specific number'),
  dialogue('dialogue or quoted speech'),
  throughline('narrative through-line (enforced at generation)');

  final String label;
  const MeaningfulnessDimension(this.label);
}

/// Post-polish meaningfulness scoring for humanized lyric QA.
///
/// Returns a 0.0–1.0 score across 5 dimensions. The default threshold is
/// 0.6 (≥3 of 5 dimensions passing).
class MeaningfulnessCheck {
  MeaningfulnessCheck({
    this.minSenseCategories = 3,
    this.threshold = MeaningfulnessCheck.defaultThreshold,
  });

  final int minSenseCategories;
  final double threshold;

  static const double defaultThreshold = 0.6;

  // ---------------------------------------------------------------------------
  // Sense lexicons
  // ---------------------------------------------------------------------------

  static const List<String> _smells = [
    'smell',
    'scent',
    'fragrance',
    'perfume',
    'aroma',
    'odor',
    'smoke',
    'rain',
    'petrichor',
    'incense',
  ];
  static const List<String> _sounds = [
    'hum',
    'echo',
    'ring',
    'whisper',
    'crack',
    'boom',
    'click',
    'snap',
    'buzz',
    'hiss',
    'roar',
    'murmur',
  ];
  static const List<String> _touch = [
    'warm',
    'cold',
    'rough',
    'soft',
    'sticky',
    'grit',
    'sweat',
    'smooth',
    'sharp',
    'damp',
    'dry',
    'numb',
  ];
  static const List<String> _taste = [
    'salt',
    'sweet',
    'bitter',
    'sour',
    'sip',
    'taste',
    'spice',
    'honey',
    'lime',
    'copper',
    'metal',
  ];
  static const List<String> _sight = [
    'glow',
    'fade',
    'shadow',
    'light',
    'dark',
    'blink',
    'flicker',
    'blur',
    'gleam',
    'flash',
    'dim',
  ];

  static const List<List<String>> _senses = [
    _smells,
    _sounds,
    _touch,
    _taste,
    _sight,
  ];

  // ---------------------------------------------------------------------------
  // Proper-noun / place / person hints
  // ---------------------------------------------------------------------------

  static const List<String> _places = [
    'oakland',
    'busan',
    'lagos',
    'brooklyn',
    'tokyo',
    'paris',
    'nairobi',
    'kingston',
    'medellin',
    'seoul',
    'accra',
    'cairo',
    'mumbai',
    'texas',
    'johannesburg',
    'manhattan',
    'soho',
    'harlem',
    'oak cliff',
    'memphis',
    'nashville',
    'detroit',
    'berlin',
    'havana',
    'sao paulo',
    'rio',
    'kinshasa',
    'laguna',
    'bronx',
  ];

  static const List<String> _names = [
    'james',
    'maria',
    'john',
    'rose',
    'lucia',
    'marco',
    'amina',
    'diego',
    'yuki',
    'kai',
    'nala',
    'jun',
    'sasha',
    'mateo',
  ];

  static const List<String> _familyTags = [
    'mama said',
    'mama told',
    'daddy said',
    'daddy told',
    'papa said',
    'mama says',
    'daddy says',
  ];

  /// Known recycled "concrete" kits the model learned from prompt examples.
  /// Hitting any of these is a QA failure even if checklist dimensions pass.
  static const List<String> stockPhrasePatterns = [
    'cold tile',
    'on cold tile',
    'tile in lagos',
    'cold tile in lagos',
    '3 am on cold',
    'at 3 am on',
    'bleach on my hands',
    'scrubbing the floor',
    'scrubbing floors',
    'bent receipt',
    'receipt lay curled',
    'by the kettle',
    'count grace before receipts',
    'kept my score till i could not count',
    'song in my chest',
    'rhythm in my chest',
    'breath fills my lungs',
    'fills my lungs',
    'borrowed and holy',
  ];

  // ---------------------------------------------------------------------------
  // Precompiled regexes
  // ---------------------------------------------------------------------------

  static final RegExp _wordBoundaryNumber = RegExp(r'\b\d{1,2}\b');

  static final RegExp _numberWords = RegExp(
    r'\b(?:one|two|three|four|five|six|seven|eight|nine|ten|'
    r'eleven|twelve|thirteen|fourteen|fifteen|sixteen|'
    r'seventeen|eighteen|nineteen|twenty|thirty|forty|'
    r'fifty|hundred|thousand)\b',
    caseSensitive: false,
  );

  static final RegExp _dialogueTag = RegExp(
    r'\b(?:she said|he said|they said|we said|i said|'
    r'she told|he told|they told|we told|i told|'
    r'mama said|daddy said|papa said)\b',
    caseSensitive: false,
  );

  /// Paired double quotes with text inside — ignores apostrophe contractions.
  static final RegExp _quotedSpeech = RegExp(r'"[^"]{2,80}"');

  static final RegExp _properNounPattern = RegExp(
    '\\b(?:${[..._places, ..._names].map(RegExp.escape).join('|')})\\b',
    caseSensitive: false,
  );

  static final RegExp _familyTagPattern = RegExp(
    '\\b(?:${_familyTags.map(RegExp.escape).join('|')})\\b',
    caseSensitive: false,
  );

  /// One precompiled pattern per sense category (longest tokens first).
  static final List<RegExp> _sensePatterns = [
    for (final category in _senses)
      RegExp(
        '(?:^|[^a-z0-9])(?:${_sortedEscaped(category).join('|')})(?:[^a-z0-9]|\$)',
        caseSensitive: false,
      ),
  ];

  static List<String> _sortedEscaped(List<String> words) {
    final sorted = [...words]..sort((a, b) => b.length.compareTo(a.length));
    return sorted.map(RegExp.escape).toList(growable: false);
  }

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Returns the number of distinct sense categories (0–5) with at least one
  /// word-boundary hit.
  int sensoryCount(String lyrics) {
    final lower = lyrics.toLowerCase();
    var hits = 0;
    for (final pattern in _sensePatterns) {
      if (pattern.hasMatch(lower)) hits++;
    }
    return hits;
  }

  bool hasProperNoun(String lyrics) {
    final lower = lyrics.toLowerCase();
    if (_properNounPattern.hasMatch(lower)) return true;
    if (_familyTagPattern.hasMatch(lower)) return true;
    return false;
  }

  bool hasSpecificNumber(String lyrics) {
    if (_wordBoundaryNumber.hasMatch(lyrics)) return true;
    return _numberWords.hasMatch(lyrics);
  }

  /// True if lyrics contain explicit dialogue tags or paired quoted speech.
  /// Does NOT trigger on apostrophes in contractions like "don't" or "I'm".
  bool hasDialogue(String lyrics) {
    if (_dialogueTag.hasMatch(lyrics)) return true;
    if (_quotedSpeech.hasMatch(lyrics)) return true;
    return false;
  }

  /// Stock "concrete" kits that pass checklist bingo but read as nonsense.
  List<String> stockPhraseHits(String lyrics) {
    final lower = lyrics.toLowerCase();
    return [
      for (final p in stockPhrasePatterns)
        if (lower.contains(p)) p,
    ];
  }

  bool hasStockPhrases(String lyrics) => stockPhraseHits(lyrics).isNotEmpty;

  /// Score 0.0–1.0 across 5 dimensions; default threshold is 0.6 (≥3 of 5).
  ///
  /// The fifth dimension (through-line) is awarded automatically because the
  /// generation prompt enforces a narrative through-line.
  /// Stock-phrase kits zero the score — checklist bingo is not meaningfulness.
  double score(String lyrics) {
    if (hasStockPhrases(lyrics)) return 0.0;
    final details = scoreDetails(lyrics);
    var pass = 0;
    for (final dim in MeaningfulnessDimension.values) {
      if (details[dim] == true) pass++;
    }
    return pass / MeaningfulnessDimension.values.length;
  }

  /// Per-dimension breakdown. Useful for logging / retry prompts.
  Map<MeaningfulnessDimension, bool> scoreDetails(String lyrics) {
    return {
      MeaningfulnessDimension.sensory:
          sensoryCount(lyrics) >= minSenseCategories,
      MeaningfulnessDimension.properNoun: hasProperNoun(lyrics),
      MeaningfulnessDimension.specificNumber: hasSpecificNumber(lyrics),
      MeaningfulnessDimension.dialogue: hasDialogue(lyrics),
      // Assumed enforced by generation prompt (kHumanVoiceDirective).
      MeaningfulnessDimension.throughline: true,
    };
  }

  bool isMeaningful(String lyrics) => score(lyrics) >= threshold;
}
