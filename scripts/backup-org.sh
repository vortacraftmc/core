#!/usr/bin/env bash
# backup-org.sh
# GitHub organization backup: git (bare) + wiki + issues/PRs/releases/labels
# + optional plain source clones + org metadata -> archive (.tar.gz by default, optional 7z encryption).
#
# Usage:      bash ~/backup-org.sh
# Settings (override with environment variables):
#   ORG=vortacraftmc  BACKUP_DIR=~/backup/ORG  OUT_DIR=~/backup-out
#   ENCRYPT=none|7z   INCLUDE_SOURCE=1|0   WITH_HOOKS=0|1   KEEP=7
#
# Token: uses VC_TOKEN or GH_TOKEN if set, otherwise prompts silently.
# Keep this script OUTSIDE any git repository folder (e.g. ~/backup-org.sh).
#
# Privacy: before archiving, tokens / URL credentials / webhook secrets / e-mail
# addresses are redacted from config and metadata files (both tar.gz and 7z),
# and the script aborts if a token pattern is still found there. Git objects and
# plain source copies are never modified.
set -euo pipefail
umask 077
ORG="${ORG:-vortacraftmc}"
BACKUP_DIR="${BACKUP_DIR:-$HOME/backup/$ORG}"
OUT_DIR="${OUT_DIR:-$HOME/backup-out}"
ENCRYPT="${ENCRYPT:-none}"
INCLUDE_SOURCE="${INCLUDE_SOURCE:-1}"
WITH_HOOKS="${WITH_HOOKS:-0}"
KEEP="${KEEP:-7}"
DATE="$(date +%F)"
log() { printf '[%s] %s\n' "$(date +%T)" "$*"; }
die() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }
# ---------------------------------------------------------------- token
TOKEN="${VC_TOKEN:-${GH_TOKEN:-}}"
TOKEN_FILE=""
cleanup() {
  [ -n "$TOKEN_FILE" ] && rm -f -- "$TOKEN_FILE"
  unset TOKEN VC_TOKEN GH_TOKEN PW1 PW2 2>/dev/null || true
}
trap cleanup EXIT
if [ -z "$TOKEN" ]; then
  read -rsp "GitHub token (input is hidden): " TOKEN
  echo
fi
[ -n "$TOKEN" ] || die "token is empty"
# ---------------------------------------------------------------- tools
command -v git >/dev/null || die "git not found"
if ! command -v github-backup >/dev/null; then
  log "installing github-backup"
  pip install --quiet github-backup
fi
case "$ENCRYPT" in 7z|none) ;; *) die "ENCRYPT must be 7z or none" ;; esac
mkdir -p "$BACKUP_DIR" "$OUT_DIR"
# ------------------------------------------- pick supported CLI flags
# Flag names can vary between versions; unsupported ones are skipped.
HELP="$(github-backup --help 2>&1 || true)"
WANT=(--repositories --wikis --issues --issue-comments --issue-events
      --pulls --pull-comments --pull-commits --pull-details
      --labels --milestones --releases --assets)
if [ "$WITH_HOOKS" = 1 ]; then WANT+=(--hooks); fi
FLAGS=()
for f in "${WANT[@]}"; do
  if grep -q -- "$f" <<<"$HELP"; then
    FLAGS+=("$f")
  else
    log "warning: $f is not available in this version, skipped"
  fi
done
# --------------------------------------------------------------- backup
log "Starting backup: $ORG -> $BACKUP_DIR"
# Keep the token out of argv: a command-line token is readable by every local
# user via `ps`/`/proc/<pid>/cmdline` for the whole (long) backup run. Newer
# github-backup versions accept a file:// path for -t; use a 0600 temp file
# (umask 077 above) removed by the EXIT trap. Older versions fall back to argv.
TOKEN_ARG="$TOKEN"
if grep -q -- 'file://' <<<"$HELP"; then
  TOKEN_FILE="$(mktemp)"
  printf '%s' "$TOKEN" > "$TOKEN_FILE"
  TOKEN_ARG="file://$TOKEN_FILE"
else
  log "warning: this github-backup has no file:// token support; token is passed on the command line (visible in ps)"
fi
github-backup "$ORG" --organization -t "$TOKEN_ARG" -o "$BACKUP_DIR" \
  --private --fork --bare --incremental "${FLAGS[@]}"
