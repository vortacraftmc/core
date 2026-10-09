"""SNBT encoding and the RCON size limit.

Issue titles and bodies come from GitHub, and anyone can open an issue, so
their text is attacker-controlled and ends up inside a command string. These
tests are the reason :func:`packd.issues.snbt_string` escapes rather than
interpolates.
"""

from __future__ import annotations

import pytest

from packd.issues import (
    MAX_BODY,
    MAX_BODY_PREVIEW,
    _render,
    STORAGE_ID,
    build_issues_commands,
    clear_command,
    issue_entry,
    refresh_command,
    snbt_string,
)
from packd.rcon import CommandPolicy, RconPolicyError
from packd.github import Issue


def make_issue(number: int = 1, title: str = "Title", body: str = "Body") -> Issue:
    return Issue(
        number=number,
        title=title,
        state="open",
        author="someone",
        created="2026-01-01T00:00:00Z",
        updated="2026-01-02T00:00:00Z",
        url=f"https://github.com/vortacraftmc/core/issues/{number}",
        labels=("bug",),
        body=body,
    )


# ------------------------------------------------------------------ escaping


def test_plain_text_round_trips():
    assert snbt_string("hello world") == '"hello world"'


def test_double_quote_is_escaped():
    assert snbt_string('say "hi"') == '"say \\"hi\\""'


def test_backslash_is_escaped():
    assert snbt_string("a\\b") == '"a\\\\b"'


def test_backslash_before_quote_cannot_reopen_the_string():
    """`\\"` unescaped would close the string and start a new command."""
    encoded = snbt_string('x\\" ,y:1}')
    assert encoded == '"x\\\\\\" ,y:1}"'
    # The quote is preceded by an escaped backslash, so it is still literal.
    assert '\\\\"' in encoded


@pytest.mark.parametrize("control", ["\n", "\r", "\t", "\x00", "\x1b", "\x7f"])
def test_control_characters_are_replaced_not_escaped(control):
    """A literal control character in a command body is what breaks packet
    framing, and SNBT's escape support varies by context, so these become
    spaces."""
    encoded = snbt_string(f"a{control}b")
    assert control not in encoded
    assert encoded == '"a b"'


def test_newline_cannot_smuggle_a_second_command():
    """The specific attack: a title ending in a newline plus `stop`."""
    encoded = snbt_string("innocent\nstop")
    assert "\n" not in encoded
    assert encoded == '"innocent stop"'


@pytest.mark.parametrize(
    "hostile",
    [
        'x",y:1} ,{z:2',            # close the string and the compound
        "x\" ,url:\"http://evil",    # inject a different url
        'x\\",y:1}',                 # escaped-quote trick
        "a\nb\rc\x00d",              # control characters
        '"',                         # just a quote
        "\\",                        # just a backslash
        '"}}}}',                     # brace spam
    ],
)
def test_hostile_text_stays_inside_one_string(hostile):
    """Whatever the input, the output is exactly one quoted SNBT string."""
    encoded = snbt_string(hostile)
    assert encoded.startswith('"') and encoded.endswith('"')
    inner = encoded[1:-1]
    # Every quote inside must be preceded by an unescaped backslash.
    i = 0
    while i < len(inner):
        if inner[i] == "\\":
            i += 2  # skip the escaped pair
            continue
        assert inner[i] != '"', f"unescaped quote in {encoded!r}"
        i += 1


def test_long_text_is_truncated():
    encoded = snbt_string("y" * 500, limit=20)
    assert len(encoded) <= 22  # 20 chars + the two quotes
    assert encoded.endswith('\u2026"')


# -------------------------------------------------------------------- shape


def test_entry_has_every_field_the_datapack_reads():
    entry = issue_entry(make_issue(number=42, title="Broken", body="First line"), with_body=True)
    for fragment in (
        "number:42",
        'title:"Broken"',
        'state:"open"',
        'author:"someone"',
        "labels:[",
        "url:",
        'preview:"First line"',
    ):
        assert fragment in entry, f"missing {fragment}"
    assert entry.startswith("{") and entry.endswith("}")


def test_body_preview_skips_html_comments():
    issue = make_issue(body="<!-- template -->\n\nThe real first line")
    assert issue.short_body == "The real first line"
    assert "template" not in issue_entry(issue, with_body=True)


def test_without_body_the_preview_is_empty_but_present():
    assert 'preview:""' in issue_entry(make_issue(body="secret"), with_body=False)
    assert "secret" not in issue_entry(make_issue(body="secret"), with_body=False)


