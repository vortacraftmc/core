#!/usr/bin/env bash
# backup-org.sh (v2)
# GitHub organization backup: bare git + wiki + issues/PRs/discussions/releases/labels
# + org and per-repo settings metadata + optional plain source clones
# -> encrypted 7z archive (default) or plain .tar.gz.
#
# Usage:      bash ~/backup-org.sh
# Settings (override with environment variables):
#   ORG=vortacraftmc  BACKUP_DIR=~/backup/ORG  OUT_DIR=~/backup-out
#   ENCRYPT=7z|none   (default 7z; "none" writes an UNENCRYPTED archive)
#   INCLUDE_SOURCE=1|0  WITH_HOOKS=0|1  WITH_META=1|0  KEEP=7
#   STRICT=0|1        (1 = exit code 2 if any warning was recorded)
#
# Token: VC_TOKEN or GH_TOKEN if set, otherwise prompted silently.
# Suggested scopes (classic PAT): repo, read:org. Teams/members/rulesets/secret
# names may need admin-level org access; if they are missing you get a warning
# at the end instead of a silent gap.
# Keep this script OUTSIDE any git repository folder (e.g. ~/backup-org.sh).
#
# NOT covered (GitHub offers no reliable export through these tools):
#   - Projects (v2) boards, Packages, secret VALUES (only secret names are saved)

set -euo pipefail
umask 077

ORG="${ORG:-vortacraftmc}"
BACKUP_DIR="${BACKUP_DIR:-$HOME/backup/$ORG}"
OUT_DIR="${OUT_DIR:-$HOME/backup-out}"
ENCRYPT="${ENCRYPT:-7z}"
INCLUDE_SOURCE="${INCLUDE_SOURCE:-1}"
WITH_HOOKS="${WITH_HOOKS:-0}"
WITH_META="${WITH_META:-1}"
STRICT="${STRICT:-0}"
KEEP="${KEEP:-7}"
DATE="$(date +%F)"

WARNINGS=()
TMPFILES=()

log()  { printf '[%s] %s\n' "$(date +%T)" "$*"; }
warn() { WARNINGS+=("$*"); printf '[%s] WARNING: %s\n' "$(date +%T)" "$*" >&2; }
die()  { printf 'ERROR: %s\n' "$*" >&2; exit 1; }

cleanup() {
  local f
  for f in "${TMPFILES[@]:-}"; do [ -n "$f" ] && rm -f -- "$f"; done
  unset TOKEN VC_TOKEN GH_TOKEN PW1 PW2 2>/dev/null || true
}
trap cleanup EXIT

case "$KEEP" in ''|*[!0-9]*) die "KEEP must be a number" ;; esac
case "$ENCRYPT" in 7z|none) ;; *) die "ENCRYPT must be 7z or none" ;; esac
if [ "$ENCRYPT" = 7z ] && [ ! -t 0 ]; then
  die "ENCRYPT=7z needs an interactive terminal for the password (or run with ENCRYPT=none)"
fi

# ---------------------------------------------------------------- token
TOKEN="${VC_TOKEN:-${GH_TOKEN:-}}"
if [ -z "$TOKEN" ]; then
  read -rsp "GitHub token (input is hidden): " TOKEN
  echo
fi
[ -n "$TOKEN" ] || die "token is empty"

# ---------------------------------------------------------------- tools
command -v git >/dev/null || die "git not found"
command -v python3 >/dev/null || die "python3 not found"
if ! command -v github-backup >/dev/null; then
  log "installing github-backup"
  pip install --quiet github-backup
fi

mkdir -p "$BACKUP_DIR" "$OUT_DIR"

# ------------------------------------------- pick supported CLI flags
# Flag names vary between versions. Missing OPTIONAL flags are skipped with a
# warning; missing CORE flags abort, because a backup without them is not a backup.
HELP="$(github-backup --help 2>&1 || true)"

CORE_WANT=(--repositories --wikis --issues --issue-comments --issue-events
           --pulls --pull-comments --pull-commits --pull-details
           --labels --milestones --releases --assets)