# ------------------------------------------------- org-level metadata
if command -v gh >/dev/null; then
  mkdir -p "$BACKUP_DIR/org-meta"
  for ep in teams members rulesets; do
    if GH_TOKEN="$TOKEN" gh api --paginate "/orgs/$ORG/$ep" \
         > "$BACKUP_DIR/org-meta/$ep.json" 2>/dev/null; then
      log "saved org-meta/$ep.json"
    else
      rm -f "$BACKUP_DIR/org-meta/$ep.json"
      log "warning: could not fetch $ep (missing permission?)"
    fi
  done
  EXPECTED="$(GH_TOKEN="$TOKEN" gh api "/orgs/$ORG" \
    --jq '.public_repos + .total_private_repos' 2>/dev/null || true)"
  ACTUAL="$(find "$BACKUP_DIR/repositories" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l)"
  if [ -n "$EXPECTED" ] && [ "$EXPECTED" != "$ACTUAL" ]; then
    log "WARNING: the org shows $EXPECTED repositories, the backup has $ACTUAL folders. Check for missing ones."
  else
    log "Repository count: $ACTUAL"
  fi
else
  log "gh not found, skipping org metadata and repository count check"
fi
# ------------------------------------------- extended metadata (more things)
# Org-level: outside collaborators, webhooks, Actions variables / secret NAMES
# (never values), permissions, GitHub App installations, pending invitations.
# Repo-level: collaborators, webhooks, deploy keys (public part), environments,
# variables / secret names, Pages, rulesets, default-branch protection.
if command -v gh >/dev/null; then
  mkdir -p "$BACKUP_DIR/org-meta" "$BACKUP_DIR/repo-meta"
  save() { # save <outfile> <api path> [jq filter]; missing permission is not fatal
    local out="$1" path="$2" filter="${3:-.}"
    if GH_TOKEN="$TOKEN" gh api --paginate "$path" --jq "$filter" > "$out.tmp" 2>/dev/null; then
      mv "$out.tmp" "$out"
    else
      rm -f "$out.tmp"; log "note: $path not available (permission or feature missing)"
    fi
  }
  save "$BACKUP_DIR/org-meta/org.json"                  "/orgs/$ORG"
  save "$BACKUP_DIR/org-meta/outside-collaborators.json" "/orgs/$ORG/outside_collaborators"
  save "$BACKUP_DIR/org-meta/hooks.json"                "/orgs/$ORG/hooks"
  save "$BACKUP_DIR/org-meta/actions-variables.json"    "/orgs/$ORG/actions/variables"
  save "$BACKUP_DIR/org-meta/actions-secret-names.json" "/orgs/$ORG/actions/secrets" '.secrets[]? | {name, created_at, updated_at, visibility}'
  save "$BACKUP_DIR/org-meta/actions-permissions.json"  "/orgs/$ORG/actions/permissions"
  save "$BACKUP_DIR/org-meta/installations.json"        "/orgs/$ORG/installations"
  save "$BACKUP_DIR/org-meta/invitations.json"          "/orgs/$ORG/invitations"
  while IFS= read -r repo; do
    [ -n "$repo" ] || continue
    d="$BACKUP_DIR/repo-meta/$repo"; mkdir -p "$d"
    save "$d/repo.json"            "/repos/$ORG/$repo"
    save "$d/collaborators.json"   "/repos/$ORG/$repo/collaborators"
    save "$d/hooks.json"           "/repos/$ORG/$repo/hooks"
    save "$d/deploy-keys.json"     "/repos/$ORG/$repo/keys"
    save "$d/environments.json"    "/repos/$ORG/$repo/environments"
    save "$d/actions-variables.json" "/repos/$ORG/$repo/actions/variables"
    save "$d/actions-secret-names.json" "/repos/$ORG/$repo/actions/secrets" '.secrets[]? | {name, created_at, updated_at}'
    save "$d/pages.json"           "/repos/$ORG/$repo/pages"
    save "$d/rulesets.json"        "/repos/$ORG/$repo/rulesets"
    branch="$(GH_TOKEN="$TOKEN" gh api "/repos/$ORG/$repo" --jq .default_branch 2>/dev/null || true)"
    [ -z "$branch" ] || save "$d/branch-protection.json" "/repos/$ORG/$repo/branches/$branch/protection"
    rmdir "$d" 2>/dev/null || true
  done < <(GH_TOKEN="$TOKEN" gh api --paginate "/orgs/$ORG/repos" --jq '.[].name' 2>/dev/null)
