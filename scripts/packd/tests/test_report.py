"""Tests for the shared status reporter.

`packd check` and `packd update` used to render a pack with two separate copies
of this text; the one behind the default command printed only a total. These
pin the shared rendering so neither can quietly regress to printing less.
"""
from __future__ import annotations

from packd.config import PackConfig
from packd.github import Commit
from packd.report import MAX_COMMITS_SHOWN, describe, describe_all
from packd.updater import PackStatus

PACK = PackConfig(name="demo", repo_path="packs/demo")


def commit(i: int) -> Commit:
    return Commit(sha=f"{i:x}" * 40, message=f"change {i}", date="", author="me", url="")


def make(**kwargs) -> PackStatus:
    base = dict(pack=PACK, installed_sha="", latest_sha="b" * 40, behind=[])
    base.update(kwargs)
    return PackStatus(**base)


def say(entry: PackStatus) -> str:
    out: list[str] = []
    describe(entry, out.append)
    return "\n".join(out)


class TestDescribe:
    def test_up_to_date_is_marked_equal(self):
        assert "= demo: up to date (aaaaaaa)" in say(make(installed_sha="a" * 40, latest_sha="a" * 40))

    def test_update_shows_both_revisions_and_the_gap(self):
        text = say(make(installed_sha="a" * 40, latest_sha="b" * 40, behind=[commit(1)]))
        assert "aaaaaaa" in text and "bbbbbbb" in text and "1 commit(s)" in text

    def test_a_missing_install_is_said_plainly(self):
        assert "(not installed)" in say(make())

    def test_an_error_wins_over_the_revision_line(self):
        text = say(make(installed_sha="a" * 40, error="nope"))
        assert "! demo: nope" in text and "^" not in text

    def test_unresolved_upstream_is_flagged_as_unknown(self):
        assert "?" in say(make(latest_sha=""))

    def test_commits_are_listed_then_truncated_with_a_true_remainder(self):
        commits = [commit(i) for i in range(MAX_COMMITS_SHOWN + 3)]
        text = say(make(behind=commits))
        assert "change 0" in text
        assert f"and {len(commits) - MAX_COMMITS_SHOWN} more" in text

    def test_no_truncation_line_when_everything_fits(self):
        assert "more" not in say(make(behind=[commit(1), commit(2)]))


class TestDescribeAll:
    def test_returns_the_number_of_outdated_packs(self):
        assert describe_all([make(), make()], lambda _s: None) == 2

    def test_errors_and_current_packs_are_not_counted_as_outdated(self):
        entries = [
            make(error="x"),
            make(installed_sha="a" * 40, latest_sha="a" * 40),
            make(),
        ]
        assert describe_all(entries, lambda _s: None) == 1

    def test_every_pack_is_printed(self):
        out: list[str] = []
        describe_all([make(), make(error="x")], out.append)
        assert any("demo" in line for line in out)
