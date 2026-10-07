#!/usr/bin/env python3
"""
vortacraftmc - ORG + TUM REPO'lar icin kapsamli denetim ve toplu duzeltme.

Kapsam
------
 A  Org ayarlari ve profili
 B  Repo metadata ve ayarlari
 C  Guvenlik durusu (secret scanning, dependabot, code scanning, SECURITY.md,
    private vulnerability reporting, CODEOWNERS)
 D  Branch / ruleset / branch protection / tag / release tutarliligi
 E  GitHub Actions: workflow tanimlari, calisma gecmisi, basarisizliklar,
    action sabitleme, permissions, secrets, retention
 F  PR ve Issue: acik/bayat, sablonlar, etiketler
 G  Git gecmisi (lokal klon): commit mesajlari, buyuk blob'lar, gecmisteki
    sir'lar, yazar anomalileri
 H  Lokal icerik (packs / mods / docs / CI dosyalari) -> audit_repo.py
 I  Topluluk sagligi dosyalari (community health)

Kullanim
--------
    export GH_TOKEN=...
    python3 scripts/audit_full.py --org vortacraftmc            # denetim
    python3 scripts/audit_full.py --org vortacraftmc --json     # JSON
    python3 scripts/audit_full.py --org vortacraftmc --fix      # guvenli fix'ler
    python3 scripts/audit_full.py --org vortacraftmc --log FILE # dosyaya da yaz

Token yalnizca GH_TOKEN / GITHUB_TOKEN ortam degiskeninden okunur; asla loglanmaz.
"""
from __future__ import annotations

import argparse
import json
import os
import re
import shutil
import subprocess
import sys
import time
import urllib.error
import urllib.request
from collections import defaultdict

API = "https://api.github.com"
FINDINGS: list[dict] = []
TOKEN = os.environ.get("GH_TOKEN") or os.environ.get("GITHUB_TOKEN") or ""
DRY = False
FIXES: list[dict] = []


# --------------------------------------------------------------------------- #
# temel
# --------------------------------------------------------------------------- #
def add(cat, fid, severity, subject, msg, autofix=False, fix=None):
    FINDINGS.append(
        {"category": cat, "id": fid, "severity": severity, "subject": subject,
         "msg": msg, "autofix": autofix, "fix": fix}
    )


def gh(path, method="GET", body=None, accept="application/vnd.github+json", raw=False,
       retries=4, backoff=6.0):
    """API cagrisi. 5xx yanitlarinda tekrar dener (GitHub tarafindaki gecici
    bozulmalar icin - 2026-10-07'de tum yazma islemleri bos govdeli 500
    dondurmeye basladi, okumalar calisiyordu)."""
    url = path if path.startswith("http") else API + path
    data = json.dumps(body).encode() if body is not None else None
    last = (0, {"message": "no attempt"})
    for attempt in range(retries):
        req = urllib.request.Request(url, data=data, method=method)
        req.add_header("Accept", accept)
        req.add_header("X-GitHub-Api-Version", "2022-11-28")
        req.add_header("User-Agent", "vortacraftmc-audit")
        if TOKEN:
            req.add_header("Authorization", f"Bearer {TOKEN}")
        try:
            with urllib.request.urlopen(req, timeout=45) as r:
                payload = r.read()
                if raw:
                    return r.status, payload
                if not payload:
                    return r.status, None
                return r.status, json.loads(payload)
        except urllib.error.HTTPError as e:
            try:
                payload = json.loads(e.read())
            except Exception:
                payload = {"message": f"HTTP {e.code} (bos govde)"}
            last = (e.code, payload)
            # 5xx ve 429 gecicidir; 4xx kalici hatadir, tekrar deneme
            if e.code in (429,) or 500 <= e.code < 600:
                if attempt < retries - 1:
                    time.sleep(backoff * (attempt + 1))
                    continue
            return e.code, payload
        except Exception as e:  # noqa: BLE001
            last = (0, {"message": str(e)})
            if attempt < retries - 1:
                time.sleep(backoff * (attempt + 1))
                continue
    return last


def gh_pages(path, key=None, limit=400):
    """Sayfali listeleme."""
    out, page = [], 1
    while len(out) < limit:
        sep = "&" if "?" in path else "?"
        st, d = gh(f"{path}{sep}per_page=100&page={page}")
        if st != 200 or not isinstance(d, list):
            if page == 1 and isinstance(d, dict):
                return {"__error__": d.get("message")}
            break
        if key:
            d = d.get(key, []) if isinstance(d, dict) else []
        out.extend(d)
        if len(d) < 100:
            break
        page += 1
    return out


