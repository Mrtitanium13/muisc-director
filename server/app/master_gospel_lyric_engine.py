"""Master Gospel & Christian music lyric + arrangement engine (5 sub-genre matrix)."""

from __future__ import annotations

import re

from app.gospel_theme_directives import directive_block

PROFILE_AFRO_GOSPEL = "afro_gospel"
PROFILE_TRADITIONAL_URBAN = "traditional_urban"
PROFILE_GOSPEL_COUNTRY = "gospel_country"
PROFILE_PRAISE_WORSHIP = "praise_worship"
PROFILE_TRADITIONAL_QUARTET = "traditional_quartet"

_GOSPEL_MARKERS = (
    "gospel",
    "worship",
    "ccm",
    "christian",
    "praise",
    "hymn",
    "afro-gospel",
    "afro gospel",
)

CROSS_ARCHITECTURE_RULES = """\
CROSS-ARCHITECTURE NON-NEGOTIABLES (this engine runs inside Suno V4):
- Output is always two blocks: BLOCK 1 — STYLE (≤150 words, ≤1,000 chars,
  one paragraph) and BLOCK 2 — LYRICS (≤2,500 chars, ending with [End]).
- Block 1 must state genre-appropriate LUFS band + −1.0 dBTP + one
  mix/master move from the Gospel blueprint.
- STUDIO-ISOLATION is default for Praise/Worship/CCM/Gospel unless the
  runtime explicitly injects [LIVE PERFORMANCE MODE: ON]. In studio mode:
  ban [Congregational], [Live], [Church], [Sanctuary], [Communal],
  [SATB Choir Stack], crowd noise, tape hiss, and vinyl crackle in
  [Intro], [Verse 1], and [Outro]. Use isolated multi-tracked vocal
  doubles instead of choir/congregation triggers.
- In LIVE PERFORMANCE MODE, override studio isolation: stadium crowd
  intro, anthemic sing-along chorus, handclap bridge, standing-ovation
  outro.
- NO raw accent adjectives in brackets. Use Section B Layer 1 descriptors.
- NO instrument or production-gear names in performable lyric lines
  (Fourth-Wall Law). Bracket staging may name instruments.
- NO trailing apostrophes in lyrics; no labeled parentheses like
  (Lead ad-libs: ...) or (Choir: ...); parens contain sung words only.
- Scan every staging bracket against SECTION D AI-generic blacklist before
  emission."""

UNIVERSAL_STRICT_RULES = """\
STRICT WRITING RULES FOR ALL GOSPEL:
- BAN COLD CLICHÉS: Do not use shallow, generic phrases. Lyrics must feel
  spiritually heavy, poetic, and visceral. Use the "Paradox Principle"
  (e.g., finding strength in weakness, finding wealth in poverty).
- CONCRETE ANCHORING: Every spiritual/emotional beat must be tied to a
  tangible image, action, or testimony detail — not an abstract label.
  "Grace broke every chain" is weak unless the chain is named (debt,
  diagnosis, prison, grief, eviction notice, empty crib).
- STRUCTURE & FLOW: Every song must include canonical bracket tags:
  [Intro], [Verse 1], [Pre-Chorus] when appropriate, [Chorus], [Verse 2],
  [Bridge], [Vamp/Flow] or [Spontaneous Flow], [Outro], [End].
- THE CLIMAX (VAMP): Every Gospel song needs a structural peak. Include a
  [Vamp] or [Spontaneous Flow] before the final chorus where the lead
  vocalist ad-libs while backing vocals repeat a core declarative truth.
- SYLLABLE ECONOMY:
    * Verse: 10–14 syllables/line, narrative testimony.
    * Pre-Chorus: 8–12 syllables/line, rising intensity.
    * Chorus: 6–10 syllables/line, anthemic and singable.
    * Vamp/Flow: 2–6 syllable repeated declarations.
- HOOK DOMINANCE: Chorus must contain one ≤6-word standalone declarative
  line and one concrete anchor. Final chorus must mutate structurally or
  lyrically, never be a 100% copy-paste.
- VOCAL DESCRIPTOR HYGIENE: In staging brackets, never use "soulful",
  "emotional", "passionate", "powerful", "haunting", "ethereal",
  "uplifting", "inspiring", or "spiritual" as raw descriptors. Use
  physical/mixable terms: belted chest voice, close-mic lead, stacked
  harmonies wide, isolated multi-tracked vocal doubles, warm Hammond
  swell, tight studio drum backbeat.
- GOSPEL STAGING BLACKLIST (replace before emission):
    * "uplifting anthem" → anointed lift + congregational sing-along
    * "powerful worship" → altar call dynamic
    * "spiritual atmosphere" → Hammond B3 swell
    * "inspiring glory" → praise break
    * "transcendent moment" → worship swell
    * "ethereal anointing" → Hammond B3 swell + anointed lift
- PIDGIN AUTHENTICITY (Afro-Gospel): When dialect is enabled, use
  Nigerian/Ghanaian Pidgin naturally — "Baba," "Chineke," "Jehovah
  overdo," "You do me well," "Olowogbogboro." Never force it where
  standard English sings better."""