CORE_MUST=(--repositories --wikis --issues --pulls --releases --assets)
OPT_WANT=(--pull-reviews --discussions --security-advisories)
if [ "$WITH_HOOKS" = 1 ]; then OPT_WANT+=(--hooks); fi
if command -v git-lfs >/dev/null; then OPT_WANT+=(--lfs); fi

has_flag() { grep -q -- "$1" <<<"$HELP"; }

for f in "${CORE_MUST[@]}"; do
  has_flag "$f" || die "github-backup lacks required flag $f (upgrade: pip install -U github-backup)"
done

CORE_FLAGS=(); OPT_FLAGS=()
for f in "${CORE_WANT[@]}"; do
  if has_flag "$f"; then CORE_FLAGS+=("$f"); else warn "flag $f not available in this github-backup version, skipped"; fi
done
for f in "${OPT_WANT[@]}"; do
  if has_flag "$f"; then OPT_FLAGS+=("$f"); else warn "flag $f not available in this github-backup version, skipped"; fi
done

# Token goes through a private temp file when supported, so it does not show up in `ps`.
TOKREF="$TOKEN"
if has_flag 'file://'; then
  TOKFILE="$(mktemp)"; TMPFILES+=("$TOKFILE")
  printf '%s' "$TOKEN" > "$TOKFILE"
  TOKREF="file://$TOKFILE"
else
  warn "this github-backup version cannot read the token from a file; it is visible in the process list during the run"
fi
TOKOPT=(-t "$TOKREF")
case "$TOKEN" in github_pat_*) has_flag '--token-fine' && TOKOPT=(--token-fine "$TOKREF") ;; esac

run_backup() {
  github-backup "$ORG" --organization "${TOKOPT[@]}" -o "$BACKUP_DIR" \
    --private --fork --bare --incremental --retries 5 "$@"
}

# --------------------------------------------------------------- backup
log "Starting backup: $ORG -> $BACKUP_DIR"
if ! run_backup "${CORE_FLAGS[@]}" "${OPT_FLAGS[@]}"; then
  warn "backup with optional flags (${OPT_FLAGS[*]:-none}) failed; retrying with core flags only"
  run_backup "${CORE_FLAGS[@]}" || die "github-backup failed"
  warn "optional data (${OPT_FLAGS[*]:-none}) was NOT backed up in this run"
fi

# ------------------------------------------- org + repo settings metadata
FLATTEN="$(mktemp)"; TMPFILES+=("$FLATTEN")
cat > "$FLATTEN" <<'PY'
# Turns `gh api --paginate` output (one JSON doc per page, concatenated) into one JSON file.
import json, sys
src, out, key = sys.argv[1:4]
text = open(src, encoding="utf-8").read()
dec, i, docs = json.JSONDecoder(), 0, []
while True:
    while i < len(text) and text[i].isspace():
        i += 1
    if i >= len(text):
        break
    d, i = dec.raw_decode(text, i)
    docs.append(d)
if key == "@obj":
    data = docs[0] if docs else {}
else:
    data = []
    for p in docs:
        if isinstance(p, list):
            data.extend(p)
        elif key and isinstance(p, dict) and key in p:
            data.extend(p[key])
        else:
            data.append(p)
with open(out, "w", encoding="utf-8") as f:
    json.dump(data, f, indent=1)
PY

# jget FILE EXPR -> prints EXPR evaluated on the JSON in FILE (variable j); never fails the backup
jget() {
  python3 - "$1" "$2" 2>/dev/null <<'PYJ' || true
import json, sys
try:
    j = json.load(open(sys.argv[1], encoding="utf-8"))
    r = eval(sys.argv[2])
    if isinstance(r, (list, tuple)):
        print("\n".join(str(x) for x in r))
    elif r is not None:
        print(r)
except Exception:
    pass
PYJ
}

