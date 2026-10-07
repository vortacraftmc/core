#!/usr/bin/env python3
"""
vortacraftmc - comprehensive consistency audit.

Audits the whole organization, not just the working tree:

  A. Org                 plan, 2FA, profile, member/repository-creation policy
  B. Repository settings description, topics, homepage, default branch
  C. Security            secret scanning, push protection, Dependabot,
                         private vulnerability reporting, rulesets
  D. Branch/Tag/Release  stale branches, backup tags, release hygiene
  E. Actions             workflows, secret/variable names, run health
  F. PR/Issue            open PRs, stale issues
  G. Git history         meaningless commit messages, repository size
  H. Local content       pack layout problems found by scripts/audit_repo.py
  I. Community health    README, license, contributing, issue templates

Usage:
    python3 scripts/audit_full.py --org vortacraftmc
    python3 scripts/audit_full.py --org vortacraftmc --json
    python3 scripts/audit_full.py --org vortacraftmc --fix [--dry-run]
    python3 scripts/audit_full.py --org vortacraftmc --log audit-run.log

The token is read from VC_TOKEN or GH_TOKEN, or from a file given by
VC_TOKEN_FILE. It is never printed and never put on a command line.
"""
from __future__ import annotations

import argparse
import json
import os
import re
import subprocess
import sys
import time
import urllib.error
import urllib.request
from collections import defaultdict

API = "https://api.github.com"
SEV_ORDER = {"high": 0, "medium": 1, "low": 2, "info": 3}
ICON = {"high": "!", "medium": "o", "low": "-", "info": "i"}

TOKEN = None
FINDINGS: list[dict] = []
LOG_LINES: list[str] = []


def out(msg=""):
    LOG_LINES.append(msg)
    print(msg)


# --------------------------------------------------------------------------- #
# HTTP with retry
# --------------------------------------------------------------------------- #


def gh(path, method="GET", body=None, expect=(200, 201, 204)):
    """Call the GitHub API. Retries 4x with linear backoff on 5xx/429.

    GitHub's write path can degrade to HTTP 500 with an empty body for several
    minutes while reads keep working and the status page still reports
    "All Systems Operational". Without this retry a --fix run would silently
    apply nothing.
    """
    url = path if path.startswith("http") else f"{API}{path}"
    data = None
    if body is not None:
        data = json.dumps(body).encode()
    last = None
    for attempt in range(4):
        req = urllib.request.Request(url, data=data, method=method)
        req.add_header("Accept", "application/vnd.github+json")
        req.add_header("X-GitHub-Api-Version", "2022-11-28")
        req.add_header("User-Agent", "vortacraftmc-consistency-audit")
        if TOKEN:
            req.add_header("Authorization", f"Bearer {TOKEN}")
        try:
            with urllib.request.urlopen(req, timeout=60) as r:
                raw = r.read()
                if r.status in expect:
                    if not raw:
                        return {}
                    try:
                        return json.loads(raw)
                    except json.JSONDecodeError:
                        return {"_raw": raw.decode("utf-8", "replace")}
                last = f"HTTP {r.status}"
        except urllib.error.HTTPError as e:
            detail = e.read().decode("utf-8", "replace")[:200]
            last = f"HTTP {e.code} {detail}"
            if e.code not in (500, 502, 503, 504, 429):
                return {"_error": last, "_status": e.code}
        except (urllib.error.URLError, TimeoutError) as e:
            last = f"network: {e}"
        time.sleep(2 * (attempt + 1))
    return {"_error": last or "unknown"}


def get(path):
    """GET, paginating list endpoints. Returns a list, dict, or {'_error': ...}."""
    out_all, page = [], 1
    while True:
        sep = "&" if "?" in path else "?"
        r = gh(f"{path}{sep}per_page=100&page={page}")
        if isinstance(r, dict) and "_error" in r:
            return r
        if isinstance(r, list):
            out_all += r
            if len(r) < 100:
                return out_all
            page += 1
        else:
            return r


