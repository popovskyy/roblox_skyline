# Skyline Zero — handoff

State on 2026-10-18: code on **`master` is `b37 · 18.10 06:17`** (zombie free-catalog outfits). Publish needs `.roblox_api_key` on the publishing machine — see `CHANGELOG.md`.

## What the game is

Roblox survival game. A ruined, overgrown city (The Last of Us / Days Gone look). Players start on a
skyscraper roof (safe), go down 4 floors for resources, food and loot, avoid zombies and toxic air,
bring things back, build Chest → Generator → Air filter → Bridge, cross the bridge to the next tower to win.
Every match starts from zero (`GameConfig.PersistProgress = false`); only the lobby leaderboard is saved.
Downed players lie until a teammate lifts them with a Bandage; everyone down = "You lost" → back to lobby.

## Places and publishing

| | Place id | Rojo project |
|---|---|---|
| Lobby (start place) | 128619231370772 | `lobby.project.json` |
| Tower (match) | 104145307601846 | `default.project.json` |

Universe id 10771270901, creator user id 8053736277 (account Tailwind777).

- Publish both: `bash scripts/publish.sh` (or `bash scripts/publish.sh tower`). Uses Open Cloud with the key
  in `.roblox_api_key` (git-ignored, NOT in the repo; scopes: universe-places write, asset write).
  `rojo upload` does not work ("Scope not authorized"); the script posts the built place with curl.
- Bump `PlacesConfig.Build` before publishing; it is printed in the server output.
- Upload a Blender FBX as a model: `bash scripts/upload_model.sh <file.fbx> <name>` → prints the asset id,
  then add it to `ASSETS` in `src/ServerScriptService/PropLibrary.luau` (loaded at runtime with InsertService).
- Images: Open Cloud `assetType: "Image"` works and gives an id usable as `rbxassetid://<id>` directly.
- Teleports do not work in Studio; test lifts in the published game.
- The user tests on PC and phone; there is no live Rojo sync (plugin lacks Script Injection).

## Code map

- `src/ReplicatedStorage/Shared` — config and data: `GameConfig`, `ItemDefinitions` (weapons have `weapon` stats),
  `UpgradeDefinitions` (chain: StorageCrate → Generator → AirFilter / Bridge), `Locale` (ALL player text, uk/ru/en;
  the server sends keys, clients render; language = Roblox menu `Player.LocaleId`), `PlacesConfig`, `Theme` (fonts),
  `SoundConfig`, `MusicConfig`, `MonetizationConfig` (off; hooks: SelfRevive, BackpackInsurance, passes).
- `src/ServerScriptService` — `ServerMain` (init/start order), `WorldBuilder` (whole tower built from code;
  random item placement via `makePlacer`, furnishing tables `FURNISHING`), `Scenery` (ruins/plants), `Atmosphere`
  (lighting), `PropLibrary` (Blender props), `Services/*`:
  PlayerData (session mode), Inventory, Storage (chest), Resource (nodes, rubble, loot crates), BaseUpgrade,
  Hazard (fall, toxic, hunger meter, zones), Flashlight, Tutorial (7 steps + ending), Damage (downed/revive,
  all-down event), Zombie (NPC AI), Combat (equip from hotbar, swing), Craft (workbench), Match (game over),
  Party (lobby party hand-off via MemoryStore), Interaction (all ProximityPrompts), Sfx, Monetization.
- `src/StarterPlayer/.../Controllers` — client UI only: HUD, Inventory (hotbar + chest window), Interaction,
  Combat (hit button, downed screen, workbench window), WorldVisuals (per-player world state, prompt texts),
  ObjectiveMarker, Intro (story card), Music, Lang, UIKit, ItemSlot.
- `src/Lobby` — lobby place: lifts (1/2/4/6, full lift counts down 3× faster), leaderboard, lobby world.
- `blender/*.py` — headless Blender 5.2 scripts (roof props, interior props, weapons, icons); `sz_blender.py` helpers.

Lint/format before every build: `stylua src && selene src` (must stay at 0 errors / 0 warnings).
Edit multi-line Cyrillic strings with a real editor, not shell heredocs (they broke strings twice).

## Uploaded assets