MASTER_ROLE = """\
You are a master lyricist and music arranger specializing in the entire
spectrum of Gospel and Christian music. You write lyrics and arrangement
notes that capture authentic spiritual depth, vocal power, and musical
heritage. You obey the Cross-Architecture Non-Negotiables and Strict
Writing Rules above."""

PRE_OUTPUT_QA = """\
SILENT PRE-OUTPUT QA FOR GOSPEL:
1. Does Block 2 end with [End]?
2. Are all staging brackets free of Section D blacklist words?
3. Are all staging brackets free of banned vocal descriptors
   (soulful, emotional, passionate, powerful, haunting, ethereal,
   uplifting, inspiring, spiritual as raw tags)?
4. Are [Intro]/[Verse 1]/[Outro] free of crowd/congregation/SATB/
   live/sanctuary/church triggers in studio mode?
5. Are there zero instrument/gear names in performable lyric lines?
6. Are there zero labeled parentheses and zero trailing apostrophes?
7. Does the chorus pass Hook Dominance (≤6-word standalone line + concrete
   anchor)?
8. Does Verse 2 introduce new testimony detail, not just restate Verse 1?
9. Does the Vamp/Flow section repeat a short declarative truth and leave
   room for lead ad-libs?
10. Would a worship leader actually sing this on Sunday?"""

_SUB_GENRE_MATRIX: dict[str, str] = {
    PROFILE_AFRO_GOSPEL: """\
SUB-GENRE: AFRO-GOSPEL / AFROBEATS WORSHIP
- Vibe: Joyful, infectious, highly rhythmic, celebratory, deeply grateful.
- Lyrical Focus: God's blessings, testimonies of favor, dance as warfare,
  the goodness of God.
- Vocabulary/Dialect: Tasteful West African (Nigerian/Ghanaian) English
  and Pidgin where appropriate ("Jehovah overdo," "You do me well,"
  "Baba," "Chineke," "My Ebenezer," "Olowogbogboro").
- Arrangement: Syncopated Afrobeat drums, highlife clean electric guitar
  grooves, bright brass/horns, log drums (Amapiano-style) or talking
  drums, call-and-response lead + tight rhythmic choir.""",
    PROFILE_TRADITIONAL_URBAN: """\
SUB-GENRE: TRADITIONAL GOSPEL / URBAN CONTEMPORARY
- Vibe: High-energy, emotionally overwhelming, deeply theological,
  communal.
- Lyrical Focus: Overcoming trials, deliverance, the blood of Jesus,
  praise, testimony.
- Vocabulary: Victory, Deliverance, Anointing, Breakthrough, Testimony,
  Grace — earned in context, not empty filler.
- Arrangement: Massive vocal stacks, choir call-and-response, Hammond B3
  organ sweeps, preacher chords, bass drops, modulation/key changes,
  vamp sections.""",
    PROFILE_GOSPEL_COUNTRY: """\
SUB-GENRE: GOSPEL COUNTRY / SOUTHERN GOSPEL
- Vibe: Earthy, narrative-driven, prayerful, acoustic, nostalgic.
- Lyrical Focus: Family heritage, trials of life, simple faith, testimony
  around the cross and homecoming.
- Vocabulary: Valley, Soil, River, Homecoming, Harvest — concrete imagery
  over stock country clichés.
- Arrangement: Close 3–4 part family harmony, acoustic guitar picking,
  pedal steel swells, brush snares, acoustic piano, storytelling pacing.""",
    PROFILE_PRAISE_WORSHIP: """\
SUB-GENRE: PRAISE & WORSHIP / INSPIRATIONAL
- Vibe: Atmospheric, vertical (singing TO God), accessible, anthemic.
- Lyrical Focus: Majesty of God, surrender, holiness, peace in the storm.
- Vocabulary: Holy, Worthy, Surrender, Beautiful, Forever, King,
  Presence — specific scenes anchoring each word.
- Arrangement: Echoing ambient electric guitars, synth pads, building
  tom-heavy drums, massive dynamic shifts whisper → stadium roar.""",
    PROFILE_TRADITIONAL_QUARTET: """\
SUB-GENRE: TRADITIONAL QUARTET
- Vibe: Driving, rhythmic, blues-infused, raspy, call-and-response.
- Lyrical Focus: Walking the straight and narrow, running the race,
  meeting Jesus.
- Vocabulary: "Lord remember me," "Trouble in my way," "On my journey,"
  "Fix it Jesus" — in fresh phrasing, not pasted clichés.
- Arrangement: Walking basslines, driving rhythm guitar, tight 4-part
  male vocal stacks, ad-libbing lead stepping out over a repetitive
  driving groove.""",
}

