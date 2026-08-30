"""Regression tests for genre_fx_matrix.json and the Dart generator."""



from __future__ import annotations



import json

import subprocess

from pathlib import Path



ROOT = Path(__file__).resolve().parents[1]





def test_required_families_present() -> None:

    data = json.loads((ROOT / "tools" / "genre_fx_matrix.json").read_text())

    required = {

        "edm",

        "techno",

        "hardstyle",

        "dnb",

        "synthwave",

        "dubstep",

        "ambient",

        "hiphop",

        "trap",

        "boom_bap",

        "amapiano",

        "pop",

        "rnb",

        "reggaeton",

        "latin",

        "rock",

        "metal",

        "indie",

        "country",

        "folk",

        "afrobeats",

        "cinematic",

        "jazz",

        "worship",

        "mandopop",

        "world",

    }

    actual = {k for k in data.keys() if not k.startswith("_")}

    missing = required - actual

    assert not missing, f"Missing families: {missing}"





def test_schema_completeness() -> None:

    data = json.loads((ROOT / "tools" / "genre_fx_matrix.json").read_text())

    for family in data:

        if family.startswith("_"):

            continue

        row = data[family]

        assert "primary_anchors" in row, f"{family}: missing primary_anchors"

        assert row["primary_anchors"], f"{family}: primary_anchors empty"

        assert "style_prompts" in row, f"{family}: missing style_prompts"

        assert "lyric_injections" in row, f"{family}: missing lyric_injections"

        for tier in ("1", "2", "3"):

            assert tier in row["style_prompts"], f"{family}: missing style tier {tier}"

            assert tier in row["lyric_injections"], (

                f"{family}: missing lyric tier {tier}"

            )

            assert row["style_prompts"][tier].strip(), (

                f"{family}[{tier}]: empty style_prompt"

            )

            if tier == "1":

                assert not row["lyric_injections"][tier].strip(), (

                    f"{family}[{tier}]: tier 1 lyric_injections must be empty"

                )





def test_no_daw_jargon_in_style() -> None:

    data = json.loads((ROOT / "tools" / "genre_fx_matrix.json").read_text())

    banned = ("sidechain", "brick-wall", "brick wall", "bus routing")

    for family in data:

        if family.startswith("_"):

            continue

        for tier in ("1", "2", "3"):

            style = data[family]["style_prompts"][tier].lower()

            for term in banned:

                assert term not in style, (

                    f'{family}[{tier}]: banned term "{term}" in style'

                )





def test_lyrics_bracket_style_normalized() -> None:

    data = json.loads((ROOT / "tools" / "genre_fx_matrix.json").read_text())

    for family in data:

        if family.startswith("_"):

            continue

        for tier in ("1", "2", "3"):

            lyrics = data[family]["lyric_injections"][tier]

            assert lyrics == lyrics.strip(), (

                f"{family}[{tier}]: lyrics has surrounding whitespace"

            )

            if lyrics:

                assert not (lyrics.startswith("*") or lyrics.startswith("-")), (

                    f"{family}[{tier}]: lyrics uses non-bracket style"

                )





def test_generator_idempotent() -> None:

    dart_file = ROOT / "lib" / "core" / "utils" / "genre_fx_matrix_data.dart"

    subprocess.run(

        ["python", "tools/gen_genre_fx_matrix_dart.py"],

        cwd=ROOT,

        check=True,

    )

    first = dart_file.read_text(encoding="utf-8")

    subprocess.run(

        ["python", "tools/gen_genre_fx_matrix_dart.py"],

        cwd=ROOT,

        check=True,

    )

    second = dart_file.read_text(encoding="utf-8")

    assert first == second, "Generator is not idempotent"





if __name__ == "__main__":

    test_required_families_present()

    test_schema_completeness()

    test_no_daw_jargon_in_style()

    test_lyrics_bracket_style_normalized()

    test_generator_idempotent()

    print("All Python tests passed")

