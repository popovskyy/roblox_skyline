#!/usr/bin/env bash
# Uploads an FBX to Roblox as a Model asset through Open Cloud and prints its asset id.
# The game loads it at runtime with InsertService (see ModelLibrary.luau / ModelAssets.luau).
#   bash scripts/upload_model.sh assets/models/InteriorProps.fbx "SkylineZero_InteriorProps"
set -euo pipefail
cd "$(dirname "$0")/.."

FILE=$1
NAME=$2
CREATOR_USER_ID=8053736277
KEY=$(tr -d ' \r\n\t' < .roblox_api_key)

REQUEST=$(printf '{"assetType":"Model","displayName":"%s","description":"Skyline Zero","creationContext":{"creator":{"userId":"%s"}}}' "$NAME" "$CREATOR_USER_ID")
OPERATION=$(curl -sS -m 180 -X POST https://apis.roblox.com/assets/v1/assets \
	-H "x-api-key: $KEY" -F "request=$REQUEST" -F "fileContent=@$FILE;type=model/fbx" |
	python -c "import json,sys; print(json.load(sys.stdin)['operationId'])")

for _ in $(seq 1 30); do
	RESULT=$(curl -sS -m 30 "https://apis.roblox.com/assets/v1/operations/$OPERATION" -H "x-api-key: $KEY")
	if echo "$RESULT" | grep -q '"done":true'; then
		echo "$RESULT" | python -c "import json,sys; print(json.load(sys.stdin)['response']['assetId'])"
		exit 0
	fi
	sleep 4
done
echo "upload did not finish in time: $OPERATION" >&2
exit 1
