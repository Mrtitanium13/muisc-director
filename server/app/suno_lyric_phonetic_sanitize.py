"""Post-process Suno output — phonetic apostrophes + instrumental staging leaks."""

from __future__ import annotations

import re

from app.suno_lyrics_audio_normalizer import apply_audio_engine_normalization_to_suno_output

_APOSTROPHE = "''\u2018\u2019"  # straight + curly open/close quotes

_LEADING_CONTRACTIONS: tuple[tuple[str, str], ...] = (
    ("'round", "around"),
    ("'bout", "bout"),
    ("'cause", "cause"),
    ("'em", "em"),
    ("'til", "til"),
)

# Word letter(s) + apostrophe (not followed by more word chars = not internal like o'clock)
_TRAILING_WORD_APOSTROPHE = re.compile(
    rf"\b([A-Za-z]+)[{re.escape(_APOSTROPHE)}](?![A-Za-z])"
)


def sanitize_suno_lyric_phonetics(text: str) -> str:
    """Remove Suno-glitch apostrophes; expand leading 'round → around."""
    if not text:
        return text

    out = text
    for old, new in _LEADING_CONTRACTIONS:
        out = out.replace(old, new)
        curly = old.replace("'", "\u2019")
        out = out.replace(curly, new)

    out = _TRAILING_WORD_APOSTROPHE.sub(r"\1", out)
    return out


_INSTRUMENTAL_BRACKET = re.compile(
    r"\[(Instrumental(?:\s+Break)?|Instrumental Interlude|Log Drum Break):\s*([^\]]+)\]",
    re.IGNORECASE,
)

_VERB_PREFIXES: tuple[str, ...] = (
    "features ",
    "feature ",
    "featured ",
    "playing a ",
    "playing ",
    "play a ",
    "play ",
    "letting the ",
    "let the ",
    "let ",
    "adding ",
    "add ",
    "introducing ",
    "introduce ",
)


def _strip_verb_lead(token: str) -> str:
    t = token.strip()
    while t:
        lower = t.lower()
        stripped = False
        for prefix in _VERB_PREFIXES:
            if lower.startswith(prefix):
                t = t[len(prefix) :].lstrip()
                stripped = True
                break
        if not stripped:
            break
    return t


def _clean_instrumental_body(body: str) -> str:
    parts = [_strip_verb_lead(part) for part in body.split(",")]
    return ", ".join(part for part in parts if part)


def sanitize_instrumental_staging_tags(text: str) -> str:
    """Strip verb-phrase leaks from instrumental-only staging brackets."""

    def repl(match: re.Match[str]) -> str:
        label = match.group(1)
        body = _clean_instrumental_body(match.group(2))
        return f"[{label}: {body}]" if body else f"[{label}]"

    return _INSTRUMENTAL_BRACKET.sub(repl, text)


_GOSPEL_LANE = re.compile(
    r"gospel|worship|praise(?:\s*(?:&|and)\s*worship)?|ccm|christian|southern\s+gospel|afro[- ]?gospel|afro[- ]?praise|contemporary\s+christian",
    re.IGNORECASE,
)

_GOSPEL_STAGING_REPLACEMENTS: tuple[tuple[re.Pattern[str], str], ...] = (
    (re.compile(r"\bsidechain\s+pump\b", re.I), "Analog VCA glue, warm dynamic leveling"),
    (re.compile(r"\bheavier\s+sidechain\b", re.I), "heavier sustained strings, warm dynamic leveling"),
    (re.compile(r"\bsidechain\s+slam\b", re.I), "warm dynamic leveling, analog console glue"),
    (re.compile(r"\bsidechain\b", re.I), "warm dynamic leveling"),
    (re.compile(r"\bdj\s+intro\b", re.I), "Dead-room isolation, pristine studio environment, close-mic vocal tracking"),
    (re.compile(r"\bdj\s+outro\b", re.I), "Sustained studio band resolution, clean multi-track fade, trailing organ decay"),
    (re.compile(r"\bmix-out\s+groove\b", re.I), "Sustained studio band resolution, clean multi-track fade, trailing organ decay"),
    (re.compile(r"\bfull\s+satb\s+choir\s+stack\b", re.I), "Isolated multi-tracked vocal doubles, Tight double-tracked vocal stacks"),
    (re.compile(r"\bauthentic\s+congregational\s+width\b", re.I), "Multi-tracked vocal overlays, Isolated multi-tracked vocal doubles"),
    (re.compile(r"\bcongregational\s+trailing\s+ad-libs\b", re.I), "clean multi-track fade"),
    (re.compile(r"\blive\s+band\s+count-in\b", re.I), "Dead-room isolation, close-mic vocal tracking"),
    (re.compile(r"\bfilter\s+sweep\b", re.I), "natural room decay"),
    (re.compile(r"\blow-pass\s+sweep\b", re.I), "warm dynamic dip"),
    (re.compile(r"\bsupersaw\b", re.I), "lush sustained live strings"),
)


