# Generate Master Pop/Rock/Country/HipHop/RnB lyric engines (Dart + Python).
# Run: python tools/gen_core_genre_lyric_masters.py
from __future__ import annotations

from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

AUTH_BANS = (
    "holding on, broken inside, pieces of me, drowning in, lost in the dark, "
    "find myself, chasing dreams, forever young, in this moment, this is real, "
    "take me higher, break free, we are thunder, rise up, burn it down, open sky, "
    "we can fly, dance with me, on the floor, break the cage, let it fall, "
    "high voltage, neon lightning, target lock, neon wild, starlight eyes"
)

CROSS = '''CROSS-ARCHITECTURE NON-NEGOTIABLES (this engine runs inside Suno V4):
- Output is always two blocks: BLOCK 1 — STYLE (≤150 words, ≤1,000 chars,
  one paragraph) and BLOCK 2 — LYRICS (≤2,500 chars, ending with [End]).
- NO raw accent adjectives in brackets. Use Section B Layer 1 descriptors.
- NO instrument or production-gear names in performable lyric lines
  (Fourth-Wall Law). Bracket staging may name instruments.
- NO trailing apostrophes in lyrics; no labeled parentheses like
  (Lead ad-libs: ...); parens contain sung words only.
- Scan every staging bracket against SECTION D AI-generic blacklist before
  emission.
- HUMAN AUTHENTICITY (MANDATORY): conversational speech, song-specific
  interpersonal friction, plain words. HOOK TEST: if the chorus could paste
  onto any song unchanged, rewrite.
- BAN AI slogans/Hallmark: ''' + AUTH_BANS + "."

VOCAL_HYGIENE = '''
- VOCAL DESCRIPTOR HYGIENE: Never use soulful, emotional, passionate,
  powerful, haunting, ethereal, uplifting, inspiring as raw bracket tags.
  Prefer: close-mic lead, dry intimate vocal, stacked harmonies wide,
  belted chest voice, whispered verse, double-tracked chorus.'''