_PROFILE_RULES: tuple[tuple[tuple[str, ...], str], ...] = (
    (("afro-gospel", "afro gospel", "afrobeat worship"), PROFILE_AFRO_GOSPEL),
    (("southern gospel", "country gospel", "gospel country"), PROFILE_GOSPEL_COUNTRY),
    (
        (
            "praise/worship",
            "praise & worship",
            "modern worship",
            "worship ballad",
            "pop worship",
            "ccm",
        ),
        PROFILE_PRAISE_WORSHIP,
    ),
    (("traditional gospel", "quartet", "four-part"), PROFILE_TRADITIONAL_QUARTET),
    (("contemporary gospel", "urban gospel"), PROFILE_TRADITIONAL_URBAN),
)

_AFRO_GOSPEL_FEW_SHOT_GOOD = """\
GOOD (write in this style, end with [End]):

[Intro: talking drums, bright highlife guitar, log drum pulse]

[Verse 1: Male Lead, rhythmic call-and-response pocket]
Sorrow had a key to my house — I gave it away too long
Baba, You rewrite the ending when the night feels strong
My Ebenezer standing where the shame used to be
Jehovah overdo — You do me well, You set me free

[Chorus: Choir stack, brass hits, syncopated Afrobeat groove]
Dance is warfare — we praise You on our feet
From valley testimony to a joyful heartbeat
You turned my mourning into a rhythm they can feel
Olowogbogboro — Your goodness is real

[Verse 2: Bass enters, lead more urgent]
The landlord knocked and I had nothing left to say
But You sent a knock louder than the debt on the table that day
Now my children eat, now my mother can rest
Baba, You do me well — I count every yes

[Chorus: Choir stack, brass hits, syncopated Afrobeat groove]
Dance is warfare — we praise You on our feet
From valley testimony to a joyful heartbeat
You turned my mourning into a rhythm they can feel
Olowogbogboro — Your goodness is real

[Bridge: Stripped to percussion and vocal ad-libs]
You do me well
You do me well
You do me well

[Vamp/Flow: Lead ad-lib, choir repeats "You do me well"]
You do me well
You do me well
My testimony is alive and well

[Final Chorus: Full stack, modulation up, max dynamics]
Dance is warfare — we praise You on our feet
From valley testimony to a joyful heartbeat
You turned my mourning into a rhythm they can feel
Olowogbogboro — Your goodness is real

[Outro: Talking drums and vocal fade]
You do me well
You do me well

[End]"""

