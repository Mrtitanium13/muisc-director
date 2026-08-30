// Engine configuration — v7. All tunable values live here.

enum PromptMode { tagList, naturalLanguage }

class ModelProfile {
  final int tokenBudgetMax;
  final int tokenBudgetMin;
  final int maxSafeDurationSec;
  final int maxSongDurationSec;
  final int maxStyleChars;
  final PromptMode promptMode;
  final List<String> versionNotes;

  const ModelProfile({
    required this.tokenBudgetMax,
    required this.tokenBudgetMin,
    required this.maxSafeDurationSec,
    required this.maxSongDurationSec,
    required this.maxStyleChars,
    required this.promptMode,
    this.versionNotes = const [],
  });
}

class TempoDef {
  final String label;
  final List<String> tokens;
  final List<String> compatibleGenres;
  final int syllableCap;
  final double durationMultiplier;
  const TempoDef({
    required this.label,
    required this.tokens,
    required this.compatibleGenres,
    required this.syllableCap,
    required this.durationMultiplier,
  });
}

class GenreDef {
  final String label;
  final List<String> tokens;
  const GenreDef({required this.label, required this.tokens});
}

class VocalDef {
  final String label;
  final List<String> tokens;
  final bool usePlatformToggle;
  final int? syllableCapOverride;
  const VocalDef({
    required this.label,
    required this.tokens,
    this.usePlatformToggle = false,
    this.syllableCapOverride,
  });
}

class FixItEntry {
  final String symptom;
  final String tool;
  final String guidance;
  const FixItEntry({required this.symptom, required this.tool, required this.guidance});
}

class SimplificationStep {
  final int step;
  final String action;
  final String message;
  const SimplificationStep({required this.step, required this.action, required this.message});
}

class EngineConfig {
  static const String version = '7.0.0';

  static const Map<String, ModelProfile> modelProfiles = {
    'suno_v3.5': ModelProfile(
      tokenBudgetMax: 8,
      tokenBudgetMin: 5,
      maxSafeDurationSec: 150,
      maxSongDurationSec: 240,
      maxStyleChars: 120,
      promptMode: PromptMode.tagList,
      versionNotes: ['Short tag prompts only. Very artifact-prone past 2:30.'],
    ),
    'suno_v4': ModelProfile(
      tokenBudgetMax: 12,
      tokenBudgetMin: 8,
      maxSafeDurationSec: 210,
      maxSongDurationSec: 240,
      maxStyleChars: 200,
      promptMode: PromptMode.tagList,
      versionNotes: ['Remaster available. Tag lists work well.'],
    ),
    'suno_v4.5': ModelProfile(
      tokenBudgetMax: 12,
      tokenBudgetMin: 8,
      maxSafeDurationSec: 300,
      maxSongDurationSec: 480,
      maxStyleChars: 1000,
      promptMode: PromptMode.tagList,
      versionNotes: [
        'Expanded 1000-char style box. Better genre fusion handling.',
        'Long songs possible but still degrade — use Extend past 5:00.',
      ],
    ),
    'suno_v5': ModelProfile(
      tokenBudgetMax: 14,
      tokenBudgetMin: 8,
      maxSafeDurationSec: 300,
      maxSongDurationSec: 480,
      maxStyleChars: 1000,
      promptMode: PromptMode.naturalLanguage,
      versionNotes: [
        'Responds better to descriptive sentences than comma tag lists.',
        'Cleaner vocals by default — over-stacking fidelity tags causes sterile "AI sheen".',
        'Fidelity boilerplate largely unnecessary; genre + mood + production intent is enough.',
      ],
    ),
    'suno_v5.5_pro': ModelProfile(
      tokenBudgetMax: 16,
      tokenBudgetMin: 8,
      maxSafeDurationSec: 360,
      maxSongDurationSec: 480,
      maxStyleChars: 1000,
      promptMode: PromptMode.naturalLanguage,
      versionNotes: [
        'ASSUMED profile — verify limits against actual platform behavior.',
        'Treat like v5: natural language prompts, minimal fidelity boilerplate.',
      ],
    ),
  };

  static const List<String> assemblyOrder = [
    'genre', 'fidelity', 'tempo', 'vocal', 'mood', 'custom',
  ];
  static const List<String> priorityOnOverflow = [
    'genre', 'vocal', 'tempo', 'fidelity', 'custom', 'mood',
  ];
  static const List<String> dedupeStems = [
    'crisp', 'clean', 'pristine', 'clear', 'transparent', 'punchy', 'tight', 'defined',
  ];
  static const List<String> fidelityTags = ['studio quality', 'clean mix'];

