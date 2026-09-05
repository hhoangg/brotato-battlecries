#!/usr/bin/env bash
set -euo pipefail

# FAST LOCAL dev loop on THIS Mac for the Battle Cries mod. Brotato's shipped build loads
# mods ONLY from the Steam Workshop content dir (it ignores local mods/ and mods-unpacked/),
# so this writes the fresh zip DIRECTLY into the downloaded Workshop folder of the
# tato-BattleCries item. Relaunch Brotato to pick it up — no re-upload to the Workshop.
#
# PREREQS (one time): publish the mod once with
#     ./publish-steamcmd.sh <steam_account>
# then SUBSCRIBE to the item in Steam so it downloads and its Workshop folder exists.
# Pass that item id here (or hardcode WS_ITEM below once you know it):
#     WS_ITEM=<published_item_id> ./sync-to-mac.sh
#
# CAVEAT: overwrites Steam-managed Workshop files. Steam may revert on "Verify integrity of
# files" or when the item is updated server-side. For a real release, upload the zip via
# publish-steamcmd.sh instead.

MOD_ID="tato-BattleCries"
APP_ID="1942280"
WS_ITEM="${WS_ITEM:-3742196613}"   # published tato-BattleCries Workshop item
if [ -z "${WS_ITEM}" ]; then
  echo "error: WS_ITEM not set." >&2
  echo "    WS_ITEM=<published_item_id> $0" >&2
  exit 1
fi
WS_DIR="${WS_DIR:-$HOME/Library/Application Support/Steam/steamapps/workshop/content/${APP_ID}/${WS_ITEM}}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ZIP="${SCRIPT_DIR}/dist/${MOD_ID}.zip"

"${SCRIPT_DIR}/build-zip.sh" >/dev/null

if [ ! -d "${WS_DIR}" ]; then
  echo "error: workshop folder not found: ${WS_DIR}" >&2
  echo "  Subscribe to the published item once so Steam downloads it, or set WS_ITEM/WS_DIR." >&2
  exit 1
fi

rm -f "${WS_DIR}"/*.zip
cp "${ZIP}" "${WS_DIR}/${MOD_ID}.zip"
echo "Synced latest build -> ${WS_DIR}/${MOD_ID}.zip"
echo "Relaunch Brotato on this Mac to load it (modding branch + --enable-mods)."
