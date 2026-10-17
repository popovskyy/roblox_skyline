# Skyline Zero — roadmap

Owner: Popovskyi. Updated 17.10 · live **b33** · epic branch `cursor/roadmap-final-pass` (no publish
until owner says merge). One list for every agent. When an item ships, move it to `CHANGELOG.md` and
delete it here. Ideas go in `docs/design/brainstorm-hooks.md`, not here.

## Now: owner merge gate (epic branch ready for review)

Branch `cursor/roadmap-final-pass` · draft PR — **do not merge/publish mid-pass** until owner OK.

| Block | State on branch |
|-------|-----------------|
| **0 HUD declutter (P0)** | **Done** (tip `d4a6314`+): soft spam killed; blackout one warning; 1+1 toast cap; intro silence; **attack tip silence race fixed** (retry until Toast succeeds) |
| **1 Phase A leftovers** | **Verified** — A1–A8 + §8 knobs re-checked on branch; no gaps / no retune |
| **2 Phase D Blender** | **Scaffold + Has()-dress** — scripts + WorldBuilder optional props. **Upload blocked** (no Blender CLI / `.roblox_api_key` on Cloud VM). Owner-PC upload → paste real ids into `PropLibrary.ASSETS` only |
| **3 Launch prep** | **Docs done** — marketing fantasy aligned; `assets/store/` checklist ready for Art; heartbeat SFX documented as blocker |

**Owner after merge:** publish build tag · optional Creator Hub Public (copy + art) · optional Blender re-upload.

## Later (not this pass)

- Heartbeat low-HP SFX — only after a real Creator Store / HANDOFF id (see `HANDOFF.md` blockers)
- Phase D mesh ids in `PropLibrary` after owner upload
- Brainstorm hooks (`docs/design/brainstorm-hooks.md`) until owner pulls them forward
- 240-stud floors / Pickaxe item / Robux token cheats — out of scope

## Rules that stay

- Robux never skips the game and never buys tokens directly (`economy-robux.md`).
- Every match starts from zero; only tokens, stats and the leaderboard persist.
- Ukrainian first, then Russian and English, for every string.
- Never invent mesh / sound / icon asset ids.
