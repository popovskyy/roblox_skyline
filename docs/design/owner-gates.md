# Skyline Zero — owner-only gates (do not fake)

> **Status (17.10, roadmap-continue):** Everything else on the roadmap that agents can do in-cloud
> is done or verified. Heartbeat SFX is wired (`9043365842`). Remaining owner steps: Blender/mesh
> upload + Creator Hub Public. **Do not invent Roblox asset or sound ids.** Do not bump
> `PlacesConfig.Build` or publish until the owner says so.

---

## 1. Blender upload → real mesh ids

**Already in this repo (regenerated on Cloud with Blender 4.2 headless):**

| Pack | FBX | Preview | Blender source |
|------|-----|---------|----------------|
| Weapons (incl. **WeaponBat**, **WeaponCrowbar**) | `assets/models/Weapons.fbx` | `assets/previews/Weapons.png` | `blender/Weapons.blend` |
| Interior (crates / ScrapNode / ElectronicsNode / Soft-HardRubble / BarricadeBoards + filler) | `assets/models/InteriorProps.fbx` | `assets/previews/InteriorProps.png` | `blender/InteriorProps.blend` |
| Roof upgrades | `assets/models/RoofProps.fbx` | `assets/previews/RoofProps.png` | `blender/RoofProps.blend` |

**Owner PC (needs `.roblox_api_key`):**

```bash
bash scripts/upload_model.sh assets/models/Weapons.fbx SkylineZero_Weapons
bash scripts/upload_model.sh assets/models/InteriorProps.fbx SkylineZero_InteriorProps
```

Paste each printed id into `src/ServerScriptService/PropLibrary.luau` → `ASSETS.Weapons` / `ASSETS.InteriorProps`.

**RoofProps.rbxm** (Studio path, not Open Cloud Model upload):

1. Studio → Import `assets/models/RoofProps.fbx`
2. Save to File → `assets/models/RoofProps.rbxm` (replaces the checked-in rbxm)
3. Rojo maps it to `ReplicatedStorage.Models`

Until upload: CombatService uses Part LOOKS for Bat/Crowbar; WorldBuilder dresses crates/nodes/rubble/boards only when `PropLibrary.Has` — grey-box Parts otherwise.

**Bat icon (Image upload, separate):** `assets/icons/svg/Bat.svg` + `assets/icons/Bat.png` are ready.
Upload as Open Cloud Image → paste id into `ItemDefinitions.Bat.iconImage` and clear `iconTint` if the art is self-sufficient. Until then Bat keeps the Club image id + Rare tint.

---

## 2. Heartbeat low-HP SFX — done

Owner id pasted: **`9043365842`** (`rbxassetid://9043365842`).

- `SoundConfig.Sounds.Heartbeat = { 9043365842 }`
- `VitalsController` plays a looped client SFX while HP ≤ 30 (stops when healed, downed, or match over).

---

## 3. Creator Hub Public + store visuals

| Asset | Path | Gate |
|-------|------|------|
| Icon 512 | `assets/store/icon-512.png` | Art approve → Hub |
| Thumb / banner 1920×1080 | `assets/store/thumbnail-1920x1080.png` | Art approve → Hub |
| Copy uk/ru/en | `docs/design/marketing-draft.md` | Owner paste after merge |
| Briefs | `store-visual-brief.md`, `banner-art-brief.md` | Direction only |

Do **not** flip the experience to Public until owner + Art OK.

---

## After gates

1. Owner merges the continue PR (if open).
2. Bump `PlacesConfig.Build` + `bash scripts/publish.sh` when owner asks.
3. Optional: Hub Public + store media upload.