- Interior props model **97341263879744**, weapons model **91152894600749** (both in `PropLibrary.ASSETS`; b35 PC upload).
- Roof props come from `assets/models/RoofProps.rbxm` (mapped to `ReplicatedStorage.Models`).
- 3D-rendered item icons were uploaded as images but the user rejected the look ("cheap"); NOT used:
  Medkit 129895350598881, Bandage 105469994496291, Cable 106193035511566, Club 125875118535946,
  Crowbar 100896719402218, Electronics 80217654901506, Flashlight 118270124098599, Food 115729061047678,
  Machete 71739707913931, Motor 130637537634065, Pipe 121452932787349, Scrap 72009556714655.

### Zombie appearance (catalog, free)

Wired in `ZombieService` via `HumanoidDescription` (not InsertService meshes). Verified 2026-10-18
(`economy.roblox.com`, price 0, creator Roblox):

| Role | Asset id | Catalog name |
|---|---|---|
| Face | 86487700 | Man Face |
| Shirt | 144076436 | Grey Striped Shirt with Denim Jacket |
| Shirt | 144076358 | Blue and Black Motorcycle Shirt |
| Shirt | 4047884046 | Guitar Tee with Black Jacket |
| Shirt | 607785314 | ROBLOX Jacket |
| Shirt | 398633584 | Denim Jacket with White Hoodie |
| Pants | 144076760 | Dark Green Jeans |
| Pants | 382537569 | Black Jeans |
| Pants | 398635338 | Ripped Skater Pants |
| Pants | 382538503 | Black Jeans with Sneakers |

Rejected for this pass: Drooling Zombie model `187789986` (meme silhouette); third-party Creator Store
R15 packs (need ownership for InsertService). Custom Blender zombie mesh deferred until Open Cloud key
is available on the publishing machine.

## Recent systems

- Animations: `python scripts/build_animations.py --upload` writes R15 KeyframeSequences and uploads them as
  Animation assets (Open Cloud supports it); ids live in `CombatController.ANIMATIONS`.
- Held item: any non-resource hotbar item goes into the hand (`CombatService`, tool "Held"); a tap / click / R2
  swings a weapon, eats/heals, or toggles the flashlight. Resources live in the pouch above the hotbar.
- Icons: `python scripts/build_icons.py [names]` draws worn cream SVGs and renders PNGs with headless Chrome;
  upload as Image and set `iconImage`.
- Loot: tiers rolled per floor (`GameConfig.Loot`), upgrade/pity on open, diamond crates locked (Key or crowbar
  break-in that alerts zombies). Effects are client-only in `LootFxController`. Crates stay opened for the match.
- QA reports from the tester thread are in `QA/` (not committed).

## Blockers (do not invent ids)

Full runbook: **`docs/design/owner-gates.md`**.

- **Low-HP heartbeat SFX:** id `9043365842` (`rbxassetid://9043365842`) in `SoundConfig.Sounds.Heartbeat`;
  `VitalsController` loops it while HP ≤ 30 (not downed / not match-over).
- **Phase D mesh re-upload:** FBX packs regenerated (Weapons with Bat/Crowbar, Interior with crates/nodes/rubble/boards, RoofProps). Live `PropLibrary.ASSETS` still InteriorProps `76157686296384` / Weapons `126001413949023` until `bash scripts/upload_model.sh` prints new ids on the owner PC (needs `.roblox_api_key`). RoofProps.rbxm still needs Studio re-import from the new FBX.
- **Bat icon Image:** `assets/icons/Bat.png` ready; `ItemDefinitions.Bat.iconImage` still Club id + tint until Open Cloud Image upload prints a real id.
- **Creator Hub Public + store art:** concepts in `assets/store/`; Art approve then owner uploads — do not flip Public without owner OK.

## In progress / next

See `docs/ROADMAP.md` (what to do next) and `CHANGELOG.md` (what each build changed). Rules for every agent: `AGENTS.md`.

## Working with the user

Popovskyi (Roblox account Tailwind777) writes in Ukrainian, wants me to do as much as possible myself,
tests on PC and phone and reports bugs with screenshots. Reply in Ukrainian, short, say what was published.