GH_ERR=""
# ghj ENDPOINT OUTFILE [KEY|@obj]  -> 0 on success; on failure sets GH_ERR
ghj() {
  local ep="$1" out="$2" key="${3:-}" tmp err sep='?'
  case "$ep" in *\?*) sep='&' ;; esac
  tmp="$(mktemp)"; err="$(mktemp)"
  if GH_TOKEN="$TOKEN" gh api --paginate "${ep}${sep}per_page=100" >"$tmp" 2>"$err" \
     && python3 "$FLATTEN" "$tmp" "$out.tmp" "$key" 2>>"$err"; then
    mv -f "$out.tmp" "$out"; rm -f "$tmp" "$err"; return 0
  fi
  GH_ERR="$(head -n1 "$err" | cut -c1-160)"
  rm -f "$tmp" "$err" "$out.tmp"; return 1
}

# meta LABEL ENDPOINT OUTFILE [KEY|@obj]
# 404 = feature not present (info only); anything else = warning.
meta() {
  local label="$1"; shift
  if ghj "$@"; then return 0; fi
  case "$GH_ERR" in
    *404*|*"Not Found"*) log "  (none) $label" ;;
    *) warn "could not fetch $label: ${GH_ERR:-unknown error}" ;;
  esac
  return 0
}

if [ "$WITH_META" = 1 ]; then
  if command -v gh >/dev/null; then
    M="$BACKUP_DIR/org-meta"; mkdir -p "$M"
    log "Saving org metadata"
    meta "org settings"             "/orgs/$ORG"                  "$M/org.json" @obj
    meta "org teams"                "/orgs/$ORG/teams"            "$M/teams.json"
    meta "org members"              "/orgs/$ORG/members"          "$M/members.json"
    meta "org outside collaborators" "/orgs/$ORG/outside_collaborators" "$M/outside_collaborators.json"
    meta "org rulesets"             "/orgs/$ORG/rulesets"         "$M/rulesets.json"
    meta "org actions variables"    "/orgs/$ORG/actions/variables" "$M/actions_variables.json" variables
    meta "org actions secret names" "/orgs/$ORG/actions/secrets"  "$M/actions_secret_names.json" secrets
    [ "$WITH_HOOKS" = 1 ] && meta "org webhooks" "/orgs/$ORG/hooks" "$M/hooks.json"

    if [ -s "$M/members.json" ] && [ "$(jget "$M/members.json" 'len(j)')" = 0 ]; then
      warn "org-meta/members.json is empty: the token probably lacks read:org (an org always has at least one owner)"
    fi

    if [ -s "$M/teams.json" ]; then
      while IFS= read -r slug; do
        [ -n "$slug" ] || continue
        mkdir -p "$M/teams/$slug"
        meta "team $slug members" "/orgs/$ORG/teams/$slug/members" "$M/teams/$slug/members.json"
        meta "team $slug repos"   "/orgs/$ORG/teams/$slug/repos"   "$M/teams/$slug/repos.json"
      done < <(jget "$M/teams.json" '[t["slug"] for t in j]')
    fi

    # Repo list from the API: compare by NAME, not just by count.
    if ghj "/orgs/$ORG/repos?type=all" "$M/repos.json"; then
      while IFS= read -r name; do
        [ -n "$name" ] || continue
        R="$BACKUP_DIR/repositories/$name"
        if [ ! -d "$R" ]; then
          warn "repo '$name' exists in the org but has no folder in the backup"
          continue
        fi
        mkdir -p "$R/meta"
        meta "$name settings"         "/repos/$ORG/$name"              "$R/meta/repo.json" @obj
        meta "$name rulesets"         "/repos/$ORG/$name/rulesets"     "$R/meta/rulesets.json"
        meta "$name collaborators"    "/repos/$ORG/$name/collaborators" "$R/meta/collaborators.json"
        meta "$name actions variables" "/repos/$ORG/$name/actions/variables" "$R/meta/actions_variables.json" variables
        meta "$name actions secret names" "/repos/$ORG/$name/actions/secrets" "$R/meta/actions_secret_names.json" secrets
        meta "$name environments"     "/repos/$ORG/$name/environments" "$R/meta/environments.json" environments
        meta "$name pages"            "/repos/$ORG/$name/pages"        "$R/meta/pages.json" @obj
        if [ -s "$R/meta/repo.json" ]; then
          br="$(jget "$R/meta/repo.json" 'j.get("default_branch","")')"
          [ -z "$br" ] || meta "$name branch protection ($br)" "/repos/$ORG/$name/branches/$br/protection" "$R/meta/branch_protection.json" @obj
        fi
      done < <(jget "$M/repos.json" '[r["name"] for r in j]')
    else
      warn "could not list org repositories: ${GH_ERR:-unknown error}; per-repo metadata and repo-name check skipped"
    fi
  else
    warn "gh not found: org/repo settings metadata and repo-name check skipped"
  fi
