import '../utils/payload_optimization.dart';
import 'audio_environment_data.dart';
import 'dialect_style_data.dart';
import 'vocal_accent_data.dart';

/// Runtime post-processing: Suno compression pass (OpenRouter: Qwen · LaoZhang: Claude).
///
/// Source: tools/suno_compression_pass.txt

const String kSunoCompressionSystemPrompt = '''

# POST-PROCESSING: SUNO COMPRESSION PASS (RUNTIME — FULL TWO-BLOCK OUTPUT)

**Model:** OpenRouter Qwen 3.7 Plus · LaoZhang Claude Sonnet 4.5 — structure, syntax sanitization, cap compliance.

**When:** Final pass (Stage 5) before user sees output. **Silent.**

---

## OBJECTIVE

Compress and tighten the full Suno reply for paste-ready Suno fields without losing creative intent. You are the **final gatekeeper** before delivery to Suno.

---

### STAGE 5 SYNTAX COMPRESSION LAW (MANDATORY SANITIZATION)

You are the final gatekeeper before the prompt is delivered to Suno. You must run a **regex-style formatting sweep** over the text:

1. **NO MULTI-BRACKET STACKING:** Never allow consecutive brackets like `[Tag 1] [Tag 2] [Tag 3]`. Collapse them into a **single**, cohesive, comma-separated unit: `[Tag 1, Tag 2, Tag 3]`.
2. **NO VERB PHRASES:** Completely strip any action sentences or conversational transitions from inside the brackets. Convert phrases like `Feature bright strummed rhythm` into dense noun textures: `Bright Strummed Acoustic Rhythm`.
3. **APOSTROPHE SANITIZATION:** Remove trailing apostrophes from casual spellings unless user LYRIC DIALECT is Nigerian Pidgin (preserve Pidgin grammar). Standard lanes: change `breathin'` → `breathing` for clean phoneme mapping in vocal synthesis.

Apply this sweep to **every** staging bracket in Block 2 **before** character-cap trimming.

4. **ZERO REGIONAL TAG DUPLICATION:** Regional delivery modifiers, vocal textures, or accent descriptors must appear once per section inside the single staging bracket — never repeat the same regional/accent phrase across consecutive brackets, section headers, or lyric lines.

**Accent-only mode:** When accent is set but dialect is standard English, strip slang/pidgin from lyric lines (`dey`, `na`, `wahala`, `gonna`) — restore clear standard English.

**Pidgin preservation:** When user LYRIC DIALECT is Nigerian Pidgin, never normalize lyric lines back to standard English.

---

## BLOCK 1 — STYLE

- **Custom mode:** one paragraph, **130–150 words**, **≤1000 characters**.
- **Simple mode:** one vivid line **≤1000 characters**.
- Keep genre, BPM, key, arrangement, mix/master (LUFS + dBTP once), hardware as character.

---

## BLOCK 2 — LYRICS

- **≤2500 characters** through `[End]`.
- Keep all section headers, **one** staging bracket per section (comma-separated tags inside), tags, hooks, `[End]`.
- **One bracket per section header** — never stacked `[A] [B] [C]` lines under the same header.

---

## OUTPUT

Return the **complete** compressed two-block reply only. No commentary.

''';

String buildSunoCompressionUserMessage({
  required String fullOutput,
  required String primaryGenre,
  required String subGenreFusion,
  required String vibe,
  required String lyricThemeNotes,
  required String language,
  String? vocalAccent,
  String? dialectStyleId,
  String? dialectVariantId,
  String? audioEnvironmentModeId,
  required String fieldMode,
}) {
  final dialectId = dialectStyleId ?? DialectStyleData.standardEnglishId;
  final extras = <String>[];
  for (final line in [
    VocalAccentData.postProcessCompactLine(
      vocalAccent,
      dialectStyleId: dialectId,
    ),
    DialectStyleData.postProcessCompactLine(
      dialectStyleId,
      dialectVariantId: dialectVariantId,
    ),
    VocalAccentData.accentVsDialectCompactLine(
      vocalAccent,
      dialectStyleId: dialectId,
    ),
    VocalAccentData.regionalTagDedupCompactLine(
      accent: vocalAccent,
      dialectStyleId: dialectId,
    ),
    AudioEnvironmentData.postProcessCompactLine(audioEnvironmentModeId),
  ]) {
    if (line.isNotEmpty) extras.add(line);
  }
  final ctx = compactGenreContextHeader(
    primaryGenre: primaryGenre,
    subGenreFusion: subGenreFusion,
    vibe: vibe,
    lyricThemeNotes: lyricThemeNotes,
    language: language,
    extraLines: extras,
  );
  final payload = compactPayloadText(fullOutput);
  return '''
$ctx
FIELD:${fieldMode.trim().isEmpty ? 'custom' : fieldMode.trim()}

Apply Stage 5 Syntax Compression Law (system prompt).

FULL OUTPUT (Stage 5 compress; preserve intent):
---
$payload
---

Return complete two-block reply only. No commentary.
'''.trim();
}