def sh(args, cwd=None):
    r = subprocess.run(args, cwd=cwd, capture_output=True, text=True)
    return r.returncode, r.stdout, r.stderr


# --------------------------------------------------------------------------- #
# A. ORG
# --------------------------------------------------------------------------- #
def audit_org(org):
    st, o = gh(f"/orgs/{org}")
    if st != 200:
        add("A", "org.not-found", "critical", org, f"org okunamadi (HTTP {st}): {o.get('message')}")
        return o
    if not o.get("description"):
        add("A", "org.no-description", "low", org, "org aciklamasi bos",
            autofix=True, fix=("org-patch", {"description": o.get("name") or org}))
    if not o.get("blog"):
        add("A", "org.no-blog", "info", org, "org 'website/blog' alani bos")
    if not o.get("email"):
        add("A", "org.no-email", "info", org, "org iletisim e-postasi yok")
    if not o.get("location"):
        add("A", "org.no-location", "info", org, "org konum alani bos")

    # 2FA
    st2, s = gh(f"/orgs/{org}/security-managers")
    if o.get("two_factor_requirement_enabled") is False:
        add("A", "org.2fa-off", "high", org,
            "org genelinde iki faktorlu dogrulama ZORUNLU DEGIL - tek koltuklu bir org'da "
            "hesap ele gecirilirse tum repolar gider")

    if o.get("members_can_create_repositories"):
        add("A", "org.members-create-repos", "medium", org,
            "uyeler repo olusturabiliyor; 'test' / 'test-private' gibi bos repolarin "
            "birikmesini engellemek icin kapatilmasi dusunulebilir",
            autofix=True, fix=("org-patch", {"members_can_create_repositories": False}))

    if o.get("default_repository_permission") not in ("none", "read"):
        add("A", "org.default-perm", "medium", org,
            f"varsayilan repo izni '{o.get('default_repository_permission')}'")

    plan = (o.get("plan") or {}).get("name")
    if plan == "free":
        add("A", "org.plan-free", "info", org,
            "org plani 'free' - GitHub Advanced Security yok; secret_scanning_non_provider_patterns "
            "ve validity_checks acilamaz (API sessizce yok sayar)")
    return o


# --------------------------------------------------------------------------- #
# B. REPO METADATA / AYARLAR
# --------------------------------------------------------------------------- #
REQUIRED_TOPICS_MIN = 1


def audit_repo_meta(org, name, r):
    full = f"{org}/{name}"
    if not r.get("description"):
        add("B", "repo.no-description", "medium", full, "repo aciklamasi yok",
            autofix=True, fix=("repo-patch", {"description": f"{name} - vortacraftmc"}))
    if not r.get("homepage"):
        add("B", "repo.no-homepage", "low", full, "repo 'website' alani bos")
    if not (r.get("topics") or []):
        add("B", "repo.no-topics", "low", full, "repo konusu (topic) yok")
    lic = (r.get("license") or {}).get("spdx_id") if r.get("license") else None
    if not lic or lic == "NOASSERTION":
        add("B", "repo.no-license", "high", full, f"lisans tanimli degil (spdx={lic})")

    if r.get("has_wiki"):
        add("B", "repo.wiki-on", "low", full,
            "wiki acik ama bos/bakimsiz wiki'ler dokuman tutarsizligi yaratir",
            autofix=True, fix=("repo-patch", {"has_wiki": False}))
    if r.get("delete_branch_on_merge") is False:
        add("B", "repo.keep-branches", "medium", full,
            "delete_branch_on_merge=false - merge sonrasi bayat branch birikir",
            autofix=True, fix=("repo-patch", {"delete_branch_on_merge": True}))
    merge_methods = [k for k in ("allow_merge_commit", "allow_squash_merge", "allow_rebase_merge")
                     if r.get(k)]
    if len(merge_methods) > 1:
        add("B", "repo.many-merge-methods", "low", full,
            f"{len(merge_methods)} merge yontemi acik ({', '.join(merge_methods)}) - "
            "gecmiste tutarsiz merge yapisi olusur")

    sa = r.get("security_and_analysis") or {}
    for k in ("secret_scanning", "secret_scanning_push_protection"):
        if (sa.get(k) or {}).get("status") != "enabled":
            add("C", "repo.secret-scanning", "high", full, f"{k} KAPALI",
                autofix=True, fix=("repo-sa", {k: "enabled"}))
    if (sa.get("dependabot_security_updates") or {}).get("status") != "enabled":
        add("C", "repo.dependabot-updates", "medium", full, "dependabot_security_updates kapali",
            autofix=True, fix=("repo-sa", {"dependabot_security_updates": "enabled"}))
    for k in ("secret_scanning_non_provider_patterns", "secret_scanning_validity_checks"):
        if (sa.get(k) or {}).get("status") != "enabled":
            add("C", "repo.ghas-only", "info", full,
                f"{k} kapali - GitHub Advanced Security gerektirir, free planda acilamaz")
    return r