fi

# ----------------------------- release assets: on-disk size must match the JSON
VERIFY="$(mktemp)"; TMPFILES+=("$VERIFY")
cat > "$VERIFY" <<'PY'
import json, os, sys
root = os.path.join(sys.argv[1], "repositories")
for repo in sorted(os.listdir(root)):
    rdir = os.path.join(root, repo, "releases")
    if not os.path.isdir(rdir):
        continue
    for fn in sorted(os.listdir(rdir)):
        if not fn.endswith(".json"):
            continue
        path = os.path.join(rdir, fn)
        tag_dir = path[:-5]
        try:
            data = json.load(open(path, encoding="utf-8"))
        except Exception:
            print("BADJSON\t%s\t%s\t-\t-\t-" % (repo, fn))
            continue
        for rel in (data if isinstance(data, list) else [data]):
            for a in rel.get("assets", []):
                p = os.path.join(tag_dir, a["name"])
                have = os.path.getsize(p) if os.path.isfile(p) else -1
                if have != a["size"]:
                    print("MISMATCH\t%s\t%s\t%s\t%s\t%s" % (repo, rel.get("tag_name", ""), a["name"], have, a["size"]))
PY

check_assets() { python3 "$VERIFY" "$BACKUP_DIR"; }

log "Verifying release assets"
STALE="$(check_assets)"
if [ -n "$STALE" ] && command -v gh >/dev/null; then
  log "Re-downloading $(grep -c . <<<"$STALE") stale/missing release asset(s)"
  while IFS=$'\t' read -r kind repo tag name have want; do
    [ "$kind" = MISMATCH ] || continue
    GH_TOKEN="$TOKEN" gh release download "$tag" -R "$ORG/$repo" -p "$name" \
      -D "$BACKUP_DIR/repositories/$repo/releases/$tag" --clobber >/dev/null 2>&1 \
      || log "  could not re-download $repo/$tag/$name"
  done <<<"$STALE"
  STALE="$(check_assets)"
fi
if [ -n "$STALE" ]; then
  while IFS=$'\t' read -r kind repo tag name have want; do
    if [ "$kind" = BADJSON ]; then warn "unreadable release file: $repo/$tag"
    else warn "release asset mismatch: $repo/$tag/$name (on disk: $have bytes, GitHub says: $want; the release may have been rebuilt during the backup)"; fi
  done <<<"$STALE"
else
  log "Release assets consistent"
fi

