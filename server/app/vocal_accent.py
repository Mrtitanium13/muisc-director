"""User-selected singer accent / regional delivery (style only — not voice cloning)."""



from __future__ import annotations



from dataclasses import dataclass



from app.dialect_style import is_nigerian_pidgin



ACCENT_VS_DIALECT_CONSTRAINT = (

    "ACCENT VS. DIALECT CONSTRAINT: When a regional accent or delivery style is specified, "

    "write lyrics in clear, standard English. You are strictly forbidden from translating "

    "text into slang, broken dialects, or patois (completely ban words like dey, na, wahala, "

    "gonna in lyric lines). Let vocal performance style remain purely phonetic in staging "

    "tags; the written lyric text must stay pristine, high-end, and universally legible."

)



REGIONAL_TAG_DEDUP_CONSTRAINT = (

    "ZERO REGIONAL TAG DUPLICATION: Regional delivery modifiers, vocal textures, or accent "

    "descriptors must appear once per section inside the single staging bracket — never "

    "repeat the same regional/accent phrase across consecutive brackets, section headers, "

    "or lyric lines. Block 1 carries primary vocal-accent prose; Block 2 tags reference "

    "delivery phonetically without re-stacking identical regional labels every section."

)





@dataclass(frozen=True)

class AccentOption:

    key: str

    label: str

    description: str

    top_level_label: str | None = None





ACCENT_OPTIONS: tuple[AccentOption, ...] = (

    AccentOption(

        key="american",

        label="American",

        description=(

            "polished vocal, bright EQ, vocal-forward mix, glossy doubles, warm chest lead, pop-radio sheen"

        ),

    ),

    AccentOption(

        key="british",

        label="British",

        description=(

            "dry room close-mic, jangly vocal, mid-Atlantic pop tone, restrained belt, minimal plate reverb"

        ),

    ),

    AccentOption(

        key="irish",

        label="Irish",

        description=(

            "warm room vocal, folk-leaning lead, intimate delivery, slight cadence lilt, sparse room"

        ),

    ),

    AccentOption(

        key="nigerian",

        label="Lagos / Standard",

        top_level_label="Nigerian",

        description=(

            "Afrobeats vocal pocket, Lagos pop mix, warm midrange, conversational cadence, "

            "Yoruba-staccato undertone, syncopated vowel pacing, glossy vocal-forward mix"

        ),

    ),

    AccentOption(

        key="nigerian_rivers_state",

        label="Rivers State (Harbour Pidgin)",

        description=(

            "hard consonant treatment, clipped syllable endings, tight rhythmic pocket, Niger Delta rap tone, "

            "Harbour Pidgin pacing, vocal-forward gritty mix, fast consonant-to-consonant transitions, "

            "minimal vowel elongation, oil-city delivery weight"

        ),

    ),

    AccentOption(

        key="nigerian_igbo",

        label="Igbo Pidgin",

        description=(

            "tonal percussive delivery, sharp pitch contours on vowels, Igbo Pidgin cadence, staccato vocal pocket, "

            "percussive consonants, Eastern highlife warmth, vocal-forward mix with tight midrange presence, "

            "pitch-rise phrase endings, rhythmic consonant clusters"

        ),

    ),

    AccentOption(

        key="nigerian_ibibio",

        label="Ibibio / Akwa Ibom State (Recommended)",

        description=(

            "triplet-feel vocal pocket, Cross-river coastal cadence, soft consonant treatment, melodic terminal rise, "

            "open vowel phrasing, maritime lyrical swing, flowing triplet flow, Akwa Ibom vocal warmth, "

            "musical terminal elongation, Cross-river melodic lilt, breathy close-mic intimacy on verses, "

            "rising intonation on statement endings, Ibibio cadence signature"

        ),

    ),

    AccentOption(

        key="west_african",

        label="West African",

        description=(

            "syncopated vocal pocket, call-and-response texture, coastal pop mix, rhythmic lead"

        ),

    ),

    AccentOption(

        key="south_african",

        label="South African",

        description=(

            "Amapiano vocal stack, chantable delivery, warm log-drum-friendly pocket, wide harmonies"

        ),

    ),

    AccentOption(

        key="australian",

        label="Australian",

        description=(

            "dry-room close-mic, relaxed indie vocal, warm lead, laid-back belt, minimal verb"

        ),

    ),

    AccentOption(

        key="canadian",

        label="Canadian",

        description=(

            "polished vocal, soft consonants, vocal-forward, bright mix, warm chest lead"

        ),

    ),

    AccentOption(

        key="caribbean",

        label="Caribbean",

        description=(

            "Dancehall vocal pocket, sharp consonants, rhythmic lead, reverb tails, dub-friendly space"

        ),

    ),

    AccentOption(

        key="latin_american",

        label="Latin American",

        description=(

            "warm intimate vocal, Spanish consonant treatment, breathy belt, close-mic, romantic sheen"

        ),

    ),

)



_LAYER1_DESCRIPTORS: dict[str, str] = {opt.key: opt.description for opt in ACCENT_OPTIONS}