_URBAN_GOSPEL_FEW_SHOT_GOOD = """\
GOOD (write in this style, end with [End]):

[Intro: Hammond B3 swell, isolated multi-tracked vocal doubles, dead-room studio]

[Verse 1: Belted chest voice, Hammond underneath]
Trouble had my name on a list I didn't write
But deliverance walked in before the morning light
I was holding an eviction notice in one hand
Grace walked in with a pen and a different plan

[Chorus: Massive vocal stack, preacher chords, modulation lift]
This is my testimony — grace broke every chain
Victory isn't a word here — it's a living name
I was counted out, but You counted me in
Your mercy wrote the story after my story ended

[Verse 2: Choir enters softly, lead more declarative]
They said the report would finish me by spring
But You are the God who breathes on anything
Now the same mouth that pronounced me gone
Is asking how I keep on keeping on

[Chorus: Massive vocal stack, preacher chords, modulation lift]
This is my testimony — grace broke every chain
Victory isn't a word here — it's a living name
I was counted out, but You counted me in
Your mercy wrote the story after my story ended

[Bridge: Strip to Hammond and lead, intimate]
I don't have to pretend the valley wasn't real
I just have to tell what Your hand made me feel

[Vamp/Flow: Choir repeats "Breakthrough" while lead ad-libs]
Breakthrough
Breakthrough
My breakthrough is a person, not a moment

[Final Chorus: Full stack, key change, max dynamics]
This is my testimony — grace broke every chain
Victory isn't a word here — it's a living name
I was counted out, but You counted me in
Your mercy wrote the story after my story ended

[Outro: Hammond fade, trailing vocal decay]

[End]"""

_GOSPEL_COUNTRY_FEW_SHOT_GOOD = """\
GOOD (write in this style, end with [End]):

[Intro: Acoustic guitar picking, brush snare, close-mic female lead]

[Verse 1: Storytelling vocal pocket, dry room]
Morning breath You gave again — I didn't earn the dawn
Every cup You fill runs over what I thought was gone
The porch light flickers like it did when Daddy prayed
Faith isn't a feeling here — it's the way the bills got paid

[Chorus: Family harmony, pedal steel swell]
Harvest in my heart where worry used to grow
Thank You for the quiet mercy I will never know
You keep the sparrow and You keep the field
You keep a roof above a love that wouldn't yield

[Verse 2: Full band enters, harmony widens]
The bank called twice while the beans were on the stove
Mama said "We ate last year this same time, we won't be broke"
And sure enough the mailbox held what we could not explain
Grace looks like a check and a neighbor in the rain

[Chorus: Family harmony, pedal steel swell]
Harvest in my heart where worry used to grow
Thank You for the quiet mercy I will never know
You keep the sparrow and You keep the field
You keep a roof above a love that wouldn't yield

[Bridge: Stripped to acoustic and solo voice]
I have seen the valley
I have seen the rain
I have seen You carry what I could not name

[Vamp/Flow: Family stack repeats "Overflowing cup"]
Overflowing cup
Overflowing cup
My table is an altar
Overflowing cup

[Final Chorus: Full family stack, steel lift]
Harvest in my heart where worry used to grow
Thank You for the quiet mercy I will never know
You keep the sparrow and You keep the field
You keep a roof above a love that wouldn't yield

[Outro: Acoustic fade, room tone]

[End]"""

_PRAISE_WORSHIP_FEW_SHOT_GOOD = """\
GOOD (write in this style, end with [End]):

[Intro: Ambient electric guitar, synth pad, dead-room isolation]

[Verse 1: Whispered close-mic lead, minimal verb]
Holy is not a word I throw — it's the air I breathe in You
When the room went quiet, Your presence walked right through
I stopped trying to name what my heart could only feel
You were the stillness holding every breaking wheel

[Pre-Chorus: Vocal doubles enter, drums build]
You are before the question
You are after the cry
You are the only answer
That never learned to lie

[Chorus: Tom build, belted chest voice, wide vocal stack]
Worthy of every whisper turning into roar
Worthy of every shuttered door You kicked down before
King of the chaos, keeper of the calm
Holy forever — You are the psalm

[Verse 2: Fuller arrangement, lead more present]
I laid my weapons down inside a room I could not light
You didn't ask me to perform — You asked me to abide
Now the fear that used to own the hallway of my chest
Bows at the name I barely had the breath to confess

[Pre-Chorus: Vocal doubles enter, drums build]
You are before the question
You are after the cry
You are the only answer
That never learned to lie

[Chorus: Tom build, belted chest voice, wide vocal stack]
Worthy of every whisper turning into roar
Worthy of every shuttered door You kicked down before
King of the chaos, keeper of the calm
Holy forever — You are the psalm

[Bridge: Half-time, stripped to pad and lead]
I surrender the steering
I surrender the shame
I surrender every title
But the one You gave my name

[Vamp/Flow: Choir holds "Forever King" while lead ad-libs]
Forever King
Forever King
You were, You are, forever

[Final Chorus: Full band, key lift, max dynamics]
Worthy of every whisper turning into roar
Worthy of every shuttered door You kicked down before
King of the chaos, keeper of the calm
Holy forever — You are the psalm

[Outro: Ambient guitar fade, trailing pad]

[End]"""

