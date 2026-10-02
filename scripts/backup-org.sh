#!/usr/bin/env bash
# backup-org.sh  v2.2
# Advanced GitHub Organization Backup
# git (bare/mirror) + wiki + issues/PRs/releases/labels/discussions + attachments
# + optional plain source clones + org metadata → archive (.tar.gz or encrypted 7z)
#
# Usage:
#   bash ~/backup-org.sh
#   ORG=myorg ENCRYPT=7z bash ~/backup-org.sh
#   DRY_RUN=1 bash ~/backup-org.sh
#
# Configuration:
#   Edit:  ~/backup-org/backup-org-config.txt
#   Environment variables always override the config file.
#
# Token resolution order:
#   1. VC_TOKEN / GH_TOKEN environment variable
#   2. gh auth token (if gh CLI is available)
#   3. Interactive hidden prompt
#
# Keep this script OUTSIDE any git repository (e.g. ~/backup-org.sh).

set -euo pipefail
umask 077
IFS=$'\n\t'

# ---------------------------------------------------------------- paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="${HOME}/backup-org"
CONFIG_FILE="${CONFIG_DIR}/backup-org-config.txt"

# ---------------------------------------------------------------- create default config if missing
create_default_config() {
  mkdir -p "$CONFIG_DIR"
  cat > "$CONFIG_FILE" << 'EOF'
# backup-org configuration file
# Lines starting with # are comments.
# Format: KEY=value
# Environment variables always override values in this file.

# Organization to backup
ORG=vortacraftmc

# Working / temporary backup directory
BACKUP_DIR=$HOME/backup/$ORG

# Directory where final archives are written
OUT_DIR=$HOME/backup-out

# Archive encryption: none | 7z
ENCRYPT=none

# Create plain source clones (source/)  1=yes  0=no
INCLUDE_SOURCE=1

# Include webhooks  1=yes  0=no
WITH_HOOKS=0

# Include Git LFS objects  1=yes  0=no
WITH_LFS=0

# How many old archives to keep
KEEP=7

# Skip archived repositories  1=yes  0=no
SKIP_ARCHIVED=0

# Parallel jobs (currently limited use)
PARALLEL=1

# Dry-run mode (show what would be done, write nothing)  1=yes  0=no
DRY_RUN=0

# Verbose logging  1=yes  0=no
VERBOSE=0

# Space-separated list of repository names to exclude
EXCLUDE=
EOF
  echo "Created default config: $CONFIG_FILE"
}