_LEGACY_KEY_ALIASES: dict[str, str] = {

    "West African (Nigeria)": "nigerian",

    "West African (Ghana)": "west_african",

    "West African (general)": "west_african",

    "Caribbean": "caribbean",

    "American (General)": "american",

    "American (Southern)": "american",

    "British (England)": "british",

    "Scottish": "british",

    "Irish": "irish",

    "Australian / New Zealand": "australian",

    "Indian English": "american",

    "French English": "british",

    "Spanish / Latin American English": "latin_american",

    "South African English": "south_african",

    "East African (general)": "west_african",

}





def canonical_accent_key(accent: str) -> str:

    a = (accent or "").strip()

    if not a:

        return ""

    if a in _LAYER1_DESCRIPTORS:

        return a

    return _LEGACY_KEY_ALIASES.get(a, "")





def layer1_descriptor_for(accent: str) -> str:

    key = canonical_accent_key(accent)

    if not key:

        return ""

    return _LAYER1_DESCRIPTORS.get(key, "")





def vocal_accent_user_block(

    accent: str,

    *,

    vocal_spec: str = "",

    language: str = "English",

    dialect_style_id: str = "",

) -> str:

    """Strong runtime directive when user picks an accent in the prompt form."""

    key = canonical_accent_key(accent)

    if not key:

        return ""

    spec = (vocal_spec or "").strip()

    lang = (language or "English").strip() or "English"

    spec_line = f"\n- Lead vocal type: {spec}" if spec else ""

    pidgin = is_nigerian_pidgin(dialect_style_id)

    descriptors = layer1_descriptor_for(accent)

    lyric_line = (

        "- Block 2 lyrics: Nigerian Pidgin dialect active — use Layer 2 sub-variant vocabulary "

        "from STAGING AND ACCENT RULES (Section B) when accent is nigerian_*; never Lagos-default Pidgin when "

        "a sub-variant is selected."

        if pidgin

        else "- Block 2 lyrics: English only — accent is production delivery via Layer 1 descriptors "

        "in staging, NOT nationality adjectives or raw accent labels in brackets."

    )

    return (

        "VOCAL ACCENT / DELIVERY (USER-SELECTED — NON-NEGOTIABLE):\n"

        f"- user_selected_accent: {key}\n"

        "- STAGING AND ACCENT RULES — Section B (mandatory): inject Layer 1 descriptor set below into Block 1 "

        "vocal prose and Block 2 staging brackets. **BANNED:** raw forms like "

        '"American vocal", "British delivery", "Nigerian breath", "Ibibio stack".\n'

        f"- Layer 1 descriptor set: {descriptors}\n"

        f"- Language context: {lang}{spec_line}\n"

        "- Block 1: Weave the Layer 1 descriptor set into vocal production prose "

        "(style/delivery only — never impersonate a real person).\n"

        "- Block 2 staging: Use ONLY the Layer 1 descriptor tokens in section staging "

        "brackets — never duplicate nationality labels per section.\n"

        f"{lyric_line}\n"

        "- Preserve singability; accent is delivery style, not a dialect caricature."

    )





def accent_vs_dialect_constraint_line(

    *,

    vocal_accent: str,

    dialect_style_id: str = "",

) -> str:

    """Stage 3 hard rule when accent is set but lyric dialect is standard English."""

    if not canonical_accent_key(vocal_accent):

        return ""

    if is_nigerian_pidgin(dialect_style_id):

        return ""

    return ACCENT_VS_DIALECT_CONSTRAINT





def regional_tag_deduplication_line(

    *,

    vocal_accent: str = "",

    dialect_style_id: str = "",

) -> str:

    """Stage 5 hard rule when regional delivery is in play."""

    if not canonical_accent_key(vocal_accent) and not is_nigerian_pidgin(dialect_style_id):

        return ""

    return REGIONAL_TAG_DEDUP_CONSTRAINT





def vocal_accent_post_process_context_line(

    accent: str,

    *,

    dialect_style_id: str = "",

) -> str:

    key = canonical_accent_key(accent)

    if not key:

        return ""

    if is_nigerian_pidgin(dialect_style_id):

        return f"VOCAL ACCENT (Layer 1 descriptors only): {key} — lyric dialect is Nigerian Pidgin."

    return f"VOCAL ACCENT (Layer 1 descriptors only — lyrics stay standard English): {key}"





def accent_vs_dialect_compact_line(

    *,

    vocal_accent: str,

    dialect_style_id: str = "",

) -> str:

    if not canonical_accent_key(vocal_accent) or is_nigerian_pidgin(dialect_style_id):

        return ""

    return "RULE:accent-only|lyrics=standard English|no dey/na/wahala in lines"





def regional_tag_deduplication_compact_line(

    *,

    vocal_accent: str = "",

    dialect_style_id: str = "",

) -> str:

    if not canonical_accent_key(vocal_accent) and not is_nigerian_pidgin(dialect_style_id):

        return ""

    return "RULE:regional-tag-once|layer1-descriptors-once-per-section"





def vocal_accent_post_process_compact_line(

    accent: str,

    *,

    dialect_style_id: str = "",

) -> str:

    key = canonical_accent_key(accent)

    if not key:

        return ""

    if is_nigerian_pidgin(dialect_style_id):

        return f"ACCENT:{key}|layer1-descriptors-only|lyrics=Pidgin"

    return f"ACCENT:{key}|layer1-descriptors-only|lyrics=standard English"


