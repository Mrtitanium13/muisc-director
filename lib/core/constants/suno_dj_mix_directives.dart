import 'package:flutter/foundation.dart';

import '../utils/structural_family_resolver.dart';

/// Per-family canonical DJ intro/outro bar counts (4/4).
/// Soft budget only — SECTION 1F prioritizes sonic language over bar math.
@immutable
class DjIntroConfig {
  const DjIntroConfig({required this.introBars, required this.outroBars});

  final int introBars;
  final int outroBars;

  static const Map<StructuralFamily, DjIntroConfig> table = {
    StructuralFamily.edmProgressiveHouse:
        DjIntroConfig(introBars: 32, outroBars: 32),
    StructuralFamily.edmTrance: DjIntroConfig(introBars: 32, outroBars: 32),
    StructuralFamily.edmTechno: DjIntroConfig(introBars: 32, outroBars: 32),
    StructuralFamily.edmHardstyle: DjIntroConfig(introBars: 32, outroBars: 32),
    StructuralFamily.edmDrumAndBass:
        DjIntroConfig(introBars: 32, outroBars: 32),
    StructuralFamily.edmBigRoom: DjIntroConfig(introBars: 32, outroBars: 32),
    StructuralFamily.trap: DjIntroConfig(introBars: 4, outroBars: 4),
    StructuralFamily.hiphop: DjIntroConfig(introBars: 4, outroBars: 4),
    StructuralFamily.boom_bap: DjIntroConfig(introBars: 4, outroBars: 4),
    StructuralFamily.amapiano: DjIntroConfig(introBars: 16, outroBars: 16),
    StructuralFamily.popRadio: DjIntroConfig(introBars: 4, outroBars: 4),
    StructuralFamily.popStandard: DjIntroConfig(introBars: 4, outroBars: 4),
  };

  static const DjIntroConfig _default =
      DjIntroConfig(introBars: 4, outroBars: 4);
}

/// Resolves DJ bar budget for [family] (defaults to 4/4 when unlisted).
DjIntroConfig djBarConfigFor(StructuralFamily family) =>
    DjIntroConfig.table[family] ?? DjIntroConfig._default;

/// Families where DJ mix-in/outro toggles are meaningful.
bool djMixAllowedForFamily(StructuralFamily family) {
  if (StructuralFamilyResolver.isEdmFamily(family)) return true;
  return const {
    StructuralFamily.trap,
    StructuralFamily.hiphop,
    StructuralFamily.boom_bap,
    StructuralFamily.amapiano,
    StructuralFamily.popRadio,
    StructuralFamily.popStandard,
  }.contains(family);
}

/// Activation tokens consumed by SECTION 1F in SYSTEM_PROMPT_V2.
const String kDjIntroOnToken = '[DJ INTRO: ON]';
const String kDjOutroOnToken = '[DJ OUTRO: ON]';

/// Implementation rules (exported for regression tests).
const String djMixImplV1 =
    'SECTION 1F: DJ framing in first 40 words of Block 1 + 12–18 word closing '
    'clause. Block 2: content-rich [Instrumental Intro]/[Instrumental Outro] '
    'bookends with follow-up staging brackets.';

const String djMixImplV2 = '''SECTION 1F audio-first:
• Block 1: DJ intent in first 40 words + closing reinforcement (≤150 words / ≤1000 chars).
• Block 2: content-rich [Instrumental Intro]/[Instrumental Outro] — zero lyric lines, but every bookend names its playing instruments + 1–2 follow-up staging brackets.
• Positive language only ("wordless", "percussion-only", "loopable fade") — never "no vocals / no melody" phrasing.
''';

const String djMixBriefRouting =
    'Block 1: DJ framing in first 40 words + closing reinforcement '
    '(≤150 words, ≤1000 chars). Block 2: content-rich [Instrumental Intro]/'
    '[Instrumental Outro] bookends with follow-up staging brackets.';

/// Soft ceiling for the injected user-block brief (content-rich templates).
const int kDjMixUserBlockCharCap = 1600;

