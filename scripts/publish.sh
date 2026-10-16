#!/usr/bin/env bash
# Builds both places and publishes them to Roblox through Open Cloud.
# Needs the API key in .roblox_api_key (git-ignored), with the universe-places:write permission.
#   bash scripts/publish.sh          # lobby + tower
#   bash scripts/publish.sh tower    # one of: lobby, tower
set -euo pipefail
cd "$(dirname "$0")/.."

UNIVERSE_ID=10771270901
LOBBY_PLACE_ID=128619231370772
TOWER_PLACE_ID=104145307601846

KEY=$(tr -d ' \r\n\t' < .roblox_api_key)
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
