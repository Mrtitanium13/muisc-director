import '../utils/payload_optimization.dart';
import 'audio_environment_data.dart';
import 'dialect_style_data.dart';
import 'vocal_accent_data.dart';

/// Runtime post-processing: humanization pass (OpenRouter + LaoZhang).
///
/// Source: tools/humanization_pass.txt — keep [systemPrompt] aligned with that
/// file; [buildUserMessage] is hand-maintained Dart-only builder logic.
abstract final class HumanizationPassConfig {
  HumanizationPassConfig._();

  static const String systemPrompt = '''

# POST-PROCESSING: HUMANIZATION PASS (RUNTIME — BLOCK 2 LYRICS)

**Model (runtime):**
- **OpenRouter:** Mistral Large — rewrite lane (natural phrasing, anti-AI, authenticity).
- **LaoZhang English song context:** Claude Sonnet 4.5 — standard English lyrics, accent-vs-dialect rules.
- **LaoZhang multilingual / Nigerian Pidgin / African languages:** GPT-5.5 — honor Language field and Pidgin grammar; never flatten to textbook English.

**When:** After theme consistency, before Suno compression (OpenRouter + LaoZhang). **Silent** — no commentary.

**Scope:** Revise **performable lyric lines** in Block 2. Keep section headers, arrangement staging lines, performance tags, and `[End]` unchanged.

---

## OBJECTIVE

Humanize lyrics: natural speech, genre-appropriate authenticity, zero AI-artifact voice.

---

## ACTIONS

1. **Humanize** — conversational, singable, not essay or caption voice.
2. **Natural phrasing** — how a real artist would say it on a record.
3. **Remove AI artifacts** — ban poster slogans, motivational copy, generic philosophy, symmetrical "polished" chains.
4. **Improve authenticity** — apply genre lane from user GENRE (Amapiano conversational · Hip-hop attitude · Country place-based · Trance singable hooks · Gospel spirit-forward · etc.).
5. **Nigerian Pidgin (when user LYRIC DIALECT says so):** Write natively in authentic Pidgin — `dey`, `na`, `wahala`, `e don set`, `small small`. Do **not** normalize to standard English. Fourth-Wall Law still applies in lyric lines.
6. **Multilingual / African languages (when user Language is not English):** Preserve native lyric intent, grammar, and cultural phrasing — do not translate into stiff English.

---

## ACCENT VS. DIALECT CONSTRAINT (STAGE 3 — MANDATORY WHEN ACCENT IS SET)

When a regional accent or delivery style is specified (e.g. Nigerian, British, Jamaican) **and** lyric dialect is **not** Nigerian Pidgin:

* Write lyrics in **clear, standard English**.
* You are **strictly forbidden** from translating text into slang, broken dialects, or patois (completely ban words like `dey`, `na`, `wahala`, `gonna` in lyric lines).
* Vocal performance style stays **purely phonetic** in staging tags; written lyric text must stay pristine, high-end, and universally legible.

**Exception:** When user LYRIC DIALECT = Nigerian Pidgin, Pidgin grammar in lyric lines is required — accent still lives in staging tags only.

---

## PRESERVE

- Syllable feel · groove · rhyme · cadence · hook anchors (unless AI-sloppy)
- All bracket structure (headers → staging → tags → lines → `[End]`)

---

## OUTPUT

Return **only** the revised Block 2 body. No Block 1. No scores. No meta.

''';

  static String buildUserMessage({
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
  }) {
    final resolvedDialectId =
        dialectStyleId ?? DialectStyleData.standardEnglishId;

    final extraLines = _buildExtraLines(
      vocalAccent: vocalAccent,
      resolvedDialectId: resolvedDialectId,
      dialectStyleId: dialectStyleId,
      dialectVariantId: dialectVariantId,
      audioEnvironmentModeId: audioEnvironmentModeId,
    );

    final contextHeader = compactGenreContextHeader(
      primaryGenre: primaryGenre,
      subGenreFusion: subGenreFusion,
      vibe: vibe,
      lyricThemeNotes: lyricThemeNotes,
      language: language,
      extraLines: extraLines,
    );

    final compactBody = compactPayloadText(block2Body);

    return '''
$contextHeader

BLOCK 2 (humanize; keep structure):
---
$compactBody
---

Return ONLY revised Block 2 through [End]. No Block 1. No commentary.
'''.trim();
  }

  static List<String> _buildExtraLines({
    required String? vocalAccent,
    required String resolvedDialectId,
    required String? dialectStyleId,
    required String? dialectVariantId,
    required String? audioEnvironmentModeId,
  }) {
    // Compact helpers return '' when inactive; filter empties so the header
    // stays dense. If any helper becomes nullable later, coalesce before filter.
    return <String>[
      VocalAccentData.postProcessCompactLine(
        vocalAccent,
        dialectStyleId: resolvedDialectId,
      ),
      DialectStyleData.postProcessCompactLine(
        dialectStyleId,
        dialectVariantId: dialectVariantId,
      ),
      VocalAccentData.accentVsDialectCompactLine(
        vocalAccent,
        dialectStyleId: resolvedDialectId,
      ),
      AudioEnvironmentData.postProcessCompactLine(audioEnvironmentModeId),
    ].where((line) => line.isNotEmpty).toList(growable: false);
  }
}

// Backward-compatible top-level names.
const String kHumanizationSystemPrompt = HumanizationPassConfig.systemPrompt;

String buildHumanizationUserMessage({
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
}) =>
    HumanizationPassConfig.buildUserMessage(
      block2Body: block2Body,
      primaryGenre: primaryGenre,
      subGenreFusion: subGenreFusion,
      vibe: vibe,
      lyricThemeNotes: lyricThemeNotes,
      language: language,
      vocalAccent: vocalAccent,
      dialectStyleId: dialectStyleId,
      dialectVariantId: dialectVariantId,
      audioEnvironmentModeId: audioEnvironmentModeId,
    );