def add(cat, sev, fid, target, msg, fix=None):
    FINDINGS.append({"category": cat, "severity": sev, "id": fid,
                     "target": target, "msg": msg, "fix": fix})


def sh(args, cwd=None):
    r = subprocess.run(args, cwd=cwd, capture_output=True, text=True)
    return r.returncode, r.stdout, r.stderr


# --------------------------------------------------------------------------- #
# A. Org
# --------------------------------------------------------------------------- #


def audit_org(org):
    o = gh(f"/orgs/{org}")
    if "_error" in o:
        add("A", "high", "org.unreachable", org, f"cannot read the org: {o['_error']}")
        return None

    if not o.get("two_factor_requirement_enabled"):
        add("A", "high", "org.2fa-off", org,
            "two-factor authentication is NOT required org-wide; on a single-seat org, "
            "losing that one account loses every repository")
    if o.get("plan", {}).get("name") == "free":
        add("A", "info", "org.plan-free", org,
            "free plan - Advanced Security features (validity checks, custom secret "
            "patterns) cannot be enabled and will silently stay disabled")
    for field, fid in (("blog", "org.no-blog"), ("email", "org.no-email"),
                       ("location", "org.no-location")):
        if not o.get(field):
            add("A", "info", fid, org, f"org profile field '{field}' is empty")

    members = get(f"/orgs/{org}/members")
    if isinstance(members, list):
        for m in members:
            if m.get("site_admin") is False and not m.get("two_factor_authentication", True):
                add("A", "high", "org.member-no-2fa", m.get("login"),
                    "member does not have 2FA enabled")
    return o


# --------------------------------------------------------------------------- #
# B. Repository settings
# --------------------------------------------------------------------------- #


def audit_repo_settings(repo, r):
    if not r.get("description"):
        add("B", "medium", "repo.no-description", repo, "no repository description")
    if not r.get("homepage"):
        add("B", "info", "repo.no-homepage", repo, "no homepage/website set")
    topics = r.get("topics") or []
    if not topics:
        add("B", "info", "repo.no-topics", repo, "no topics set")
    if r.get("has_issues") and not r.get("has_projects") and not r.get("has_wiki"):
        add("B", "info", "repo.features-minimal", repo,
            "wiki and projects are disabled (fine if intentional)")
    if r.get("archived"):
        add("B", "info", "repo.archived", repo, "repository is archived")


# --------------------------------------------------------------------------- #
# C. Security
# --------------------------------------------------------------------------- #


def audit_security(repo, r, plan):
    # The fields checked below (secret_scanning*, security_and_analysis) are only
    # present on the single-repository GET, not on the list endpoint that
    # /orgs/{org}/repos returns. Re-fetch, or every check here would silently
    # read None and report nothing.
    full = gh(f"/repos/{repo}")
    if isinstance(full, dict) and "_error" not in full:
        r = full
    sa = r.get("security_and_analysis") or {}
    for field, label in (
        ("secret_scanning", "secret scanning alerts"),
        ("secret_scanning_push_protection", "secret scanning push protection"),
        ("dependabot_security_updates", "Dependabot security updates"),
        ("dependabot_alerts_enabled", "Dependabot alerts"),
    ):
        if r.get(field) is False:
            add("C", "high", f"repo.{field}", repo, f"{label} is DISABLED",
                fix=("patch-repo", repo, {field: True}))

    vr = gh(f"/repos/{repo}/private-vulnerability-reporting")
    if isinstance(vr, dict) and vr.get("enabled") is False:
        add("C", "medium", "repo.no-private-vuln-reporting", repo,
            "private vulnerability reporting is disabled",
            fix=("enable-private-vuln", repo, None))

    # These two live under security_and_analysis and require GitHub Advanced
    # Security. On a free plan the PATCH returns 200 but leaves the field
    # disabled, so report instead of pretending to fix.
    for field in ("secret_scanning_non_provider_patterns", "secret_scanning_validity_checks"):
        entry = sa.get(field) or {}
        if entry.get("status") == "disabled":
            sev = "info" if plan == "free" else "medium"
            add("C", sev, "repo.ghas-only", repo,
                f"'{field}' is off (requires GitHub Advanced Security; org plan is '{plan}')")

    for rs in get(f"/repos/{repo}/rulesets") or []:
        if not isinstance(rs, dict) or "_error" in rs:
            continue
        detail = gh(f"/repos/{repo}/rulesets/{rs['id']}")
        rules = {x.get("type"): x for x in detail.get("rules", [])}
        if "pull_request" in rules:
            pr = rules["pull_request"].get("parameters", {})
            if not pr.get("required_approving_review_count"):
                add("C", "medium", "ruleset.no-review", repo,
                    f"ruleset '{rs.get('name')}' requires a pull request but "
                    "required_approving_review_count=0, so the author can self-merge")
            if not pr.get("require_code_owner_review"):
                add("C", "low", "ruleset.no-codeowner", repo,
                    f"ruleset '{rs.get('name')}' does not require CODEOWNERS review")
        if "required_status_checks" not in rules:
            add("C", "medium", "ruleset.no-status-checks", repo,
                f"ruleset '{rs.get('name')}' requires no status checks - a failing CI can still merge")

    prot = gh(f"/repos/{repo}/branches/{r.get('default_branch','main')}/protection")
    if isinstance(prot, dict) and "_error" not in prot:
        if prot.get("required_status_checks") is None:
            add("C", "medium", "branch.no-required-checks", repo,
                "default branch has no required status checks")


