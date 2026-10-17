# Skyline Zero — roadmap

Owner: Popovskyi. Updated 17.10, build b28 (Phase A + LOCAL fixes published).
One list for every agent; work top to bottom unless the owner says otherwise. When an item ships, move it
to `CHANGELOG.md` and delete it here. Do not add items the owner did not ask for: put ideas in
`docs/design/brainstorm-hooks.md` instead.

## Now: check b28 in the game (owner)

The owner tests on PC, phone, tablet and PS5. Focus for this pass (Phase A + LOCAL):
- Tablet short tap = swing/punch (portrait/landscape); camera drag still aims; jump/hotbar do not attack.
- Flashlight in F1 corridors / doorways — no strobe flicker; beam still readable.
- Craft Bat with Club — only Bat remains in hand; cannot hold Club+Pipe together.
- Phone: weapon name/rarity readable on denser plates; long objective (tutorial.7) stays inside the strip.
- Glowing scrap on F1; soft rubble (3 s, no tool) opens a wing; Crowbar room still gives Лом; scrap
  nodes stay empty after roof return.
- Co-op: opened crate empty for the whole party; Common weak vs Rare/Gold; Chest needs a full F1 trip;
  Barricade affordable; floors feel more populated (zombies 2/4/5/6).
- Build Barricade before ~8–10 min; next horde piles behind boards (no zombies on roof pad); players
  still leave via stairs / vault.
- Still re-check from b26/b27 if time: keys F3/F4, hotbar after craft, lobby Records/?, rarity frames,
  blackout once on F2/F3, AFK roof nudge, hunger pause until terminal/floor.

Questions for the owner:
- A gamepad has no button to open the Classes panel in the lobby. Add one?

## Next (in this order)

1. **Slow survival Phase B/C** (`docs/design/slow-survival-loop.md`): playtest b28 Phase A, then continue
   the loop redesign. Do not pull brainstorm ideas ahead of that doc.
2. **Polish (still open)**: better Blender models for props and weapons (the Bat still borrows the club's
   model and icon — needs Blender + Open Cloud upload; no inventing asset ids). Low-health heartbeat
   sound needs a suitable Creator Store / HANDOFF id first (none yet; do not invent). **Only after**
   Phase C loop feels right.
3. **Launch**: store copy drafted in `docs/design/marketing-draft.md` (uk/ru/en, roof→bridge fantasy).
   Store art concepts in `assets/store/` + `docs/design/banner-art-brief.md` — do **not** upload to
   Creator Hub until owner + Art approve. Then Creator Dashboard → Public when owner says so.

## Rules that stay

- Robux never skips the game and never buys tokens directly (`economy-robux.md`).
- Every match starts from zero; only tokens, stats and the leaderboard persist.
- Ukrainian first, then Russian and English, for every string.
