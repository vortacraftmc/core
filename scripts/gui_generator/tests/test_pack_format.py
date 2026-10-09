"""Tests for the configurable pack format, the origin watermark, and the
duplicate-page-index guard.

Each of these covers a defect that was found by running the generator rather
than by reading it:

  * the pack format was a literal 122 in the generator, so targeting any other
    Minecraft version meant editing library code;
  * the generated pack carried no `_vc_origin.mcfunction`, so it could not be
    committed under `packs/` without the `zipPacks` Gradle task failing;
  * two pages declaring the same `index` were accepted with "Config OK" while
    the generator wrote both to the same file and discarded one of them.
"""

from __future__ import annotations

import json

import pytest

from guigenmc.generators import generate_datapack
from guigenmc.models import DEFAULT_PACK_FORMAT, menu_from_dict
from guigenmc.validate import validate_menu


def _cfg(**extra) -> dict:
    base = {
        "namespace": "demo",
        "menu_id": "shop",
        "pages": [
            {
                "index": 0,
                "name": "Main",
                "widgets": [
                    {
                        "kind": "button",
                        "slot": 13,
                        "item": "minecraft:diamond",
                        "commands": ["say hi"],
                    }
                ],
            }
        ],
    }
    base.update(extra)
    return base


def _meta(menu) -> dict:
    return json.loads(generate_datapack(menu)["pack.mcmeta"])["pack"]


# --------------------------------------------------------------- pack format


def test_default_format_is_the_26_4_array_form():
    """No format in the config -> the default, written as [major, minor]."""
    meta = _meta(menu_from_dict(_cfg()))
    assert meta["min_format"] == list(DEFAULT_PACK_FORMAT)
    assert meta["max_format"] == list(DEFAULT_PACK_FORMAT)


def test_legacy_pack_format_int_is_accepted_for_both_bounds():
    meta = _meta(menu_from_dict(_cfg(pack_format=107)))
    assert meta["min_format"] == [107, 0]
    assert meta["max_format"] == [107, 0]


def test_legacy_pack_format_pair_is_accepted():
    meta = _meta(menu_from_dict(_cfg(pack_format=[107, 1])))
    assert meta["min_format"] == [107, 1]
    assert meta["max_format"] == [107, 1]


def test_modern_min_max_pair_is_accepted():
    """The form that has been mandatory since 25w31a (1.21.9)."""
    meta = _meta(menu_from_dict(_cfg(min_format=[121, 0], max_format=[122, 1])))
    assert meta["min_format"] == [121, 0]
    assert meta["max_format"] == [122, 1]


def test_min_format_alone_defaults_max_to_it():
    meta = _meta(menu_from_dict(_cfg(min_format=107)))
    assert meta["min_format"] == [107, 0]
    assert meta["max_format"] == [107, 0]


def test_modern_names_win_over_legacy_when_both_present():
    meta = _meta(menu_from_dict(_cfg(pack_format=107, min_format=122, max_format=122)))
    assert meta["min_format"] == [122, 0]


def test_no_pack_format_field_is_emitted():
    """pack_format is only needed for clients older than data format 82, and
    supported_formats was removed in the same change. Emitting either would be
    wrong for the modern range the generator targets."""
    meta = _meta(menu_from_dict(_cfg()))
    assert "pack_format" not in meta
    assert "supported_formats" not in meta


def test_min_greater_than_max_is_rejected():
    with pytest.raises(ValueError, match="greater than max_format"):
        menu_from_dict(_cfg(min_format=[122, 0], max_format=[107, 0]))


@pytest.mark.parametrize(
    "value",
    ["122", [122], [122, 0, 1], 0, -1, [0, 0], [122, -1], None, True, {"a": 1}],
)
def test_malformed_format_is_rejected(value):
    with pytest.raises(ValueError):
        menu_from_dict(_cfg(pack_format=value))


# --------------------------------------------------------- origin watermark


def test_origin_watermark_is_generated_at_the_required_path():
    """`zipPacks` aborts when a datapack under packs/ has no watermark, so a
    generated pack without one could not be committed to this repository."""
    files = generate_datapack(menu_from_dict(_cfg()))
    assert "data/demo/function/_vc_origin.mcfunction" in files


def test_origin_watermark_names_its_own_pack():
    body = generate_datapack(menu_from_dict(_cfg()))[
        "data/demo/function/_vc_origin.mcfunction"
    ]
    assert 'namespace "demo" / menu "shop"' in body
    assert "vortacraftmc/core - Provenance Watermark" in body


def test_origin_watermark_survives_a_custom_namespace():
    files = generate_datapack(menu_from_dict(_cfg(namespace="other_ns")))
    assert "data/other_ns/function/_vc_origin.mcfunction" in files


# ------------------------------------------------- duplicate page index guard


def test_duplicate_page_index_is_reported():
    """Reproduces the silent data loss: both pages write to
    menu/<menu>/page/0.mcfunction, so the second overwrites the first."""
    menu = menu_from_dict(
        _cfg(
            pages=[
                {"index": 0, "name": "First", "widgets": []},
                {"index": 0, "name": "Second", "widgets": []},
            ]
        )
    )
    warnings = validate_menu(menu)
    assert any("Page index 0 is used by 2 pages" in w for w in warnings)
    assert any('"First"' in w and '"Second"' in w for w in warnings)


def test_duplicate_index_actually_collapses_the_output():
    """The warning is not cosmetic - confirm the loss it describes is real."""
    menu = menu_from_dict(
        _cfg(
            pages=[
                {
                    "index": 0,
                    "name": "First",
                    "widgets": [
                        {"kind": "button", "slot": 10, "id": "alpha",
                         "item": "minecraft:diamond"}
                    ],
                },
                {
                    "index": 0,
                    "name": "Second",
                    "widgets": [
                        {"kind": "button", "slot": 11, "id": "beta",
                         "item": "minecraft:gold_ingot"}
                    ],
                },
            ]
        )
    )
    files = generate_datapack(menu)
    page_files = [p for p in files if "/page/" in p and p.endswith(".mcfunction")]
    assert len(page_files) == 1, page_files
    assert validate_menu(menu), "the collapse must be reported, not silent"


def test_distinct_indices_are_not_reported():
    menu = menu_from_dict(
        _cfg(
            pages=[
                {"index": 0, "name": "A", "widgets": []},
                {"index": 1, "name": "B", "widgets": []},
            ]
        )
    )
    assert not any("is used by" in w for w in validate_menu(menu))
