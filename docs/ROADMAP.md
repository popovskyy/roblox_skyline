# Skyline Zero — roadmap

Owner: Popovskyi. Updated 17.10, build b30 · 17.10 16:40 (rubble hold, stair roof lip, tooltip, hide default Health).
One list for every agent; work top to bottom unless the owner says otherwise. When an item ships, move it
to `CHANGELOG.md` and delete it here. Do not add items the owner did not ask for: put ideas in
`docs/design/brainstorm-hooks.md` instead.

## Now: check b30 in the game (owner)

The owner tests on PC, phone, tablet and PS5. Focus for this pass:
- F1 soft rubble: **hold** ~3 s (not click) — pile clears, wing scrap reachable; Crowbar room gives Лом.
- Stair descent roof → F1 → F2: no floating roof/ceiling chunk in the shaft.
- Phone: tap Food — "Їжа · З'їсти" crisp on black plate; top-right has no yellow Health bar (only ☰).
- Bottom weight "Вага x / 20" and centre ЦІЛЬ strip stay.

Questions for the owner:
- A gamepad has no button to open the Classes panel in the lobby. Add one?

## Next (in this order)

1. **Slow survival Phase B/C** (`docs/design/slow-survival-loop.md`): playtest b30 / Phase A, then continue
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
