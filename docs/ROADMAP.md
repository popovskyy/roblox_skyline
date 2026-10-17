# Skyline Zero — roadmap

Owner: Popovskyi. Updated 17.10, after Phase B/C readiness slice (Unreleased, post-b31).
One list for every agent; work top to bottom unless the owner says otherwise. When an item ships, move it
to `CHANGELOG.md` and delete it here. Do not add items the owner did not ask for: put ideas in
`docs/design/brainstorm-hooks.md` instead.

## Now: Phase C playtest gate (owner)

Code readiness for Phase B/C is in (Unreleased): `Horde.Enabled` kill-switch, Scrap≠Лом tip same beat,
Gold/Diamond open juice. **Owner signs Phase C** before any Phase D / polish / publish.

Focus in game (solo + 2–3 co-op):
- First Scrap tip visible with pickup; F1 scrap path + soft rubble still obvious.
- Barricade before ~8–10 min → horde stuck behind boards (video); if not → set `Horde.Enabled = false`.
- Gold/Diamond open clearly louder than Common; crates stay party-shared and scarce.
- Co-op Bridge typically **≥ 25 min**; solo **≥ 30 min** without AFK.

Still OK from b31: crisp hotbar tooltip / touch caption; soft rubble hold-clear; stair shaft; no yellow Health.

Questions for the owner:
- A gamepad has no button to open the Classes panel in the lobby. Add one?

## Next (in this order)

1. **Slow survival Phase B/C** — owner Phase C sign-off (`docs/design/slow-survival-loop.md` §10). LOCAL
   #2–#5 and C-gate hardening are done; do not pull brainstorm ideas or Phase D ahead of that sign-off.
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
