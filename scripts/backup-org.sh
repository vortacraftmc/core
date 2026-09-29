#!/usr/bin/env bash
# backup-org.sh
# GitHub organization backup: git (bare) + wiki + issues/PRs/releases/labels
# + optional plain source clones + org metadata -> encrypted archive.
#
# Usage:      bash ~/backup-org.sh
# Settings (override with environment variables):
#   ORG=vortacraftmc  BACKUP_DIR=~/backup/ORG  OUT_DIR=~/backup-out
#   ENCRYPT=7z|none   INCLUDE_SOURCE=1|0   WITH_HOOKS=0|1   KEEP=7
#
# Token: uses VC_TOKEN or GH_TOKEN if set, otherwise prompts silently.
# Keep this script OUTSIDE any git repository folder (e.g. ~/backup-org.sh).

set -euo pipefail
umask 077

ORG="${ORG:-vortacraftmc}"
BACKUP_DIR="${BACKUP_DIR:-$HOME/backup/$ORG}"
OUT_DIR="${OUT_DIR:-$HOME/backup-out}"
ENCRYPT="${ENCRYPT:-7z}"
INCLUDE_SOURCE="${INCLUDE_SOURCE:-1}"
WITH_HOOKS="${WITH_HOOKS:-0}"
KEEP="${KEEP:-7}"
DATE="$(date +%F)"

log() { printf '[%s] %s\n' "$(date +%T)" "$*"; }
die() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }

# ---------------------------------------------------------------- token
TOKEN="${VC_TOKEN:-${GH_TOKEN:-}}"
cleanup() { unset TOKEN VC_TOKEN GH_TOKEN 2>/dev/null || true; }
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
github-backup "$ORG" --organization -t "$TOKEN" -o "$BACKUP_DIR" \
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
  log "Creating encrypted archive. You will be asked for the password twice (use ASCII characters only)."
  (cd "$PARENT" && 7z a -t7z -mhe=on -p -bd "$ARCHIVE" "$BASE")
  log "Testing archive. Enter the password once more."
  7z t -p -bd "$ARCHIVE" | tail -n 5
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