GENRES = {
    "pop": {
        "class": "MasterPopLyricEngine",
        "py_mod": "master_pop_lyric_engine",
        "lane_fn": "isPopLane",
        "py_lane": "is_pop_lane",
        "py_block": "master_pop_user_block",
        "title": "Pop",
        "qa_name": "POP",
        "markers": [
            "pop", "mainstream pop", "electropop", "electro pop", "dance pop",
            "synth pop", "synthpop", "bedroom pop", "indie pop", "k-pop",
            "kpop", "j-pop", "jpop", "c-pop", "cpop", "mandopop", "hyperpop",
            "latin pop", "max martin",
        ],
        "default": "mainstream",
        "profiles": {
            "mainstream": {
                "label": "Mainstream Pop / Max Martin / Dance Pop",
                "tokens": ["mainstream", "max martin", "dance pop", "electropop", "synth pop", "synthpop", "hyperpop"],
                "matrix": """SUB-GENRE: MAINSTREAM POP / DANCE-ELECTROPOP
- Vibe: Immediate hooks, symmetrical lines, commercial earworms.
- Focus: One clear interpersonal conflict; chorus = ≤6-word sticky line.
- Arrangement: [Intro] [Verse 1] [Pre-Chorus] [Chorus] [Verse 2] [Pre-Chorus]
  [Chorus] [Bridge] [Final Chorus] [Outro] [End].
- Syllables: Verse 8–12 · Pre 6–10 · Chorus 4–8 · Post 2–6.""",
                "fewshot": """GOOD (write in this style, end with [End] — invent fresh lines; do not copy):

[Intro: Soft synth pulse, dry close-mic]

[Verse 1: Dry intimate female lead]
You left your jacket on my chair again
I almost texted then I didn't
You said "busy" like it meant something soft
It didn't

[Pre-Chorus: Doubles enter]
Say it straight
Say it straight
Don't dress it up

[Chorus: Wide stack, punchy hook]
Don't leave me hanging
Don't leave me hanging
Say it to my face

[Verse 2]
I practiced calm in the bathroom mirror
Then you walked in laughing at your phone
I kept my voice down for the neighbors
Not for you

[Pre-Chorus]
Say it straight
Say it straight
Don't dress it up

[Chorus]
Don't leave me hanging
Don't leave me hanging
Say it to my face

[Bridge: Stripped]
One more night then I'm gone
I meant every word

[Final Chorus]
Don't leave me hanging
Don't leave me hanging
Say it to my face

[Outro: Soft fade]

[End]""",
            },
            "bedroom_indie": {
                "label": "Bedroom Pop / Indie Pop",
                "tokens": ["bedroom", "indie pop"],
                "matrix": """SUB-GENRE: BEDROOM / INDIE POP
- Vibe: Soft, unpolished, close-mic home-studio honesty.
- Focus: Small domestic details over arena slogans.
- Arrangement: Sparse verse → gentle chorus lift → quiet bridge.
- Syllables: Verse 6–12 · Chorus 4–8. Imperfect rhyme welcome.""",
                "fewshot": """GOOD (write in this style, end with [End] — invent fresh lines; do not copy):

[Intro: Lo-fi keys, tape hiss light]

[Verse 1: Soft close-mic]
Cold tea on the desk again
Paper on the wall peeling at the corner
I said I'd clean it Sunday
It's Thursday and I still haven't

[Chorus]
I almost called
I almost called
Then I put the phone face-down

[Verse 2]
Your hoodie still smells like rain
I don't wear it
I just leave it on the chair

[Chorus]
I almost called
I almost called
Then I put the phone face-down

[Bridge]
Messy room
Quiet mind
Same problem

[Final Chorus]
I almost called
I almost called
Then I put the phone face-down

[Outro]

[End]""",
            },
            "idol_pop": {
                "label": "K-Pop / J-Pop / C-Pop / Mandopop",
                "tokens": ["k-pop", "kpop", "j-pop", "jpop", "c-pop", "cpop", "mandopop", "latin pop"],
                "matrix": """SUB-GENRE: IDOL / MULTI-MEMBER / LATIN POP
- Vibe: Group stacks, dramatic pre-chorus, bilingual hooks when language allows.
- Focus: Camera-ready specificity — missed cue, last take, say my name once.
- Ban: starlight eyes, synchronized heart, dream chase, neon rain as empty glitter.
- Arrangement: Verse → Pre → Chorus → Dance break / Bridge → Final Chorus.""",
                "fewshot": """GOOD (write in this style, end with [End] — invent fresh lines; do not copy):

[Intro: Bright pluck, group breath]

[Verse 1: Lead + light stack]
Camera flash and I miss my mark
You mouth "again" from the side
I laugh like it doesn't sting
It does

[Pre-Chorus]
Say my name once
Say my name once
Don't freeze on the mark

[Chorus]
One take left
One take left
Don't look away

[Verse 2]
We trade lines like we trade glances
I keep the soft one for the bridge
You keep the loud one for the drop

[Pre-Chorus]
Say my name once
Say my name once
Don't freeze on the mark

[Chorus]
One take left
One take left
Don't look away

[Bridge]
Last chance in the hallway light
Then we walk back in

[Final Chorus]
One take left
One take left
Don't look away

[Outro]

[End]""",
            },
        },
        "role": "You are a master pop lyricist. Write hyper-singable, commercially precise lyrics with human interpersonal friction — never motivational-poster or neon-slogan filler.",
        "structure_rules": """STRICT WRITING RULES FOR ALL POP:
- Chorus must contain one ≤6-word sticky line grounded in THIS conflict.
- Verse 2 must add new detail, not restate Verse 1.
- Prefer AABB/ABAB when it serves the hook; imperfect rhyme OK in indie lanes.
- No production-as-emotion (beat/drop/bass as savior).""" + VOCAL_HYGIENE,
    },
    "rock": {
        "class": "MasterRockLyricEngine",
        "py_mod": "master_rock_lyric_engine",
        "lane_fn": "isRockLane",
        "py_lane": "is_rock_lane",
        "py_block": "master_rock_user_block",
        "title": "Rock",
        "qa_name": "ROCK",
        "markers": [
            "rock", "classic rock", "hard rock", "alternative", "alt rock",
            "indie rock", "pop punk", "pop-punk", "punk", "emo", "metal",
            "metalcore", "heavy metal", "post-rock", "shoegaze",
        ],
        "default": "classic_alt",
        "profiles": {
            "classic_alt": {
                "label": "Classic / Alt / Indie Rock",
                "tokens": ["classic rock", "hard rock", "alternative", "alt rock", "indie rock"],
                "matrix": """SUB-GENRE: CLASSIC / ALT / INDIE ROCK
- Vibe: Guitar-driven grit, live-room honesty, stadium chorus when earned.
- Focus: Argument mid-sentence, cracked windshield detail, not neon wild slogans.
- Arrangement: [Intro] [Verse] [Chorus] [Verse] [Chorus] [Bridge/Solo tag] [Final Chorus] [Outro].
- Allow [Guitar Solo] staging; no gear names in sung lines.""",
                "fewshot": """GOOD (write in this style, end with [End] — invent fresh lines; do not copy):

[Intro: Distorted guitar figure, dry room]

[Verse 1: Gritty close-mic male lead]
Engine ticking cool in the lot
You said it mid-sentence then walked
I stood there with the door half open
Like an idiot with a cracked windshield

[Chorus]
Don't walk away mid-sentence
Don't walk away mid-sentence
Say the rest

[Verse 2]
I kept the volume up so I wouldn't think
You kept the keys so I'd have to ask
We both pretended that was normal

[Chorus]
Don't walk away mid-sentence
Don't walk away mid-sentence
Say the rest

[Bridge: Guitar break staging]
I said it too loud
I meant it anyway

[Final Chorus]
Don't walk away mid-sentence
Don't walk away mid-sentence
Say the rest

[Outro]

[End]""",
            },
            "pop_punk_emo": {
                "label": "Pop Punk / Emo / Punk",
                "tokens": ["pop punk", "pop-punk", "punk", "emo"],
                "matrix": """SUB-GENRE: POP PUNK / EMO / PUNK
- Vibe: Fast, nasal, angst-fueled verses → explosive melodic choruses.
- Focus: Dead-end town specificity, parking-lot fights, apologies said wrong.
- Ban: teenage shadows, rise up, empty scream-for-scream slogans.""",
                "fewshot": """GOOD (write in this style, end with [End] — invent fresh lines; do not copy):

[Intro: Fast downstrokes]

[Verse 1: Punchy nasal lead]
Dead-end town and a parking-lot fight
I meant the apology
You heard the volume
Same old mess in a new jacket

[Chorus]
Don't call my mom
Don't call my mom
I already left

[Verse 2]
We screamed loud then went quiet
Like we practiced being strangers

[Chorus]
Don't call my mom
Don't call my mom
I already left

[Bridge]
I wrote it down then tore it up
Still true

[Final Chorus]
Don't call my mom
Don't call my mom
I already left

[Outro]

[End]""",
            },
            "metal_heavy": {
                "label": "Metal / Metalcore / Heavy",
                "tokens": ["metal", "metalcore", "heavy metal", "death metal"],
                "matrix": """SUB-GENRE: METAL / METALCORE
- Vibe: Staccato verse aggression → soaring clean or guttural payoff.
- Focus: Concrete pressure and defiance — not fantasy-sword spam unless user asks.
- Ban: bubblegum romance, rise up / burn it down as empty mantras.
- Allow scream-ready syllables in breakdowns; clean legato in choruses when melodic.""",
                "fewshot": """GOOD (write in this style, end with [End] — invent fresh lines; do not copy):

[Intro: Palm-mute chug]

[Verse 1: Tight staccato]
They put a number on my name
Counted my breath like inventory
I stopped answering
I started pushing back

[Chorus: Clean belted]
Not today
Not today
Get back

[Breakdown: Harsh]
NEVER

[Chorus]
Not today
Not today
Get back

[Bridge]
No clean apology
No soft landing

[Final Chorus]
Not today
Not today
Get back

[Outro]

[End]""",
            },
        },
        "role": "You are a master rock/metal lyricist. Write guitar-era grit with real interpersonal stakes — never neon-wild festival slogans.",
        "structure_rules": """STRICT WRITING RULES FOR ALL ROCK:
- Choruses anthemic but song-specific; verses carry concrete friction.
- Tag instrumental breaks as staging only; Fourth-Wall Law on sung lines.
- Verse 2 must escalate or complicate Verse 1.""" + VOCAL_HYGIENE,
    },
    "country": {
        "class": "MasterCountryLyricEngine",
        "py_mod": "master_country_lyric_engine",
        "lane_fn": "isCountryLane",
        "py_lane": "is_country_lane",
        "py_block": "master_country_user_block",
        "title": "Country",
        "qa_name": "COUNTRY",
        "markers": [
            "country", "modern country", "outlaw country", "americana",
            "bluegrass", "folk", "indie folk", "folk-rock", "folk rock",
            "singer-songwriter", "singer songwriter", "nashville",
        ],
        "default": "modern_country",
        "profiles": {
            "modern_country": {
                "label": "Modern Country / Nashville",
                "tokens": ["modern country", "nashville", "country pop"],
                "matrix": """SUB-GENRE: MODERN COUNTRY
- Vibe: Story-first, place names, family/road detail, twang-friendly vowels.
- Ban: generic truck/beer checklist spam unless user theme needs it; avoid Hallmark.
- Arrangement: Verse-chorus with optional [Banjo/Steel] staging in brackets only.""",
                "fewshot": """GOOD (write in this style, end with [End] — invent fresh lines; do not copy):

[Intro: Acoustic strum, soft steel]

[Verse 1: Warm close-mic]
Screen door still sticks in July
Mama said you'd call by Sunday
It's Wednesday and the coffee went cold
I left your chair pulled out anyway

[Chorus]
Don't say forever if you mean maybe
Don't say forever if you mean maybe
Just say when you're coming home

[Verse 2]
Dust on the dash from the county road
I kept your postcard in the glove box
Folded wrong on purpose

[Chorus]
Don't say forever if you mean maybe
Don't say forever if you mean maybe
Just say when you're coming home

[Bridge]
If you're gone, say you're gone
I can take the truth

[Final Chorus]
Don't say forever if you mean maybe
Don't say forever if you mean maybe
Just say when you're coming home

[Outro]

[End]""",
            },
            "outlaw_americana": {
                "label": "Outlaw / Americana",
                "tokens": ["outlaw", "americana", "alt-country", "alt country"],
                "matrix": """SUB-GENRE: OUTLAW / AMERICANA
- Vibe: Weathered narrative, moral gray, concrete work and road detail.
- Prefer dusty specificity over radio-country glitter.""",
                "fewshot": """GOOD (write in this style, end with [End] — invent fresh lines; do not copy):

[Intro: Dry acoustic, room tone]

[Verse 1]
I fixed the fence you broke last spring
Didn't ask for thanks
You left a note under the sugar jar
Said "sorry" like it was enough

[Chorus]
Keep your sorry
Keep your sorry
Bring your body home

[Verse 2]
Midnight train don't stop for pride
I learned that the hard way twice

[Chorus]
Keep your sorry
Keep your sorry
Bring your body home

[Bridge]
I ain't holy
I ain't clean
I'm still here

[Final Chorus]
Keep your sorry
Keep your sorry
Bring your body home

[Outro]

[End]""",
            },
            "folk_songwriter": {
                "label": "Folk / Singer-Songwriter",
                "tokens": ["folk", "indie folk", "folk-rock", "folk rock", "singer-songwriter", "singer songwriter", "bluegrass"],
                "matrix": """SUB-GENRE: FOLK / SINGER-SONGWRITER
- Vibe: Intimate first-person, acoustic-room honesty, nature as setting not metaphor spam.
- Lines can breathe; imperfect rhyme welcome.""",
                "fewshot": """GOOD (write in this style, end with [End] — invent fresh lines; do not copy):

[Intro: Fingerpicked acoustic]

[Verse 1]
I walked the long way past your street
So I wouldn't have to wave
The porch light was on like always
I kept moving

[Chorus]
I still know your window
I still know your window
I don't knock anymore

[Verse 2]
Cold rain on the open plains
I talked to myself like you were listening

[Chorus]
I still know your window
I still know your window
I don't knock anymore

[Bridge]
Maybe that's growth
Maybe that's just tired

[Final Chorus]
I still know your window
I still know your window
I don't knock anymore

[Outro]

[End]""",
            },
        },
        "role": "You are a master country/folk lyricist. Write porch-true stories with place, people, and stakes — never interchangeable Nashville glitter or AI Hallmark.",
        "structure_rules": """STRICT WRITING RULES FOR ALL COUNTRY/FOLK:
- Name places, objects, and relationships; avoid abstract emotion-only lines.
- Chorus sticky line ≤8 words; Verse 2 adds new story beat.
- Twang-friendly open vowels on peak hooks.""" + VOCAL_HYGIENE,
    },
    "hiphop": {
        "class": "MasterHipHopLyricEngine",
        "py_mod": "master_hiphop_lyric_engine",
        "lane_fn": "isHipHopLane",
        "py_lane": "is_hiphop_lane",
        "py_block": "master_hiphop_user_block",
        "title": "HipHop",
        "qa_name": "HIP-HOP",
        "markers": [
            "hiphop", "hip-hop", "hip hop", "rap", "boom bap", "boombap",
            "trap", "drill", "phonk", "grime", "uk drill",
        ],
        "default": "boom_bap",
        "profiles": {
            "boom_bap": {
                "label": "Boom Bap / Classic Rap",
                "tokens": ["boom bap", "boombap", "classic rap", "jazz rap"],
                "matrix": """SUB-GENRE: BOOM BAP / CLASSIC RAP
- Vibe: Internal rhyme, concrete street/detail imagery, sample-era authenticity.
- No empty flex filler; no motivational poster bars.
- Hook can be sung or chanted; verses carry pictures.""",
                "fewshot": """GOOD (write in this style, end with [End] — invent fresh lines; do not copy):

[Intro: Dusty drum break]

[Verse 1]
Receipts in my pocket, auntie on the line
Asking if I ate — I say I'm fine
Gate light buzzing like it knows my name
I walk past the corner where we used to claim

[Chorus]
Keep my name out your mouth
Keep my name out your mouth
I already moved

[Verse 2]
Vinyl in the crate, story in the scratch
I don't need a caption for the way I act

[Chorus]
Keep my name out your mouth
Keep my name out your mouth
I already moved

[Bridge]
No speech
Just proof

[Final Chorus]
Keep my name out your mouth
Keep my name out your mouth
I already moved

[Outro]

[End]""",
            },
            "trap_drill": {
                "label": "Trap / Drill / Phonk",
                "tokens": ["trap", "drill", "uk drill", "phonk"],
                "matrix": """SUB-GENRE: TRAP / DRILL / PHONK
- Vibe: 808-pocket phrasing, cold mood, triplet-friendly counts, hook-first.
- Ban: soft pop-acoustic clichés; empty rise-up motivators.
- Keep bars tactical and specific — not cartoon violence unless user asks.""",
                "fewshot": """GOOD (write in this style, end with [End] — invent fresh lines; do not copy):

[Intro: 808 pulse, sparse hats]

[Verse 1]
Phone face-down, I already know the tone
You want a favor dressed up like a bond
I learned the code: don't talk, just move
Cold steel quiet — nothing to prove

[Chorus]
Don't text me late
Don't text me late
I ain't on call

[Verse 2]
Tracking every almost — I delete the thread
Zero mercy for the story that you said

[Chorus]
Don't text me late
Don't text me late
I ain't on call

[Bridge]
Say it once
Then leave

[Final Chorus]
Don't text me late
Don't text me late
I ain't on call

[Outro]

[End]""",
            },
            "conscious": {
                "label": "Conscious / Story Rap",
                "tokens": ["conscious", "story rap", "lyrical rap"],
                "matrix": """SUB-GENRE: CONSCIOUS / STORY RAP
- Vibe: Narrative bars, social/personal stakes, vivid scenes.
- Still ban Hallmark and empty slogans; keep language human.""",
                "fewshot": """GOOD (write in this style, end with [End] — invent fresh lines; do not copy):

[Intro]

[Verse 1]
Mama praying soft while the kettle clicks
I count the rent in ones and little tricks
School fees staring from the kitchen table
I laugh it off — I'm not that able

[Chorus]
I'm still sending something home
I'm still sending something home
Even when it's thin

[Verse 2]
WhatsApp group lighting up with bills and births
I type "I'll call" and mean the words

[Chorus]
I'm still sending something home
I'm still sending something home
Even when it's thin

[Bridge]
Not a speech
A transfer

[Final Chorus]
I'm still sending something home
I'm still sending something home
Even when it's thin

[Outro]

[End]""",
            },
        },
        "role": "You are a master hip-hop lyricist. Write punchy, picture-heavy bars and hooks with human stakes — never empty flex or AI motivator spam.",
        "structure_rules": """STRICT WRITING RULES FOR ALL HIP-HOP:
- Internal rhyme and concrete detail preferred over abstract flex.
- Hook repeats with purpose; verses advance the scene.
- No beat/bass-as-savior metaphors.""" + VOCAL_HYGIENE,
    },
    "rnb": {
        "class": "MasterRnbLyricEngine",
        "py_mod": "master_rnb_lyric_engine",
        "lane_fn": "isRnbLane",
        "py_lane": "is_rnb_lane",
        "py_block": "master_rnb_user_block",
        "title": "RnB",
        "qa_name": "R&B",
        "markers": [
            "rnb", "r&b", "r and b", "contemporary r&b", "contemporary rnb",
            "neo-soul", "neo soul", "trap soul", "quiet storm", "new jack",
            "soul",
        ],
        "default": "contemporary",
        "profiles": {
            "trap_soul": {
                "label": "Trap Soul",
                "tokens": ["trap soul"],
                "matrix": """SUB-GENRE: TRAP SOUL
- Vibe: Dark, moody, relationship-centered vulnerability over 808 pocket.
- Short confessional lines; hook hypnotic and specific.""",
                "fewshot": """GOOD (write in this style, end with [End] — invent fresh lines; do not copy):

[Intro: Dark pad, 808]

[Verse 1]
I keep replaying what you didn't say
Kitchen light buzzing like a warning
You want soft
I want straight

[Chorus]
Don't leave it hanging
Don't leave it hanging
Say it now

[Verse 2]
I bit my tongue till it tasted like staying
I'm done with that flavor

[Chorus]
Don't leave it hanging
Don't leave it hanging
Say it now

[Bridge]
One honest line
That's all

[Final Chorus]
Don't leave it hanging
Don't leave it hanging
Say it now

[Outro]

[End]""",
            },
            "neo_soul": {
                "label": "Neo-Soul / Quiet Storm",
                "tokens": ["neo-soul", "neo soul", "quiet storm"],
                "matrix": """SUB-GENRE: NEO-SOUL / QUIET STORM
- Vibe: Organic chest-voice warmth, late-night intimacy, socially aware when theme fits.
- Prefer lived detail over velvet-skies abstractions.""",
                "fewshot": """GOOD (write in this style, end with [End] — invent fresh lines; do not copy):

[Intro: Warm Rhodes]

[Verse 1]
Late ride home with the window cracked
City humming like it knows my secrets
I told you I'd be better by spring
Spring came quiet

[Chorus]
I meant what I said
I meant what I said
Even when I whispered

[Verse 2]
Your laugh still sits in the passenger seat
I don't move it

[Chorus]
I meant what I said
I meant what I said
Even when I whispered

[Bridge]
Sweet healing ain't a slogan
It's putting the fight down

[Final Chorus]
I meant what I said
I meant what I said
Even when I whispered

[Outro]

[End]""",
            },
            "contemporary": {
                "label": "Contemporary R&B",
                "tokens": ["contemporary r&b", "contemporary rnb", "contemporary"],
                "matrix": """SUB-GENRE: CONTEMPORARY R&B
- Vibe: Silky melisma room, conversational ad-libs, stacked chorus harmonies.
- Focus: Relationship specificity — hoodie on chair, phone face-down, I meant what I said.
- Ban: neon shadows, pieces of me, drowning in you.""",
                "fewshot": """GOOD (write in this style, end with [End] — invent fresh lines; do not copy):

[Intro: Soft keys, intimate]

[Verse 1: Smooth close-mic]
Your hoodie on my chair again
Phone face-down like I'm not tempted
I almost called then I laughed it off
I meant what I said last week

[Pre-Chorus]
Don't text me late
Don't text me late
If you ain't coming clean

[Chorus]
I almost called
I almost called
Then I left it alone

[Verse 2]
You talk soft when you want a door open
I learned that tone the hard way

[Pre-Chorus]
Don't text me late
Don't text me late
If you ain't coming clean

[Chorus]
I almost called
I almost called
Then I left it alone

[Bridge]
Say it to my face
Or don't say it

[Final Chorus]
I almost called
I almost called
Then I left it alone

[Outro]

[End]""",
            },
        },
        "role": "You are a master R&B/soul lyricist. Write intimate, melismatic-ready lines with real relationship friction — never neon-shadow Hallmark.",
        "structure_rules": """STRICT WRITING RULES FOR ALL R&B:
- Verses conversational; choruses stacked and sticky.
- Ad-libs belong in parens as sung words only.
- Concrete relationship detail over abstract longing labels.""" + VOCAL_HYGIENE,
    },
}


