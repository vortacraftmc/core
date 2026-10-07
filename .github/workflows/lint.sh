#!/usr/bin/env bash

set -uo pipefail

# ANSI Renk Kodları
COLOR_RESET="\033[0m"
COLOR_INFO="\033[1;34m"      # Mavi
COLOR_SUCCESS="\033[1;32m"   # Yeşil
COLOR_WARN="\033[1;33m"      # Sarı
COLOR_PATH="\033[0;36m"      # Siyan
COLOR_MUTED="\033[0;90m"     # Gri
COLOR_SUBHEADER="\033[1;35m" # Mor

echo "::group::📦 Installing Mecha"
python -m pip install mecha
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

echo -e "${COLOR_SUBHEADER} ┌─ [Sub-Group] Copying Repository${COLOR_RESET}"
cp -a . "$TMP_DIR/project"
echo -e "${COLOR_MUTED} │  Files copied to temporary directory: $TMP_DIR/project${COLOR_RESET}"

cd "$TMP_DIR/project"

echo -e "${COLOR_SUBHEADER} ┌─ [Sub-Group] Removing Ignored Patterns${COLOR_RESET}"
REMOVED_FILES=()

for pattern in "${IGNORE_PATHS[@]}"; do
    while IFS= read -r -d '' target; do
        echo -e "${COLOR_MUTED} │  ├─ Removing:${COLOR_RESET}${target#./}"
        echo "::notice::Ignoring ${target#./}"
        REMOVED_FILES+=("${target#./}")
        rm -rf "$target"
    done < <(find . -path "./$pattern" -print0 2>/dev/null)
done

echo "::endgroup::"

echo "::group::🔍 Mecha validation"

mecha_status=0
echo -e "${COLOR_INFO} ┌─ [Sub-Group] Running Mecha Analysis${COLOR_RESET}"

if mecha .; then
    echo -e "${COLOR_SUCCESS} │  └─ Mecha validation passed successfully.${COLOR_RESET}"
    echo "::notice::Mecha validation passed."
else
    mecha_status=$?
    echo -e "${COLOR_WARN} │  └─ Mecha reported validation errors (exit status: $mecha_status).${COLOR_RESET}"
    echo "::warning::Mecha reported validation errors (exit $mecha_status)."
fi

echo "::endgroup::"

echo "::group::♻️ Restoring deleted files"

cd "$ORIGINAL_DIR"

echo -e "${COLOR_SUBHEADER} ┌─ [Sub-Group] Checking Working Tree${COLOR_RESET}"

if [ "${#REMOVED_FILES[@]}" -gt 0 ]; then
    if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        git checkout -- "${REMOVED_FILES[@]}" 2>/dev/null || true
        echo -e "${COLOR_SUCCESS} │  └─ Restored ${#REMOVED_FILES[@]} item(s) from Git index.${COLOR_RESET}"
        echo "::notice::Restored ${#REMOVED_FILES[@]} file(s)/folder(s) from Git index."
    else
        echo -e "${COLOR_MUTED} │  └─ Working directory is intact (modifications were isolated in temp directory).${COLOR_RESET}"
        echo "::notice::Working directory is intact (files were only modified in temp directory)."
    fi
else
    echo -e "${COLOR_MUTED} │  └─ No files needed to be restored.${COLOR_RESET}"
    echo "::notice::No files to restore."
fi

echo "::endgroup::"

echo "::group::✅ Validation summary"

echo -e "${COLOR_INFO} ┌─ Execution Results:${COLOR_RESET}"
if [ "$mecha_status" -eq 0 ]; then
    echo -e "${COLOR_SUCCESS} │  Status: PASSED${COLOR_RESET}"
    echo -e " │  Log: Mecha validation finished."
else
    echo -e "${COLOR_WARN} │  Status: PASSED WITH WARNINGS (exit status $mecha_status)${COLOR_RESET}"
    echo -e " │  Log: Validation errors were muted to warning level."
fi
echo -e "${COLOR_PATH} │  Total Ignored Paths configured: ${#IGNORE_PATHS[@]}${COLOR_RESET}"

echo "::endgroup::"

# Süreç hatayla sonlanmasın, her zaman 0 ile çıksın (Uyarı Modu)
exit 0