# --------------------------------------------------------------------------- #
# C. GUVENLIK
# --------------------------------------------------------------------------- #
def audit_security(org, name, files):
    full = f"{org}/{name}"
    st, d = gh(f"/repos/{org}/{name}")
    pv = None
    st2, pv = gh(f"/repos/{org}/{name}/private-vulnerability-reporting")
    if st2 == 200 and isinstance(pv, dict) and pv.get("enabled") is False:
        add("C", "repo.pvr-off", "medium", full,
            "private vulnerability reporting kapali; SECURITY.md 'Report a vulnerability' diyor",
            autofix=True, fix=("pvr-on", {}))

    for kind in ("secret-scanning", "dependabot", "code-scanning"):
        st3, alerts = gh(f"/repos/{org}/{name}/{kind}/alerts?state=open")
        if st3 == 200 and isinstance(alerts, list):
            for a in alerts[:10]:
                sev = (a.get("security_vulnerability") or {}).get("severity") or a.get("severity") or "?"
                pkg = ((a.get("dependency") or {}).get("package") or {}).get("name") or a.get("tool", {}).get("name", "?")
                add("C", f"alert.{kind}", "high" if sev in ("critical", "high") else "medium",
                    full, f"acik {kind} alarmi: {pkg} ({sev})")
        elif st3 == 403:
            add("C", f"alert.{kind}", "info", full, f"{kind} alarmlari okunamadi (yetki yok)")


# --------------------------------------------------------------------------- #
# D. BRANCH / RULESET / TAG / RELEASE
# --------------------------------------------------------------------------- #
def audit_refs(org, name, repo_dir):
    full = f"{org}/{name}"
    st, rulesets = gh(f"/repos/{org}/{name}/rulesets")
    if st == 200 and isinstance(rulesets, list):
        for rs in rulesets:
            st2, detail = gh(f"/repos/{org}/{name}/rulesets/{rs['id']}")
            if st2 != 200:
                continue
            rules = {r["type"]: r.get("parameters") or {} for r in detail.get("rules", [])}
            pr = rules.get("pull_request")
            if pr is not None and pr.get("required_approving_review_count", 0) == 0:
                add("D", "ruleset.no-review", "medium", full,
                    f"ruleset '{detail.get('name')}': PR zorunlu ama required_approving_review_count=0 - "
                    "self-merge mumkun, bu da '.' gibi bos commit mesajlarinin main'e girmesini aciklar")
            if "required_status_checks" not in rules:
                add("D", "ruleset.no-status-checks", "medium", full,
                    f"ruleset '{detail.get('name')}': required_status_checks yok - CI kirmizi olsa bile merge edilebilir")
    elif st == 200 and rulesets == []:
        add("D", "ruleset.none", "high", full, "hic ruleset/branch protection yok - main'e dogrudan push mumkun")

    # bayat branch
    st, branches = gh(f"/repos/{org}/{name}/branches?per_page=100")
    default = None
    st0, r0 = gh(f"/repos/{org}/{name}")
    default = r0.get("default_branch")
    if isinstance(branches, list):
        for b in branches:
            if b["name"] == default:
                continue
            add("D", "branch.extra", "low", full, f"merge edilmemis/ek branch: {b['name']}")

    # tag <-> release
    tags = gh_pages(f"/repos/{org}/{name}/tags")
    releases = gh_pages(f"/repos/{org}/{name}/releases")
    if isinstance(releases, list):
        tag_names = {t["name"] for t in tags} if isinstance(tags, list) else set()
        for rel in releases:
            if rel.get("draft"):
                add("D", "release.draft", "low", full, f"draft release bekliyor: {rel.get('tag_name')}")
            if not rel.get("assets"):
                add("D", "release.no-assets", "medium", full,
                    f"release '{rel.get('tag_name')}' icinde hic asset yok")
            if rel.get("tag_name") not in tag_names:
                add("D", "release.orphan-tag", "high", full,
                    f"release '{rel.get('tag_name')}' icin tag listelenmiyor")
    # yedek tag'leri release'e donusmemeli
    for t in (tags if isinstance(tags, list) else []):
        if t["name"].startswith("audit-backup/"):
            add("D", "tag.backup", "info", full,
                f"yedek tag'i duruyor: {t['name']} (rollback branch'lerinin kaybi onlemek icin olusturuldu)")

    # gecmisteki sir taramasi
    if repo_dir:
        audit_history(full, repo_dir)