_QUARTET_FEW_SHOT_GOOD = """\
GOOD (write in this style, end with [End]):

[Intro: Walking bass, driving rhythm guitar, 4-part male stack]

[Verse 1: Raspy lead, tight 4-part harmony, behind-the-beat pocket]
Trouble in my way — but I hear You say remember me
The road got steep and the night got long, but Your hand kept carrying me
I ain't got much but what I got is sure
Jesus on my side is the only wealth I need

[Chorus: Tight male quartet, call-and-response]
On my journey I won't walk alone
On my journey I won't walk alone
Fix it Jesus — make a way where there ain't no road
On my journey I won't walk alone

[Verse 2: Lead steps out, stack supports]
Devil tried to tell me my race was already run
But the same God who started me ain't forgot where I'm from
I may be limping but I'm still in the fight
Fix it Jesus — bring me through tonight

[Chorus: Tight male quartet, call-and-response]
On my journey I won't walk alone
On my journey I won't walk alone
Fix it Jesus — make a way where there ain't no road
On my journey I won't walk alone

[Bridge: Strip to bass and lead]
I don't need it easy
I just need it true
I don't need a crowd
I just need You

[Vamp/Flow: Lead ad-libs, quartet repeats "Fix it Jesus"]
Fix it Jesus
Fix it Jesus
Fix it Jesus
Make a way

[Final Chorus: Full quartet, driving groove, modulation]
On my journey I won't walk alone
On my journey I won't walk alone
Fix it Jesus — make a way where there ain't no road
On my journey I won't walk alone

[Outro: Bass and guitar fade]

[End]"""

_FEW_SHOT_GOOD: dict[str, str] = {
    PROFILE_AFRO_GOSPEL: _AFRO_GOSPEL_FEW_SHOT_GOOD,
    PROFILE_TRADITIONAL_URBAN: _URBAN_GOSPEL_FEW_SHOT_GOOD,
    PROFILE_GOSPEL_COUNTRY: _GOSPEL_COUNTRY_FEW_SHOT_GOOD,
    PROFILE_PRAISE_WORSHIP: _PRAISE_WORSHIP_FEW_SHOT_GOOD,
    PROFILE_TRADITIONAL_QUARTET: _QUARTET_FEW_SHOT_GOOD,
}

_PROFILE_LABELS = {
    PROFILE_AFRO_GOSPEL: "Afro-Gospel / Afrobeats Worship",
    PROFILE_TRADITIONAL_URBAN: "Traditional Gospel / Urban Contemporary",
    PROFILE_GOSPEL_COUNTRY: "Gospel Country / Southern Gospel",
    PROFILE_PRAISE_WORSHIP: "Praise & Worship / Inspirational",
    PROFILE_TRADITIONAL_QUARTET: "Traditional Quartet",
}

_DEFAULT_MOODS = {
    PROFILE_AFRO_GOSPEL: "Up-tempo, Joyful, Rhythmic",
    PROFILE_TRADITIONAL_URBAN: "High-energy, Communal, Triumphant",
    PROFILE_GOSPEL_COUNTRY: "Prayerful, Narrative, Earthy",
    PROFILE_PRAISE_WORSHIP: "Atmospheric, Vertical, Building",
    PROFILE_TRADITIONAL_QUARTET: "Driving, Blues-infused, Call-and-response",
}

_WORD_PATTERNS: dict[str, re.Pattern[str]] = {}


def _normalize_phrase(value: str) -> str:
    raw = value.lower()
    raw = re.sub(r"[-/]+", " ", raw)
    return re.sub(r"\s+", " ", raw).strip()


def _genre_blob(
    *,
    primary_genre: str = "",
    sub_genre_fusion: str = "",
    vibe: str = "",
    lyric_theme_notes: str = "",
) -> str:
    return _normalize_phrase(
        f"{primary_genre} {sub_genre_fusion} {vibe} {lyric_theme_notes}"
    )


def _has_word(blob: str, word: str) -> bool:
    key = _normalize_phrase(word)
    if not key:
        return False
    pattern = _WORD_PATTERNS.get(key)
    if pattern is None:
        pattern = re.compile(rf"\b{re.escape(key)}\b")
        _WORD_PATTERNS[key] = pattern
    return pattern.search(blob) is not None


