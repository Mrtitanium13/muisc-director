/// Universal human-voice art direction — injected for every lyrical generation.
///
/// Principles only. Stock-scene / AI-poetry patterns are enforced by
/// [MeaningfulnessCheck.stockPhrasePatterns] (and the Python detector on
/// `/generate-prompt`). Do not re-enumerate ban lists here — models copy them.
const String kHumanVoiceDirective = '''
HUMAN VOICE DIRECTIVE v2.0 (non-negotiable — violations are rejected and retried)

0. ANTI-PARROT (highest priority): NEVER reuse prompt examples, pool
   exemplars, or prior-run stock scenes. Every concrete detail must be
   MOTIVATED by this brief's theme, genre, region, and narrator. If a
   detail could swap into an unrelated song unchanged, delete it.
   Do not assemble checklist bingo (clock-time + random city + kitchen
   prop + "Mama said"). Banned stock kits are enforced by runtime QA.

1. SENSORY ANCHOR: ≥2 lines carry a sensory detail earned by the scene
   (sight / sound / touch / taste / smell). No kitchen-prop padding.
   Invent fresh details — never copy examples from this directive.

2. GROUNDING (when natural): at most one grounded cue — name, place, brand,
   year, workplace — that fits THIS story. Never force a city name.

3. NUMBER / TIME (optional): a specific number only when it serves the
   story. No default clock-time crutch.

4. DIALOGUE (optional): quoted speech only when someone in the story
   actually speaks. No filler "Mama said…" beats.

5. EMOTIONAL THROUGHLINE: the song orbits ONE primary emotion matching the
   brief. Choose one; stay in it.

6. SHOW, DON'T TELL — but stay human. Prefer everyday idiom over literary
   body metaphor (e.g. "song in my heart", not ornate chest/lungs poetry).
   Kitchen-table test: if you wouldn't say it to a friend, rewrite.

7. NO EQUALITY LINES: every line must be true of THIS narrator and THIS
   addressee. If it could fit any song ever written, rewrite it.

8. NARRATOR MEMORY (internal craft): before writing, fix one specific
   memory that colors ≥2 lines. Don't print the narrator's name unless it
   serves the song. Speak like a person, not a greeting card.
''';
