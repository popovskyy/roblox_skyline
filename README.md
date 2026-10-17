# SkylineZero

Co-op post-apoc Roblox tower (main place + lobby). Canonical repo: [popovskyy/roblox_skyline](https://github.com/popovskyy/roblox_skyline).

Scripts live in a Rojo-style tree; `.rbxlx` place backups keep injected scripts + greybox builders.

## Layout

| Path | Role |
|------|------|
| `src/` | Tower place Luau |
| `src_lobby/` | Lobby place Luau |
| `places/` | Place backups (`.rbxlx`) — scripts + procedural world |
| `tools/` | `extract_rbxlx.py` / `inject_scripts.py` |
| `default.project.json` | Rojo map — tower |
| `lobby.project.json` | Rojo map — lobby |

**Note:** Places are ~650KB / ~100KB. Full mesh packs are not in the rbxlx — `WorldBuilder` / `LobbyWorld` build the greybox at runtime. Floor plate is **240×240** studs.

## Place IDs

From `PlacesConfig` (universe `10771270901`):

- Lobby: `128619231370772`
- Tower: `104145307601846`

Open Cloud API key: keep only under `.secrets/.roblox_api_key` (gitignored). Never commit it.

## Open in Studio with Rojo

1. Install [Rojo](https://rojo.space/docs/installation/) and the Rojo Studio plugin.
2. Clone this repo.
3. Tower:
   ```bash
   rojo serve default.project.json
   ```
   In Studio: Plugins → Rojo → Connect (default port 34872).
4. Lobby (second Studio instance or switch project):
   ```bash
   rojo serve lobby.project.json
   ```
5. Or sync scripts back into the place XML and open the file:
   ```bash
   python3 tools/inject_scripts.py places/SkylineZero.rbxlx src -o places/SkylineZero.rbxlx
   python3 tools/inject_scripts.py places/SkylineZero_Lobby.rbxlx src_lobby -o places/SkylineZero_Lobby.rbxlx
   ```
   Then File → Open from File → `places/*.rbxlx`.

## Extract / inject

```bash
python3 tools/extract_rbxlx.py places/SkylineZero.rbxlx src
python3 tools/extract_rbxlx.py places/SkylineZero_Lobby.rbxlx src_lobby
python3 tools/inject_scripts.py places/SkylineZero.rbxlx src -o places/SkylineZero.rbxlx
python3 tools/inject_scripts.py places/SkylineZero_Lobby.rbxlx src_lobby -o places/SkylineZero_Lobby.rbxlx
```

## Shipped so far

- Elevators: 2–6 party-size dialog (no Solo/2/4/6 signs)
- Rubble clearable + electronics prompt gating; shared server collision
- Floor scale 240 + denser loot / tutorial scrap path
- Ground item drop (G / long-press) for teammates
- Shared team chest
- Live loot `n/m` HUD; objective marker → nearest scrap/electronics
- Downed teammate markers (dir + meters)
- No zombie respawn after floor clear

Still open: atmosphere/lighting/roof, weather, onboarding polish, medkit craft balance, tokens, mobile melee anims.