fi
# ------------------------------------ integrity check + plain source clones
shopt -s dotglob nullglob
for d in "$BACKUP_DIR"/repositories/*/; do
  r="${d%/}"
  if [ -d "$r/repository" ]; then
    git --git-dir="$r/repository" fsck --no-progress >/dev/null 2>&1 \
      || log "WARNING: git fsck failed: $r/repository"
  fi
  rm -rf "$r/source" "$r/wiki-source"
  if [ "$INCLUDE_SOURCE" = 1 ]; then
    if [ -d "$r/repository" ]; then
      git clone --quiet "$r/repository" "$r/source" 2>/dev/null \
        || log "warning: could not clone $r/source (empty repository?)"
    fi
    if [ -d "$r/wiki" ]; then
      git clone --quiet "$r/wiki" "$r/wiki-source" 2>/dev/null \
        || log "warning: could not clone $r/wiki-source (empty wiki?)"
    fi
  fi
done
shopt -u dotglob nullglob
if [ "$INCLUDE_SOURCE" = 1 ]; then
  n="$(find "$BACKUP_DIR/repositories" -path '*/source/*' -not -path '*/.git/*' -type f | wc -l)"
  log "Plain source files going into the archive: $n"
  if [ "$n" -eq 0 ]; then log "WARNING: source/ folders are empty, source code will not be in the archive."; fi
fi
# ----------------------------------------------------------- sanitize
# Runs on the folder BEFORE archiving, so tar.gz and 7z are both covered.
# Touches only config/metadata files; never git objects or source copies.
TOKEN_RE='(gh[pousr]_[A-Za-z0-9]{30,}|github_pat_[A-Za-z0-9_]{40,})'
sanitize_dir() {
  local n=0 f
  # token / credential redaction: git configs, FETCH_HEAD, all metadata json
  while IFS= read -r -d '' f; do
    if grep -aEq "$TOKEN_RE|https?://[^/[:space:]@:]+:[^@[:space:]/]+@|\"(secret|token|password|client_secret)\"[[:space:]]*:[[:space:]]*\"[^\"]+\"|hooks\.slack\.com/services|discord(app)?\.com/api/webhooks" "$f"; then
      perl -0pi -e '
        s#\b(gh[pousr]_[A-Za-z0-9]{30,}|github_pat_[A-Za-z0-9_]{40,})\b#[REDACTED:token]#g;
        s#(https?://)[^/\s:@]+:[^@\s/]+@#$1\[REDACTED]@#g;
        s#("(?:secret|token|password|client_secret)"\s*:\s*)"[^"]+"#$1"[REDACTED]"#gi;
        s#https://(?:hooks\.slack\.com/services|discord(?:app)?\.com/api/webhooks)/[^\s"\x27]+#[REDACTED:webhook]#g;
      ' "$f"
      n=$((n + 1))
    fi
  done < <(find "$BACKUP_DIR" \( -path '*/source' -o -path '*/wiki-source' -o -name objects -o -name '*.pack' \) -prune -o \
             -type f \( -name config -o -name FETCH_HEAD -o -name '*.json' \) -print0)
  # personal data: e-mail addresses in API metadata only (not in git history/source)
  while IFS= read -r -d '' f; do
    perl -0pi -e 's#(?<![\w.+-])[\w.+-]+@(?!users\.noreply\.github\.com)[\w-]+(?:\.[\w-]+)+#[REDACTED:email]#g' "$f"
  done < <(find "$BACKUP_DIR/org-meta" "$BACKUP_DIR/repo-meta" -type f -name '*.json' -print0 2>/dev/null)
  log "Sanitized $n config/metadata file(s)"
  # fail closed: no token may remain in the files we just cleaned
  if find "$BACKUP_DIR" \( -path '*/source' -o -path '*/wiki-source' -o -name objects -o -name '*.pack' \) -prune -o \
       -type f \( -name config -o -name FETCH_HEAD -o -name '*.json' \) -print0 \
       | xargs -0 -r grep -aElq "$TOKEN_RE"; then
    die "a token pattern is still present in config/metadata files after sanitizing; aborting before archive"
  fi
}
sanitize_dir
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
  (cd "$PARENT" && 7z a -t7z -mhe=on -p"$PW1" -bd "$ARCHIVE" "$BASE" >/dev/null) \
    || die "could not create archive"
  log "Testing archive"
  7z t -p"$PW1" -bd "$ARCHIVE" >/dev/null || die "archive test failed"
  log "Archive test passed"
  unset PW1 PW2
else
  ARCHIVE="$OUT_DIR/$ORG-$DATE.tar.gz"
  log "WARNING: the archive is NOT encrypted. It contains private code; encrypt it before uploading anywhere."
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
echo
echo "Next steps:"
echo "  1. File > Open Folder > $OUT_DIR, right-click the archive > Download"
echo "  2. Verify the hash locally and open the archive (7-Zip); try cloning one repository"
echo "  3. Revoke the token on GitHub (Settings > Developer settings)"
echo "  4. Delete the Codespace only after verifying the download"
echo "  Note: the unencrypted backup folder is still in the Codespace: $BACKUP_DIR"
