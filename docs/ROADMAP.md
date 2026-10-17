# Skyline Zero — roadmap

Owner: Popovskyi. Updated 17.10, build b24. One list for every agent; work top to bottom unless the owner
says otherwise. When an item ships, move it to `CHANGELOG.md` and delete it here. Do not add items the
owner did not ask for: put ideas in `docs/design/brainstorm-hooks.md` instead.

## Now: check b24 in the game (owner)

The owner tests on PC, phone, tablet and PS5. Open questions for that pass:
- Hit animations visible on phone and tablet (they were missing while an older build was live).
- Lift: solo lift plus three group lifts; the first player in a group lift picks 2–6 on the lift card.
- Team chest and buildings shared, rubble cleared for everyone, hold-to-drop items, downed marker.
- Lighting: no flicker entering a floor; roof gloomier; rain and night readable.

## Next (in this order)

1. **Bugs from the b24 test pass.** Always first.
2. **Objective marker points at the loot, not the stairs**, during "collect N" steps (nearest node or
   crate of the needed item on the floor the player is on; stairs only when on the roof).
3. **Classes** (Medic, Mechanic, Fighter, Scout), unlocked with tokens in the lobby. This is the token
   sink; prices and effects from `docs/design/economy-robux.md` and `game-design-loops.md`, numbers into
   `GameConfig`. Chosen in the lobby before the lift, carried in TeleportData.
4. **Lobby buttons** from the HUD spec: "Records" (leaderboard up close) and "?" (how to play).
5. **Weapon rarity** (common club → rare bat → gold pipe → diamond machete): slot frame colour = rarity.
6. **Horde on the roof**: every 8–10 minutes a siren, 6–10 zombies come up the stairs; barricades as a
   new upgrade.
7. **One mid-floor event** (blackout or fire door), from the brainstorm list.
8. **Polish**: idle nudge on the roof, toast throttling, hunger paused during the first steps,
   low-health heartbeat sound, better Blender models for props and weapons.
9. **Launch**: store icon and thumbnails (`docs/design/store-visual-brief.md`), description
   (`marketing-draft.md`), make the experience public.

## Rules that stay

- Robux never skips the game and never buys tokens directly (`economy-robux.md`).
- Every match starts from zero; only tokens, stats and the leaderboard persist.
- Ukrainian first, then Russian and English, for every string.