/// Authoritative DJ mix production brief for the LLM user block.
String buildDjMixUserBlock({
  required bool djIntroMixIn,
  required bool djOutroMixOut,
  required String sunoVersion,
  required StructuralFamily family,
  bool v2UnifiedOutput = false,
}) {
  if (!djIntroMixIn && !djOutroMixOut) return '';

  if (!djMixAllowedForFamily(family)) {
    return '';
  }

  final v = sunoVersion.trim().toLowerCase();
  final isV45 = v == 'v4.5';
  final isV55 = v.startsWith('v5.5');
  final isV5 = !isV45 && v.startsWith('v5') && !isV55;
  final useV2Impl = v2UnifiedOutput || isV5 || isV55;
  final bars = djBarConfigFor(family);

  final buf = StringBuffer()
    ..writeln('[PRODUCTION REQUIREMENT: DJ-FRIENDLY STRUCTURE]')
    ..writeln(
      '(MANDATORY SECTION 1F: name the playing instruments — Suno renders '
      'what you describe. Say "wordless", "percussion-only", never '
      '"no vocals / no melody" phrasing.)',
    );

  if (djIntroMixIn) {
    buf.writeln('\n$kDjIntroOnToken');
    buf.writeln(
      '- Block 1 first 40 words: built for club mix-in blending — opens with '
      'an extended wordless percussion intro (kick loop, closed hats, shaker '
      'groove, layers building one by one into Verse 1; '
      '~${bars.introBars} bars soft).',
    );
    buf.writeln(
      '- Block 2 FIRST: [Instrumental Intro: four-on-the-floor kick loop, '
      'closed hi-hats, shaker groove, extended wordless club mix-in] then '
      '1–2 follow-up staging brackets ([Percussion Build: …], [Riser: …]) so '
      'the intro fills real time. Zero lyric lines inside the intro region; '
      'first lyric tag is [Verse 1].',
    );
  }

  if (djOutroMixOut) {
    buf.writeln('\n$kDjOutroOnToken');
    buf.writeln(
      '- Block 1 closing clause: outro rides kick and hats into a long '
      'loopable fade (~${bars.outroBars} bars soft).',
    );
    buf.writeln(
      '- Block 2 LAST: [Instrumental Outro: kick and hats groove, synth '
      'layers fading one by one, long loopable mix-out] then '
      '[Fade Out: percussion slowly dissolves to a lone kick, loop-ready '
      'tail] → [End]. Zero lyric lines or ad-libs in the outro region.',
    );
  }

  if (!isV45) {
    buf.writeln(useV2Impl ? djMixBriefRouting : djMixImplV1);
  } else if (djIntroMixIn || djOutroMixOut) {
    buf.writeln(
      _v45Impl(introBars: bars.introBars, outroBars: bars.outroBars),
    );
  }

  if (isV5 && (djIntroMixIn || djOutroMixOut)) {
    buf.writeln(
      _v5BracketHint(
        djIntro: djIntroMixIn,
        djOutro: djOutroMixOut,
      ),
    );
  }

  if (isV55 && (djIntroMixIn || djOutroMixOut)) {
    buf.writeln(
      _v55BracketHint(
        djIntro: djIntroMixIn,
        djOutro: djOutroMixOut,
      ),
    );
  }

  final out = buf.toString().trim();
  assert(
    out.length <= kDjMixUserBlockCharCap,
    'DJ directive total ${out.length} exceeds $kDjMixUserBlockCharCap-char cap',
  );
  return out;
}

String _v45Impl({required int introBars, required int outroBars}) {
  return 'DJ arc (v4.5): Block 1 early positive framing + closing clause; '
      'Block 2 content-rich bookends with follow-up staging brackets — '
      'wordless percussion building layer by layer, sonic language is '
      'primary (~$introBars-bar intro / ~$outroBars-bar outro soft).';
}

String _v5BracketHint({
  required bool djIntro,
  required bool djOutro,
}) {
  final parts = <String>[
    'v5: keep each DJ bracket to a single descriptor',
  ];
  if (djIntro) parts.add('intro tag opens Block 2');
  if (djOutro) parts.add('outro tag + [End] close Block 2');
  return '${parts.join('; ')}.';
}

String _v55BracketHint({required bool djIntro, required bool djOutro}) {
  final parts = <String>[
    'v5.5: render the DJ bookend brackets above as full multi-descriptor '
        "director's notes",
  ];
  if (djIntro) parts.add('intro names its layers one by one');
  if (djOutro) parts.add('outro names each layer as it fades');
  return '${parts.join('; ')}.';
}

/// Appends DJ Tool / Club Mix genre modifier when mix sections are enabled.
String primaryGenreWithDjToolModifier({
  required String primaryGenre,
  required bool djIntroMixIn,
  required bool djOutroMixOut,
  required StructuralFamily family,
}) {
  final base = primaryGenre.trim();
  if (base.isEmpty) return base;
  if (!djMixAllowedForFamily(family)) return base;
  if (!djIntroMixIn && !djOutroMixOut) return base;
  return '$base, DJ Tool, Club Mix';
}
