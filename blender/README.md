# Blender моделі

Headless scripts build low-poly props for Skyline Zero. **1 Blender unit = 1 stud.** Mesh names are
`<Prop>_<Part>_<Paint>`; in-game colour/material comes from `<Paint>` (`PropLibrary` / `WorldBuilder`).

## Scripts

| Script | Output | Notes |
|--------|--------|-------|
| `build_weapons.py` | `assets/models/Weapons.fbx` | Club, **WeaponBat**, **WeaponCrowbar**, Pipe, Machete |
| `build_interior_props.py` | `assets/models/InteriorProps.fbx` | Filler + **LootCrate**\* / ScrapNode / ElectronicsNode / Soft-HardRubble / BarricadeBoards |
| `build_roof_props.py` | `assets/models/RoofProps.fbx` | Storage / Generator / AirFilter / Bridge |
| `build_icons.py` | `assets/icons/*.png` | 3D icon renders (owner rejected look — prefer SVG path) |

SVG / Chrome icons (preferred for hotbar): `python scripts/build_icons.py [Bat …]`.

### Owner PC (Blender 5.x example)

```
"C:\Program Files\Blender Foundation\Blender 5.2\blender.exe" --background --factory-startup --python blender/build_weapons.py
```

### Cloud / Linux (verified Blender 4.2 LTS)

Needs Mesa EGL + a display for Workbench preview (use `xvfb-run`):

```bash
xvfb-run -a blender --background --factory-startup --python blender/build_weapons.py
xvfb-run -a blender --background --factory-startup --python blender/build_interior_props.py
xvfb-run -a blender --background --factory-startup --python blender/build_roof_props.py
```

Also writes `.blend` sources and `assets/previews/*.png`.

## How models reach the live game

1. **Weapons / Interior (Open Cloud Model):**  
   `bash scripts/upload_model.sh assets/models/<pack>.fbx <Name>` → print asset id → paste into
   `PropLibrary.ASSETS` (**never invent ids**).
2. **RoofProps (Studio rbxm):** Studio Import FBX → Save to File `assets/models/RoofProps.rbxm` → Rojo
   maps to `ReplicatedStorage.Models`.

Until re-upload: CombatService falls back to Part LOOKS for Bat/Crowbar; WorldBuilder dresses crates /
nodes / rubble / boards only when `PropLibrary.Has` — grey-box Parts otherwise.

Live ids today: InteriorProps `76157686296384`, Weapons `126001413949023`.

## Owner gates

See `docs/design/owner-gates.md` — upload key, heartbeat SFX, Creator Hub Public are owner-only.
