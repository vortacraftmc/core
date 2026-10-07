#!/usr/bin/env bash

set -uo pipefail

# ANSI Color Codes
COLOR_RESET="\033[0m"
COLOR_INFO="\033[1;34m"      # Blue
COLOR_SUCCESS="\033[1;32m"   # Green
COLOR_WARN="\033[1;33m"      # Yellow
COLOR_PATH="\033[0;36m"      # Cyan
COLOR_MUTED="\033[0;90m"     # Muted / Gray
COLOR_SUBHEADER="\033[1;35m" # Magenta

# Pinned: the IGNORE_PATHS below are tied to this grammar version. Bump deliberately.
MECHA_VERSION="${MECHA_VERSION:-0.101.0}"

echo "::group::📦 Installing Mecha ${MECHA_VERSION}"
python -m pip install "mecha==${MECHA_VERSION}"
echo "::endgroup::"

IGNORE_PATHS=(
    "archived/*"
    "build/*"
    # Legacy pack (pack_format 12): camelCase gamerule names are valid there,
    # Mecha validates against the newest game version and rejects them.
    "packs/cmdTunnel-datapack/*"
    # Uses the 26.x `time query minecraft:day` form, which Mecha's grammar
    # (v0.101.0) does not know yet. Only these two files are skipped.
    "packs/macroEngine-Datapack-v26.4/data/macroengine/function/world/time_phase.mcfunction"
    "packs/macroEngine-Datapack-v26.4/data/macroengine/function/world/get_time.mcfunction"
)

echo "::group::🚫 Ignoring paths"
for path in "${IGNORE_PATHS[@]}"; do
    echo -e "${COLOR_PATH}  ├─ Ignore:${COLOR_RESET}$path"
done
echo "::endgroup::"

echo "::group::🔧 Preparing validation"

ORIGINAL_DIR="$(pwd)"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

echo -e "${COLOR_SUBHEADER}▶ Copying Repository:${COLOR_RESET}"
cp -a . "$TMP_DIR/project"
echo -e "${COLOR_MUTED}  │ Files copied to temporary directory: $TMP_DIR/project${COLOR_RESET}"

cd "$TMP_DIR/project" || exit 1

echo -e "${COLOR_SUBHEADER}▶ Removing Ignored Paths:${COLOR_RESET}"
REMOVED_FILES=()

for pattern in "${IGNORE_PATHS[@]}"; do
    while IFS= read -r -d '' target; do
        echo -e "${COLOR_MUTED}  │ ├─ Removing:${COLOR_RESET}${target#./}"
        echo "::notice::Ignoring ${target#./}"
        REMOVED_FILES+=("${target#./}")
        rm -rf "$target"
    done < <(find . -path "./$pattern" -print0 2>/dev/null)
done

echo "::endgroup::"

echo "::group::🔍 Mecha validation"

mecha_status=0
echo -e "${COLOR_INFO}▶ Starting Mecha Analysis...${COLOR_RESET}"

if mecha .; then
    echo -e "${COLOR_SUCCESS}  └── Mecha validation passed successfully.${COLOR_RESET}"
    echo "::notice::Mecha validation passed."
else
    mecha_status=$?
    echo -e "${COLOR_WARN}  └── Mecha reported validation errors (exit status: $mecha_status).${COLOR_RESET}"
    echo "::warning::Mecha reported validation errors (exit $mecha_status)."
fi

echo "::endgroup::"

echo "::group::♻️ Cleanup"

# Ignored paths were only removed inside the temporary copy, so the working
# tree is untouched. (An earlier version ran `git checkout -- <ignored paths>`
# here, which does nothing useful in CI and silently DISCARDS uncommitted local
# changes to those paths when the script is run by hand.)
cd "$ORIGINAL_DIR" || exit 1
echo -e "${COLOR_MUTED}  └── Working directory untouched (${#REMOVED_FILES[@]} path(s) were removed from the temp copy only).${COLOR_RESET}"

echo "::endgroup::"

echo "::group::✅ Validation summary"

echo -e "${COLOR_INFO}Execution Summary:${COLOR_RESET}"
if [ "$mecha_status" -eq 0 ]; then
    echo -e "${COLOR_SUCCESS}  Status: PASSED${COLOR_RESET}"
    echo -e "  Log: Mecha validation finished successfully."
else
    echo -e "${COLOR_WARN}  Status: FAILED (exit status $mecha_status)${COLOR_RESET}"
    echo -e "  Log: Mecha reported validation errors; this now fails the build unless LINT_WARN_ONLY=1."
fi
echo -e "${COLOR_PATH}  Ignored paths count: ${#IGNORE_PATHS[@]}${COLOR_RESET}"

echo "::endgroup::"

# Exit status policy (audit 2026-10-07).
#
# This used to be an unconditional `exit 0` ("Warning Mode"). Combined with the
# `continue-on-error: true` on the "Lint datapacks" step in
# .github/workflows/build.yml, that made the datapack lint a triple no-op: it
# could never fail a build, so a green CI run said nothing about datapack
# validity while NOTICE.md claimed CI enforced it.
#
# Mecha 0.101.0 validates all 3634 .mcfunction files in this repo and currently
# passes with zero errors (verified 2026-10-07, including a negative control
# where a deliberately malformed line produced exit 1). Enforcing it is
# therefore safe today.
#
# Set LINT_WARN_ONLY=1 to restore the old advisory behaviour for a single run.
if [ "${LINT_WARN_ONLY:-0}" = "1" ]; then
    echo "LINT_WARN_ONLY=1 - exiting 0 despite validation errors (advisory mode)."
    exit 0
fi

exit "$mecha_status"