def is_gospel_lane(
    *,
    primary_genre: str = "",
    sub_genre_fusion: str = "",
    vibe: str = "",
    lyric_theme_notes: str = "",
) -> bool:
    blob = _genre_blob(
        primary_genre=primary_genre,
        sub_genre_fusion=sub_genre_fusion,
        vibe=vibe,
        lyric_theme_notes=lyric_theme_notes,
    )
    if not blob:
        return False
    return any(_has_word(blob, marker) for marker in _GOSPEL_MARKERS)


def resolve_profile(
    *,
    primary_genre: str = "",
    sub_genre_fusion: str = "",
    vibe: str = "",
) -> str:
    blob = _genre_blob(
        primary_genre=primary_genre,
        sub_genre_fusion=sub_genre_fusion,
        vibe=vibe,
    )

    for tokens, profile in _PROFILE_RULES:
        if any(_has_word(blob, token) for token in tokens):
            return profile

    if _has_word(blob, "afro") and _has_word(blob, "gospel"):
        return PROFILE_AFRO_GOSPEL

    return PROFILE_TRADITIONAL_URBAN


def sub_genre_label(profile: str) -> str:
    return _PROFILE_LABELS.get(profile, "Gospel / Christian")


def _format_vocalist(vocal_spec: str, vocal_tone: str) -> str:
    s = vocal_spec.strip()
    t = vocal_tone.strip()
    if not s and not t:
        return "Genre-appropriate lead with choir support"
    if not s:
        return t
    if not t:
        return s
    return f"{s} — {t}"


def _default_mood_for_profile(profile: str) -> str:
    return _DEFAULT_MOODS.get(profile, "Spiritually heavy, Relatable")


def _few_shot_vocalist_for(profile: str) -> str:
    if profile == PROFILE_AFRO_GOSPEL:
        return (
            "Warm chest-register male lead with rhythmic call-and-response choir"
        )
    if profile == PROFILE_GOSPEL_COUNTRY:
        return "Female lead, close-mic storytelling tone"
    if profile == PROFILE_PRAISE_WORSHIP:
        return "Intimate verse whisper building to belted anthem chorus"
    if profile == PROFILE_TRADITIONAL_QUARTET:
        return "Raspy lead stepping out over tight 4-part male stack"
    return "Belted chest-register lead with stacked choir support"


def _few_shot_theme_fallbacks(
    *,
    profile: str,
    lyric_theme_notes: str,
    vibe: str,
) -> tuple[str, str]:
    notes = lyric_theme_notes.strip()
    theme_vibe = vibe.strip()

    if notes:
        return notes, theme_vibe

    if profile == PROFILE_AFRO_GOSPEL:
        notes = "Celebrating how God turned my story from sorrow to joy"
        if not theme_vibe:
            theme_vibe = "Up-tempo, Joyful, Rhythmic"
    elif profile == PROFILE_TRADITIONAL_URBAN:
        notes = "Testimony of deliverance from a trial I could not fix alone"
        if not theme_vibe:
            theme_vibe = "High-energy, Communal, Triumphant"
    elif profile == PROFILE_GOSPEL_COUNTRY:
        notes = "Gratitude for simple daily mercies"
        if not theme_vibe:
            theme_vibe = "Prayerful, Close-mic, Intimate"
    elif profile == PROFILE_PRAISE_WORSHIP:
        notes = "Surrender to God's presence in the middle of uncertainty"
        if not theme_vibe:
            theme_vibe = "Atmospheric, Vertical, Building"
    elif profile == PROFILE_TRADITIONAL_QUARTET:
        notes = "Running the race and asking God to remember me"
        if not theme_vibe:
            theme_vibe = "Driving, Blues-infused, Call-and-response"
    else:
        notes = "God's faithfulness in difficulty"

    return notes, theme_vibe


def compose_system_block(
    *,
    primary_genre: str = "",
    sub_genre_fusion: str = "",
    vibe: str = "",
    profile: str | None = None,
) -> str:
    p = profile or resolve_profile(
        primary_genre=primary_genre,
        sub_genre_fusion=sub_genre_fusion,
        vibe=vibe,
    )
    matrix = _SUB_GENRE_MATRIX.get(p, _SUB_GENRE_MATRIX[PROFILE_TRADITIONAL_URBAN])
    return "\n\n".join(
        (
            CROSS_ARCHITECTURE_RULES,
            MASTER_ROLE,
            matrix,
            UNIVERSAL_STRICT_RULES,
            PRE_OUTPUT_QA,
        )
    )


