---
cursor:
  subagentId: "bc-4ecb48ee-b764-540d-86f3-da47b80ac5ac"
---

# RCA — spawn in sky / endless fall (our builds)

**Emergency baseline now live:** untouched artifacts published with **no inject / no edits**  
- Tower place `104145307601846` → **v33** (from `artifacts/places/SkylineZero.rbxlx`)  
- Lobby place `128619231370772` → **v34** (from `artifacts/places/SkylineZero_Lobby.rbxlx`)  
- Build stamp inside those files: `b15 · drop-chest-hud-zombies`  
- Binary md5: tower `d115d7f33357af7c8c4b7ff47d22cf9d` · lobby `fcdad26ed89576be7f6ee2debf6fa64f`

**Do not republish agent builds until coordinator says so.**

---

## What we verified (static)

| Check | Artifact (owner upload) | Our tree / last agent places |
|-------|-------------------------|------------------------------|
| `World.FloorSize` / `RoofY` | 240 / 396 | **same** |
| `RoofSpawn` CFrame | `(0, RoofY+0.5, -38)` | **same** |
| Stairwell hole constants | HOLE_X=9, Z −15…15 | **same** |
| Baked `SpawnLocation` in place XML | **none** | **none** |
| Spawn created only at runtime | `WorldBuilder` / `LobbyWorld` | same pattern |
| `GeneratedWorld` parented | **only after** all floors finish | same — error before parent = **no spawn in workspace** |
| `CharacterAutoLoads` | `false` until `PlayerLifecycleService.Start()` after world | same |
| `TokenService` / `WeatherService` | **absent** | **required at top of `ServerMain` before Build** |
| F2 rubble wings / `roomNP` placer | **absent** | **added in our WorldBuilder** (runs before `root.Parent`) |
| Lobby `LobbySpawn` / Ground | `(0,0.5,-25)` / Ground top Y=0 | matches artifact LobbyWorld after lift rollback |

**Not a FloorSize-240 “spawn off the plate” bug:** the owner’s uploaded artifact already ships FloorSize 240 and the same RoofSpawn math. Shifting the plate alone does not explain a new void fall vs that baseline.

---

## Root cause (most likely)

**Failure mode:** tower (or lobby) server aborts or never parents the generated world → **no Enabled `SpawnLocation` under the player** → `LoadCharacter` places the avatar in the void / default height → fall → death → respawn loop (“falling forever”).

### Smoking gun A — new hard requires before world build

Artifact `ServerMain` builds the world with no Token/Weather modules.

Our `ServerMain` does:

```lua
local TokenService = require(Services.TokenService)
local WeatherService = require(Services.WeatherService)
-- ...
TokenService.Init()
local world = WorldBuilder.Build()
```

If either ModuleScript is missing, disabled, or errors on load in a published binary, **the entire server script dies before `WorldBuilder.Build()` and before `PlayerLifecycleService.Start()`**. Combined with runtime-only spawns, that is a void-spawn class failure. Artifact places cannot hit this path.

### Smoking gun B — WorldBuilder errors before `root.Parent = workspace`

`WorldBuilder.Build()` creates `RoofSpawn` during `buildRoof`, but only does `root.Parent = workspace` **after** stairwell + F1–F4 + neighbor. Our F2 patch (`F2_Rubble_A/B`, `makePlacer(..., { "roomPP", "roomNP" })`, extra elec nodes) runs in that window. Any runtime error there leaves **RoofSpawn never in Workspace** — same void outcome. Artifact `buildFloor2` never had those calls.

### Ruled out / weak

- RoofSpawn vs hole math: spawn Z=−38 is outside stairwell hole (−15…15); identical in artifact.  
- LobbyWorld spawn/ground mismatch after lift rollback: LobbyWorld matches artifact; not the primary tower-void theory.  
- Overlay-only UI (`LobbyClient` Active=false panel): cannot remove floor collision or SpawnLocation.

### Lobby vs tower

Endless fall after **lift teleport** points at **tower** ServerMain/WorldBuilder. Endless fall **on lobby join** points at LobbyMain never completing `LobbyWorld.Build()` (no `LobbySpawn` / Ground). Same structural pattern: runtime spawn only.

---

## What we could not verify

- **Live join** on agent builds or on the new artifact v33/v34 (universe PRIVATE; this agent has no play session).  
- **Open Cloud Luau Execution:** still `PERMISSION_DENIED` — missing scope `universe.place.luau-execution-session:10771270901:write`. Cannot prove enter/spawn/teleport in a headless DM.  
- Exact server error string from a broken publish (no log access).

---

## Next (coordinator-gated)

1. Owner confirms artifact **Lobby v34 / Tower v33** stands and walks (no sky fall).  
2. Reapply fixes **one at a time** from this baseline, each separately published and owner-confirmed.  
3. First candidate to reintroduce carefully: Token/Weather **only after** world build + spawn exist (or soft-require), then WorldBuilder F2 loot — never a hard `require` that can kill ServerMain before `Build()`.