def _is_gospel_lane(primary: str, fusion: str = "") -> bool:
    blob = f"{primary} {fusion}".strip()
    return bool(blob) and _GOSPEL_LANE.search(blob) is not None


def _sanitize_gospel_bracket_inner(inner: str) -> str:
    out = inner
    for pattern, replacement in _GOSPEL_STAGING_REPLACEMENTS:
        out = pattern.sub(replacement, out)
    return out


_SECTION_MARK = re.compile(
    r"^\[(Intro|Verse\s*\d+|Chorus|Final\s+Chorus|Bridge|Outro|Pre-Chorus|Drop|Build)\]\s*$",
    re.IGNORECASE,
)
_SECTION_HEADER = re.compile(r"^\[[^\]]+\]\s*$", re.MULTILINE)

_STUDIO_VOCAL_REPLACEMENTS: tuple[tuple[re.Pattern[str], str], ...] = (
    (re.compile(r"\bstudio\s+harmonic\s+overlays\b", re.I), "Wider multi-tracked studio harmonies"),
    (re.compile(r"\bstudio\s+harmonic\s+backing\b", re.I), "Isolated multi-tracked vocal doubles"),
    (re.compile(r"\bharmonic\s+overlays\b", re.I), "Wider multi-tracked studio harmonies"),
    (re.compile(r"\bharmonic\s+backing\b", re.I), "Isolated multi-tracked vocal doubles"),
)

_INTRO_CROWD_BANS: tuple[tuple[re.Pattern[str], str], ...] = (
    (re.compile(r"\bcongregational\b", re.I), "Isolated multi-tracked vocal doubles"),
    (re.compile(r"\bsanctuary\b", re.I), "Pristine studio environment"),
    (re.compile(r"\bcommunal\b", re.I), "Multi-tracked vocal overlays"),
    (re.compile(r"\bchurch\b", re.I), "Warm studio room"),
    (re.compile(r"\bchoir\b", re.I), "Isolated multi-tracked vocal doubles"),
    (re.compile(r"\bcongregation\b", re.I), "Tight double-tracked vocal stacks"),
    (re.compile(r"\bsatb\b", re.I), "Isolated multi-tracked vocal doubles"),
    (re.compile(r"\blive\b", re.I), "Studio"),
)

_TAPE_NOISE_BANS: tuple[tuple[re.Pattern[str], str], ...] = (
    (re.compile(r"\bsubtle\s+tape\s+hiss\b", re.I), "focused studio room"),
    (re.compile(r"\btape\s+hiss\b", re.I), "dry acoustic room"),
    (re.compile(r"\bvinyl\s+crackle\b", re.I), "sparse fingerpicked acoustic guitar"),
    (re.compile(r"\broom\s+noise\b", re.I), "dead-room silence"),
)


def _is_staging_bracket(header: str) -> bool:
    if ":" in header:
        return False
    if re.match(r"^(Intro|Verse\s*\d+|Chorus|Final\s+Chorus|Bridge|Outro|Pre-Chorus|Drop|Build)\s*$", header, re.I):
        return False
    return "," in header


def _sanitize_studio_bracket_inner(
    inner: str,
    *,
    gospel: bool,
    early: bool,
    outro: bool,
) -> str:
    out = _sanitize_gospel_bracket_inner(inner) if gospel else inner
    for pattern, replacement in _STUDIO_VOCAL_REPLACEMENTS:
        out = pattern.sub(replacement, out)
    if early:
        for pattern, replacement in _INTRO_CROWD_BANS:
            out = pattern.sub(replacement, out)
    if early or outro:
        for pattern, replacement in _TAPE_NOISE_BANS:
            out = pattern.sub(replacement, out)
    return out


def sanitize_studio_isolation_tags(
    text: str,
    *,
    primary_genre: str = "",
    sub_genre_fusion: str = "",
    audio_environment_mode: str = "",
) -> str:
    """Strip crowd, harmonic-backing, and tape-noise triggers in studio-isolation mode."""
    from app.audio_environment import is_live_performance_mode

    if is_live_performance_mode(audio_environment_mode):
        return text
    if not text:
        return text

    gospel = _is_gospel_lane(primary_genre, sub_genre_fusion)
    lines = text.splitlines()
    out_lines: list[str] = []
    current_section = ""

    for line in lines:
        stripped = line.strip()
        section_match = _SECTION_MARK.match(stripped)
        if section_match:
            current_section = section_match.group(1)
            out_lines.append(line)
            continue
        if stripped.startswith("[") and _SECTION_HEADER.match(stripped):
            header = stripped[1 : stripped.rfind("]")]
            if _is_staging_bracket(header):
                early = bool(
                    re.match(r"^(Intro|Verse\s*1)\s*$", current_section, re.I)
                )
                outro = bool(re.match(r"^Outro\s*$", current_section, re.I))
                cleaned = _sanitize_studio_bracket_inner(
                    header,
                    gospel=gospel,
                    early=early,
                    outro=outro,
                )
                out_lines.append(f"[{cleaned}]")
                continue
        out_lines.append(line)

    return "\n".join(out_lines)


