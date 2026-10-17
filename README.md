# SkylineZero

Co-op post-apoc Roblox tower (main place + lobby). Scripts live in a Rojo-style tree; `.rbxlx` place backups keep world/assets.

## Layout

| Path | Role |
|------|------|
| `src/` | Tower place Luau (extracted + edited) |
| `src_lobby/` | Lobby place Luau |
| `places/` | Source-of-truth place backups (`.rbxlx`) |
| `tools/` | Extract / inject helpers for `.rbxlx` ↔ tree |
| `default.project.json` | Rojo map for the tower |
| `lobby.project.json` | Rojo map for the lobby |

**Note:** The checked-in places are scripts + greybox builders (~630KB / ~92KB). Full mesh/map packs are not in these files — `WorldBuilder` / `LobbyWorld` generate the playable greybox at runtime.

## Place IDs

From `PlacesConfig`:

- Lobby: `128619231370772`
- Tower: `104145307601846`

Open Cloud key (local only, never commit): store `secrets/.roblox_api_key` or `/workspace/.secrets/.roblox_api_key`.

## Local workflow

```bash
# Re-extract from places (overwrites src trees)
python3 tools/extract_rbxlx.py places/SkylineZero.rbxlx src
python3 tools/extract_rbxlx.py places/SkylineZero_Lobby.rbxlx src_lobby

# Write edited sources back into place XML
python3 tools/inject_scripts.py places/SkylineZero.rbxlx src -o places/SkylineZero.rbxlx
python3 tools/inject_scripts.py places/SkylineZero_Lobby.rbxlx src_lobby -o places/SkylineZero_Lobby.rbxlx

# Rojo (if installed)
rojo serve default.project.json
rojo serve lobby.project.json
```

## First slice (this branch)

1. **Elevators:** removed Solo/2/4/6 capacity cabins; two identical lifts; dialog to pick party size **2–6**.
2. **Rubble / electronics:** rubble parented under `Interactables`; shared server collision clear; electronics prompts gated until rubble cleared; clearer copy (`res.needRubble`).
3. **Floor scale:** plate **240×240** (from 70); denser scrap; tutorial scrap near stairs; zombie spawn counts scaled.

Remaining backlog items stay open (drops, team chest, live loot HUD, zombie no-respawn-after-clear, atmosphere, onboarding polish, melee mobile anims, …).