SECRET_PATTERNS = [
    (re.compile(r"github_pat_[A-Za-z0-9_]{20,}"), "GitHub fine-grained PAT"),
    (re.compile(r"ghp_[A-Za-z0-9]{36}"), "GitHub classic PAT"),
    (re.compile(r"gho_[A-Za-z0-9]{36}"), "GitHub OAuth token"),
    (re.compile(r"github_pat_[A-Za-z0-9_]{20,}"), "GitHub PAT"),
    (re.compile(r"-----BEGIN [A-Z ]*PRIVATE KEY-----"), "private key"),
    (re.compile(r"AKIA[0-9A-Z]{16}"), "AWS access key"),
    (re.compile(r"xox[baprs]-[A-Za-z0-9-]{10,}"), "Slack token"),
]


def audit_history(full, repo_dir):
    rc, out, _ = sh(["git", "log", "--pretty=%H%x09%s"], cwd=repo_dir)
    if rc == 0:
        total = len(out.splitlines())
        bad = []
        for line in out.splitlines():
            h, _, subj = line.partition("\t")
            s = subj.strip()
            if s in ("", ".", "..", "-", "update", "fix", "wip", "asdf", "test", "a", "aa"):
                bad.append((h[:7], s or "(bos)"))
        if bad:
            add("G", "git.meaningless-commits", "medium", full,
                f"{len(bad)}/{total} commit mesaji anlamsiz: "
                + ", ".join(f"{h} '{s}'" for h, s in bad[:10])
                + ("..." if len(bad) > 10 else ""))

    # gecmisteki tum blob'larda sir taramasi (calisma agaci yetmez)
    rc, out, _ = sh(["git", "rev-list", "--objects", "--all"], cwd=repo_dir)
    scanned = 0
    hits = []
    if rc == 0:
        objs = [l.split(" ", 1) for l in out.splitlines() if " " in l]
        # performans icin orneklem + yol adina gore filtre
        for sha, path in objs:
            if len(hits) >= 10:
                break
            if not re.search(r"\.(sh|py|yml|yaml|json|md|properties|env|txt|gradle|kts|toml|cfg|ini)$", path):
                continue
            rc2, content, _ = sh(["git", "cat-file", "blob", sha], cwd=repo_dir)
            if rc2 != 0 or len(content) > 400_000:
                continue
            scanned += 1
            for rx, label in SECRET_PATTERNS:
                if rx.search(content):
                    hits.append((path, label))
                    break
    if hits:
        seen = set()
        for path, label in hits:
            if path in seen:
                continue
            seen.add(path)
            add("G", "git.secret-in-history", "critical", full,
                f"git GECMISINDE olasi sir ({label}): {path} - dosya silinse bile gecmiste durur, "
                "token iptal edilip gecmis yeniden yazilmali")

    rc, out, _ = sh(["git", "count-objects", "-vH"], cwd=repo_dir)
    if rc == 0:
        for line in out.splitlines():
            if line.startswith("size-pack:"):
                add("G", "git.size", "info", full, f"git paket boyutu: {line.split(':',1)[1].strip()}")

    rc, out, _ = sh(["git", "rev-list", "--objects", "--all"], cwd=repo_dir)
    if rc == 0:
        big = []
        for line in out.splitlines():
            if " " not in line:
                continue
            sha, path = line.split(" ", 1)
            rc2, so, _ = sh(["git", "cat-file", "-s", sha], cwd=repo_dir)
            if rc2 == 0 and so.strip().isdigit() and int(so.strip()) > 5_000_000:
                big.append((path, int(so.strip())))
        for path, sz in sorted(big, key=lambda x: -x[1])[:5]:
            add("G", "git.large-blob", "medium", full,
                f"gecmiste {sz/1e6:.1f} MB blob: {path}")