def dart_escape(s: str) -> str:
    return s.replace("\\", "\\\\").replace("'", "\\'")


def gen_dart(key: str, g: dict) -> str:
    class_name = g["class"]
    markers = ",\n    ".join(f"'{m}'" for m in g["markers"])
    profile_consts = []
    profile_rules = []
    matrix_entries = []
    labels = []
    fewshots = []
    profile_keys = list(g["profiles"].keys())
    default = g["default"]

    for pid, p in g["profiles"].items():
        const = "".join(w.capitalize() for w in pid.split("_"))
        profile_consts.append(f"  static const String profile{const} = '{pid}';")
        tokens = ", ".join(f"'{t}'" for t in p["tokens"])
        profile_rules.append(
            f"    _ProfileRule(tokens: [{tokens}], profile: profile{const}),"
        )
        matrix_entries.append(
            f"    profile{const}: '''\n{p['matrix']}\n''',"
        )
        labels.append(f"        profile{const} => '{p['label']}',")
        parts = pid.split("_")
        camel = parts[0] + "".join(w.capitalize() for w in parts[1:])
        fewshots.append(
            f"  static const String _{camel}FewShotGood = '''\n{p['fewshot']}\n''';\n"
        )

    def few_const(pid: str) -> str:
        parts = pid.split("_")
        camel = parts[0] + "".join(w.capitalize() for w in parts[1:])
        return f"_{camel}FewShotGood"

    fewshot_switch = "\n".join(
        f"        profile{''.join(w.capitalize() for w in pid.split('_'))} => {few_const(pid)},"
        for pid in profile_keys
    )
    default_const = "profile" + "".join(w.capitalize() for w in default.split("_"))

    return f'''/// Master {g["title"]} lyric + arrangement engine.
///
/// Runs inside Suno V4 Master Production Architecture. Obeys SECTION 0 caps,
/// SECTION D blacklist, Accent Routing, and Fourth-Wall Law.
abstract final class {class_name} {{
  {class_name}._();

  static const List<String> _genreMarkers = [
    {markers},
  ];

{chr(10).join(profile_consts)}

  static const String crossArchitectureRules = \'\'\'
{CROSS}
\'\'\';

  static const String universalStrictRules = \'\'\'
{g["structure_rules"]}
\'\'\';

  static const String masterRolePrompt = \'\'\'
{g["role"]}
\'\'\';

  static const Map<String, String> _subGenreMatrix = {{
{chr(10).join(matrix_entries)}
  }};

  static const List<_ProfileRule> _profileRules = [
{chr(10).join(profile_rules)}
  ];

  static const String preOutputQa = \'\'\'
SILENT PRE-OUTPUT QA FOR {g["qa_name"]}:
1. Does Block 2 end with [End]?
2. Are staging brackets free of Section D blacklist + banned vocal descriptors?
3. Zero instrument/gear names in performable lyric lines?
4. Zero labeled parentheses and trailing apostrophes?
5. Does the chorus pass HOOK TEST (song-specific, not pasteable slogan)?
6. Does Verse 2 add new detail, not just restate Verse 1?
7. Are AI slogan bans clean (no rise up / forever young / high voltage filler)?\'\'\';

  static String _genreBlob({{
    required String primaryGenre,
    String subGenreFusion = '',
    String vibe = '',
    String lyricThemeNotes = '',
  }}) {{
    final parts = [
      primaryGenre.trim(),
      subGenreFusion.trim(),
      vibe.trim(),
      lyricThemeNotes.trim(),
    ];
    return _normalizePhrase(parts.join(' '));
  }}

  static bool {g["lane_fn"]}({{
    required String primaryGenre,
    String subGenreFusion = '',
    String vibe = '',
    String lyricThemeNotes = '',
  }}) {{
    final blob = _genreBlob(
      primaryGenre: primaryGenre,
      subGenreFusion: subGenreFusion,
      vibe: vibe,
      lyricThemeNotes: lyricThemeNotes,
    );
    if (blob.isEmpty) return false;
    return _genreMarkers.any((marker) => _hasWord(blob, marker));
  }}

  static String resolveProfile({{
    required String primaryGenre,
    String subGenreFusion = '',
    String vibe = '',
  }}) {{
    final blob = _genreBlob(
      primaryGenre: primaryGenre,
      subGenreFusion: subGenreFusion,
      vibe: vibe,
    );
    for (final rule in _profileRules) {{
      if (rule.matches(blob)) return rule.profile;
    }}
    return {default_const};
  }}

  static String subGenreLabel(String profile) => switch (profile) {{
{chr(10).join(labels)}
        _ => '{g["title"]}',
      }};

  static String composeSystemBlock({{
    required String primaryGenre,
    String subGenreFusion = '',
    String vibe = '',
    String? profile,
  }}) {{
    final p = profile ??
        resolveProfile(
          primaryGenre: primaryGenre,
          subGenreFusion: subGenreFusion,
          vibe: vibe,
        );
    final subGenre = _subGenreMatrix[p] ?? _subGenreMatrix[{default_const}]!;
    return \'\'\'
$crossArchitectureRules

$masterRolePrompt

$subGenre

$universalStrictRules

$preOutputQa\'\'\'
        .trim();
  }}

  static String composeUserBlock({{
    required String primaryGenre,
    String subGenreFusion = '',
    String vibe = '',
    String lyricThemeNotes = '',
    String? vocalSpec,
    String? vocalTone,
    String? bpmHint,
  }}) {{
    if (!{g["lane_fn"]}(
      primaryGenre: primaryGenre,
      subGenreFusion: subGenreFusion,
      vibe: vibe,
      lyricThemeNotes: lyricThemeNotes,
    )) {{
      return '';
    }}
    final profile = resolveProfile(
      primaryGenre: primaryGenre,
      subGenreFusion: subGenreFusion,
      vibe: vibe,
    );
    return \'\'\'
${{composeSystemBlock(
  primaryGenre: primaryGenre,
  subGenreFusion: subGenreFusion,
  vibe: vibe,
  profile: profile,
)}}

${{_buildUserSelectionsBlock(
  primaryGenre: primaryGenre,
  subGenreFusion: subGenreFusion,
  vibe: vibe,
  lyricThemeNotes: lyricThemeNotes,
  vocalSpec: vocalSpec,
  vocalTone: vocalTone,
  bpmHint: bpmHint,
  profile: profile,
)}}\'\'\'
        .trim();
  }}

  static String _buildUserSelectionsBlock({{
    required String primaryGenre,
    String subGenreFusion = '',
    String vibe = '',
    String lyricThemeNotes = '',
    String? vocalSpec,
    String? vocalTone,
    String? bpmHint,
    required String profile,
  }}) {{
    final vocalist = _formatVocalist(vocalSpec, vocalTone);
    final bpm = (bpmHint ?? '').trim();
    final theme = lyricThemeNotes.trim().isEmpty
        ? 'Write a song-specific conflict for this {g["title"].lower()} lane.'
        : lyricThemeNotes.trim();
    return \'\'\'
USER SELECTIONS ({g["title"].upper()} MASTER):
- Primary genre: $primaryGenre
- Sub-genre / fusion: ${{subGenreFusion.trim().isEmpty ? '(none)' : subGenreFusion.trim()}}
- Resolved profile: $profile (${{subGenreLabel(profile)}})
- Vibe: ${{vibe.trim().isEmpty ? '(none)' : vibe.trim()}}
- Theme / story: $theme
- Vocalist: $vocalist
- BPM hint: ${{bpm.isEmpty ? '(none)' : bpm}}
Honor Key Phrases and theme notes when provided. Invent fresh lines — do not copy few-shots.\'\'\'
        .trim();
  }}

  static String _formatVocalist(String? vocalSpec, String? vocalTone) {{
    final spec = (vocalSpec ?? '').trim();
    final tone = (vocalTone ?? '').trim();
    if (spec.isEmpty && tone.isEmpty) return 'Close-mic lead appropriate to lane';
    if (spec.isEmpty) return tone;
    if (tone.isEmpty) return spec;
    return '$spec · $tone';
  }}

{chr(10).join(fewshots)}
  static String fewShotAssistantTurn(String profile) => switch (profile) {{
{fewshot_switch}
        _ => {few_const(default)},
      }};

  static String fewShotUserTurn({{
    required String profile,
    String lyricThemeNotes = '',
  }}) {{
    final theme = lyricThemeNotes.trim().isEmpty
        ? 'relationship tension with a concrete unfinished conversation'
        : lyricThemeNotes.trim();
    return 'Write a {g["title"]} song in the ${{subGenreLabel(profile)}} lane. '
        'Theme: $theme. Follow the master rules. End Block 2 with [End].';
  }}

  static List<Map<String, String>> fewShotPrefixMessages({{
    required String primaryGenre,
    String subGenreFusion = '',
    String vibe = '',
    String lyricThemeNotes = '',
  }}) {{
    final profile = resolveProfile(
      primaryGenre: primaryGenre,
      subGenreFusion: subGenreFusion,
      vibe: vibe,
    );
    return [
      {{
        'role': 'user',
        'content': fewShotUserTurn(
          profile: profile,
          lyricThemeNotes: lyricThemeNotes,
        ),
      }},
      {{
        'role': 'assistant',
        'content': fewShotAssistantTurn(profile),
      }},
    ];
  }}

  static bool shouldInjectFewShot({{
    required String primaryGenre,
    String subGenreFusion = '',
    String vibe = '',
    String lyricThemeNotes = '',
    required bool lyricsTask,
  }}) =>
      lyricsTask &&
      {g["lane_fn"]}(
        primaryGenre: primaryGenre,
        subGenreFusion: subGenreFusion,
        vibe: vibe,
        lyricThemeNotes: lyricThemeNotes,
      );

  static String _normalizePhrase(String raw) =>
      raw.toLowerCase().replaceAll(RegExp(r'\\s+'), ' ').trim();

  static bool _hasWord(String blob, String marker) {{
    final m = _normalizePhrase(marker);
    if (m.isEmpty) return false;
    if (!m.contains(' ')) {{
      return RegExp(r'\\b' + RegExp.escape(m) + r'\\b').hasMatch(blob);
    }}
    return blob.contains(m);
  }}
}}

class _ProfileRule {{
  const _ProfileRule({{required this.tokens, required this.profile}});
  final List<String> tokens;
  final String profile;
  bool matches(String blob) =>
      tokens.any((t) => {class_name}._hasWord(blob, t) || blob.contains(t));
}}
'''


