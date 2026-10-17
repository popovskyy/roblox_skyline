# Skyline Zero — roadmap

Owner: Popovskyi. Updated 17.10 · live **b33** · epic branch `cursor/roadmap-final-pass` (no publish until
owner says merge). One list for every agent; work top to bottom unless the owner says otherwise. When an
item ships, move it to `CHANGELOG.md` and delete it here. Do not add items the owner did not ask for: put
ideas in `docs/design/brainstorm-hooks.md` instead.

## Now: final roadmap pass (epic branch)

Owner waived mid-pass Phase C wait for this haul. Plan: Project `docs/roadmap-final-pass.md`.

**Already live (skip on this branch):** Phase A A1–A10 + LOCAL #1–#6 + lobby L1 Classes (b28–b33). Audit
confirmed §8 numbers and barricade/rubble/loot knobs match design.

**In progress on `cursor/roadmap-final-pass`:**

1. **HUD declutter (P0)** — **landed on branch** (kill soft spam, blackout merge, 1+1 toast cap, intro
   silence). No new toast system.
2. **Phase D Blender polish** — Bat/Crowbar + interior scaffolds on branch; upload blocked on Cloud VM
   (no Blender CLI / API key). Owner-PC `upload_model.sh` → real ids only.
3. **Launch prep (docs only)** — align `marketing-draft.md` + banner checklist; heartbeat SFX stays blocked
   until a Creator Store / HANDOFF id exists. **Do not** upload Creator Hub art.

**Do not** merge or publish mid-pass. Owner merge + optional Public after Blocks 1–3 are ready.

## Later (after owner merge)

- Creator Dashboard → Public when owner + Art approve store art.
- Heartbeat SFX once a real sound id is in HANDOFF.
- Brainstorm hooks stay in `docs/design/brainstorm-hooks.md` until owner pulls them forward.

## Rules that stay

- Robux never skips the game and never buys tokens directly (`economy-robux.md`).
- Every match starts from zero; only tokens, stats and the leaderboard persist.
- Ukrainian first, then Russian and English, for every string.