# --------------------------------------------------------------------------- #
# E. ACTIONS
# --------------------------------------------------------------------------- #
def audit_actions(org, name):
    full = f"{org}/{name}"
    st, wf = gh(f"/repos/{org}/{name}/actions/workflows")
    if st == 200:
        for w in wf.get("workflows", []):
            if w.get("state") == "disabled_manually":
                add("E", "actions.disabled-workflow", "low", full,
                    f"workflow elle devre disi: {w['name']} ({w['path']})")
    runs = gh_pages(f"/repos/{org}/{name}/actions/runs", key="workflow_runs", limit=300)
    if isinstance(runs, list) and runs:
        concl = defaultdict(int)
        for r in runs:
            concl[r.get("conclusion") or "?"] += 1
        add("E", "actions.run-summary", "info", full,
            f"son {len(runs)} calisma: " + ", ".join(f"{k}={v}" for k, v in sorted(concl.items())))
        fails = [r for r in runs if r.get("conclusion") == "failure"]
        for r in fails[:5]:
            add("E", "actions.failed-run", "medium", full,
                f"basarisiz calisma: {r.get('name')} @ {r.get('head_branch')} {str(r.get('created_at'))[:16]} "
                f"({r.get('html_url')})")
        cancels = [r for r in runs if r.get("conclusion") == "cancelled"]
        if len(cancels) > len(runs) * 0.1:
            add("E", "actions.many-cancelled", "low", full,
                f"{len(cancels)}/{len(runs)} calisma iptal - concurrency ayari veya sik push isareti")

    # secrets / variables
    for kind in ("secrets", "variables"):
        st2, d = gh(f"/repos/{org}/{name}/actions/{kind}")
        if st2 == 200 and isinstance(d, dict):
            add("E", f"actions.{kind}", "info", full, f"tanimli {kind}: {d.get('total_count', 0)}")


def audit_workflow_files(org, name, repo_dir):
    if not repo_dir:
        return
    wf_dir = os.path.join(repo_dir, ".github", "workflows")
    if not os.path.isdir(wf_dir):
        return
    try:
        import yaml
    except ImportError:
        yaml = None
    for f in sorted(os.listdir(wf_dir)):
        p = os.path.join(wf_dir, f)
        if not f.endswith((".yml", ".yaml")):
            continue
        txt = open(p, encoding="utf-8", errors="replace").read()
        if yaml:
            try:
                doc = yaml.safe_load(txt)
            except Exception as e:  # noqa: BLE001
                add("E", "actions.yaml-invalid", "critical", f"{org}/{name}", f"{f}: YAML hatasi {e}")
                continue
            if not isinstance(doc, dict):
                continue
            for jn, job in (doc.get("jobs") or {}).items():
                for step in job.get("steps") or []:
                    u = step.get("uses")
                    if u and not re.match(r"^[\w.\-/]+@(v\d+(\.\d+)*|[0-9a-f]{40})$", str(u)):
                        add("E", "actions.unpinned", "medium", f"{org}/{name}",
                            f"{f}: sabitlenmemis action {u} (supply-chain riski; @vN veya 40 haneli SHA kullanin)")
            if "permissions" not in doc:
                add("E", "actions.no-top-permissions", "medium", f"{org}/{name}",
                    f"{f}: workflow duzeyinde 'permissions' yok")