# --------------------------------------------------------------------------- #
# D. Branch / Tag / Release
# --------------------------------------------------------------------------- #


def audit_refs(repo, r):
    default = r.get("default_branch", "main")
    for b in get(f"/repos/{repo}/branches") or []:
        name = b.get("name")
        if not name or name == default:
            continue
        prs = get(f"/repos/{repo}/pulls?head={repo.split('/')[1]}:{name}&state=all")
        merged = isinstance(prs, list) and any(p.get("merged_at") for p in prs)
        if merged:
            add("D", "low", "branch.merged", f"{repo}@{name}",
                "branch is already merged but still exists",
                fix=("delete-branch", repo, name))
        elif any(k in name.lower() for k in ("rollback", "undo", "revert")):
            add("D", "medium", "branch.rollback", f"{repo}@{name}",
                "branch exists to roll the default branch back - the repository is "
                "directionally undecided; merge it or delete it")
        else:
            add("D", "info", "branch.extra", f"{repo}@{name}", "unmerged branch present")

    for t in get(f"/repos/{repo}/tags") or []:
        name = t.get("name", "")
        if name.startswith("audit-backup/"):
            add("D", "info", "tag.backup", f"{repo}@{name}",
                "rollback tag from a previous audit run (keep until you trust the fixes)")

    rels = get(f"/repos/{repo}/releases") or []
    if isinstance(rels, list):
        latest = [x for x in rels if x.get("tag_name") == "packs-latest"]
        if latest and not latest[0].get("assets"):
            add("D", "high", "release.no-assets", repo,
                "'packs-latest' release has no assets attached")
        for x in rels:
            if x.get("draft"):
                add("D", "low", "release.draft", f"{repo}@{x.get('tag_name')}",
                    "draft release sitting unpublished")


# --------------------------------------------------------------------------- #
# E. Actions
# --------------------------------------------------------------------------- #


