# Skyline Zero — roadmap

Owner: Popovskyi. Updated 17.10, build **b35 · 17.10 17:27** published (PR #4 merge: PropLibrary real ids + heartbeat).
One list for every agent; work top to bottom unless the owner says otherwise. When an item ships, move it
to `CHANGELOG.md` and delete it here. Do not add items the owner did not ask for: put ideas in
`docs/design/brainstorm-hooks.md` instead.

## Now: live b35

Shipped with b35 (merge of roadmap-continue):

- Phase D FBX regen (Weapons / InteriorProps / RoofProps) + PC upload → real `PropLibrary.ASSETS` ids.
- Heartbeat SFX wired (`SoundConfig` **9043365842**).
- HUD declutter / Phase D Has()-dress / lobby L1 Classes already from prior builds.

## Next (owner only — see `docs/design/owner-gates.md`)

1. **Launch Public** — Art approve `assets/store/` → Creator Hub Public when you say so. **Do not flip without owner OK.**
2. Optional: upload Bat.png Image → `ItemDefinitions.Bat.iconImage`; re-import RoofProps.fbx → `.rbxm` in Studio.
3. Brainstorm hooks — only when you pull them forward.

## Rules that stay

- Robux never skips the game and never buys tokens directly (`economy-robux.md`).
- Every match starts from zero; only tokens, stats and the leaderboard persist.
- Ukrainian first, then Russian and English, for every string.
- **No invent asset / sound ids. No publish / Build bump unless owner asks.**
