# Skyline Zero — roadmap

Owner: Popovskyi. Updated 17.10, build **b34 · 17.10 19:30** published (continue branch: FBX regen + Bat icon art; **no publish**).
One list for every agent; work top to bottom unless the owner says otherwise. When an item ships, move it
to `CHANGELOG.md` and delete it here. Do not add items the owner did not ask for: put ideas in
`docs/design/brainstorm-hooks.md` instead.

## Now: owner gates only

Live **b34** already shipped: HUD declutter, Phase D scaffold + Has()-dress, launch prep docs, lobby L1 Classes.

**Cloud continue (this branch) closed everything agents can do without your PC / Creator Hub:**

- Regenerated `Weapons.fbx` / `InteriorProps.fbx` / `RoofProps.fbx` with Bat, Crowbar, crates, nodes, rubble, boards (Blender headless on Cloud).
- Bat worn-cream SVG + PNG ready for Image upload (`assets/icons/…`).
- Owner gate runbook: `docs/design/owner-gates.md`.
- Docs synced (marketing / HANDOFF / blender README / first-session status).
- Tip inventory re-audited — DIE list still silent; no new tip spam.

## Next (owner only — see `docs/design/owner-gates.md`)

1. **Blender upload** — `upload_model.sh` on PC with `.roblox_api_key` → paste printed ids into `PropLibrary.ASSETS`. Re-import RoofProps.fbx → `.rbxm` in Studio. Optional: upload Bat.png Image → `ItemDefinitions.Bat.iconImage`.
2. **Heartbeat SFX** — done (id `9043365842` wired in `SoundConfig` + `VitalsController` low-HP loop).
3. **Launch Public** — Art approve `assets/store/` → Creator Hub Public when you say so.
4. Brainstorm hooks — only when you pull them forward.

## Rules that stay

- Robux never skips the game and never buys tokens directly (`economy-robux.md`).
- Every match starts from zero; only tokens, stats and the leaderboard persist.
- Ukrainian first, then Russian and English, for every string.
- **No invent asset / sound ids. No publish / Build bump unless owner asks.**
