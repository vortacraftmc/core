"""Packaging metadata tests.

These cover problems that are invisible when running from a source tree: the
version was declared in two files, the project URLs pointed at a repository
that does not exist, and the README told people to `pip install` a package that
was never published.

Written against the file text rather than a TOML parser on purpose. `tomllib`
only exists on Python 3.11+, and this project supports 3.9 (see
`requires-python`), so a tomllib-based test would silently skip on the CI job
that needs it most.
"""

from __future__ import annotations

import re
from pathlib import Path

import pytest

ROOT = Path(__file__).resolve().parent.parent
PYPROJECT = (ROOT / "pyproject.toml").read_text(encoding="utf-8")
README = (ROOT / "README.md").read_text(encoding="utf-8")

# The [project] table only - stops a later table's keys matching by accident.
PROJECT = PYPROJECT.split("[project]", 1)[1].split("[project.urls]", 1)[0]


def _url(key: str) -> str:
    m = re.search(rf'^{key}\s*=\s*"([^"]+)"', PYPROJECT, re.M)
    assert m, f"{key} not declared in [project.urls]"
    return m.group(1)


# ------------------------------------------------------------------ version


def test_version_is_declared_once():
    """`__version__` is the single source of truth; pyproject must read it
    dynamically rather than repeating it, or the installed metadata and
    `guigenmc --version` can disagree."""
    assert not re.search(r'^version\s*=\s*"', PROJECT, re.M), (
        "pyproject must not hardcode a version"
    )
    assert re.search(r'^dynamic\s*=\s*\["version"\]', PROJECT, re.M)
    assert 'version = { attr = "guigenmc.__version__" }' in PYPROJECT


def test_declared_version_is_a_valid_pep440_string():
    from guigenmc import __version__

    assert re.fullmatch(r"\d+\.\d+\.\d+([abrc.]\d+)?", __version__), __version__


def test_no_stale_version_string_lingers_in_pyproject():
    """Guards the failure mode the dynamic config exists to prevent: someone
    re-adds a literal version, or bumps one file and not the other."""
    from guigenmc import __version__

    assert f'version = "{__version__}"' not in PROJECT


def test_cli_reports_the_same_version(capsys):
    """The whole point of the dynamic version: what `guigenmc --version` prints
    and what the built metadata declares must be the same string."""
    from guigenmc import __version__
    from guigenmc.cli import main

    with pytest.raises(SystemExit) as exc:
        main(["--version"])
    assert exc.value.code == 0
    assert capsys.readouterr().out.strip() == f"guigenmc {__version__}"


# ------------------------------------------------------------- project urls


@pytest.mark.parametrize(
    "key", ["Homepage", "Documentation", "Repository", "Issues", "Changelog"]
)
def test_project_urls_point_at_this_repository(key):
    """All five used to point at github.com/guigenmc/guigenmc, which answers
    404 - an org and repo that do not exist. These are the URLs shown on the
    published package page."""
    url = _url(key)
    assert url.startswith("https://github.com/vortacraftmc/core"), url
    assert "guigenmc/guigenmc" not in url


def test_documentation_url_points_at_this_tool_not_the_monorepo_root():
    assert "scripts/gui_generator" in _url("Documentation")


# ------------------------------------------------------------------ licence


def test_licence_uses_the_spdx_string_form():
    """setuptools stops supporting `license` as a table on 2027-Feb-18, and the
    build warns about it until then."""
    assert re.search(r'^license\s*=\s*"MIT"', PROJECT, re.M)
    assert "license = {" not in PYPROJECT
    assert "License ::" not in PYPROJECT, (
        "the License :: classifier is deprecated alongside the table form"
    )


def test_setuptools_floor_can_actually_build_this_pyproject():
    """The SPDX licence form needs setuptools>=77; the pinned floor must not
    claim a version that cannot build the file."""
    m = re.search(r'"setuptools>=(\d+)', PYPROJECT)
    assert m, "setuptools requirement not found"
    assert int(m.group(1)) >= 77


# ------------------------------------------------------------------- README


def test_readme_does_not_claim_a_pypi_install():
    """`pip install guigenmc` cannot work: pypi.org/simple/guigenmc/ is a 404
    and pip reports no matching distribution. The README said to run it.

    Only fenced code blocks are checked - the prose mentions the command in
    order to say it does not work, which is the correction, not the claim.
    """
    code_blocks = re.findall(r"```[a-z]*\n(.*?)```", README, re.S)
    assert code_blocks, "README has no fenced code blocks - is the regex stale?"
    runnable = "\n".join(code_blocks)
    assert "pip install guigenmc" not in runnable
    assert "not published to PyPI" in README


def test_readme_install_commands_reference_a_path_that_exists():
    assert "pip install ./scripts/gui_generator" in README
    assert "subdirectory=scripts/gui_generator" in README
    assert (ROOT.parent.parent / "scripts" / "gui_generator").is_dir()


def test_readme_publish_section_does_not_name_a_missing_workflow():
    """It named `publish.yml` and Repository `guigenmc`; neither exists."""
    publish = README.split("## Publish", 1)[1]
    assert "Repository: `core`" in publish
    assert "vortacraftmc" in publish