def audit_actions(repo):
    wfs = gh(f"/repos/{repo}/actions/workflows")
    if isinstance(wfs, dict) and "_error" not in wfs:
        for w in wfs.get("workflows", []):
            if w.get("state") != "active":
                add("E", "low", "actions.disabled-workflow", f"{repo}@{w.get('name')}",
                    f"workflow is {w.get('state')}")

    for kind in ("secrets", "variables"):
        r = gh(f"/repos/{repo}/actions/{kind}")
        if isinstance(r, dict) and "_error" not in r:
            names = [x.get("name") for x in r.get(kind, [])]
            if kind == "secrets" and names:
                add("E", "info", "actions.secrets", repo,
                    f"{len(names)} Actions secret(s): {', '.join(names)}")
            if kind == "variables" and names:
                add("E", "info", "actions.variables", repo,
                    f"{len(names)} Actions variable(s): {', '.join(names)}")

    runs = gh(f"/repos/{repo}/actions/runs?per_page=25")
    if isinstance(runs, dict) and "_error" not in runs:
        concl = [x.get("conclusion") for x in runs.get("workflow_runs", [])
                 if x.get("status") == "completed"]
        bad = [x for x in runs.get("workflow_runs", [])
               if x.get("conclusion") in ("failure", "cancelled", "timed_out")]
        if bad:
            add("E", "medium", "actions.failing-runs", repo,
                f"{len(bad)} of the last {len(concl) or 1} completed run(s) did not succeed; "
                f"most recent: {bad[0].get('name')} / {bad[0].get('conclusion')}")
        elif concl:
            add("E", "info", "actions.runs-green", repo,
                f"last {len(concl)} completed run(s) all succeeded")


# --------------------------------------------------------------------------- #
# F. PR / Issue
# --------------------------------------------------------------------------- #


def audit_prs_issues(repo):
    for p in get(f"/repos/{repo}/pulls?state=open") or []:
        age = (time.time() - time.mktime(
            time.strptime(p["created_at"], "%Y-%m-%dT%H:%M:%SZ"))) / 86400
        sev = "medium" if age > 14 else "info"
        add("F", sev, "pr.open", f"{repo}#{p['number']}",
            f"open PR '{p.get('title','')[:60]}' by {p.get('user',{}).get('login')} "
            f"({age:.0f} day(s) old, {p.get('state')})")

    for i in get(f"/repos/{repo}/issues?state=open") or []:
        if "pull_request" in i:
            continue
        age = (time.time() - time.mktime(
            time.strptime(i["created_at"], "%Y-%m-%dT%H:%M:%SZ"))) / 86400
        if age > 30:
            add("F", "low", "issue.stale", f"{repo}#{i['number']}",
                f"issue open for {age:.0f} day(s): '{i.get('title','')[:60]}'")


# --------------------------------------------------------------------------- #
# G. Git history
# --------------------------------------------------------------------------- #

MEANINGLESS = {"", ".", "..", "-", "update", "fix", "wip", "test", "a", "aa", "asdf"}


def audit_history(repo, workdir):
    r = gh(f"/repos/{repo}")
    if isinstance(r, dict) and r.get("size", 0) > 50_000:
        add("G", "info", "git.size", repo, f"repository size is {r['size']} KB")

    local = os.path.join(workdir, os.path.basename(repo))
    if not os.path.isdir(local):
        add("G", "info", "git.not-cloned", repo,
            "no local clone in --workdir, skipping commit-message audit")
        return
    rc, text, _ = sh(["git", "-C", local, "log", "--pretty=%H%x09%s"])
    if rc != 0:
        return
    bad = []
    for line in text.splitlines():
        h, _, subj = line.partition("\t")
        if subj.strip().lower() in MEANINGLESS:
            bad.append(h[:7])
    if bad:
        add("G", "medium", "local.git.meaningless-commits", repo,
            f"{len(bad)} commit(s) have a meaningless message ('.'); they cannot be "
            "repaired without rewriting history and force-pushing, which needs explicit "
            f"approval. First 5: {', '.join(bad[:5])}")


# --------------------------------------------------------------------------- #
# H. Local content
# --------------------------------------------------------------------------- #


