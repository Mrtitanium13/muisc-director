import '../utils/remix_payload_compiler.dart';
import 'audio_environment_data.dart';
import 'dialect_style_data.dart';
import '../../data/models/song_generation_type.dart';
import 'vocal_accent_data.dart';

/// Runtime post-processing: theme consistency on Block 2 lyrics only.
///
/// Source: tools/theme_consistency_pass.txt — keep in sync when editing.

const String kThemeConsistencySystemPrompt = '''

# POST-PROCESSING STAGE: THEME CONSISTENCY PASS (RUNTIME — BLOCK 2 ONLY)

**When:** After lyrics are generated, before output is shown to the user. **Silent** — never print scores, theme labels, or audit notes.

**Scope:** Revise **BLOCK 2 — LYRICS** only. Do **not** change Block 1. Preserve all section headers, arrangement staging lines, performance tags, and `[End]`.

---

## OBJECTIVE

Ensure every section supports the same emotional identity, narrative direction, and thematic message. Fix songs that feel like unrelated ideas stitched together.

---

## STEP 1 — IDENTIFY THE CORE THEME

Analyze the lyrics and determine the dominant theme.

Possible themes: Confidence · Swagger · Self-belief · Romance · Longing · Heartbreak · Healing · Celebration · Nightlife · Freedom · Nostalgia · Friendship · Spirituality · Motivation · Success · Reflection · Adventure · Seduction · Empowerment.

Choose the **strongest primary theme**. If multiple exist, name PRIMARY + SECONDARY — primary must dominate.

Honor user **lyric theme notes** and **vibe** when present.

---

## STEP 2 — AUDIT EVERY SECTION

Review Intro · Verse · Build · Pre-Chorus · Chorus · Drop · Breakdown · Bridge · Outro.

For each: *Does this reinforce the primary theme?* Flag sections that do not.

---

## STEP 3 — DETECT THEME DRIFT

Remove lines that shift into another emotional world (e.g. loneliness in a confidence song; money flex in a romance song).

---

## STEP 4 — REWRITE INCONSISTENT LINES

Preserve: syllable count · groove · rhyme feel · cadence · arrangement structure (headers + staging + tags).

Change **only** thematic content.

---

## STEP 5 — MAINTAIN GENRE FIT

Do not rewrite into another genre. Match lane expectations (Amapiano conversational/groove · Afrobeats relationship/lifestyle · Trance emotional hooks · Hip-hop attitude/story · Country place-based narrative).

---

## STEP 6 — PROTECT STRONG HOOKS

Do **not** rewrite strong hooks unless they conflict with the theme. Protect title hooks, repeated chorus anchors, memorable phrases.

---

## STEP 7 — HUMAN LANGUAGE CHECK

Remove production notes, motivational posters, social captions, marketing slogans, AI philosophy.

---

## STEP 8 — FINAL SCORING (INTERNAL ONLY)

Score internally: Theme Consistency · Human Authenticity · Hook Strength · Genre Suitability (each /10).

If Theme Consistency **< 9/10**, revise again (max one extra internal pass).

---

## OUTPUT RULES

Return **only** the revised Block 2 lyrics body: section headers → staging lines → performance tags → lyric lines → `[End]`.

**No** Block 1. **No** commentary. **No** score table. **No** theme labels.

''';

String buildThemeConsistencyUserMessage({
  required String block2Body,
  required String primaryGenre,
  required String subGenreFusion,
  required String vibe,
  required String lyricThemeNotes,
  required String language,
  String? vocalAccent,
  String? dialectStyleId,
  String? dialectVariantId,
  String? audioEnvironmentModeId,
  String remixOriginalSongTitle = '',
  String remixOriginalArtist = '',
  SongGenerationType songGenerationType = SongGenerationType.fullSong,
  String extraDirective = '',
}) {
  final theme =
      lyricThemeNotes.trim().isEmpty ? '(infer from lyrics, genre, and vibe)' : lyricThemeNotes.trim();
  final accentLine = VocalAccentData.postProcessContextLine(
    vocalAccent,
    dialectStyleId: dialectStyleId ?? DialectStyleData.standardEnglishId,
  );
  final accentBlock = accentLine.isEmpty ? '' : '\n$accentLine';
  final dialectLine = DialectStyleData.postProcessContextLine(
    dialectStyleId,
    dialectVariantId: dialectVariantId,
  );
  final dialectBlock = dialectLine.isEmpty ? '' : '\n$dialectLine';
  final accentRule = VocalAccentData.accentVsDialectConstraintLine(
    vocalAccent,
    dialectStyleId: dialectStyleId ?? DialectStyleData.standardEnglishId,
  );
  final accentRuleBlock = accentRule.isEmpty ? '' : '\n$accentRule';
  final dedupRule = VocalAccentData.regionalTagDedupConstraintLine(
    accent: vocalAccent,
    dialectStyleId: dialectStyleId ?? DialectStyleData.standardEnglishId,
  );
  final dedupBlock = dedupRule.isEmpty ? '' : '\n$dedupRule';
  final envBlock =
      '\n${AudioEnvironmentData.postProcessCompactLine(audioEnvironmentModeId)}';
  final remixLine = remixPostProcessCompactLine(
    originalSongTitle: remixOriginalSongTitle,
    originalArtist: remixOriginalArtist,
    generationType: songGenerationType,
  );
  final remixBlock = remixLine.isEmpty ? '' : '\n$remixLine';
  final extra = extraDirective.trim();
  final extraBlock = extra.isEmpty ? '' : '\n$extra';
  return '''
GENRE: ${primaryGenre.trim().isEmpty ? 'unspecified' : primaryGenre.trim()}
FUSION: ${subGenreFusion.trim().isEmpty ? 'none' : subGenreFusion.trim()}
VIBE: ${vibe.trim().isEmpty ? 'unspecified' : vibe.trim()}
LANGUAGE: ${language.trim().isEmpty ? 'English' : language.trim()}
LYRIC THEME NOTES: $theme$accentBlock$dialectBlock$accentRuleBlock$dedupBlock$envBlock$remixBlock$extraBlock

BLOCK 2 LYRICS (revise for theme consistency — preserve structure):
---
${block2Body.trim()}
---

Return ONLY the revised Block 2 body (headers, staging, tags, lines, [End]). No Block 1. No commentary.
'''.trim();
}
