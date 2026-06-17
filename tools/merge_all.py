"""Run all source-to-generated merges for Music Director.

Canonical rebuild after editing tools/*.txt prompt sources or tools/*.json matrix sources:

    python tools/merge_all.py

Runs merge_suno_v2_prompt.py plus every matrix Dart generator. Server matrix modules
read JSON from tools/ directly; only Flutter needs the generated Dart data files.
"""

from __future__ import annotations

import subprocess
import sys
from pathlib import Path

root = Path(__file__).resolve().parents[1]

GENERATORS = (
    "tools/merge_suno_v2_prompt.py",
    "tools/gen_drum_matrix_dart.py",
    "tools/gen_live_instrument_matrix_dart.py",
    "tools/gen_code_translation_matrix_dart.py",
    "tools/gen_genre_hardware_modules.py",
    "tools/gen_genre_fx_matrix_dart.py",
)


def main() -> None:
    for rel in GENERATORS:
        path = root / rel
        if not path.is_file():
            raise SystemExit(f"Missing generator: {rel}")
        print(f"--- {rel} ---")
        subprocess.run([sys.executable, str(path)], cwd=root, check=True)
    print("All merges complete.")


if __name__ == "__main__":
    main()
