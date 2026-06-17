"""Strip internal cognition blocks leaked by the model (e.g. master_blueprint)."""

from __future__ import annotations

import re

_INTERNAL_TAGS = ("master_blueprint", "psychology_audit", "lyric_audit")


def _strip_tag_block(text: str, tag: str) -> str:
    closed = re.compile(
        rf"<{tag}\b[^>]*>.*?</{tag}>",
        re.IGNORECASE | re.DOTALL,
    )
    open_only = re.compile(
        rf"<{tag}\b[^>]*>.*",
        re.IGNORECASE | re.DOTALL,
    )
    out = closed.sub("", text)
    if f"<{tag}" in out.lower():
        out = open_only.sub("", out)
    return out


def strip_internal_cognition_blocks(text: str) -> str:
    """Remove hidden chain-of-thought blocks; keep BLOCK 1 + BLOCK 2 product shape."""
    if not text:
        return text
    lower = text.lower()
    if not any(f"<{tag}" in lower for tag in _INTERNAL_TAGS):
        return text
    out = text
    for tag in _INTERNAL_TAGS:
        out = _strip_tag_block(out, tag)
    out = re.sub(r"\n{3,}", "\n\n", out)
    return out.strip()