# --------------------------------------------------------------------- size


def test_small_list_fits_in_one_command():
    payload = build_issues_commands(
        [make_issue(i) for i in range(1, 4)], fetched_at="2026-01-01T00:00:00Z"
    )
    assert len(payload.commands) == 1
    assert payload.included == 3
    assert payload.truncated is False


def test_every_command_is_within_the_rcon_body_limit():
    """The whole point of measuring: a command too long for a packet fails at
    the socket, after the server has already been told to expect it."""
    issues = [make_issue(i, title=f"Issue {i} " + "t" * 100, body="b" * 400) for i in range(60)]
    payload = build_issues_commands(issues, fetched_at="2026-01-01T00:00:00Z")
    assert payload.commands, "must always produce at least one command"
    for command in payload.commands:
        assert len(command) <= MAX_BODY, f"{len(command)} > {MAX_BODY}"
    assert payload.total == 60
    assert payload.included < 60
    assert payload.truncated is True


def test_degrades_by_dropping_bodies_before_dropping_issues():
    """Body previews are the cheaper thing to lose, so they go first.

    Sized so that the full list *with* bodies overflows the command limit but
    the same list *without* them fits - that is the exact branch under test.
    (Body text is capped at MAX_BODY_PREVIEW, so a handful of short issues
    never reaches it; this needs enough of them to actually overflow.)
    """
    # Find the smallest count that overflows with bodies. Asserting the
    # preconditions below means a change to MAX_BODY_PREVIEW or MAX_BODY makes
    # this test fail loudly instead of silently testing nothing.
    count = next(
        n
        for n in range(2, 200)
        if len(_render([make_issue(i, title=f"#{i}", body="b" * 400) for i in range(n)],
                       with_body=True, fetched_at="2026-01-01T00:00:00Z")) + 38 > MAX_BODY
    )
    issues = [make_issue(i, title=f"#{i}", body="b" * 400) for i in range(count)]
    payload = build_issues_commands(issues, fetched_at="2026-01-01T00:00:00Z")

    with_bodies = _render(issues, with_body=True, fetched_at="2026-01-01T00:00:00Z")
    without_bodies = _render(issues, with_body=False, fetched_at="2026-01-01T00:00:00Z")
    overhead = len("data merge storage macroengine:issues ")
    assert len(with_bodies) + overhead > MAX_BODY, "test needs the full payload to overflow"
    assert len(without_bodies) + overhead <= MAX_BODY, "test needs the bodyless payload to fit"

    assert payload.included == count, "no issue should have been dropped"
    assert payload.with_body is False, "bodies should go before issues do"
    assert MAX_BODY_PREVIEW > 0


def test_empty_list_still_produces_a_valid_command():
    payload = build_issues_commands([], fetched_at="2026-01-01T00:00:00Z")
    assert len(payload.commands) == 1
    assert "count:0" in payload.commands[0]
    assert "issues:[]" in payload.commands[0]


def test_a_single_absurd_issue_still_yields_a_sendable_command():
    """One issue whose title alone exceeds the limit must not wedge the loop."""
    huge = make_issue(1, title="x" * 5000, body="y" * 5000)
    payload = build_issues_commands([huge], fetched_at="2026-01-01T00:00:00Z")
    assert len(payload.commands) == 1
    assert len(payload.commands[0]) <= MAX_BODY


def test_custom_max_body_is_respected():
    payload = build_issues_commands(
        [make_issue(i) for i in range(5)], fetched_at="now", max_body=200
    )
    for command in payload.commands:
        assert len(command) <= 200


# ------------------------------------------------- the commands are sendable


def test_generated_commands_pass_the_rcon_allowlist():
    """End-to-end: what this module builds must be something the client will
    actually send. A mismatch here would only show up at runtime."""
    policy = CommandPolicy()
    payload = build_issues_commands(
        [make_issue(i, title=f"t{i}", body="b" * 100) for i in range(20)],
        fetched_at="2026-01-01T00:00:00Z",
    )
    for command in payload.commands:
        policy.check(command)
    policy.check(clear_command())
    policy.check(refresh_command("macroengine"))
    policy.check(refresh_command("guikit"))


def test_refresh_command_rejects_other_namespaces():
    with pytest.raises(Exception, match="unsupported namespace"):
        refresh_command("macroengine:evil")


def test_storage_id_matches_what_the_datapack_reads():
    assert STORAGE_ID == "macroengine:issues"
    assert clear_command() == "data remove storage macroengine:issues"
