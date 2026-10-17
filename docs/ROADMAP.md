# Skyline Zero — roadmap

Owner: Popovskyi. Updated 17.10, build b27 (includes b26); local unreleased Phase A + tablet anim fix.
One list for every agent; work top to bottom unless the owner says otherwise. When an item ships, move it
to `CHANGELOG.md` and delete it here. Do not add items the owner did not ask for: put ideas in
`docs/design/brainstorm-hooks.md` instead.

## Now: check b24–b27 in the game (owner)

The owner tests on PC, phone, tablet and PS5. Open questions for that pass:
- ~~b26: swing and punch animations on phone and tablet~~ — tablet path fixed locally (Unreleased); re-check
  tablet tap swing vs camera drag, and whether zombies take damage from taps.
- b26: keys on floors 3 and 4, carrying two keys, the diamond crate, a key into a full chest.
- b26: hotbar after crafting a Pipe / Machete on a 5-slot phone (items stay in their slots, nothing
  hidden on page 2).
- b26/b27: lobby "Records" and "?" on PC, phone and PS5 (X / Y open, B closes); panels and lift card
  readable on a narrow phone; Records/? sit above the lift card.
- b26: weapon rarity frames on the hotbar (PC, phone, PS5), the Bat in hand and at the workbench.
- b26: roof horde at ~8–10 min (siren + toast), solo vs group counts, Barricade blocks the stair mouth,
  floor zombies still do not respawn.
- b26: mid-floor blackout once per match on floor 2 or 3 (warn toast → dark → power back), green exit
  lamps stay on; does not overlap the first roof horde.
- b26 polish: AFK ~45 s on the roof before the terminal (soft click + marker bob once); soft toasts at
  most every 15 s while warning/error still land; hunger full until terminal or first floor, then drains.
- Lift: solo lift plus three group lifts; the first player in a group lift picks 2–6 on the lift card.
- Team chest and buildings shared, rubble cleared for everyone, hold-to-drop items, downed marker.
- Lighting: no flicker entering a floor; roof gloomier; rain and night readable.
- Classes: buy, pick, each perk; goal marker leads to loot on the floor. Fighter keeps the Pipe start
  (owner choice).

Questions for the owner:
- A gamepad has no button to open the Classes panel in the lobby. Add one?

## Next (in this order)

1. **Slow survival Phase A** (`docs/design/slow-survival-loop.md`): barricade AI, scrap path, soft rubble,
   loot rarity, pacing. Owner approved (+). No publish until Phase C playtest.
2. **Remaining LOCAL_AGENT_STEPS** (#2 flicker, #3 weapon replace, #4 blur, #5 text overflow, #6 crates
   shared — #6 overlaps Phase A). Tablet anim (#1) done locally.
3. **Polish (still open)**: better Blender models for props and weapons (the Bat still borrows the club's
   model and icon — needs Blender + Open Cloud upload; no inventing asset ids). Low-health heartbeat
   sound needs a suitable Creator Store / HANDOFF id first (none yet; do not invent). **Only after**
   Phase C loop feels right.
4. **Launch**: store copy drafted in `docs/design/marketing-draft.md` (uk/ru/en, roof→bridge fantasy).
   Blocked on: owner test pass + store art (`store-visual-brief.md`; `media/marketing/` still empty) +
   explicit owner OK to publish. Then bump `PlacesConfig.Build`, `bash scripts/publish.sh`, Creator
   Dashboard → Public.

## Rules that stay

- Robux never skips the game and never buys tokens directly (`economy-robux.md`).
- Every match starts from zero; only tokens, stats and the leaderboard persist.
- Ukrainian first, then Russian and English, for every string.
