# Skyline Zero — roadmap

Owner: Popovskyi. Updated 18.10, build **b36 · 18.10 09:15** (tablet Hit + procedural swing; F1 SoftWing /
server rubble open).
One list for every agent; work top to bottom unless the owner says otherwise. When an item ships, move it
to `CHANGELOG.md` and delete it here. Do not add items the owner did not ask for: put ideas in
`docs/design/brainstorm-hooks.md` instead.

## Now: live b36

Shipped with b36:

- Touch: Hit button + procedural Motor6D swing (no more AnimationTrack-only tablet path).
- F1 SoftWing corridor gap; server-side rubble collision clear; F4 debris doorway skip.

## In flight

- **Zombie looks** — free Roblox catalog outfits + ashen skin on `ZombieService` (branch
  `cursor/zombie-models-7623`). Publish after loot/horde music agent takes its Build bump; use next free
  number (do not steal b37).

## Next (owner only — see `docs/design/owner-gates.md`)

1. **Launch Public** — Art approve `assets/store/` → Creator Hub Public when you say so. **Do not flip without owner OK.**
2. Optional: upload Bat.png Image → `ItemDefinitions.Bat.iconImage`; re-import RoofProps.fbx → `.rbxm` in Studio.
3. Brainstorm hooks — only when you pull them forward.

## Rules that stay

- Robux never skips the game and never buys tokens directly (`economy-robux.md`).
- Every match starts from zero; only tokens, stats and the leaderboard persist.
- Ukrainian first, then Russian and English, for every string.
- **No invent asset / sound ids. No publish / Build bump unless owner asks.**
