"""Mandatory Block 1 mix/master/hardware user-block (Part E v2.1)."""

from __future__ import annotations

from app.genre_hardware_profiles import hardware_profile_user_block


def block1_mix_master_user_block(
    *,
    primary_genre: str,
    sub_genre_fusion: str = "",
    dj_intro: bool = False,
    dj_outro: bool = False,
) -> str:
    return hardware_profile_user_block(
        primary_genre=primary_genre,
        sub_genre_fusion=sub_genre_fusion,
        dj_intro=dj_intro,
        dj_outro=dj_outro,
    )
