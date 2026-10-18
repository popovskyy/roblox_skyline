# Skyline Zero — roadmap

Owner: Popovskyi. Updated 18.10, build **b38 · 18.10 06:25** (shared loot, horde sky, floor tokens).
One list for every agent; work top to bottom unless the owner says otherwise. When an item ships, move it
to `CHANGELOG.md` and delete it here. Do not add items the owner did not ask for: put ideas in
`docs/design/brainstorm-hooks.md` instead.

## Now: live b38

Shipped with b38:

- Party-shared floor piles + crates; readable PropLibrary dress / grey-box fallback.
- Horde: scary music bed + orange/dark sky with siren.
- Tokens only from deepest floor; scrap budgets retuned for shared loot.

Prior b37: zombie free-catalog outfits. Prior b36: tablet Hit + SoftWing / rubble open.

## Next (owner only — see `docs/design/owner-gates.md`)

1. **Launch Public** — Art approve `assets/store/` → Creator Hub Public when you say so. **Do not flip without owner OK.**
2. Optional: upload Bat.png Image → `ItemDefinitions.Bat.iconImage`; re-import RoofProps.fbx → `.rbxm` in Studio.
3. Brainstorm hooks — only when you pull them forward.

## Rules that stay

- Robux never skips the game and never buys tokens directly (`economy-robux.md`).
- Every match starts from zero; only tokens, stats and the leaderboard persist.
- Ukrainian first, then Russian and English, for every string.
- **No invent asset / sound ids. No publish / Build bump unless owner asks.**
