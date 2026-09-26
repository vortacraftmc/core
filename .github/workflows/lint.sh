#!/usr/bin/env bash

set -uo pipefail

echo "::group::📦 Installing Mecha"
python -m pip install mecha
echo "::endgroup::"

IGNORE_PATHS=(
    "packs/inv_gui"
    "packs/cmdTunnel-datapack/data/*/functions/init.mcfunction"
    "packs/macroEngine-Datapack-v26.3/data/macroengine/function/world/get_time.mcfunction"
    "packs/macroEngine-Datapack-v26.3/data/macroengine/function/world/time_phase.mcfunction"
)

echo "::group::🚫 Ignoring paths"

for path in "${IGNORE_PATHS[@]}"; do
    echo "Ignore: $path"
done

echo "::endgroup::"

echo "::group::🔧 Preparing validation"

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

cp -a . "$TMP_DIR/project"

cd "$TMP_DIR/project"

for pattern in "${IGNORE_PATHS[@]}"; do
    while IFS= read -r -d '' target; do
        echo "::notice::Ignoring ${target#./}"
        rm -rf "$target"
    done < <(find . -path "./$pattern" -print0 2>/dev/null)
done

echo "::endgroup::"

echo "::group::🔍 Mecha validation"

mecha_status=0
if mecha .; then
    echo "::notice::Mecha validation passed."
else
    mecha_status=$?
    echo "::error::Mecha reported validation errors (exit $mecha_status)."
fi

echo "::endgroup::"

echo "::group::✅ Validation summary"
if [ "$mecha_status" -eq 0 ]; then
    echo "Mecha validation finished: PASSED."
else
    echo "Mecha validation finished: FAILED (exit $mecha_status)."
fi
echo "Ignored paths: ${#IGNORE_PATHS[@]}"
echo "::endgroup::"

# FIX (audit): this script previously always ended with `exit 0`, so a real
# Mecha validation failure was logged as a warning and then swallowed -- the
# "lint" job in build.yml could never actually fail because of it. Propagate
# Mecha's real exit status so the job goes red when validation fails.
exit "$mecha_status"