  static const Map<String, String> replacementMap = {
    'lo-fi': 'warm analog character',
    'lofi': 'warm analog character',
    'lo fi': 'warm analog character',
    'vinyl crackle': 'subtle analog warmth',
    'tape hiss': 'analog saturation',
    'heavy reverb': 'short plate reverb',
    'echoey': 'controlled ambience',
    'cavernous': 'spacious but defined',
    'muddy': 'warm low-mids',
    'wall of sound': 'dense layered arrangement, clear separation',
    'maximalist': 'richly layered, defined mix',
    'bitcrushed': 'textured digital edge',
    'raw': 'unpolished character, clean capture',
    'distorted vocals': 'saturated vocals, intelligible',
  };
  static const List<String> whitelistPhrases = [
    'garage rock', 'uk garage', 'future garage', 'raw emotion',
  ];
  static const List<String> hardBanned = [
    'low quality', 'demo tape', 'bad recording', 'clipping', 'blown out',
  ];

  static const Map<String, TempoDef> tempoEnergy = {
    'slow': TempoDef(
      label: 'Slow / Ballad',
      tokens: ['70 BPM', 'relaxed pace'],
      compatibleGenres: ['all'],
      syllableCap: 8,
      durationMultiplier: 1.15,
    ),
    'mid': TempoDef(
      label: 'Mid-Tempo',
      tokens: ['105 BPM', 'steady groove'],
      compatibleGenres: ['all'],
      syllableCap: 10,
      durationMultiplier: 1.0,
    ),
    'upbeat': TempoDef(
      label: 'Upbeat',
      tokens: ['128 BPM', 'high energy'],
      compatibleGenres: ['electronic', 'hiphop_pop', 'rock_metal'],
      syllableCap: 12,
      durationMultiplier: 0.9,
    ),
    'intense': TempoDef(
      label: 'Intense',
      tokens: ['150 BPM', 'relentless drive'],
      compatibleGenres: ['rock_metal', 'electronic'],
      syllableCap: 12,
      durationMultiplier: 0.85,
    ),
  };

  static const Map<String, GenreDef> genreFamilies = {
    'electronic': GenreDef(
      label: 'Electronic / Dance / Synthwave',
      tokens: ['electronic', 'tight sub-bass', 'clean digital synths', 'punchy drum programming'],
    ),
    'rock_metal': GenreDef(
      label: 'Rock / Metal / Alternative',
      tokens: ['rock', 'punchy drums', 'articulate guitars', 'tight rhythm section'],
    ),
    'hiphop_pop': GenreDef(
      label: 'Pop / Hip-Hop / R&B',
      tokens: ['pop', 'polished vocal production', 'controlled 808', 'balanced dynamics'],
    ),
    'acoustic_orchestral': GenreDef(
      label: 'Acoustic / Folk / Orchestral',
      tokens: ['acoustic', 'close mic recording', 'natural room tone', 'defined instrumentation'],
    ),
  };

  static const Map<String, VocalDef> vocalProfiles = {
    'female': VocalDef(label: 'Female Lead', tokens: ['clear female lead vocals', 'upfront in the mix']),
    'male': VocalDef(label: 'Male Lead', tokens: ['smooth male lead vocals', 'present and defined']),
    'duet': VocalDef(label: 'Duet', tokens: ['male and female duet', 'distinct vocal separation']),
    'whisper': VocalDef(label: 'Intimate', tokens: ['intimate close-mic vocals', 'breathy but intelligible']),
    'rap': VocalDef(label: 'Rap', tokens: ['articulate rhythmic delivery', 'vocals upfront'], syllableCapOverride: 16),
    'choir': VocalDef(label: 'Choir / Layers', tokens: ['layered vocal harmonies', 'each voice defined']),
    'instrumental': VocalDef(label: 'Instrumental', tokens: [], usePlatformToggle: true),
  };

  static const List<String> moodOptions = [
    'melancholic', 'euphoric', 'tense', 'warm', 'triumphant', 'nocturnal',
  ];

  static const int maxGenreTokens = 2;
  static const Map<String, int> syllableCapBonus = {
    'suno_v5': 2,
    'suno_v5.5_pro': 2,
  };
  static const Map<String, int> maxGenresByModel = {
    'suno_v3.5': 2,
    'suno_v4': 2,
    'suno_v4.5': 2,
    'suno_v5': 3,
    'suno_v5.5_pro': 3,
  };
  static const List<String> humanizingTokens = [
    'natural performance',
    'live drum feel',
    'slight vocal grit',
    'organic dynamics',
    'played not programmed',
  ];
  static const String v5SheenTip =
      'v5 models over-polish by default. Add ONE humanizing token to avoid the sterile AI sheen.';
  static const List<List<String>> riskyPairs = [
    ['acoustic_orchestral', 'rock_metal'],
    ['acoustic_orchestral', 'electronic'],
  ];
  static const String riskyFusionWarning =
      "This fusion increases artifact risk. Make one genre dominant, e.g. "
      "'cinematic metal with orchestral elements' instead of two competing genre nouns.";

