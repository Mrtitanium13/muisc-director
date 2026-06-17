// Strong user-block copy when DJ intro/outro toggles are on — improves Suno compliance.



String buildDjMixUserBlock({

  required bool djIntroMixIn,

  required bool djOutroMixOut,

  bool v2UnifiedOutput = false,

}) {

  if (!djIntroMixIn && !djOutroMixOut) {

    return 'DJ mix: intro (mix-in)=false, outro (mix-out)=false — no special DJ blending.';

  }



  final buf = StringBuffer()

    ..writeln(

      'DJ MIX (user enabled) — NON-NEGOTIABLE; Suno must follow this in the generated audio:',

    );



  if (djIntroMixIn) {

    buf.writeln(v2UnifiedOutput ? _introLinesV2 : _introLines);

  }

  if (djOutroMixOut) {

    buf.writeln(v2UnifiedOutput ? _outroLinesV2 : _outroLines);

  }



  buf.writeln(

    v2UnifiedOutput ? _implV2 : _implV1,

  );



  return buf.toString().trim();

}



const String _implV1 = '''Implementation rule: Repeat the DJ requirements verbatim inside SUNO STYLE using dense, comma-separated production tags (e.g. "DJ mix-in intro; filtered kick; 24+ bars before full groove"). In SUNO STRUCTURE, the timeline MUST start with a long intro segment (if intro on) and end with a long outro segment (if outro on) before/after the main song body — never skip or shorten these in prose.''';



const String _implV2 = '''Implementation rule: Full DJ arc in **Block 1** producer prose (≤150 words, ≤1000 characters). In Block 2 (Lyrics), the section timeline MUST start with a long intro segment (if intro on) and end with a long outro segment (if outro on) around the main song body — never skip or shorten these.''';



const String _introLines = '''DJ INTRO (mix-in) = ON — REQUIRED BEHAVIOR:

- The song MUST NOT start at full energy. Begin with a long DJ-friendly blend-in from a hypothetical previous track (16–48+ bars): sparse rhythm, filtered drums, rising hi-hats, subtle FX; main groove / chorus energy enters only AFTER this intro.

- No instant drop or full vocal hook at bar 0; leave space for a crossfader blend (sidechain-friendly kick, mono-safe low end, gradual filter opening).

- Describe this intro explicitly in SUNO STRUCTURE as the FIRST section and again in SUNO STYLE with concrete mix words (filter sweep, kick creep, snare roll, energy step at bar ~X).

''';



const String _introLinesV2 = '''DJ INTRO (mix-in) = ON — REQUIRED BEHAVIOR:

- The song MUST NOT start at full energy. Begin with a long DJ-friendly blend-in from a hypothetical previous track (16–48+ bars): sparse rhythm, filtered drums, rising hi-hats, subtle FX; main groove / chorus energy enters only AFTER this intro.

- No instant drop or full vocal hook at bar 0; leave space for a crossfader blend (sidechain-friendly kick, mono-safe low end, gradual filter opening).

- Describe the full blend-in in **Block 1** producer prose (bars, filter arc, energy staging) within **130–150 words** and **≤1000 characters**; mirror it as the FIRST section in Block 2; repeat key mix words in Block 1 (filter sweep, kick creep, snare roll, energy step at bar ~X).

''';



const String _outroLines = '''DJ OUTRO (mix-out) = ON — REQUIRED BEHAVIOR:

- The song MUST NOT end cold on the last downbeat. Finish with a long mix-out tail for blending into the next track: strip leads and hook, sustain hats/ride, filter down or open noise, gradual energy decay; avoid a hard stop.

- Describe this outro explicitly in SUNO STRUCTURE as the LAST section and again in SUNO STYLE (tail length, fade, last elements left in the mix).

''';



const String _outroLinesV2 = '''DJ OUTRO (mix-out) = ON — REQUIRED BEHAVIOR:

- The song MUST NOT end cold on the last downbeat. Finish with a long mix-out tail for blending into the next track: strip leads and hook, sustain hats/ride, filter down or open noise, gradual energy decay; avoid a hard stop.

- Describe the full mix-out in **Block 1** prose within **130–150 words** and **≤1000 characters**; mirror it as the LAST section in Block 2 (tail length, fade, last elements left in the mix).

''';