# --------------------------------------------------------------------------- #
# F. PR / ISSUE
# --------------------------------------------------------------------------- #
def audit_prs_issues(org, name):
    full = f"{org}/{name}"
    prs = gh_pages(f"/repos/{org}/{name}/pulls?state=open")
    if isinstance(prs, list):
        for p in prs:
            age = (time.time() - time.mktime(time.strptime(p["created_at"][:10], "%Y-%m-%d"))) / 86400
            if age > 14:
                add("F", "pr.stale", "medium", full, f"#{p['number']} {age:.0f} gundur acik: {p['title'][:50]}")
            else:
                add("F", "pr.open", "info", full, f"#{p['number']} acik: {p['title'][:60]}")
    issues = gh_pages(f"/repos/{org}/{name}/issues?state=open")
    if isinstance(issues, list):
        for i in issues:
            if "pull_request" in i:
                continue
            age = (time.time() - time.mktime(time.strptime(i["created_at"][:10], "%Y-%m-%d"))) / 86400
            add("F", "issue.stale" if age > 30 else "issue.open",
                "medium" if age > 30 else "info", full,
                f"#{i['number']} {age:.0f} gundur acik: {i['title'][:50]}")
    st, labels = gh(f"/repos/{org}/{name}/labels?per_page=100")
    if st == 200 and isinstance(labels, list) and len(labels) < 3:
        add("F", "labels.few", "low", full, f"yalnizca {len(labels)} etiket tanimli")


# --------------------------------------------------------------------------- #
# I. TOPLULUK SAGLIGI
# --------------------------------------------------------------------------- #
def _all_files(top):
    for root, dirs, files in os.walk(top):
        dirs[:] = [d for d in dirs if d not in (".git", "build", ".gradle", "node_modules")]
        for f in files:
            yield os.path.join(root, f)


def audit_cross_repo(org, repo_dir, other_dirs):
    """Bir repo'nun dokümanlari baska repo'daki varliklardan bahsediyorsa dogrula."""
    if not repo_dir or not other_dirs:
        return
    for p in _all_files(repo_dir):
        if not p.endswith(".md"):
            continue
        txt = open(p, encoding="utf-8", errors="replace").read()
        # `packs/` tablosunda adlari sayilan paketler.
        # Yalnizca gercekten bir proje listesi olan satirlarda calis: satir
        # packs/ veya mods/ icermeli, aksi halde duz metindeki "for example
        # brute-forcing, ..." gibi ifadeler proje adi sanilir.
        for line in txt.splitlines():
            if "packs/" not in line and "mods/" not in line:
                continue
            for m in re.finditer(r"for example ([^)\n|]{5,200})\)", line):
                names = [x.strip().strip('`') for x in m.group(1).split(",")]
                for nm in names:
                    if not re.match(r"^[A-Za-z0-9_.\-]+$", nm):
                        continue
                    found = any(
                        any(
                            d2 == nm or d2.startswith(nm + "-") or d2.startswith(nm + "_")
                            for base in ("packs", "mods", "examples")
                            if os.path.isdir(os.path.join(d, base))
                            for d2 in os.listdir(os.path.join(d, base))
                        )
                        for d in other_dirs
                    )
                    if not found:
                        add("I", "docs.phantom-project", "medium",
                            f"{org}/{os.path.basename(repo_dir)}:{os.path.relpath(p, repo_dir)}",
                            f"var olmayan proje adi ornek olarak verilmis: `{nm}`")


def audit_community(org, name, repo_dir):
    full = f"{org}/{name}"
    st, ch = gh(f"/repos/{org}/{name}/community/profile")
    if st == 200 and isinstance(ch, dict):
        files = ch.get("files") or {}
        for k, v in files.items():
            if v is None:
                sev = "medium" if k in ("code_of_conduct", "security", "contributing") else "low"
                add("I", f"community.{k}", sev, full, f"topluluk sagligi dosyasi eksik: {k}")
        pct = ch.get("health_percentage")
        if pct is not None and pct < 100:
            add("I", "community.health", "info", full, f"community health puani: {pct}%")

    # README'nin iddia ettigi dosyalar gercekten var mi
    if repo_dir:
        readme_candidates = ["README.md", "profile/README.md"]
        for rc_name in readme_candidates:
            rp = os.path.join(repo_dir, rc_name)
            if not os.path.exists(rp):
                continue
            txt = open(rp, encoding="utf-8", errors="replace").read()
            for m in re.finditer(r"`([^`\n]+\.(?:md|yml|yaml|json|py|sh))`", txt):
                ref = m.group(1)
                if "/" not in ref:
                    # ciplak dosya adi: repo genelinde ara (README kisaltma kullanabilir)
                    if any(os.path.basename(p) == ref for p in _all_files(repo_dir)):
                        continue
                    cand = [os.path.join(repo_dir, ref), os.path.join(repo_dir, ".github", ref)]
                else:
                    cand = [os.path.join(repo_dir, ref)]
                if not any(os.path.exists(c) for c in cand):
                    # baska repo'ya referans olabilir
                    if "github.com" in txt[max(0, m.start() - 200):m.start()]:
                        continue
                    add("I", "docs.phantom-file", "medium", f"{full}:{rc_name}",
                        f"README var olmayan dosyayi belgeliyor: `{ref}`")


