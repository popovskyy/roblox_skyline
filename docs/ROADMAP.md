# Skyline Zero — roadmap

Owner: Popovskyi. Updated 17.10, build b26 (not published yet). One list for every agent; work top to bottom unless the owner
says otherwise. When an item ships, move it to `CHANGELOG.md` and delete it here. Do not add items the
owner did not ask for: put ideas in `docs/design/brainstorm-hooks.md` instead.

## Now: check b24–b26 in the game (owner)

The owner tests on PC, phone, tablet and PS5. Open questions for that pass:
- b26: swing and punch animations on phone and tablet, and whether zombies take damage from taps.
- b26: keys on floors 3 and 4, carrying two keys, the diamond crate, a key into a full chest.
- b26: hotbar after crafting a Pipe / Machete on a 5-slot phone (items stay in their slots, nothing
  hidden on page 2).
- b26: lobby "Records" and "?" buttons on PC, phone and PS5 (X / Y open, B closes).
- b26: weapon rarity frames on the hotbar (PC, phone, PS5), the Bat in hand and at the workbench.
- Lift: solo lift plus three group lifts; the first player in a group lift picks 2–6 on the lift card.
- Team chest and buildings shared, rubble cleared for everyone, hold-to-drop items, downed marker.
- Lighting: no flicker entering a floor; roof gloomier; rain and night readable.
- Classes: buy, pick, each perk; goal marker leads to loot on the floor.

Questions for the owner:
- The Fighter class starts with a Pipe instead of the Club (deliberate in `Classes.luau`). Keep it, or
  give both?
- A gamepad has no button to open the Classes panel in the lobby. Add one?

## Next (in this order)

1. **Bugs from the b24–b26 test pass.** Always first.
2. **Horde on the roof**: every 8–10 minutes a siren, 6–10 zombies come up the stairs; barricades as a
   new upgrade.
3. **One mid-floor event** (blackout or fire door), from the brainstorm list.
4. **Polish**: idle nudge on the roof, toast throttling, hunger paused during the first steps,
   low-health heartbeat sound, better Blender models for props and weapons (the Bat still borrows the
   club's model and icon).
5. **Launch**: store icon and thumbnails (`docs/design/store-visual-brief.md`), description
   (`marketing-draft.md`), make the experience public.

## Rules that stay

- Robux never skips the game and never buys tokens directly (`economy-robux.md`).
- Every match starts from zero; only tokens, stats and the leaderboard persist.
- Ukrainian first, then Russian and English, for every string.
