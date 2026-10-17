#!/usr/bin/env bash
# Builds both places and publishes them to Roblox through Open Cloud.
# Needs ROBLOX_API_KEY in the environment, or .roblox_api_key / .env (git-ignored).
# Open Cloud permission: universe-places:write.
#   bash scripts/publish.sh          # lobby + tower
#   bash scripts/publish.sh tower    # one of: lobby, tower
set -euo pipefail
cd "$(dirname "$0")/.."

UNIVERSE_ID=10771270901
LOBBY_PLACE_ID=128619231370772
TOWER_PLACE_ID=104145307601846

if [[ -z "${ROBLOX_API_KEY:-}" && -f .env ]]; then
	# shellcheck disable=SC1091
	set -a
	# shellcheck disable=SC1091
	source .env
	set +a
fi
if [[ -n "${ROBLOX_API_KEY:-}" ]]; then
	KEY=$(printf '%s' "$ROBLOX_API_KEY" | tr -d ' \r\n\t')
elif [[ -f .roblox_api_key ]]; then
	KEY=$(tr -d ' \r\n\t' < .roblox_api_key)
else
	echo "Missing ROBLOX_API_KEY (env) or .roblox_api_key" >&2
	exit 1
fi
OUT=$(mktemp -d)
trap 'rm -rf "$OUT"' EXIT

publish() {
	local name=$1 project=$2 place=$3
	rojo build "$project" -o "$OUT/$name.rbxl" > /dev/null
	local response
	response=$(curl -sS -m 300 -X POST \
		"https://apis.roblox.com/universes/v1/$UNIVERSE_ID/places/$place/versions?versionType=Published" \
		-H "x-api-key: $KEY" -H "Content-Type: application/octet-stream" \
		--data-binary "@$OUT/$name.rbxl")
	echo "$name: $response"
}

target=${1:-all}
if [[ $target == all || $target == lobby ]]; then publish lobby lobby.project.json "$LOBBY_PLACE_ID"; fi
if [[ $target == all || $target == tower ]]; then publish tower default.project.json "$TOWER_PLACE_ID"; fi