def sanitize_gospel_staging_tags(
    text: str,
    *,
    primary_genre: str = "",
    sub_genre_fusion: str = "",
) -> str:
    """Swap club/EDM staging leaks for sanctuary tokens when genre is gospel/worship."""
    return apply_critical_reconciliation(
        text,
        primary_genre=primary_genre,
        sub_genre_fusion=sub_genre_fusion,
    )


_ELECTRONIC_DOMINANT = re.compile(
    r"techno|edm|house|trance|amapiano|trap|dnb|drum\s+and\s+bass|hardstyle|dubstep|electro|future\s+bass|melodic\s+techno",
    re.IGNORECASE,
)

_LIVE_ACOUSTIC = re.compile(
    r"gospel|worship|praise|folk|country|acoustic|americana|bluegrass|singer-songwriter|ccm|christian|southern\s+gospel",
    re.IGNORECASE,
)

_ELECTRONIC_LEAK_PHRASES: tuple[str, ...] = (
    "sidechain pump",
    "sidechain slam",
    "sidechain",
    "drum loop",
    "16-bar dj",
    "dj intro",
    "dj outro",
    "mix-out groove",
    "mix out groove",
    "filter sweep",
    "low-pass sweep",
    "supersaw",
    "sub bloom",
    "hat rolls",
    "808 bloom",
    "riser",
)

_ACOUSTIC_MARKER = re.compile(
    r"acoustic|live drum|hammond|choir|satb|organic|folk|strings|piano|guitar|congregational",
    re.IGNORECASE,
)


def _fusion_active(fusion: str) -> bool:
    f = fusion.strip().lower()
    if not f:
        return False
    return f not in {"none", "n/a", "na", "-", "—"}


def _hybrid_split_dna_active(primary: str, fusion: str) -> bool:
    return _fusion_active(fusion) and bool(_ELECTRONIC_DOMINANT.search(primary or ""))


def _strict_reconciliation_lane(primary: str, fusion: str) -> bool:
    if _hybrid_split_dna_active(primary, fusion):
        return False
    blob = f"{primary} {fusion}".strip()
    if not blob:
        return False
    return bool(_LIVE_ACOUSTIC.search(blob)) or _is_gospel_lane(primary, fusion)


def _token_has_electronic_leak(token: str) -> bool:
    low = token.lower()
    return any(phrase in low for phrase in _ELECTRONIC_LEAK_PHRASES)


def _reconcile_bracket_inner(
    inner: str,
    *,
    strict: bool,
    hybrid: bool,
    gospel: bool,
) -> str:
    if strict or gospel:
        inner_work = _sanitize_gospel_bracket_inner(inner) if gospel else inner
        parts = [p.strip() for p in inner_work.split(",") if p.strip()]
        parts = [p for p in parts if not _token_has_electronic_leak(p)]
        return ", ".join(parts)
    if hybrid and _ACOUSTIC_MARKER.search(inner):
        parts = [p for p in parts if not _token_has_electronic_leak(p)]
        return ", ".join(parts)
    return inner


def apply_critical_reconciliation(
    text: str,
    *,
    primary_genre: str = "",
    sub_genre_fusion: str = "",
) -> str:
    """SUNO V4 §3 Critical Reconciliation — strip EDM leaks from live/gospel staging brackets."""
    if not text:
        return text
    strict = _strict_reconciliation_lane(primary_genre, sub_genre_fusion)
    hybrid = _hybrid_split_dna_active(primary_genre, sub_genre_fusion)
    gospel = _is_gospel_lane(primary_genre, sub_genre_fusion)
    if not strict and not hybrid:
        return text

    def repl(match: re.Match[str]) -> str:
        inner = _reconcile_bracket_inner(
            match.group(1),
            strict=strict,
            hybrid=hybrid,
            gospel=gospel,
        )
        return f"[{inner}]" if inner else "[]"

    return re.sub(r"\[([^\]]+)\]", repl, text)


def sanitize_suno_post_output(
    text: str,
    *,
    primary_genre: str = "",
    sub_genre_fusion: str = "",
    audio_environment_mode: str = "",
) -> str:
    """Full V2 post-output hygiene (phonetics + instrumental + reconciliation)."""
    text = sanitize_suno_lyric_phonetics(text)
    text = sanitize_instrumental_staging_tags(text)
    text = sanitize_studio_isolation_tags(
        text,
        primary_genre=primary_genre,
        sub_genre_fusion=sub_genre_fusion,
        audio_environment_mode=audio_environment_mode,
    )
    text = apply_critical_reconciliation(
        text,
        primary_genre=primary_genre,
        sub_genre_fusion=sub_genre_fusion,
    )
    return apply_audio_engine_normalization_to_suno_output(text)
