#!/usr/bin/env bash
set -euo pipefail

# Build the Battle Cries voice mod into a distributable .zip.
#
# The .mp3 voice clips live in mods-unpacked/<id>/voices/<slug>/<slug>_NN.mp3 (10 per
# character) — this mod is their single home (the web app does not use them). We just zip
# the mod folder; voices/CHECKLIST.md (the voice-map doc) and .DS_Store are excluded.
#
# The zip's internal layout is mods-unpacked/<id>/...  — exactly what Brotato's ModLoader
# expects (it mounts the zip at res://).
#
# Usage:  ./build-zip.sh
# Output: dist/tato-BattleCries.zip

MOD_ID="tato-BattleCries"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT_DIR="${SCRIPT_DIR}/dist"
OUT="${OUT_DIR}/${MOD_ID}.zip"

if [ ! -d "${SCRIPT_DIR}/mods-unpacked/${MOD_ID}" ]; then
  echo "error: mod not found at ${SCRIPT_DIR}/mods-unpacked/${MOD_ID}" >&2
  exit 1
fi

mkdir -p "${OUT_DIR}"
rm -f "${OUT}"
( cd "${SCRIPT_DIR}" && zip -r -q "${OUT}" "mods-unpacked/${MOD_ID}" \
    -x '*.DS_Store' -x '*/voices/CHECKLIST.md' )

CLIPS=$(unzip -l "${OUT}" | grep -c '\.mp3$' || true)
echo "Built: ${OUT}"
echo "  bundled voice clips: ${CLIPS}"
echo "--- contents (must start with mods-unpacked/${MOD_ID}/) ---"
unzip -l "${OUT}" | sed -n '3,8p'
echo "Test locally: upload this zip via GodotWorkshopUtility (Brotato folder), subscribe + relaunch."