def audit_local(repo, workdir):
    if not os.path.basename(repo) == "core":
        return
    script = os.path.join(os.path.dirname(os.path.abspath(__file__)), "audit_repo.py")
    if not os.path.exists(script):
        return
    local = os.path.join(workdir, "core")
    rc, text, err = sh([sys.executable, script, "--json"], cwd=local)
    if rc != 0:
        add("H", "medium", "local.audit-failed", repo,
            f"scripts/audit_repo.py exited {rc}: {err.strip()[:120]}")
        return
    try:
        items = json.loads(text)
    except json.JSONDecodeError:
        add("H", "medium", "local.audit-unparsable", repo, "audit_repo.py did not return JSON")
        return
    for f in items:
        sev = {"critical": "high", "high": "high", "medium": "medium",
               "low": "low", "info": "info"}.get(f["severity"], "info")
        add("H", sev, f"local.pack.{f['id'].split('.', 1)[-1]}",
            f.get("path") or repo, f["msg"])


# --------------------------------------------------------------------------- #
# I. Community health
# --------------------------------------------------------------------------- #


def audit_community(repo):
    c = gh(f"/repos/{repo}/community/profile")
    if isinstance(c, dict) and "_error" not in c:
        pct = c.get("health_percentage")
        if pct is not None and pct < 100:
            add("I", "low" if pct >= 75 else "medium", "community.health", repo,
                f"community health is {pct}%")
        files = c.get("files") or {}
        for key in ("code_of_conduct", "contributing", "license",
                    "issue_template", "pull_request_template"):
            v = files.get(key)
            present = bool(v) and (v is not True or True)
            if v is None:
                add("I", "info", "community.missing", f"{repo}:{key}",
                    f"'{key}' is missing - GitHub's community profile reports it absent. "
                    "Note: this endpoint is cached per field, so confirm with the "
                    "contents API before treating it as a real gap.")


# --------------------------------------------------------------------------- #
# cross-repository references
# --------------------------------------------------------------------------- #


def audit_cross_refs(org, repos, workdir):
    local = os.path.join(workdir, "core")
    if not os.path.isdir(local):
        return
    rc, text, _ = sh(["git", "-C", local, "grep", "-nI", "-E",
                      r"github\.com/vortacraftmc/[A-Za-z0-9._-]+"])
    if rc != 0:
        return
    known = {r.split("/")[1] for r in repos}
    seen = set()
    for line in text.splitlines():
        for m in re.finditer(r"github\.com/vortacraftmc/([A-Za-z0-9._\-]+)", line):
            name = m.group(1).rstrip(".)")
            if name in known or name in seen:
                continue
            seen.add(name)
            add("I", "medium", "xref.unknown-repo", line.split(":")[0],
                f"references vortacraftmc/{name}, which does not exist in the org")


# --------------------------------------------------------------------------- #
# fixes
# --------------------------------------------------------------------------- #


def apply_fixes(dry_run):
    applied = []
    for f in FINDINGS:
        if not f.get("fix"):
            continue
        kind = f["fix"][0]
        if dry_run:
            applied.append((f["id"], f["target"], "dry-run"))
            continue
        if kind == "patch-repo":
            _cat, repo, patch = f["fix"]
            r = gh(f"/repos/{repo}", "PATCH", patch)
            ok = "_error" not in r
            # PATCH of GHAS-gated fields returns 200 but changes nothing; re-read.
            if ok:
                check = gh(f"/repos/{repo}")
                ok = all(check.get(k) == v for k, v in patch.items())
            applied.append((f["id"], repo, "applied" if ok else f"FAILED: {r.get('_error','?')}"))
        elif kind == "enable-private-vuln":
            _cat, repo, _ = f["fix"]
            r = gh(f"/repos/{repo}/private-vulnerability-reporting", "POST", expect=(204,))
            applied.append((f["id"], repo, "applied" if "_error" not in r else f"FAILED: {r['_error']}"))
        elif kind == "delete-branch":
            _cat, repo, name = f["fix"]
            r = gh(f"/repos/{repo}/git/refs/heads/{name}", "DELETE", expect=(204,))
            applied.append((f["id"], f"{repo}@{name}",
                            "deleted" if "_error" not in r else f"FAILED: {r['_error']}"))
    return applied


# --------------------------------------------------------------------------- #


