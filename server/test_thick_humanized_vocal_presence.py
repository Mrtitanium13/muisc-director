"""Tests for thick humanized vocal presence."""

from app.thick_humanized_vocal_presence import (
    VocalFamily,
    detect_families,
    detect_family,
    thick_humanized_vocal_user_block,
)
from app.vocal_spec_tone import GOSPEL_CHOIR_SPEC, RAP_VOCAL_SPACE_SPEC


def test_skips_instrumental_only():
    assert (
        thick_humanized_vocal_user_block(
            primary_genre="Trance",
            vocal_spec="Instrumental Only",
        )
        == ""
    )


def test_injects_pop_overlay_for_vocal_pop():
    block = thick_humanized_vocal_user_block(
        primary_genre="Pop",
        vocal_spec="Female Lead",
    )
    assert "THICK HUMANIZED VOCAL PRESENCE" in block
    assert "ultra-close-mic" in block.lower()
    assert "FAMILY OVERLAY — POP" in block


def test_edm_dense_overlay():
    for genre in ("Hardstyle", "Progressive House", "Trance", "Big Room House"):
        block = thick_humanized_vocal_user_block(
            primary_genre=genre,
            vocal_spec="Female Lead",
        )
        assert "FAMILY OVERLAY — EDM DENSE" in block


def test_normalizes_punctuated_genre_labels():
    assert detect_family("Hard-Style", "Rawstyle Fusion") == VocalFamily.EDM_DENSE
    assert detect_family("K-Pop", "") == VocalFamily.ASIAN_POP
    assert "R&B" in thick_humanized_vocal_user_block(
        primary_genre="R&B", vocal_spec="Female Lead"
    )


def test_word_boundary_matching():
    assert detect_family("Afternoon Folk Set", "") == VocalFamily.ACOUSTIC
    assert VocalFamily.AFRO not in detect_families("Afternoon Folk Set", "")
    assert detect_family("kpop", "") == VocalFamily.ASIAN_POP


def test_detect_families_fusion():
    families = detect_families("Afro House", "R&B Fusion")
    assert VocalFamily.AFRO in families
    assert VocalFamily.RNB in families
    assert families[0] == VocalFamily.AFRO

    single = thick_humanized_vocal_user_block(
        primary_genre="Afro House",
        sub_genre_fusion="R&B",
        vocal_spec="Female Lead",
    )
    assert "AFRO" in single
    assert "R&B / SOUL" not in single

    multi = thick_humanized_vocal_user_block(
        primary_genre="Afro House",
        sub_genre_fusion="R&B",
        vocal_spec="Female Lead",
        include_all_family_matches=True,
    )
    assert "AFRO" in multi
    assert "R&B / SOUL" in multi


def test_latin_and_pop_families():
    assert detect_family("Reggaeton", "") == VocalFamily.LATIN
    assert "LATIN" in thick_humanized_vocal_user_block(
        primary_genre="Reggaeton", vocal_spec="Male Lead"
    )
    assert detect_family("Bedroom Pop", "") == VocalFamily.POP


def test_falls_back_to_vocal_spec():
    # Use a genre that matches no family keyword so the spec fallback fires.
    assert "HIP-HOP" in thick_humanized_vocal_user_block(
        primary_genre="Zither Polka Fusion", vocal_spec=RAP_VOCAL_SPACE_SPEC
    )
    assert "GOSPEL" in thick_humanized_vocal_user_block(
        primary_genre="Zither Polka Fusion", vocal_spec=GOSPEL_CHOIR_SPEC
    )


def test_ambient_maps_to_acoustic_family():
    assert "ACOUSTIC" in thick_humanized_vocal_user_block(
        primary_genre="Ambient Drone", vocal_spec="Male Lead"
    )


def test_family_overlays():
    assert "HIP-HOP" in thick_humanized_vocal_user_block(
        primary_genre="Trap", vocal_spec="Male Lead"
    )
    assert "GOSPEL" in thick_humanized_vocal_user_block(
        primary_genre="Gospel", vocal_spec="Choir"
    )
    assert "AFRO" in thick_humanized_vocal_user_block(
        primary_genre="Amapiano", vocal_spec="Female Lead"
    )
    assert "ASIAN POP" in thick_humanized_vocal_user_block(
        primary_genre="K-Pop", vocal_spec="Female Lead"
    )
    assert "R&B" in thick_humanized_vocal_user_block(
        primary_genre="R&B", vocal_spec="Female Lead"
    )
    assert "ROCK" in thick_humanized_vocal_user_block(
        primary_genre="Indie Rock", vocal_spec="Male Lead"
    )
    assert "ACOUSTIC" in thick_humanized_vocal_user_block(
        primary_genre="Folk", vocal_spec="Female Lead"
    )