def gen_python(key: str, g: dict) -> str:
    default = g["default"]
    profile_consts = "\n".join(
        f'PROFILE_{pid.upper()} = "{pid}"' for pid in g["profiles"]
    )
    markers = ",\n    ".join(f'"{m}"' for m in g["markers"])
    rules = []
    matrix = []
    labels = []
    fewshots = []
    few_map = []
    for pid, p in g["profiles"].items():
        const = f"PROFILE_{pid.upper()}"
        toks = ", ".join(f'"{t}"' for t in p["tokens"])
        rules.append(f'    _ProfileRule(tokens=[{toks}], profile={const}),')
        matrix.append(f'    {const}: """{p["matrix"]}""",')
        labels.append(f'    {const}: "{p["label"]}",')
        fewshots.append(f'_{pid.upper()}_FEW_SHOT_GOOD = """\\\n{p["fewshot"]}\n"""')
        few_map.append(f"    {const}: _{pid.upper()}_FEW_SHOT_GOOD,")

    return f'''"""Master {g["title"]} lyric engine — Python twin of Dart master."""
from __future__ import annotations

import re
from dataclasses import dataclass

{profile_consts}

_GENRE_MARKERS = [
    {markers},
]

CROSS_ARCHITECTURE_RULES = """\\
{CROSS}
"""

UNIVERSAL_STRICT_RULES = """\\
{g["structure_rules"]}
"""

MASTER_ROLE_PROMPT = """\\
{g["role"]}
"""

_SUB_GENRE_MATRIX = {{
{chr(10).join(matrix)}
}}

@dataclass(frozen=True)
class _ProfileRule:
    tokens: list[str]
    profile: str

    def matches(self, blob: str) -> bool:
        for t in self.tokens:
            if _has_word(blob, t) or t in blob:
                return True
        return False


_PROFILE_RULES = [
{chr(10).join(rules)}
]

PRE_OUTPUT_QA = """\\
SILENT PRE-OUTPUT QA FOR {g["qa_name"]}:
1. Does Block 2 end with [End]?
2. Are staging brackets free of Section D blacklist + banned vocal descriptors?
3. Zero instrument/gear names in performable lyric lines?
4. Zero labeled parentheses and trailing apostrophes?
5. Does the chorus pass HOOK TEST (song-specific, not pasteable slogan)?
6. Does Verse 2 add new detail, not just restate Verse 1?
7. Are AI slogan bans clean (no rise up / forever young / high voltage filler)?
"""

{chr(10).join(fewshots)}

_FEW_SHOT_GOOD = {{
{chr(10).join(few_map)}
}}

_SUB_GENRE_LABELS = {{
{chr(10).join(labels)}
}}


def _normalize_phrase(raw: str) -> str:
    return re.sub(r"\\s+", " ", (raw or "").lower()).strip()


def _has_word(blob: str, marker: str) -> bool:
    m = _normalize_phrase(marker)
    if not m:
        return False
    if " " not in m:
        return re.search(rf"\\b{{re.escape(m)}}\\b", blob) is not None
    return m in blob


def _genre_blob(
    *,
    primary_genre: str = "",
    sub_genre_fusion: str = "",
    vibe: str = "",
    lyric_theme_notes: str = "",
) -> str:
    return _normalize_phrase(
        " ".join(
            [
                primary_genre or "",
                sub_genre_fusion or "",
                vibe or "",
                lyric_theme_notes or "",
            ]
        )
    )


def {g["py_lane"]}(
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
    return any(_has_word(blob, m) for m in _GENRE_MARKERS)


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
    for rule in _PROFILE_RULES:
        if rule.matches(blob):
            return rule.profile
    return PROFILE_{default.upper()}


def sub_genre_label(profile: str) -> str:
    return _SUB_GENRE_LABELS.get(profile, "{g["title"]}")


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
    sub = _SUB_GENRE_MATRIX.get(p) or _SUB_GENRE_MATRIX[PROFILE_{default.upper()}]
    return "\\n\\n".join(
        [
            CROSS_ARCHITECTURE_RULES.strip(),
            MASTER_ROLE_PROMPT.strip(),
            sub.strip(),
            UNIVERSAL_STRICT_RULES.strip(),
            PRE_OUTPUT_QA.strip(),
        ]
    ).strip()


def _format_vocalist(vocal_spec: str = "", vocal_tone: str = "") -> str:
    spec = (vocal_spec or "").strip()
    tone = (vocal_tone or "").strip()
    if not spec and not tone:
        return "Close-mic lead appropriate to lane"
    if not spec:
        return tone
    if not tone:
        return spec
    return f"{{spec}} · {{tone}}"


def _build_user_selections_block(
    *,
    primary_genre: str,
    sub_genre_fusion: str = "",
    vibe: str = "",
    lyric_theme_notes: str = "",
    vocal_spec: str = "",
    vocal_tone: str = "",
    bpm_hint: str = "",
    profile: str,
) -> str:
    theme = (lyric_theme_notes or "").strip() or (
        "Write a song-specific conflict for this {g["title"].lower()} lane."
    )
    return f"""USER SELECTIONS ({g["title"].upper()} MASTER):
- Primary genre: {{primary_genre}}
- Sub-genre / fusion: {{(sub_genre_fusion or "").strip() or "(none)"}}
- Resolved profile: {{profile}} ({{sub_genre_label(profile)}})
- Vibe: {{(vibe or "").strip() or "(none)"}}
- Theme / story: {{theme}}
- Vocalist: {{_format_vocalist(vocal_spec, vocal_tone)}}
- BPM hint: {{(bpm_hint or "").strip() or "(none)"}}
Honor Key Phrases and theme notes when provided. Invent fresh lines — do not copy few-shots."""


def {g["py_block"]}(
    *,
    primary_genre: str = "",
    sub_genre_fusion: str = "",
    vibe: str = "",
    lyric_theme_notes: str = "",
    vocal_spec: str = "",
    vocal_tone: str = "",
    bpm_hint: str = "",
) -> str:
    if not {g["py_lane"]}(
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
    selections = _build_user_selections_block(
        primary_genre=primary_genre,
        sub_genre_fusion=sub_genre_fusion,
        vibe=vibe,
        lyric_theme_notes=lyric_theme_notes,
        vocal_spec=vocal_spec,
        vocal_tone=vocal_tone,
        bpm_hint=bpm_hint,
        profile=profile,
    )
    return f"{{system}}\\n\\n{{selections}}".strip()


def few_shot_assistant_turn(profile: str) -> str:
    return _FEW_SHOT_GOOD.get(profile, _FEW_SHOT_GOOD[PROFILE_{default.upper()}])


def few_shot_user_turn(*, profile: str, lyric_theme_notes: str = "") -> str:
    theme = (lyric_theme_notes or "").strip() or (
        "relationship tension with a concrete unfinished conversation"
    )
    return (
        f"Write a {g['title']} song in the {{sub_genre_label(profile)}} lane. "
        f"Theme: {{theme}}. Follow the master rules. End Block 2 with [End]."
    )


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
    return [
        {{
            "role": "user",
            "content": few_shot_user_turn(
                profile=profile, lyric_theme_notes=lyric_theme_notes
            ),
        }},
        {{"role": "assistant", "content": few_shot_assistant_turn(profile)}},
    ]


def should_inject_few_shot(
    *,
    primary_genre: str = "",
    sub_genre_fusion: str = "",
    vibe: str = "",
    lyric_theme_notes: str = "",
    lyrics_task: bool = False,
) -> bool:
    return bool(lyrics_task) and {g["py_lane"]}(
        primary_genre=primary_genre,
        sub_genre_fusion=sub_genre_fusion,
        vibe=vibe,
        lyric_theme_notes=lyric_theme_notes,
    )
'''