# --------------------------------------------------------------------------- #
# FIX
# --------------------------------------------------------------------------- #
def apply_fixes(org, name):
    applied = []
    for f in FINDINGS:
        if not f.get("autofix") or not f.get("fix"):
            continue
        kind, payload = f["fix"]
        if kind == "org-patch":
            st, d = gh(f"/orgs/{org}", "PATCH", payload)
            applied.append((f"org {list(payload)[0]}", st, d.get("message")))
            f["fix"] = None
        elif kind == "repo-patch":
            st, d = gh(f"/repos/{org}/{name}", "PATCH", payload)
            applied.append((f"{name} {list(payload)[0]}", st, d.get("message")))
            f["fix"] = None
        elif kind == "repo-sa":
            cur = {}
            for k, v in payload.items():
                cur[k] = {"status": v}
            st, d = gh(f"/repos/{org}/{name}", "PATCH", {"security_and_analysis": cur})
            sa = (d or {}).get("security_and_analysis") or {}
            res = {k: (sa.get(k) or {}).get("status") for k in payload}
            applied.append((f"{name} security_and_analysis", st, json.dumps(res)))
            f["fix"] = None
        elif kind == "pvr-on":
            st, d = gh(f"/repos/{org}/{name}/private-vulnerability-reporting", "PUT")
            applied.append((f"{name} private-vulnerability-reporting", st, d.get("message") if isinstance(d, dict) else None))
            f["fix"] = None
    return applied


# --------------------------------------------------------------------------- #
ORDER = {"critical": 0, "high": 1, "medium": 2, "low": 3, "info": 4}
ICONS = {"critical": "✘", "high": "▲", "medium": "●", "low": "·", "info": "ℹ"}
CATS = {"A": "Org", "B": "Repo ayarlari", "C": "Guvenlik", "D": "Branch/Tag/Release",
        "E": "Actions", "F": "PR/Issue", "G": "Git gecmisi", "H": "Lokal icerik",
        "I": "Topluluk sagligi"}


def merge_local_findings(org, name, repo_dir):
    """audit_repo.py'yi calistirip bulgularini H kategorisi olarak dahil et."""
    script = os.path.join(repo_dir, "scripts", "audit_repo.py")
    if not os.path.exists(script):
        return
    rc, out, err = sh([sys.executable, script, "--json"], cwd=repo_dir)
    if rc != 0:
        add("H", "local.audit-failed", "high", f"{org}/{name}",
            f"audit_repo.py calisamadi: {(err or out)[:200]}")
        return
    try:
        items = json.loads(out)
    except json.JSONDecodeError:
        add("H", "local.audit-failed", "high", f"{org}/{name}", "audit_repo.py JSON dondurmedi")
        return
    for it in items:
        add("H", f"local.{it['id']}", it["severity"],
            f"{org}/{name}:{it.get('path') or '-'}", it["msg"])


