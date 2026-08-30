#!/usr/bin/env python3
"""Chorus-only smoke for gospel / EDM / hardstyle / amapiano master injection.

Usage (server must be up with SONGWRITER_PIPELINE=1):
    python scripts/smoke_songwriter_masters.py
"""

from __future__ import annotations

import json
import sys
import urllib.error
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
BASE = "http://127.0.0.1:8080"

CASES = [
    {
        "genre": "Amapiano",
        "subgenre": "",
        "mood": "late-night groove",
        "theme": "soft flex, rooftop afterparty, leave space for log drum",
        "expect_lane": "amapiano",
    },
    {
        "genre": "Gospel",
        "subgenre": "",
        "mood": "hopeful testimony",
        "theme": "walking out of doubt into quiet praise",
        "expect_lane": "gospel",
    },
    {
        "genre": "Hardstyle",
        "subgenre": "",
        "mood": "festival euphoria",
        "theme": "raw release on the drop without crowd-cheer lyrics",
        "expect_lane": "hardstyle",
    },
    {
        "genre": "EDM",
        "subgenre": "Progressive House",
        "mood": "build and release",
        "theme": "night drive toward the drop, short chantable hook",
        "expect_lane": "edm",
    },
]


def _get(path: str) -> dict:
    with urllib.request.urlopen(f"{BASE}{path}", timeout=30) as r:
        return json.loads(r.read().decode("utf-8"))


def _post(path: str, body: dict, timeout: float = 900) -> dict:
    data = json.dumps(body).encode("utf-8")
    req = urllib.request.Request(
        f"{BASE}{path}",
        data=data,
        headers={"Content-Type": "application/json"},
        method="POST",
    )
    with urllib.request.urlopen(req, timeout=timeout) as r:
        return json.loads(r.read().decode("utf-8"))


def main() -> int:
    try:
        health = _get("/health")
        status = _get("/songwriter/status")
    except Exception as e:
        print(f"FAIL — server not reachable: {e}")
        return 1

    if not status.get("enabled"):
        print("FAIL — SONGWRITER_PIPELINE is not enabled")
        return 1

    print(f"OK health={health} songwriter_enabled={status.get('enabled')}")
    results = []
    failed = 0

    for case in CASES:
        label = f"{case['genre']}/{case['subgenre'] or '-'}"
        print(f"\n--- smoke {label} (chorus_only / fast) ---")
        body = {
            "genre": case["genre"],
            "subgenre": case["subgenre"],
            "mood": case["mood"],
            "theme": case["theme"],
            "story": case["theme"],
            "language": "English",
            "mode": "chorus_only",
            "quality_mode": "fast",
            "energy": 70,
            "perspective": "I",
        }
        try:
            out = _post("/generate-lyrics", body, timeout=900)
        except urllib.error.HTTPError as e:
            detail = e.read().decode("utf-8", errors="replace")
            print(f"HTTP {e.code}: {detail[:500]}")
            failed += 1
            results.append({"label": label, "ok": False, "error": detail[:200]})
            continue
        except Exception as e:
            print(f"ERROR: {e}")
            failed += 1
            results.append({"label": label, "ok": False, "error": str(e)})
            continue

        meta = out.get("metadata") or {}
        lane = meta.get("genreLyricMasterLane")
        injected = meta.get("genreLyricEngineInjected")
        truncated = meta.get("genreLyricEngineTruncated")
        raw = meta.get("genreLyricEngineRawChars")
        chars = meta.get("genreLyricEngineChars")
        lyrics = (out.get("lyrics") or "").strip()
        ok = (
            bool(injected)
            and lane == case["expect_lane"]
            and not truncated
            and bool(lyrics)
        )
        if not ok:
            failed += 1
        print(
            f"lane={lane} expect={case['expect_lane']} injected={injected} "
            f"trunc={truncated} raw={raw} out={chars} "
            f"quality={out.get('quality_status')} ship={out.get('ship')} "
            f"lyrics_chars={len(lyrics)} ok={ok}"
        )
        if lyrics:
            preview = lyrics.replace("\n", " | ")[:180]
            print(f"preview: {preview}")
        results.append(
            {
                "label": label,
                "ok": ok,
                "lane": lane,
                "injected": injected,
                "truncated": truncated,
                "quality_status": out.get("quality_status"),
                "lyrics_chars": len(lyrics),
            }
        )

    print("\n======== SUMMARY ========")
    for r in results:
        mark = "PASS" if r.get("ok") else "FAIL"
        print(f"{mark}  {r.get('label')}  {json.dumps({k: v for k, v in r.items() if k != 'label'})}")

    out_path = ROOT / "scripts" / "_smoke_songwriter_masters_last.json"
    out_path.write_text(json.dumps(results, indent=2), encoding="utf-8")
    print(f"\nWrote {out_path}")
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
