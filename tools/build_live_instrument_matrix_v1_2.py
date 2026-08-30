"""Build tools/live_instrument_matrix.json v1.2.0 with promptText + expanded library."""

from __future__ import annotations

import json
from pathlib import Path
from typing import Any


def inst(
    id_: str,
    name: str,
    category: str,
    articulation: str,
    mix_role: str,
    *,
    prompt_text: str | None = None,
    aliases: list[str] | None = None,
) -> dict[str, Any]:
    row: dict[str, Any] = {
        "id": id_,
        "name": name,
        "category": category,
        "defaultArticulation": articulation,
        "mixRole": mix_role,
    }
    if prompt_text:
        row["promptText"] = prompt_text
    if aliases:
        row["aliases"] = aliases
    return row


def main() -> None:
    root = Path(__file__).resolve().parents[1]
    out = root / "tools" / "live_instrument_matrix.json"

    data: dict[str, Any] = {
        "schemaVersion": "1.2.0",
        "categoryTaxonomy": {
            "bass": "Low-frequency foundation (sub/low-mid, 40-250Hz)",
            "melodic_bass": "Bass-range instrument that carries melodic content (log drum, synth bass leads)",
            "guitar": "Plucked/strummed string instruments (acoustic, electric, nylon)",
            "keys": "Keyboard instruments (piano, Rhodes, Wurlitzer, organ, synth pads)",
            "strings": "Bowed/sustained string sections (orchestral, erhu, guzheng)",
            "saxophones": "Saxophone family (alto, tenor, soprano, baritone)",
            "trumpets": "Brass — trumpet, flugelhorn, trombone section",
            "horns": "Brass — French horn, tuba, mixed brass pads",
            "winds": "Woodwind and folk wind instruments (flute, clarinet, pan flute, ocarina)",
            "drums": "Acoustic/electronic drum kits and breaks",
            "world_perc": "Hand drums, shakers, ethnic percussion (non-kit)",
            "vocals_choir": "Backing vocal stacks, choirs, chants, vocal chops",
            "synth": "Synthesized leads/pads/textures not better classified as keys",
        },
        "genrePresetAlias": {
            "Praise/Worship": "praise_and_worship",
            "Modern Worship": "praise_and_worship",
            "Worship Ballad": "praise_and_worship",
            "Alt Rock": "rock_alternative",
            "Alternative": "rock_alternative",
            "Indie Rock": "rock_alternative",
            "Contemporary R&B": "contemporary_rnb",
            "90s R&B": "contemporary_rnb",
            "Trap Soul": "contemporary_rnb",
            "Deep House": "deep_house",
            "Tech House": "deep_house",
            "Afrobeats": "afrobeats",
            "Afro-Swing": "afrobeats",
            "Amapiano": "amapiano",
            "Amapiano-Vinahouse": "amapiano",
            "Vinahouse": "amapiano",
            "Boom Bap": "boom_bap",
            "Jazz Rap": "boom_bap",
            "Mandopop": "mandopop",
            "C-Pop": "mandopop",
            "Neo-Soul": "neo_soul",
            "House": "house",
            "Soulful House": "house",
            "Disco House": "house",
            "Nu-Disco": "house",
            "Jazz": "jazz",
            "Vocal Jazz": "jazz",
            "Smooth Jazz": "jazz",
            "Bebop": "jazz",
            "Trap": "trap",
            "Melodic Trap": "trap",
            "Cloud Rap": "trap",
            "Pop": "pop",
            "Mainstream Pop": "pop",
            "Dance Pop": "pop",
            "Electropop": "pop",
            "EDM": "edm",
            "Trance": "edm",
            "Progressive House": "edm",
            "Techno": "edm",
            "Melodic Techno": "edm",
            "Future Bass": "edm",
            "Synthwave": "edm",
            "Cinematic": "cinematic",
            "Film Score": "cinematic",
            "Orchestral": "cinematic",
        },
        "genres": {},
    }

    g = data["genres"]

    g["praise_and_worship"] = [
        inst("worship-piano", "Contemporary Piano", "keys", "open contemporary worship voicings, building register sweeps at chorus", "bright clear center, driving harmonic foundation, slight plate reverb"),
        inst("worship-acoustic-gtr", "Acoustic Rhythm Guitar", "guitar", "steel-string strumming, building from muted verses to open chorus power chords", "wide stereo spread, ambient hall reverb tail, mid-range bed"),
        inst("worship-strings", "Live Orchestral String Pad", "strings", "lush legato swells, chordal textures building verse-to-chorus", "enveloping wall of sound, deep stereo landscape, low-mid warmth", prompt_text="Orchestral string pad, lush studio recording, no crowd noise"),
        inst("worship-horns", "Orchestral French Horn Swells", "horns", "majestic sustained brass chords, warm crescendo on final chorus", "deep background warmth, cinematic stereo width, felt not heard"),
        inst("worship-percussion", "Acoustic Shakers & Congas", "world_perc", "organic rhythmic pulses, continuous soft accents, tom swells at transitions", "panned moderately wide, high-mid rhythmic glue, dry close mic"),
        inst("worship-vocals", "Worship Backing Layers", "vocals_choir", "layered SATB oohs and aahs, soft consonant swells, dynamic build from whisper to full belt", "halo reverb wide stereo, sits behind lead vocal, lifts at final chorus"),
        inst("church-pipe-organ", "Church Pipe Organ", "keys", "majestic sustained chords with deep pedal bass", "wide hall depth, spiritual lift on chorus", prompt_text="Majestic, powerful church pipe organ with deep bass pedals and soaring high notes, clean studio recording", aliases=["pipe organ"]),
    ]

    g["rock_alternative"] = [
        inst("rock-les-paul", "Les Paul Electric Guitar", "guitar", "overdriven rhythm, palm-muted chugging, octave-doubled riff layers", "dense aggressive midrange, hard-panned L/R double-tracked"),
        inst("rock-distorted-gtr", "Distorted Rock Guitar", "guitar", "heavy palm-muted riffing, saturated power chords", "forward midrange aggression, tight room", prompt_text="Heavy distorted electric guitar riff, palm-muted, powerful rock or metal tone, clean studio recording", aliases=["heavy guitar", "distortion guitar"]),
        inst("rock-hammond-b3", "Hammond B3 Organ", "keys", "warm drawbar setting, swirling Leslie speaker, subtle tremolo swells", "gluing the band together, wide stereo, midrange body"),
        inst("rock-sax", "Blazing Tenor Saxophone", "saxophones", "gritty overdriven solos, raw bluesy growls, breathy low-register bends", "center-panned lead presence, high-mid crunch, spring reverb"),
        inst("rock-trumpets", "Punchy Rock Trumpet Stabs", "trumpets", "aggressive staccato unison hits, high-register energy, fall-off articulations", "bright cutting high-end, forward in the mix, plate reverb"),
        inst("rock-p-bass", "Fender P-Bass", "bass", "fingerpicked driving root patterns, punchy attack", "mono low-end pocket, tape saturation, foundational", aliases=["p bass", "precision bass"]),
        inst("rock-vocals", "Alt-Rock Backing Textures", "vocals_choir", "gritty shouted harmonies, gang-vocal chorus yell, whispered verse doubles", "wide stereo with grit saturation, sits slightly behind lead, room mic bleed"),
    ]

    g["contemporary_rnb"] = [
        inst("rnb-bass", "Fender Jazz Bass", "bass", "smooth fingerstyle, sub-heavy pocket, subtle ghost-note slides", "rounded low-mids, tape-warm saturation, vocal-forward bed"),
        inst("rnb-keys", "Rhodes Electric Piano", "keys", "silky chord voicings, gentle ghost notes, subtle tremolo breath", "warm mid-range, intimate room, stereo widening on chorus"),
        inst("rnb-sax", "Sultry Alto Saxophone", "saxophones", "smoky legato phrasing, breathy sensual runs, low-register whispers", "intimate center-left mix, warm vintage room saturation, tape compression"),
        inst("rnb-trumpets", "Harmon-Muted Trumpet", "trumpets", "soft melancholic jazz fills, close-mic breath, half-valve bends", "dry intimate center-right space, breathy presence, minimal reverb"),
        inst("rnb-perc", "Warm Studio Conga Loops", "world_perc", "subtle ghost notes, syncopated low-mid slaps, finger-roll flourishes", "mono-centered low-mid warmth, dry mix, tape saturation"),
        inst("rnb-vocals", "R&B Vocal Harmonies", "vocals_choir", "stacked 3-part close harmonies, gospel-style melisma lifts, whispered ad-lib doubles", "wide stereo oohs, sits under lead, plate reverb, lifts on chorus hook"),
    ]

    g["deep_house"] = [
        inst("house-bass", "Live Slap Bass", "bass", "funky syncopated melodic bassline, thumb-slap pops on the one", "sidechained to kick, punchy low-mid, ducking groove", prompt_text="Clean DI slap bass, funky, no crowd noise", aliases=["slap bass"]),
        inst("house-909-kit", "Roland TR-909 Kit", "drums", "classic four-on-the-floor kick, open hat on the offbeat, snappy claps", "mono-center kick, wide stereo hats, driving sidechain pump"),
        inst("house-sax", "Deep House Baritone Sax", "saxophones", "rhythmic low-register loops, syncopated jazz riffs, breathy stabs", "warm low-mid punch, heavy sidechain compression, panned left"),
        inst("house-horns", "Muted Brass Horn Section", "horns", "tight muted trumpet and trombone stabs, disco-style unison hits", "mid-range lift, classic disco/house hook presence, wide pan"),
        inst("house-conga", "High-Gloss Afro-House Congas", "world_perc", "four-on-the-floor syncopated hand drums, open tone slap patterns", "sidechained pumping effect, wide stereo widening, high-mid air"),
        inst("house-vocals", "House Vocal Hooks", "vocals_choir", "diva-style belted riffs, chopped rhythmic vocal phrases, gospel ad-libs", "chopped and sidechained, wide stereo, rhythmic hook element"),
        inst("organic-house-perc", "Organic House Percussion", "world_perc", "layered hand percussion with syncopated grooves", "wide stereo, dry close mic, sidechain pump", prompt_text="Layered hand percussion: bongos, shakers, light congas, djembe, clean studio recording, no crowd noise", aliases=["organic percussion"]),
    ]

    g["afrobeats"] = [
        inst("afro-gtr", "Clean Electric Guitar", "guitar", "highlife-tinged picking, melodic riff motifs dancing around the vocal", "bright dancing center-right, crisp compression, around-vocal pocket"),
        inst("afro-sax", "Fela-Inspired Tenor Saxophone", "saxophones", "blazing continuous polyrhythmic melodies, modal runs, repeating hypnotic phrases", "mid-forward tropical crunch, center placement, tape warmth"),
        inst("afro-trumpets", "Punchy Afrobeats Trumpet Section", "trumpets", "staccato interlocking geometric riffs, high accent pings, call-response patterns", "bright glossy sheen, wide stereo panning layout, punchy attack"),
        inst("afro-perc", "Traditional Talking Drum & Congas", "world_perc", "organic pitch-bent rhythms, open conga tones, shekere shake layers", "mid-range syncopation, dry close room mic, wide panning"),
        inst("afro-vocals", "Afro-Pop Backing Vocals", "vocals_choir", "call-and-response group chants, Pidgin-English ad-libs, crowd singalong lifts", "panned wide L/R, high-mid energy, lifts chorus into anthem"),
        inst("kora-arpeggios", "Kora Arpeggios", "strings", "delicate cascading harp-like arpeggios", "sparkling mid-highs, wide stereo, around vocal", prompt_text="Delicate, cascading kora (West African harp) arpeggios, clean studio recording", aliases=["kora"]),
        inst("djembe-rhythm", "Djembe Rhythm", "world_perc", "powerful hand drum patterns with syncopated accents", "mid-forward rhythmic drive, dry room", prompt_text="Powerful, intricate djembe hand drum patterns, clean studio recording", aliases=["djembe"]),
        inst("shekere-percussion", "Shekere & Gourd Percussion", "world_perc", "crisp shaker loops and resonant gourd accents", "high-mid sparkle, wide pan", prompt_text="Crisp shekere and resonant gourd shaker loops, clean studio recording", aliases=["shekere"]),
        inst("balafon-melody", "Balafon", "world_perc", "woody melodic xylophone lines", "mid-range melodic hook, dry close mic", prompt_text="Organic, woody balafon (xylophone) melody, clean studio recording", aliases=["balafon"]),
        inst("cajon-rhythm", "Cajon", "world_perc", "woody box drum backbeat with slaps and taps", "center groove, dry intimate room", prompt_text="Woody, resonant cajon providing a rhythmic foundation, acoustic pop or flamenco feel, clean studio recording", aliases=["cajon"]),
    ]

    g["amapiano"] = [
        inst("amapiano-log-drum", "Live Log Drum", "melodic_bass", "organic log-drum melodic pattern, pitched slides and knock tones", "warm low-mid pocket, sidechained groove, center-forward", prompt_text="Organic log drum, warm studio recording, no crowd noise", aliases=["log drum"]),
        inst("amapiano-piano", "Acoustic Piano", "keys", "sparse jazz-influenced comping, jazzy 7th and 9th extensions", "intimate center, dry room mic, mid-range clarity"),
        inst("amapiano-sax", "Smooth Jazzy Alto Sax", "saxophones", "sparse improvisational lounge lines, soft phrasing, breathy low-register fills", "panned left with lush dark reverb tail, intimate lounge feel"),
        inst("amapiano-shakers", "Live Congas & Seed Shakers", "world_perc", "continuous hypnotic syncopated shaker groove, hard conga slaps", "high frequency air, ultra-wide panning, dry close mic", prompt_text="Studio congas and seed shakers, clean close-mic recording, no crowd noise", aliases=["congas", "shakers"]),
        inst("amapiano-vocals", "Amapiano Chant Accents", "vocals_choir", "rhythmic chant phrases on the 4, whispered group calls, repetitive hook mantras", "mid-forward rhythmic hook, mono-center with wide reverb throw"),
        inst("mbira-melody", "Mbira (Kalimba)", "keys", "hypnotic thumb-piano melodic loops", "center sparkle, dry intimate mic", prompt_text="Hypnotic mbira (thumb piano) melody, clean recording", aliases=["kalimba", "thumb piano"]),
    ]

    g["boom_bap"] = [
        inst("bap-bass", "Fender P-Bass", "bass", "fingerpicked, warm and punchy, walking root-note patterns", "mono low-end pocket, tape saturation, foundational"),
        inst("bap-break", "Dusty Vinyl Drum Break", "drums", "chopped Amen/Winston-style breakbeat, hard quantized snare hits, swung hat pocket", "vinyl-crackle overlay, bandpass filtered, mono-centric, sample grit"),
        inst("bap-keys", "Rhodes Electric Piano", "keys", "chordal stabs and jazzy extensions, repetitive hypnotic loop", "mid-range, subtle tremolo, filtered loop bed"),
        inst("bap-sax", "Vintage Sampled Soprano Sax", "saxophones", "lo-fi filtered loop, repetitive smoky melodic hook", "vinyl crackle overlay, bandpass filtered, mono, center"),
        inst("bap-strings", "Gritty Vinyl Orchestra Strings", "strings", "staccato string phrases, lo-fi pitch warbles, sampled 70s soul chops", "filtered mid-highs, panned slightly right, wow/flutter texture"),
        inst("bap-vocals", "Hip-Hop Hype Vocals", "vocals_choir", "hype-man ad-libs, echoed tag shouts, scratched vocal phrases", "panned hard L/R, lo-fi compression, call-response pocket"),
    ]

    g["mandopop"] = [
        inst("mando-erhu", "Erhu (Chinese Fiddle)", "strings", "expressive pentatonic melodic phrases, cinematic vibrato slides", "lead melodic voice, cinematic vibrato, center-forward"),
        inst("mando-guzheng", "Guzheng (Chinese Zither)", "strings", "plucked cascading pentatonic runs, delicate harmonic taps", "sparkling high-mids, traditional color, wide stereo"),
        inst("mando-horns", "Soft Orchestral French Horns", "horns", "melancholic sustained accompaniment, emotional tracking swells", "wide stereo backdrop, cinematic room depth, felt not heard"),
        inst("mando-perc", "Acoustic Shakers & Light Congas", "world_perc", "soft finger-plucked hand drums, delicate pulse", "subtle background panning, low-mids dipped, dry"),
        inst("mando-vocals", "Mandopop Choral Layers", "vocals_choir", "cinematic choral oohs, Mandarin unison chants, emotional bridge harmonies", "wide cinematic stereo, lush plate reverb, builds chorus lift"),
    ]

    g["neo_soul"] = [
        inst("soul-bass", "Fender Jazz Bass", "bass", "deep pocket, syncopated ghost notes, laid-back behind-the-beat feel", "smooth rounded low-mids, tape compression, groove anchor"),
        inst("soul-wurlitzer", "Wurlitzer Electric Piano", "keys", "lush slightly overdriven chord comps, tremolo breathe", "warm intimate vocal-forward space, slightly overdriven grit"),
        inst("soul-sax", "Warm Tenor Saxophone Section", "saxophones", "velvet legato crescendos, jazzy fall-offs, smoky low-register fills", "stereo left spread, rich natural midrange room, intimate"),
        inst("soul-trumpets", "Crisp Trumpet Unison Harmon Swells", "trumpets", "laid-back behind-the-beat brass extensions, silky top-end swells", "stereo right spread, silky top-end sheen, plate reverb"),
        inst("soul-perc", "Hand-Plucked Studio Congas", "world_perc", "laid-back behind-the-beat finger slaps, subtle ghost-note patterns", "warm natural room mic, subtle panning width, mid-range glue"),
        inst("soul-vocals", "Neo-Soul Vocal Beds", "vocals_choir", "breathy layered harmonies, gospel-tinged ad-libs, whispered doubles on verse", "vintage warm spread, sits under lead vocal, tape saturation"),
    ]

    g["house"] = [
        inst("house-disco-bass", "Fender Jazz Bass", "bass", "funky octave bassline, four-on-the-floor pocket, walking disco runs", "sidechained mono low-end, punchy ducking groove"),
        inst("house-rhodes", "Rhodes Electric Piano", "keys", "classic disco chord stabs, gospel 9th voicings, tremolo breathe", "mid-range lift, subtle tremolo, stereo widening on chorus"),
        inst("house-trumpets", "Sizzling Disco Trumpet Section", "trumpets", "screaming high-octave runs, rapid staccato falls, fanfare hits on the one", "ultra-wide stereo image, brilliant high-end lift, forward"),
        inst("house-strings", "Disco String Section", "strings", "sustained bowing lifts, pizzicato stabs on offbeats, octave-doubled unison lines", "wide stereo wash, uplifting high-mid shimmer, chorus hook bed"),
        inst("house-vocals", "Disco Falsetto Overlays", "vocals_choir", "falsetto oohs and aahs, call-and-response phrases, chopped rhythmic vocal hooks", "wide stereo halo, filtered sweeps on build, disco lift"),
        inst("organic-house-perc", "Organic House Percussion", "world_perc", "layered hand percussion with syncopated grooves", "wide stereo, dry close mic, sidechain pump", prompt_text="Layered hand percussion: bongos, shakers, light congas, djembe, clean studio recording, no crowd noise", aliases=["organic percussion"]),
    ]

    g["jazz"] = [
        inst("jazz-upright", "Upright Double Bass", "bass", "walking bass line, acoustic finger plucks, subtle slides between chord tones", "dry intimate foundational low-end, center, minimal reverb"),
        inst("jazz-kit", "Bop Drum Kit (Brushes & Sticks)", "drums", "swinging ride pattern, interactive snare comping, dynamic brush-to-stick transitions", "authentic wide spatial field, raw venue air, room mic bleed"),
        inst("jazz-sax", "Smoky Tenor Saxophone Solo", "saxophones", "expressive bebop improvisations, complex harmonic runs, vocal-like phrasing", "perfectly centered front-and-forward, close-mic dry, intimate"),
        inst("jazz-trumpet", "Muted Trumpet", "trumpets", "smoky harmon-muted melodic fills, breathy attacks, half-valve bends", "dry intimate room mic, close-mic'd center, whispered presence"),
        inst("jazz-perc", "Acoustic Congas & Bop Percussion", "world_perc", "swinging hand-drum syncopation, complex brush strokes, subtle shaker bed", "authentic wide spatial field, raw venue air, natural reverb"),
        inst("jazz-vocals", "Jazz Vocal Unison Oohs", "vocals_choir", "soft scat-style oohs, unison melody doubles, breathy behind-the-beat phrasing", "dry intimate center, sits under soloist, minimal reverb"),
        inst("nylon-string-guitar", "Nylon String Guitar", "guitar", "warm fingerpicked bossa and jazz comping", "intimate center, dry room", prompt_text="Warm, mellow nylon-string acoustic guitar, suitable for classical, flamenco, or bossa nova styles, clean studio recording", aliases=["classical guitar", "flamenco guitar"]),
        inst("warm-clarinet", "Warm Clarinet Lead", "winds", "rich legato melodic lines with breathy tone", "center-forward jazz lead, dry room", prompt_text="Rich, warm clarinet lead, smooth jazz or klezmer style, clean studio recording", aliases=["clarinet"]),
        inst("pan-flute-echoes", "Pan Flute Echoes", "winds", "haunting melodic lines with light echo", "ethereal center lead", prompt_text="Haunting pan flute melody with light reverb and echo, clean studio recording", aliases=["pan flute", "panpipe"]),
        inst("mellow-trombone", "Mellow Trombone Section", "horns", "soft brass swells and warm unison lines", "mid-range warmth, wide stereo", prompt_text="Soft, mellow trombone swells, brass band texture, clean studio recording", aliases=["trombone"]),
    ]

    g["trap"] = [
        inst("trap-808", "Tuned 808 Sub Bass", "melodic_bass", "long sustained sub slides, pitch-bent risers, distorted saturation tail", "mono sub foundation, sidechained to kick, dominates low-end"),
        inst("trap-hats", "Roland TR-808 Hi-Hats", "drums", "rapid triplet rolls, pitch-shifted hat flurries, snappy open-close patterns", "crisp high-end stereo, machinegun rhythmic texture, forward"),
        inst("trap-keys", "Grand Piano", "keys", "dark minor-key melodic loops, sparse haunting chords", "centered with subtle reverb tail, haunting bed layer"),
        inst("trap-strings", "Orchestral Strings", "strings", "staccato stabs and dramatic swells, minor-key tension pads", "wide stereo field, cinematic dark lift, behind 808"),
        inst("trap-sax", "Dark Synthesized Alto Sax", "saxophones", "hypnotic minor-scale staccato runs, rapid pitch slides, detuned saw texture", "panned center, heavy stereo tape delay effect, haunting lead"),
        inst("trap-vocals", "Trap Vocal Chops", "vocals_choir", "pitched-up vocal fragments, chopped rhythmic phrases, reversed vocal textures", "hard-panned L/R, glitchy rhythmic ear candy, hook accent"),
    ]

    g["pop"] = [
        inst("pop-guitar", "Acoustic Guitar", "guitar", "bright strummed rhythm, tight pocket, octave-doubled layers", "wide stereo, glossy pop sheen, mid-range bed"),
        inst("pop-kit", "Live Drum Kit & Congas", "drums", "tight studio backbeat, bright hand-percussion layers, crisp snare", "centered groove, competitive loudness, crisp highs, punchy kick", prompt_text="Acoustic studio drum kit, clean room recording, prominent congas, no crowd noise", aliases=["drums", "drum kit"]),
        inst("pop-cello", "Solo Cello", "strings", "emotive lyrical melodic lines", "warm center-left, intimate lift on chorus", prompt_text="Emotive, lyrical solo cello melody, rich and resonant, clean studio recording", aliases=["cello"]),
        inst("pop-strings", "Live String Section", "strings", "lush sustained pads and octave doubles, sweeping chorus lifts", "wide stereo wash behind vocal, cinematic lift on chorus", prompt_text="Studio string section, lush close-mic recording, no crowd noise", aliases=["string section"]),
        inst("pop-funk-gtr", "Funky Strat Rhythm Guitar", "guitar", "clean percussive rhythm chops", "mid-range pocket, stereo width", prompt_text="Clean, funky stratocaster rhythm guitar, percussive and in-the-pocket, Nile Rodgers style, clean studio recording", aliases=["funk guitar", "stratocaster"]),
        inst("pop-trumpets", "Polished Synth-Trumpet Fanfare", "trumpets", "crisp modern anthemic brass chords, punchy attack, fanfare stabs", "ultra-wide tracking, hyper-compressed highs, hook lift"),
        inst("pop-vocals", "Pop Choral Harmonies", "vocals_choir", "polished 3-part stack, gang-vocal chorus hook, whispered verse doubles, ad-lib runs", "ultra-wide stereo, glossy compression, lift on final chorus"),
        inst("breathy-flute", "Breathy Flute Melody", "winds", "airy soulful melodic lines", "center sparkle, soft reverb tail", prompt_text="Airy, breathy wooden flute melody, soulful and emotive, clean studio recording", aliases=["flute", "wooden flute"]),
        inst("ocarina-lead", "Ocarina Lead", "winds", "simple pure folk melody", "center intimate lead", prompt_text="Simple, pure ocarina melody, folk style, clean studio recording", aliases=["ocarina"]),
    ]

    g["edm"] = [
        inst("trance-piano-melody", "Trance Piano Melody", "keys", "epic reverb-heavy chord swells", "center lift on breakdown", prompt_text="Epic, melodic grand piano chords, reverb-heavy, suitable for a trance or progressive house breakdown, clean studio recording", aliases=["edm piano", "trance piano"]),
        inst("edm-string-section", "EDM String Section", "strings", "soaring layered pads for euphoric drops", "wide stereo cinematic lift", prompt_text="Soaring, emotional orchestral string section, layered pads, cinematic feel, perfect for a euphoric electronic drop, clean studio recording", aliases=["edm strings"]),
        inst("future-bass-piano-chords", "Future Bass Piano Chords", "keys", "bright punchy chord stabs", "mid-forward hook bed", prompt_text="Bright, punchy piano chords, slightly compressed, characteristic of future bass or melodic dubstep, clean studio recording", aliases=["future bass piano"]),
        inst("organic-house-perc", "Organic House Percussion", "world_perc", "layered hand percussion with syncopated grooves", "wide stereo, dry close mic, sidechain pump", prompt_text="Layered hand percussion: bongos, shakers, light congas, djembe, clean studio recording, no crowd noise", aliases=["organic percussion"]),
        inst("synthwave-sax-solo", "Synthwave Sax Solo", "saxophones", "smooth retro sax lead with long reverb", "center lead, wide 80s tail", prompt_text="Reverb-drenched 80s style saxophone solo, smooth and melodic, iconic synthwave sound, clean studio recording", aliases=["retro sax", "80s sax"]),
        inst("sampled-vocal-chops", "Sampled Vocal Chops", "vocals_choir", "rhythmic pitched vocal hook fragments", "wide stereo hook accent", prompt_text="Rhythmic, melodic vocal chops, pitched and processed, used as an instrumental hook, clean studio recording", aliases=["vocal chops"]),
    ]

    g["cinematic"] = [
        inst("cinematic-timpani", "Cinematic Timpani", "drums", "powerful rolls and hits for epic transitions", "wide low-mid impact, dramatic lift", prompt_text="Powerful, resonant timpani rolls and hits, epic and orchestral, clean studio recording", aliases=["timpani"]),
        inst("intimate-string-quartet", "String Quartet", "strings", "chamber interplay between four string voices", "close-mic intimate center spread", prompt_text="Intimate string quartet (two violins, viola, cello), chamber music feel, clean and close-mic'd recording", aliases=["quartet"]),
        inst("emotive-solo-cello", "Solo Cello", "strings", "lyrical solo melody with rich resonance", "center emotional lead", prompt_text="Emotive, lyrical solo cello melody, rich and resonant, clean studio recording", aliases=["cello"]),
        inst("nimble-solo-violin", "Solo Violin", "strings", "expressive agile solo lines", "soaring center lead", prompt_text="Nimble and expressive solo violin lead, can be both melancholic or soaring, clean studio recording", aliases=["violin"]),
        inst("church-pipe-organ", "Church Pipe Organ", "keys", "majestic sustained chords with deep pedal bass", "wide hall depth, spiritual lift on chorus", prompt_text="Majestic, powerful church pipe organ with deep bass pedals and soaring high notes, clean studio recording", aliases=["pipe organ"]),
        inst("mando-horns", "Soft Orchestral French Horns", "horns", "melancholic sustained accompaniment, emotional tracking swells", "wide stereo backdrop, cinematic room depth, felt not heard"),
        inst("glockenspiel-melody", "Glockenspiel / Marimba", "keys", "bright bell-like melodic figures", "sparkling high-mids, magical lift", prompt_text="Bright, bell-like glockenspiel or woody marimba melody, adds a magical or childlike quality, clean studio recording", aliases=["glockenspiel", "marimba", "bells"]),
    ]

    out.write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    voice_count = sum(len(v) for v in g.values())
    print(f"OK wrote {out} — {len(g)} bundles, {voice_count} voices")


if __name__ == "__main__":
    main()
