"""Generate lib/core/utils/genre_fx_matrix_data.dart from tools/genre_fx_matrix.json."""



from __future__ import annotations



import json

import sys

from pathlib import Path



root = Path(__file__).resolve().parents[1]

src = root / "tools" / "genre_fx_matrix.json"

out = root / "lib" / "core" / "utils" / "genre_fx_matrix_data.dart"



DAW_ROUTING_BANNED = (

    "sidechain",

    "brick-wall",

    "brick wall",

    "bus routing",

    "parallel compression",

    "mono-safe",

)



REQUIRED_FAMILIES = {

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

    "reggae",

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



DEFAULT_ANCHORS = ["[Chorus]"]



FAMILY_ANCHOR_FALLBACKS: dict[str, str] = {

    "boom_bap": "hiphop",

    "amapiano": "afrobeats",

    "worship": "pop",

    "mandopop": "pop",

    "world": "afrobeats",

}



FAMILY_FX_FALLBACKS: dict[str, str] = {

    "boom_bap": "hiphop",

    "amapiano": "afrobeats",

    "worship": "pop",

    "mandopop": "pop",

    "world": "afrobeats",

}





def _tier_maps(levels: dict) -> tuple[dict[str, str], dict[str, str]]:

    if "style_prompts" in levels and "lyric_injections" in levels:

        style_prompts = levels["style_prompts"]

        lyric_injections = levels["lyric_injections"]

        return (

            {tier: str(style_prompts[tier]).strip() for tier in ("1", "2", "3")},

            {tier: str(lyric_injections[tier]).strip() for tier in ("1", "2", "3")},

        )

    return (

        {tier: str(levels[tier]["style"]).strip() for tier in ("1", "2", "3")},

        {tier: str(levels[tier]["lyrics"]).strip() for tier in ("1", "2", "3")},

    )





def _primary_anchors(levels: dict, genre: str) -> list[str]:

    raw = levels.get("primary_anchors")

    if isinstance(raw, list) and raw:

        return [str(item).strip() for item in raw if str(item).strip()]

    return list(DEFAULT_ANCHORS)





ACCESSOR_BLOCK = """

  /// Golden anchors for FX injection priority (from genre_fx_matrix.json).

  static List<String> getAnchors({required String family}) {

    final key = family.trim().toLowerCase();

    final direct = primaryAnchors[key];

    if (direct != null && direct.isNotEmpty) {

      return List<String>.from(direct);

    }

    final fallbackKey = _anchorFallbackFamily(key);

    if (fallbackKey != null) {

      final fallback = primaryAnchors[fallbackKey];

      if (fallback != null && fallback.isNotEmpty) {

        return List<String>.from(fallback);

      }

    }

    return List<String>.from(DEFAULT_ANCHORS);

  }



  /// Returns [style, lyrics] pair for the given family + tier.

  /// Falls back to the nearest sibling lane if the family is missing,

  /// or to empty strings if nothing matches.

  static ({String style, String lyrics}) getFx({

    required String family,

    String tier = '1',

  }) {

    final row = profiles[family] ?? _fallbackFamily(family);

    final tierMap = row?[tier] ?? row?['2'] ?? row?['1'];

    if (tierMap == null) {

      return (style: '', lyrics: '');

    }

    return (

      style: tierMap['style'] ?? '',

      lyrics: tierMap['lyrics'] ?? '',

    );

  }



  static String? _anchorFallbackFamily(String family) {

    const fallbacks = <String, String>{

      'boom_bap': 'hiphop',

      'amapiano': 'afrobeats',

      'worship': 'pop',

      'mandopop': 'pop',

    };

    return fallbacks[family];

  }



  static Map<String, Map<String, String>>? _fallbackFamily(

    String family,

  ) {

    const fallbacks = <String, String>{

      'boom_bap': 'hiphop',

      'amapiano': 'afrobeats',

      'worship': 'pop',

      'mandopop': 'pop',

    };

    final target = fallbacks[family];

    if (target == null) return null;

    return profiles[target];

  }

  static String getLyricEngineDirectives({required String family}) {
    final key = family.trim().toLowerCase();
    final direct = lyricEngineDirectives[key];
    if (direct != null && direct.isNotEmpty) {
      return direct;
    }
    final fallbackKey = _anchorFallbackFamily(key);
    if (fallbackKey != null) {
      final fallback = lyricEngineDirectives[fallbackKey];
      if (fallback != null && fallback.isNotEmpty) {
        return fallback;
      }
    }
    return '';
  }

"""





def validate(raw: dict) -> tuple[list[str], dict[str, list[str]]]:

    """Return sorted genre keys and anchor map."""

    actual = set(raw.keys()) - {"_schema"}

    missing = REQUIRED_FAMILIES - actual

    if missing:

        raise ValueError(

            f"genre_fx_matrix.json is missing required families: {sorted(missing)}"

        )



    extras = actual - REQUIRED_FAMILIES

    if extras:

        print(

            f"WARNING: unexpected extra genre keys {sorted(extras)}",

            file=sys.stderr,

        )



    genres = sorted(k for k in raw.keys() if not k.startswith("_"))

    anchors: dict[str, list[str]] = {}

    for genre in genres:

        levels = raw[genre]

        anchors[genre] = _primary_anchors(levels, genre)

        if not anchors[genre]:

            raise ValueError(f"{genre}: primary_anchors must be non-empty")

        if "lyric_engine_directives" not in levels:
            raise ValueError(f"{genre}: missing lyric_engine_directives")



        style_prompts, lyric_injections = _tier_maps(levels)

        for tier in ("1", "2", "3"):

            style = style_prompts[tier]

            lyrics = lyric_injections[tier]

            if not style:

                raise ValueError(f"{genre}[{tier}]: missing style_prompt")

            style_lower = style.lower()

            for term in DAW_ROUTING_BANNED:

                if term in style_lower:

                    raise ValueError(

                        f'{genre}[{tier}]: banned term "{term}" in style'

                    )

            if tier == "1" and lyrics:

                raise ValueError(

                    f"{genre}[{tier}]: tier 1 lyric_injections must be empty"

                )



    return genres, anchors





def emit(raw: dict, genres: list[str], anchors: dict[str, list[str]]) -> str:

    required_list = ", ".join(sorted(REQUIRED_FAMILIES))

    lines = [

        "// GENERATED from tools/genre_fx_matrix.json — do not edit by hand.",

        "// Rebuild: python tools/gen_genre_fx_matrix_dart.py",

        "// ignore_for_file: constant_identifier_names",

        "//",

        "// Data shape: profile[genre][tier] -> { style: String, lyrics: String }",

        "// primaryAnchors[genre] -> golden anchor tags for FX injection",

        f"// Genre count: {len(genres)} | Required families: {required_list}",

        "//",

        "// Convention: tier '1' lyric_injections are empty (low-intensity = style only).",

        "",

        "class GenreFxMatrixData {",

        "  GenreFxMatrixData._();",

        "  static const List<String> DEFAULT_ANCHORS = ['[Chorus]'];",

        "  static const Map<String, List<String>> primaryAnchors = {",

    ]

    for genre in genres:

        anchor_list = json.dumps(anchors[genre], ensure_ascii=False)

        lines.append(f"    '{genre}': {anchor_list},")

    lines.append("  };")

    lines.append("  static const Map<String, String> lyricEngineDirectives = {")

    for genre in genres:

        directive = json.dumps(

            str(raw[genre].get("lyric_engine_directives", "")).strip(),

            ensure_ascii=False,

        )

        lines.append(f"    '{genre}': {directive},")

    lines.append("  };")

    lines.append("  static const Map<String, Map<String, Map<String, String>>> profiles = {")

    for genre in genres:

        style_prompts, lyric_injections = _tier_maps(raw[genre])

        lines.append(f"    '{genre}': {{")

        for tier in ("1", "2", "3"):

            style = json.dumps(style_prompts[tier], ensure_ascii=False)

            lyrics = json.dumps(lyric_injections[tier], ensure_ascii=False)

            lines.append(

                f"      '{tier}': {{'style': {style}, 'lyrics': {lyrics}}},"

            )

        lines.append("    },")

    lines.append("  };")

    lines.append(ACCESSOR_BLOCK.rstrip())

    lines.extend(["}", ""])

    return "\n".join(lines)





def main() -> None:

    raw = json.loads(src.read_text(encoding="utf-8"))

    genres, anchors = validate(raw)

    out.write_text(emit(raw, genres, anchors), encoding="utf-8")

    print(f"wrote {len(genres)} genres -> {out}")





if __name__ == "__main__":

    main()