# ---------------------------------------------------------------- load config
load_config() {
  if [ ! -f "$CONFIG_FILE" ]; then
    create_default_config
  fi

  # shellcheck disable=SC1090
  # We only accept simple KEY=value lines
  while IFS= read -r line || [ -n "$line" ]; do
    # skip empty lines and comments
    [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue
    # only accept KEY=value
    if [[ "$line" =~ ^([A-Za-z_][A-Za-z0-9_]*)=(.*)$ ]]; then
      local key="${BASH_REMATCH[1]}"
      local val="${BASH_REMATCH[2]}"
      # expand $HOME and $ORG if present
      val="${val//\$HOME/$HOME}"
      # do not override if already set in environment
      if [ -z "${!key+x}" ]; then
        printf -v "$key" '%s' "$val"
      fi
    fi
  done < "$CONFIG_FILE"
}

# Load config early (before defaults)
load_config

# ---------------------------------------------------------------- defaults (only applied if still unset)
: "${ORG:=vortacraftmc}"
: "${BACKUP_DIR:=$HOME/backup/$ORG}"
: "${OUT_DIR:=$HOME/backup-out}"
: "${ENCRYPT:=none}"
: "${INCLUDE_SOURCE:=1}"
: "${WITH_HOOKS:=0}"
: "${WITH_LFS:=0}"
: "${KEEP:=7}"
: "${SKIP_ARCHIVED:=0}"
: "${PARALLEL:=1}"
: "${DRY_RUN:=0}"
: "${VERBOSE:=0}"
: "${EXCLUDE:=}"

# Re-expand BACKUP_DIR in case it contained $ORG
BACKUP_DIR="${BACKUP_DIR//\$ORG/$ORG}"
BACKUP_DIR="${BACKUP_DIR//\$HOME/$HOME}"
OUT_DIR="${OUT_DIR//\$HOME/$HOME}"

DATE="$(date +%F)"
LOG_FILE="${OUT_DIR}/backup-${ORG}-${DATE}.log"

# ---------------------------------------------------------------- logging
mkdir -p "$OUT_DIR"
exec > >(tee -a "$LOG_FILE") 2>&1

RED=$'\e[31m'; GREEN=$'\e[32m'; YELLOW=$'\e[33m'; CYAN=$'\e[36m'; BOLD=$'\e[1m'; RESET=$'\e[0m'

log()   { printf '%s[%s]%s %s\n' "$CYAN" "$(date +%T)" "$RESET" "$*"; }
ok()    { printf '%s[%s]%s %s%s%s\n' "$GREEN" "$(date +%T)" "$RESET" "$GREEN" "$*" "$RESET"; }
warn()  { printf '%s[%s]%s %s%s%s\n' "$YELLOW" "$(date +%T)" "$RESET" "$YELLOW" "WARNING: $*" "$RESET"; }
die()   { printf '%s[%s]%s %sERROR: %s%s\n' "$RED" "$(date +%T)" "$RESET" "$RED" "$*" "$RESET" >&2; exit 1; }
debug() { [ "$VERBOSE" = 1 ] && printf '%s[%s]%s %s\n' "$CYAN" "$(date +%T)" "$RESET" "DEBUG: $*"; }

# ---------------------------------------------------------------- cleanup
TOKEN=""
PW1="" PW2=""
cleanup() {
  unset TOKEN VC_TOKEN GH_TOKEN PW1 PW2 2>/dev/null || true
  rm -f /tmp/github-backup-$$.* 2>/dev/null || true
}
trap cleanup EXIT INT TERM

# ---------------------------------------------------------------- token
resolve_token() {
  if [ -n "${VC_TOKEN:-}" ]; then
    TOKEN="$VC_TOKEN"
    log "Token taken from VC_TOKEN environment variable"
  elif [ -n "${GH_TOKEN:-}" ]; then
    TOKEN="$GH_TOKEN"
    log "Token taken from GH_TOKEN environment variable"
  elif command -v gh >/dev/null 2>&1; then
    if TOKEN="$(gh auth token 2>/dev/null)"; then
      log "Token taken from gh CLI"
    fi
  fi

  if [ -z "${TOKEN:-}" ]; then
    read -rsp "GitHub token (input is hidden): " TOKEN
    echo
  fi
  [ -n "$TOKEN" ] || die "Token is empty"
}

# ---------------------------------------------------------------- tool checks
check_tools() {
  command -v git >/dev/null || die "git not found"
  command -v tar >/dev/null || die "tar not found"
  command -v sha256sum >/dev/null || die "sha256sum not found"

  if ! command -v github-backup >/dev/null; then
    log "Installing github-backup..."
    pip install --quiet --upgrade github-backup || die "Failed to install github-backup"
  fi

  if [ "$ENCRYPT" = "7z" ] && ! command -v 7z >/dev/null; then
    log "Installing p7zip..."
    if command -v apt-get >/dev/null; then
      sudo apt-get update -qq && sudo apt-get install -y -qq p7zip-full
    elif command -v brew >/dev/null; then
      brew install p7zip
    else
      die "7z not found and could not be installed automatically"
    fi
  fi

  if [ "$WITH_LFS" = 1 ] && ! command -v git-lfs >/dev/null; then
    warn "git-lfs not found, disabling LFS support"
    WITH_LFS=0
  fi
}

# ---------------------------------------------------------------- dynamic flag selection
build_flags() {
  local HELP
  HELP="$(github-backup --help 2>&1 || true)"

  local WANT=(
    --repositories --wikis
    --issues --issue-comments --issue-events --issue-timeline
    --pulls --pull-comments --pull-commits --pull-details --pull-reviews
    --labels --milestones --releases --assets --attachments
    --discussions --security-advisories
  )

  [ "$WITH_HOOKS" = 1 ] && WANT+=(--hooks)
  [ "$WITH_LFS"   = 1 ] && WANT+=(--lfs)

  FLAGS=()
  for f in "${WANT[@]}"; do
    if grep -q -- "$f" <<<"$HELP"; then
      FLAGS+=("$f")
    else
      warn "$f is not available in this version, skipped"
    fi
  done

  if grep -q -- "--throttle-limit" <<<"$HELP"; then
    FLAGS+=(--throttle-limit 50 --throttle-pause 15)
  fi
  if grep -q -- "--retries" <<<"$HELP"; then
    FLAGS+=(--retries 5)
  fi
  if [ "$SKIP_ARCHIVED" = 1 ] && grep -q -- "--skip-archived" <<<"$HELP"; then
    FLAGS+=(--skip-archived)
  fi
}

# ---------------------------------------------------------------- org-level metadata
backup_org_meta() {
  if ! command -v gh >/dev/null; then
    warn "gh CLI not found → skipping org metadata"
    return
  fi

  mkdir -p "$BACKUP_DIR/org-meta"
  local endpoints=(teams members rulesets projects invitations)

  for ep in "${endpoints[@]}"; do
    if GH_TOKEN="$TOKEN" gh api --paginate "/orgs/$ORG/$ep" \
         > "$BACKUP_DIR/org-meta/$ep.json" 2>/dev/null; then
      ok "saved org-meta/$ep.json"
    else
      rm -f "$BACKUP_DIR/org-meta/$ep.json"
      debug "could not fetch $ep (missing permission or endpoint)"
    fi
  done

  GH_TOKEN="$TOKEN" gh api "/orgs/$ORG" > "$BACKUP_DIR/org-meta/org.json" 2>/dev/null \
    && ok "saved org-meta/org.json" || true

  local EXPECTED ACTUAL
  EXPECTED="$(GH_TOKEN="$TOKEN" gh api "/orgs/$ORG" \
    --jq '.public_repos + .total_private_repos' 2>/dev/null || echo "")"
  ACTUAL="$(find "$BACKUP_DIR/repositories" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l | tr -d ' ')"

  if [ -n "$EXPECTED" ] && [ "$EXPECTED" != "$ACTUAL" ]; then
    warn "Org reports $EXPECTED repositories, backup has $ACTUAL folders → some may be missing"
  else
    ok "Repository count matches: $ACTUAL"
  fi
}

# ---------------------------------------------------------------- integrity check + plain source clones
process_repos() {
  shopt -s nullglob
  local repos=("$BACKUP_DIR"/repositories/*/)
  local total=${#repos[@]}
  local i=0

  log "Processing repositories ($total total)..."

  for d in "${repos[@]}"; do
    ((i++)) || true
    local r="${d%/}"
    local name
    name="$(basename "$r")"

    if [ -n "$EXCLUDE" ]; then
      for ex in $EXCLUDE; do
        if [ "$name" = "$ex" ]; then
          log "[$i/$total] $name → excluded"
          continue 2
        fi
      done
    fi

    printf '\r%s[%s]%s [%d/%d] %s' "$CYAN" "$(date +%T)" "$RESET" "$i" "$total" "$name"

    if [ -d "$r/repository" ]; then
      if ! git --git-dir="$r/repository" fsck --no-progress >/dev/null 2>&1; then
        warn "git fsck failed: $name"
      fi
    fi

    rm -rf "$r/source" "$r/wiki-source" 2>/dev/null || true

    if [ "$INCLUDE_SOURCE" = 1 ]; then
      if [ -d "$r/repository" ]; then
        local obj_count
        obj_count="$(git --git-dir="$r/repository" rev-list --all --count 2>/dev/null || echo 0)"
        if [ "$obj_count" -gt 0 ]; then
          git clone --quiet "$r/repository" "$r/source" 2>/dev/null \
            || warn "could not clone source: $name"
        else
          debug "$name is empty, skipping source clone"
        fi
      fi
      if [ -d "$r/wiki" ]; then
        git clone --quiet "$r/wiki" "$r/wiki-source" 2>/dev/null || true
      fi
    fi
  done
  echo
  shopt -u nullglob

  if [ "$INCLUDE_SOURCE" = 1 ]; then
    local n
    n="$(find "$BACKUP_DIR/repositories" -path '*/source/*' -not -path '*/.git/*' -type f 2>/dev/null | wc -l | tr -d ' ')"
    ok "Plain source files that will go into the archive: $n"
    [ "$n" -eq 0 ] && warn "source/ folders are empty → source code will not be in the archive"
  fi
}

# ---------------------------------------------------------------- archive creation
create_archive() {
  local PARENT BASE ARCHIVE
  PARENT="$(dirname "$BACKUP_DIR")"
  BASE="$(basename "$BACKUP_DIR")"

  if [ "$ENCRYPT" = "7z" ]; then
    ARCHIVE="$OUT_DIR/$ORG-$DATE.7z"
    rm -f "$ARCHIVE"

    log "Set an archive password (ASCII characters recommended)."
    while :; do
      read -rsp "Archive password: " PW1; echo
      read -rsp "Password (again): " PW2; echo
      if [ -n "$PW1" ] && [ "$PW1" = "$PW2" ]; then break; fi
      warn "Passwords are empty or do not match, try again."
    done

    log "Creating 7z archive (AES-256 + header encryption)..."
    (cd "$PARENT" && 7z a -t7z -m0=lzma2 -mx=9 -mhe=on -p"$PW1" -bd "$ARCHIVE" "$BASE" >/dev/null) \
      || die "Failed to create 7z archive"

    log "Testing archive..."
    7z t -p"$PW1" -bd "$ARCHIVE" >/dev/null || die "Archive test failed"
    ok "Archive test passed"
    unset PW1 PW2
  else
    ARCHIVE="$OUT_DIR/$ORG-$DATE.tar.gz"
    warn "The archive is NOT encrypted. It contains private code; encrypt it before uploading anywhere."
    tar -czf "$ARCHIVE" -C "$PARENT" "$BASE"
    tar -tzf "$ARCHIVE" >/dev/null || die "Archive verification failed"
  fi

  (cd "$OUT_DIR" && sha256sum "$(basename "$ARCHIVE")" > "$(basename "$ARCHIVE").sha256")
  ARCHIVE_PATH="$ARCHIVE"
}

# ---------------------------------------------------------------- prune old archives
prune_old() {
  find "$OUT_DIR" -maxdepth 1 -type f \( -name "$ORG-*.7z" -o -name "$ORG-*.tar.gz" \) \
    -printf '%T@ %p\n' 2>/dev/null | sort -rn | tail -n +"$((KEEP + 1))" | cut -d' ' -f2- |
  while IFS= read -r old; do
    log "Removing old archive: $old"
    rm -f -- "$old" "$old.sha256"
  done
}

# ---------------------------------------------------------------- summary
print_summary() {
  local size hash
  size="$(du -h "$ARCHIVE_PATH" | cut -f1)"
  hash="$(cut -d' ' -f1 "$ARCHIVE_PATH.sha256")"

  echo
  ok "Backup completed successfully."
  echo
  echo "  Archive : $ARCHIVE_PATH ($size)"
  echo "  SHA256  : $hash"
  echo "  Log     : $LOG_FILE"
  echo "  Config  : $CONFIG_FILE"
  echo
  echo "Next steps:"
  echo "  1. Download the archive from $OUT_DIR"
  echo "  2. Verify the SHA256 hash locally and open the archive"
  echo "  3. Try cloning one repository from the backup to confirm integrity"
  echo "  4. Revoke the token on GitHub (Settings → Developer settings)"
  echo "  5. Delete the temporary environment only after verification"
  echo
  echo "Note: the unencrypted working directory is still present at:"
  echo "      $BACKUP_DIR"
  echo
}

# ---------------------------------------------------------------- main
main() {
  log "=== GitHub Organization Backup v2.2 ==="
  log "Config file  : $CONFIG_FILE"
  log "Organization : $ORG"
  log "Backup dir   : $BACKUP_DIR"
  log "Output dir   : $OUT_DIR"
  log "Encrypt      : $ENCRYPT"
  log "Include source: $INCLUDE_SOURCE"
  log "Keep archives: $KEEP"

  case "$ENCRYPT" in 7z|none) ;; *) die "ENCRYPT must be '7z' or 'none'" ;; esac
  [[ "$KEEP" =~ ^[0-9]+$ ]] || die "KEEP must be a positive integer"

  if [ "$DRY_RUN" = 1 ]; then
    log "DRY-RUN mode – no changes will be made"
    resolve_token
    check_tools
    build_flags
    log "Would run: github-backup $ORG --organization -t *** -o $BACKUP_DIR --private --fork --bare --incremental ${FLAGS[*]}"
    exit 0
  fi

  resolve_token
  check_tools
  build_flags

  mkdir -p "$BACKUP_DIR" "$OUT_DIR"

  log "Starting backup: $ORG → $BACKUP_DIR"
  github-backup "$ORG" \
    --organization \
    -t "$TOKEN" \
    -o "$BACKUP_DIR" \
    --private \
    --fork \
    --bare \
    --incremental \
    "${FLAGS[@]}"

  backup_org_meta
  process_repos
  create_archive
  prune_old
  print_summary
}

main "$@"