# ------------------------------------ integrity check + plain source clones
shopt -s dotglob nullglob
for d in "$BACKUP_DIR"/repositories/*/; do
  r="${d%/}"
  if [ -d "$r/repository" ]; then
    git --git-dir="$r/repository" fsck --no-progress >/dev/null 2>&1 \
      || warn "git fsck failed: $r/repository"
  fi
  rm -rf "$r/source" "$r/wiki-source"
  if [ "$INCLUDE_SOURCE" = 1 ]; then
    if [ -d "$r/repository" ]; then
      git clone --quiet "$r/repository" "$r/source" 2>/dev/null \
        || warn "could not clone $r/source (empty repository?)"
    fi
    if [ -d "$r/wiki" ]; then
      git clone --quiet "$r/wiki" "$r/wiki-source" 2>/dev/null \
        || log "note: could not clone $r/wiki-source (empty wiki?)"
    fi
  fi
done
shopt -u dotglob nullglob

if [ "$INCLUDE_SOURCE" = 1 ]; then
  n="$(find "$BACKUP_DIR/repositories" -path '*/source/*' -not -path '*/.git/*' -type f | wc -l)"
  log "Plain source files going into the archive: $n"
  if [ "$n" -eq 0 ]; then warn "source/ folders are empty, source code will not be in the archive"; fi
fi

# -------------------------------------------------------------- archive
PARENT="$(dirname "$BACKUP_DIR")"
BASE="$(basename "$BACKUP_DIR")"

if [ "$ENCRYPT" = 7z ]; then
  if ! command -v 7z >/dev/null; then
    log "installing p7zip"
    sudo apt-get update -qq && sudo apt-get install -y -qq p7zip-full
  fi
  ARCHIVE="$OUT_DIR/$ORG-$DATE.7z"
  rm -f "$ARCHIVE"
  log "Set an archive password (ASCII characters only)."
  while :; do
    read -rsp "Archive password: " PW1; echo
    read -rsp "Password (again): " PW2; echo
    if [ -n "$PW1" ] && [ "$PW1" = "$PW2" ]; then break; fi
    log "Passwords are empty or do not match, try again."
  done
  # Note: 7z only accepts the password as an argument, so it is briefly visible in `ps` on this machine.
  (cd "$PARENT" && 7z a -t7z -mhe=on -p"$PW1" -bd "$ARCHIVE" "$BASE" >/dev/null) \
    || die "could not create archive"
  log "Testing archive"
  7z t -p"$PW1" -bd "$ARCHIVE" >/dev/null || die "archive test failed"
  log "Archive test passed"
  unset PW1 PW2
else
  ARCHIVE="$OUT_DIR/$ORG-$DATE.tar.gz"
  warn "the archive is NOT encrypted. It contains private code; encrypt it before uploading anywhere"
  tar -czf "$ARCHIVE" -C "$PARENT" "$BASE"
  tar -tzf "$ARCHIVE" >/dev/null || die "archive verification failed"
fi

(cd "$OUT_DIR" && sha256sum "$(basename "$ARCHIVE")" > "$(basename "$ARCHIVE").sha256")

# ------------------------------------------------- prune old archives
find "$OUT_DIR" -maxdepth 1 -type f \( -name "$ORG-*.7z" -o -name "$ORG-*.tar.gz" \) \
  -printf '%T@ %p\n' | sort -rn | tail -n +"$((KEEP + 1))" | cut -d' ' -f2- |
  while IFS= read -r old; do
    log "removing old archive: $old"
    rm -f -- "$old" "$old.sha256"
  done

# -------------------------------------------------------------- summary
echo
log "Done."
echo "  Archive: $ARCHIVE ($(du -h "$ARCHIVE" | cut -f1))"
echo "  SHA256 : $(cut -d' ' -f1 "$ARCHIVE.sha256")"
if [ "${#WARNINGS[@]}" -gt 0 ]; then
  echo
  echo "  ${#WARNINGS[@]} warning(s) - the backup is INCOMPLETE or degraded in these points:"
  for w in "${WARNINGS[@]}"; do echo "   - $w"; done
fi
echo
echo "Next steps:"
echo "  1. File > Open Folder > $OUT_DIR, right-click the archive > Download"
echo "  2. Verify the hash locally and open the archive (7-Zip); try cloning one repository"
echo "  3. Revoke the token on GitHub (Settings > Developer settings)"
echo "  4. Delete the Codespace only after verifying the download"
echo "  Note: the unencrypted backup folder is still in the Codespace: $BACKUP_DIR"

if [ "$STRICT" = 1 ] && [ "${#WARNINGS[@]}" -gt 0 ]; then exit 2; fi
