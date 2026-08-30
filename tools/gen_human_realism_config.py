"""Generate lib/core/constants/human_realism_config.dart from tools/human_realism_config.json."""

from __future__ import annotations

import json
from pathlib import Path

root = Path(__file__).resolve().parents[1]
src = root / "tools" / "human_realism_config.json"
out = root / "lib" / "core" / "constants" / "human_realism_config.dart"


def emit(raw: dict) -> str:
    schema = raw["_schema"]
    default_level = schema["default_level"]
    min_level = schema["min_level"]
    max_level = schema["max_level"]
    helper = json.dumps(raw["helper_text"], ensure_ascii=False)
    header = json.dumps(raw["user_block_header"], ensure_ascii=False)
    guardrail = json.dumps(raw["low_poetic_guardrail"], ensure_ascii=False)

    band_entries = []
    instruction_entries = []
    for band in raw["bands"]:
        lo, hi = band["min"], band["max"]
        label = json.dumps(band["label"], ensure_ascii=False)
        band_entries.append(f"    ({lo}, {hi}): {label},")
        instr = json.dumps(band["instructions"], ensure_ascii=False)
        instruction_entries.append(f"    ({lo}, {hi}): {instr},")

    return f"""// GENERATED from tools/human_realism_config.json — do not edit by hand.
// Rebuild: python tools/gen_human_realism_config.py

import 'elite_human_lyricist_directive.dart';

/// Human Realism slider (0–100) — lyric authenticity vs polished AI writing.
class HumanRealismConfig {{
  HumanRealismConfig._();

  static const int defaultLevel = {default_level};
  static const int minLevel = {min_level};
  static const int maxLevel = {max_level};

  static const String helperText = {helper};

  static const Map<(int, int), String> _bandLabels = {{
{chr(10).join(band_entries)}
  }};

  static const Map<(int, int), String> _bandInstructions = {{
{chr(10).join(instruction_entries)}
  }};

  static const String _userBlockHeader = {header};
  static const String _lowPoeticGuardrail = {guardrail};

  static int clampLevel(int value) =>
      value.clamp(minLevel, maxLevel).toInt();

  static String bandLabel(int raw) {{
    final v = clampLevel(raw);
    for (final entry in _bandLabels.entries) {{
      final (lo, hi) = entry.key;
      if (v >= lo && v <= hi) return entry.value;
    }}
    return 'Balanced';
  }}

  static String _instructionsFor(int level) {{
    final v = clampLevel(level);
    for (final entry in _bandInstructions.entries) {{
      final (lo, hi) = entry.key;
      if (v >= lo && v <= hi) return entry.value;
    }}
    return _bandInstructions[(41, 60)]!;
  }}

  /// Injected into the Suno user block when Block 2 lyrics are expected.
  static String userBlockDirective(
    int raw, {{
    String? dialectStyleId,
  }}) {{
    final level = clampLevel(raw);
    final band = _instructionsFor(level);
    final lines = <String>[
      EliteHumanLyricistDirective.userBlockPrefix(
        dialectStyleId: dialectStyleId,
      ),
      '',
      _userBlockHeader,
      band,
      '',
      'Human Realism Level: $level/100',
      'Adjust lyric generation accordingly.',
      'Higher values: increase authenticity, specificity, conversational language, and imperfections; '
      'decrease metaphor density, poetic abstraction, and forced rhyming.',
      'Lower values: increase lyricism, poetic imagery, technical rhymes, and stylization.',
      'Maintain genre conventions while applying the realism level.',
    ];
    if (level <= 40) {{
      lines.add(_lowPoeticGuardrail);
    }}
    return lines.join('\\n');
  }}
}}
"""


def main() -> None:
    raw = json.loads(src.read_text(encoding="utf-8"))
    out.write_text(emit(raw), encoding="utf-8")
    print(f"wrote {out}")


if __name__ == "__main__":
    main()
