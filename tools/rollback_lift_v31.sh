#!/usr/bin/env bash
# One-command rollback: re-publish Lobby+Tower from frozen v31 binaries.
set -euo pipefail
KEY_FILE="${ROBLOX_API_KEY_FILE:-/cursor/stores/bc-c7dd64b7-c0e6-4288-b04f-766744c8d32e/secrets/.roblox_api_key}"
KEY=$(tr -d '\n\r' < "$KEY_FILE")
UNIVERSE=10771270901
BIN_DIR="${ROLLBACK_BIN_DIR:-$(cd "$(dirname "$0")" BIN_DIR="${ROLLBACK_BIN_DIR:-/tmp/rollback-v31}"BIN_DIR="${ROLLBACK_BIN_DIR:-/tmp/rollback-v31}" pwd)/rollback-v31}"
upload() {
  local pid="$1" file="$2" label="$3"
  HTTP=$(curl -sS -o "/tmp/rollback_${label}.json" -w "%{http_code}" \
    -X POST "https://apis.roblox.com/universes/v1/${UNIVERSE}/places/${pid}/versions?versionType=Published" \
    -H "x-api-key: ${KEY}" \
    -H "Content-Type: application/octet-stream" \
    --data-binary @"${file}")
  echo "$label HTTP $HTTP $(cat /tmp/rollback_${label}.json)"
}
upload 104145307601846 "${BIN_DIR}/tower-v31.rbxl" tower
upload 128619231370772 "${BIN_DIR}/lobby-v31.rbxl" lobby