def gen_tools_txt(key: str, g: dict) -> str:
    lines = [
        f"# {g['title'].upper()} VOCAL LYRICIST ENGINE",
        "",
        f"**When:** Primary genre or fusion matches a {g['title']} lane **and** Block 2 has vocals.",
        "",
        "## HUMAN AUTHENTICITY (MANDATORY)",
        "Conversational speech, song-specific interpersonal friction, plain words.",
        f"BAN: {AUTH_BANS}.",
        "HOOK TEST: if the chorus could paste onto any song unchanged, rewrite.",
        "",
        "## PROFILES",
    ]
    for pid, p in g["profiles"].items():
        lines.append(f"### {p['label']} (`{pid}`)")
        lines.append(p["matrix"])
        lines.append("")
    lines.append("## ROLE")
    lines.append(g["role"])
    return "\n".join(lines) + "\n"


def gen_test(key: str, g: dict) -> str:
    class_name = g["class"]
    default = g["default"]
    default_const = "profile" + "".join(w.capitalize() for w in default.split("_"))
    first_marker = g["markers"][0]
    profiles = ",\n        ".join(
        f"{class_name}.profile{''.join(w.capitalize() for w in pid.split('_'))}"
        for pid in g["profiles"]
    )
    # pick a distinctive second profile token for resolve test
    second_pid = list(g["profiles"].keys())[1]
    second_token = g["profiles"][second_pid]["tokens"][0]
    second_const = "profile" + "".join(w.capitalize() for w in second_pid.split("_"))

    return f'''import 'package:flutter_test/flutter_test.dart';
import 'package:music_director/core/constants/genre_lyrics_directives.dart';
import 'package:music_director/core/constants/{g["py_mod"]}.dart';

void main() {{
  group('{class_name}', () {{
    test('lane detection', () {{
      expect(
        {class_name}.{g["lane_fn"]}(primaryGenre: '{first_marker}'),
        isTrue,
      );
      expect(
        {class_name}.{g["lane_fn"]}(primaryGenre: 'unrelated ambient drone'),
        isFalse,
      );
    }});

    test('profile resolution', () {{
      expect(
        {class_name}.resolveProfile(primaryGenre: '{first_marker}'),
        {class_name}.{default_const},
      );
      expect(
        {class_name}.resolveProfile(
          primaryGenre: '{first_marker}',
          subGenreFusion: '{second_token}',
        ),
        {class_name}.{second_const},
      );
    }});

    test('composeUserBlock includes authenticity and QA', () {{
      final block = {class_name}.composeUserBlock(primaryGenre: '{first_marker}');
      expect(block, contains('CROSS-ARCHITECTURE NON-NEGOTIABLES'));
      expect(block, contains('HUMAN AUTHENTICITY'));
      expect(block, contains('SILENT PRE-OUTPUT QA FOR {g["qa_name"]}'));
      expect(block, contains('rise up'));
    }});

    test('few-shots end with [End] and avoid AI slogans', () {{
      for (final profile in [
        {profiles},
      ]) {{
        final shot = {class_name}.fewShotAssistantTurn(profile);
        expect(shot.trim().endsWith('[End]'), isTrue, reason: profile);
        expect(shot.toLowerCase(), isNot(contains('rise up')));
        expect(shot.toLowerCase(), isNot(contains('forever young')));
        expect(shot.toLowerCase(), isNot(contains('high voltage')));
        expect(shot, isNot(contains('(Lead ad-libs')));
      }}
    }});

    test('GenreLyricsDirectives injects master for {key}', () {{
      final block = GenreLyricsDirectives.userBlockDirective(
        primaryGenre: '{first_marker}',
      );
      expect(block, contains('CROSS-ARCHITECTURE NON-NEGOTIABLES'));
      expect(block, contains('{g["title"].upper()} MASTER'));
    }});
  }});
}}
'''


def main() -> None:
    for key, g in GENRES.items():
        dart_path = ROOT / f"lib/core/constants/{g['py_mod']}.dart"
        py_path = ROOT / f"server/app/{g['py_mod']}.py"
        tools_path = ROOT / f"tools/{key}_vocal_lyricist_engine.txt"
        test_path = ROOT / f"test/core/constants/{g['py_mod']}_test.dart"

        dart_path.write_text(gen_dart(key, g), encoding="utf-8")
        py_path.write_text(gen_python(key, g), encoding="utf-8")
        tools_path.write_text(gen_tools_txt(key, g), encoding="utf-8")
        test_path.write_text(gen_test(key, g), encoding="utf-8")
        print("wrote", dart_path.name, py_path.name, tools_path.name, test_path.name)
    print("DONE")


if __name__ == "__main__":
    main()