def build_user_selections_block(
    *,
    primary_genre: str = "",
    sub_genre_fusion: str = "",
    vibe: str = "",
    lyric_theme_notes: str = "",
    vocal_spec: str = "",
    vocal_tone: str = "",
    bpm_hint: str = "",
    profile: str | None = None,
) -> str:
    p = profile or resolve_profile(
        primary_genre=primary_genre,
        sub_genre_fusion=sub_genre_fusion,
        vibe=vibe,
    )
    mood = vibe.strip() or _default_mood_for_profile(p)
    label = sub_genre_label(p)
    vocalist = _format_vocalist(vocal_spec, vocal_tone)
    theme_block = directive_block(
        lyric_theme_notes=lyric_theme_notes,
        vibe=vibe,
    )
    lines = [
        "Write a song based on the following user selections:",
        f"- SUB-GENRE: {label}",
        f"- MOOD/VIBE: {mood}",
        f"- VOCALIST: {vocalist}",
    ]
    if bpm_hint.strip():
        lines.append(f"- BPM: {bpm_hint.strip()}")
    if theme_block:
        lines.append("")
        lines.append(theme_block)
    return "\n".join(lines)


def _few_shot_user_turn(
    *,
    profile: str,
    lyric_theme_notes: str = "",
    vibe: str = "",
) -> str:
    label = sub_genre_label(profile)
    mood = vibe.strip() or _default_mood_for_profile(profile)
    vocalist = _few_shot_vocalist_for(profile)
    theme_notes, theme_vibe = _few_shot_theme_fallbacks(
        profile=profile,
        lyric_theme_notes=lyric_theme_notes,
        vibe=vibe,
    )
    theme_block = directive_block(
        lyric_theme_notes=theme_notes,
        vibe=theme_vibe,
    )
    lines = [
        "Write a song based on the following user selections:",
        f"- SUB-GENRE: {label}",
        f"- MOOD/VIBE: {mood}",
        f"- VOCALIST: {vocalist}",
    ]
    if theme_block:
        lines.append("")
        lines.append(theme_block)
    return "\n".join(lines)


def master_gospel_user_block(
    *,
    primary_genre: str = "",
    sub_genre_fusion: str = "",
    vibe: str = "",
    lyric_theme_notes: str = "",
    vocal_spec: str = "",
    vocal_tone: str = "",
    bpm_hint: str = "",
) -> str:
    if not is_gospel_lane(
        primary_genre=primary_genre,
        sub_genre_fusion=sub_genre_fusion,
        vibe=vibe,
        lyric_theme_notes=lyric_theme_notes,
    ):
        return ""
    profile = resolve_profile(
        primary_genre=primary_genre,
        sub_genre_fusion=sub_genre_fusion,
        vibe=vibe,
    )
    system = compose_system_block(
        primary_genre=primary_genre,
        sub_genre_fusion=sub_genre_fusion,
        vibe=vibe,
        profile=profile,
    )
    user = build_user_selections_block(
        primary_genre=primary_genre,
        sub_genre_fusion=sub_genre_fusion,
        vibe=vibe,
        lyric_theme_notes=lyric_theme_notes,
        vocal_spec=vocal_spec,
        vocal_tone=vocal_tone,
        bpm_hint=bpm_hint,
        profile=profile,
    )
    return f"{system}\n\n{user}"


def few_shot_prefix_messages(
    *,
    primary_genre: str = "",
    sub_genre_fusion: str = "",
    vibe: str = "",
    lyric_theme_notes: str = "",
) -> list[dict[str, str]]:
    profile = resolve_profile(
        primary_genre=primary_genre,
        sub_genre_fusion=sub_genre_fusion,
        vibe=vibe,
    )
    user = _few_shot_user_turn(
        profile=profile,
        lyric_theme_notes=lyric_theme_notes,
        vibe=vibe,
    )
    assistant = _FEW_SHOT_GOOD.get(
        profile, _FEW_SHOT_GOOD[PROFILE_TRADITIONAL_URBAN]
    )
    return [
        {"role": "user", "content": user},
        {"role": "assistant", "content": assistant},
    ]