  static const List<String> excludeUniversal = ['lo-fi', 'muffled', 'noisy', 'distorted master'];
  static const Map<String, List<String>> excludePerGenre = {
    'electronic': ['hardstyle kick distortion', 'bitcrush'],
    'rock_metal': ['garage recording', 'demo quality', 'blown-out drums'],
    'hiphop_pop': ['mumbled vocals', 'excessive autotune', 'vinyl'],
    'acoustic_orchestral': ['synthetic strings', 'electronic drums', 'reverb wash'],
  };
  static const Map<String, List<String>> excludePerVocal = {
    'female': ['male vocals'],
    'male': ['female vocals'],
    'instrumental': ['vocals', 'singing', 'spoken word'],
  };
  static const int maxExclusions = 6;
  static const String overExclusionWarning =
      'Over-excluding constrains the model into thin, hollow output.';

  static const List<String> bracketLibrary = [
    '[Intro]', '[Verse 1]', '[Pre-Chorus]', '[Chorus]', '[Verse 2]',
    '[Bridge]', '[Instrumental Break]', '[Final Chorus]', '[Outro]', '[End]',
  ];
  static const List<String> safeModifiers = [
    'soft', 'building', 'big harmonies', 'stripped back', 'half-time',
  ];
  static const int maxModifierWords = 3;
  static const int maxConsecutiveLinesWithoutBreak = 8;
  static const int maxWordsInParentheticals = 3;

  static const Map<String, int> secondsPerSection = {
    'intro': 12, 'verse': 25, 'pre-chorus': 12, 'chorus': 22,
    'bridge': 18, 'instrumental break': 15, 'final chorus': 22, 'outro': 15,
  };
  static const String overBudgetAdvice =
      "Structure exceeds the safe zone. Quality degrades in long generations. "
      "Split the song: generate through [Bridge], then use Suno's Extend for the "
      "final chorus/outro. Extends reset the model's attention and dramatically "
      "reduce late-song artifacts.";

  static const Map<String, String> expandSymbols = {
    '&': 'and', '%': 'percent', '@': 'at', r'$': 'dollars', '+': 'plus', '#': 'number',
  };
  static const Map<String, String> expandAbbreviations = {
    'st.': 'street', 'dr.': 'doctor', 'mr.': 'mister', 'mrs.': 'missus',
    'ft.': 'featuring', 'vs.': 'versus',
  };
  static const List<String> homographs = [
    'read', 'live', 'tear', 'bass', 'lead', 'wound', 'close', 'wind', 'bow', 'record',
  ];
  static const String homographMessage =
      "Ambiguous pronunciation — consider a phonetic respelling (e.g. 'live' -> 'lyve').";
  static const int sibilanceThreshold = 6;
  static const String sibilanceMessage =
      'Heavy s/sh sounds in one line risk sizzle artifacts.';
  static const String elongationMessage =
      "Stretched spelling (e.g. 'looove') causes pitch warble — write 'love' and let the melody stretch it.";

  static const List<SimplificationStep> simplificationLadder = [
    SimplificationStep(step: 1, action: 'drop_mood', message: 'Retry without the mood token.'),
    SimplificationStep(step: 2, action: 'drop_one_texture', message: 'Retry with one fewer texture token.'),
    SimplificationStep(step: 3, action: 'minimal_core', message: 'Retry with the minimal clean core: genre + tempo + vocal only.'),
  ];
  static const String listenGuidance =
      'Judge the first 10 seconds. Muddy intros almost never recover — skip to the next take immediately.';

  static const List<FixItEntry> fixItTree = [
    FixItEntry(
      symptom: 'One section is garbled, the rest is good',
      tool: 'Replace Section',
      guidance: "Don't reroll the whole song. Use Suno's section editing (or Crop + Extend) to replace just the bad bars.",
    ),
    FixItEntry(
      symptom: 'Whole song is good but sounds muddy or dull',
      tool: 'Remaster',
      guidance: 'Run Remaster before rerolling — it often fixes tonal artifacts for free.',
    ),
    FixItEntry(
      symptom: 'Good melody and structure, bad vocals',
      tool: 'Cover',
      guidance: 'Use Cover with your clean style string to re-render the vocal performance.',
    ),
    FixItEntry(
      symptom: 'Good song, bad or garbled ending',
      tool: 'Crop + Extend',
      guidance: 'Crop just before the artifact, then Extend with lyrics containing only [Outro] then [End]. The single most effective outro fix.',
    ),
    FixItEntry(
      symptom: 'Vocals are buried in the mix',
      tool: 'Stems',
      guidance: "Export stems and rebalance in a DAW, or Cover with 'vocals upfront in the mix' added to the style prompt.",
    ),
    FixItEntry(
      symptom: 'Wrong vocal gender or random extra voices',
      tool: 'Exclude Styles + reroll',
      guidance: 'Add the unwanted gender to Exclude Styles (it enforces far better than the style prompt) and reroll.',
    ),
  ];
}