def main():
    global DRY
    ap = argparse.ArgumentParser()
    ap.add_argument("--org", default="vortacraftmc")
    ap.add_argument("--workdir", default="/tmp/audit-workdir")
    ap.add_argument("--json", action="store_true")
    ap.add_argument("--fix", action="store_true")
    ap.add_argument("--dry-run", action="store_true")
    ap.add_argument("--log", default=None)
    args = ap.parse_args()
    DRY = args.dry_run

    out_fh = open(args.log, "a", encoding="utf-8") if args.log else None

    def emit(s=""):
        print(s, flush=True)
        if out_fh:
            out_fh.write(s + "\n")
            out_fh.flush()

    if not TOKEN:
        emit("UYARI: GH_TOKEN/GITHUB_TOKEN yok - yalnizca public okuma yapilabilir, fix uygulanamaz.")

    emit("=" * 78)
    emit(f"VORTACRAFTMC KAPSAMLI DENETIM  org={args.org}  {time.strftime('%Y-%m-%d %H:%M:%S')}")
    emit("=" * 78)

    org = audit_org(args.org)

    st, repos = gh(f"/orgs/{args.org}/repos?per_page=100&type=all")
    if st != 200 or not isinstance(repos, list):
        emit(f"FATAL: repo listesi alinamadi (HTTP {st})")
        return 1

    emit(f"\nrepo sayisi: {len(repos)}")
    os.makedirs(args.workdir, exist_ok=True)

    cloned: dict[str, str] = {}
    for r in sorted(repos, key=lambda x: x["name"]):
        name = r["name"]
        full = f"{args.org}/{name}"
        emit(f"\n{'-'*70}\nDENETLENİYOR: {full}  (private={r.get('private')}, size={r.get('size')} KB)")
        audit_repo_meta(args.org, name, r)
        audit_security(args.org, name, None)
        audit_refs(args.org, name, None)
        audit_actions(args.org, name)
        audit_prs_issues(args.org, name)

        # lokal klon
        dest = os.path.join(args.workdir, name)
        if os.path.isdir(dest):
            shutil.rmtree(dest)
        url = f"https://github.com/{args.org}/{name}.git"
        rc, o, e = sh(["git", "clone", "--quiet", url, dest])
        repo_dir = dest if rc == 0 else None
        if rc != 0:
            emit(f"  ! klonlanamadi: {e.strip()[:150]}")
        else:
            audit_workflow_files(args.org, name, repo_dir)
            audit_community(args.org, name, repo_dir)
            audit_history(full, repo_dir)
            merge_local_findings(args.org, name, repo_dir)
            cloned[name] = repo_dir

        if args.fix:
            emit("  --fix uygulanıyor...")
            for label, code, msg in apply_fixes(args.org, name):
                FIXES.append({"target": label, "http": code, "resp": msg})
                mark = "ok" if code in (200, 201, 204) else f"HTTP {code}"
                emit(f"    [{mark}] {label}" + (f" - {msg}" if msg and code not in (200, 201, 204) else ""))

    # repo'lararasi referans denetimi (bir repo baska repo'nun iceriginden bahseder)
    if len(cloned) > 1:
        emit("\n" + "-" * 70)
        emit("REPO'LARARASI REFERANS DENETIMI")
        for nm, rd in cloned.items():
            others = [v for k, v in cloned.items() if k != nm]
            audit_cross_repo(args.org, rd, others)

    # org fix'leri
    if args.fix:
        for f in list(FINDINGS):
            if f.get("fix") and f["fix"][0] == "org-patch":
                st, d = gh(f"/orgs/{args.org}", "PATCH", f["fix"][1])
                FIXES.append({"target": f"org {list(f['fix'][1])[0]}", "http": st})
                emit(f"    [{'ok' if st == 200 else st}] org {list(f['fix'][1])[0]}")
                f["fix"] = None

    FINDINGS.sort(key=lambda f: (ORDER[f["severity"]], f["category"], f["id"]))
    counts = defaultdict(int)
    for f in FINDINGS:
        counts[f["severity"]] += 1

    emit("\n" + "=" * 78)
    emit(f"TOPLAM BULGU: {len(FINDINGS)}  " +
         "  ".join(f"{ICONS[k]} {k}: {counts[k]}" for k in ORDER if counts[k]))
    emit("=" * 78)

    by_cat = defaultdict(list)
    for f in FINDINGS:
        by_cat[f["category"]].append(f)
    for cat in sorted(by_cat):
        emit(f"\n### {cat}. {CATS.get(cat, cat)}  ({len(by_cat[cat])} bulgu)")
        last = None
        for f in by_cat[cat]:
            if f["id"] != last:
                emit(f"  {ICONS[f['severity']]} [{f['severity'].upper()}] {f['id']}")
                last = f["id"]
            emit(f"      {f['subject']}")
            emit(f"        {f['msg']}")

    if args.json:
        print(json.dumps([{k: v for k, v in f.items() if k != "fix"} for f in FINDINGS],
                         ensure_ascii=False, indent=2))
    if FIXES:
        emit("\n" + "=" * 78)
        emit(f"UYGULANAN FIX: {len(FIXES)}")
        for x in FIXES:
            emit(f"  {x['target']}: HTTP {x['http']}" + (f" {x['resp']}" if x.get("resp") else ""))

    if out_fh:
        out_fh.close()
    return 0


if __name__ == "__main__":
    sys.exit(main())