def main():
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--org", default="vortacraftmc")
    ap.add_argument("--workdir", default=os.getcwd(),
                    help="directory containing local clones (for categories G/H)")
    ap.add_argument("--json", action="store_true")
    ap.add_argument("--fix", action="store_true")
    ap.add_argument("--dry-run", action="store_true")
    ap.add_argument("--log", help="also write the report to this file")
    args = ap.parse_args()

    global TOKEN
    TOKEN = os.environ.get("VC_TOKEN") or os.environ.get("GH_TOKEN")
    if not TOKEN and os.environ.get("VC_TOKEN_FILE"):
        try:
            TOKEN = open(os.environ["VC_TOKEN_FILE"]).read().strip()
        except OSError as e:
            out(f"cannot read VC_TOKEN_FILE: {e}")
    if not TOKEN:
        out("WARNING: no token set (VC_TOKEN / GH_TOKEN / VC_TOKEN_FILE); "
            "only public data will be readable")

    org = audit_org(args.org)
    plan = (org or {}).get("plan", {}).get("name", "unknown")

    repos = get(f"/orgs/{args.org}/repos")
    if not isinstance(repos, list):
        out(f"cannot list repositories: {repos}")
        return 1

    out("=" * 78)
    out(f"VORTACRAFTMC CONSISTENCY AUDIT  org={args.org}  {time.strftime('%F %T')}")
    out("=" * 78)
    out(f"\nrepositories: {len(repos)}\n")

    for r in sorted(repos, key=lambda x: x["name"]):
        repo = r["full_name"]
        out("-" * 70)
        out(f"AUDITING: {repo}  (private={r.get('private')}, size={r.get('size')} KB)\n")
        audit_repo_settings(repo, r)
        audit_security(repo, r, plan)
        audit_refs(repo, r)
        audit_actions(repo)
        audit_prs_issues(repo)
        audit_history(repo, args.workdir)
        audit_local(repo, args.workdir)
        audit_community(repo)

    out("-" * 70)
    out("CROSS-REPOSITORY REFERENCES\n")
    audit_cross_refs(args.org, [r["full_name"] for r in repos], args.workdir)

    FINDINGS.sort(key=lambda f: (SEV_ORDER[f["severity"]], f["category"], f["id"]))

    counts = defaultdict(int)
    for f in FINDINGS:
        counts[f["severity"]] += 1
    out("=" * 78)
    out(f"TOTAL FINDINGS: {len(FINDINGS)}  "
        + "  ".join(f"{ICON[k]} {k}: {counts[k]}" for k in SEV_ORDER if counts[k]))
    out("=" * 78)

    CATS = {"A": "Org", "B": "Repository settings", "C": "Security",
            "D": "Branch/Tag/Release", "E": "Actions", "F": "PR/Issue",
            "G": "Git history", "H": "Local content", "I": "Community health"}
    for cat in "ABCDEFGHI":
        items = [f for f in FINDINGS if f["category"] == cat]
        if not items:
            continue
        out(f"\n### {cat}. {CATS[cat]}  ({len(items)} findings)")
        for f in items:
            out(f"  {ICON[f['severity']]} [{f['severity'].upper()}] {f['id']}")
            out(f"      {f['target']}")
            out(f"        {f['msg']}")

    if args.json:
        print(json.dumps(FINDINGS, ensure_ascii=False, indent=2))

    if args.fix:
        out("\n" + "=" * 78)
        out("APPLYING FIXES" + ("  [DRY-RUN]" if args.dry_run else ""))
        for fid, target, res in apply_fixes(args.dry_run):
            out(f"  {fid} [{target}]: {res}")
    else:
        fixable = sum(1 for f in FINDINGS if f.get("fix"))
        out(f"\nauto-fixable with --fix: {fixable}  |  needs a human decision: "
            f"{len(FINDINGS) - fixable}")

    if args.log:
        with open(args.log, "w", encoding="utf-8") as fh:
            fh.write("\n".join(LOG_LINES) + "\n")
    return 0


if __name__ == "__main__":
    sys.exit(main())
