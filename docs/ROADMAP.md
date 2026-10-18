# Skyline Zero — roadmap

Owner: Popovskyi. Updated 18.10, build **b39**. One list for every agent; work top to bottom unless the
owner says otherwise. When an item ships, move it to `CHANGELOG.md` and delete it here. Do not add items the
owner did not ask for: put ideas in `docs/design/brainstorm-hooks.md` instead.

## Now: check b39 (owner)

- Team pooling: chest needs 10 scrap, you carry 5 and a teammate on the roof carries 5 → you can build it
  (teammate gets "you chipped in"). Same for the workbench. Goal counters count the whole team.
- Hit animation on a tablet: visible to you and to a teammate on another device; pale trail on the
  weapon while it swings.
- Zombies do not hit through walls; they walk around instead. Players cannot hit through walls either.

## Polish plan — from "raw prototype" to "looks like a real game"

The owner's verdict on b38: it still looks raw. The mechanics are mostly there; what is missing is how it
looks, sounds and feels. Order matters: each phase is visible on its own. Every item has a "done when"
the owner can check on a phone.

### P1 · The first two minutes (lobby → roof → first floor)
What every new player sees first, so it gets the most care.
1. **Lobby set**: replace grey-box plaza and lift cabins with real models (Creator Store free models or
   Blender), lit signage, a few survivors (NPC idles), the tower rising into fog. Done when: a screenshot of
   the lobby could be a store thumbnail.
2. **Roof hero props**: chest, generator, air filter, bridge, workbench as real models with a clear
   "not built yet" hologram and a satisfying build moment (dust, sound, short camera nudge). Done when: each
   build looks different and reads from across the roof.
3. **Floor 1 art pass**: materials and colour per room (not one concrete grey), decals (graffiti, posters,
   stains, arrows to the stairs), clutter that tells a story, one strong light source per room. Done when:
   two rooms of floor 1 are recognisable from a screenshot.

### P2 · Combat feel
4. **Zombie animation set**: proper walk, run, attack and death (ragdoll or death clip), hit stagger.
   Done when: a hit visibly knocks the zombie back for a moment and a kill drops it believably.
5. **Player feedback**: hit flash on the zombie, short camera shake on a hit, screen-edge red on taking
   damage, weapon models in hand for every weapon (no plain blocks). Done when: you can tell a hit from a
   miss with the sound off.
6. **Weapon swing per weapon**: different clips for club, bat, pipe, machete and fists.

### P3 · Floors 2–4 and the city
7. **Art pass per floor theme**: residential (flats, kitchens), ventilation (ducts, fans, fog), ruins
   (collapsed slabs, fire, water), each with its own palette and lighting mood.
8. **Skyline**: building models with window detail and broken tops instead of boxes; distant fires and
   smoke columns; birds. Done when: looking off the roof is the screenshot people share.
9. **Layout variety**: a few room templates per floor shuffled each match, so floors do not feel identical.

### P4 · Sound
10. **Ambience per place**: wind on the roof, dripping and creaks inside, muffled city below; footsteps on
    concrete / metal / glass.
11. **Music**: calm roof theme, tense floor theme, horde theme, win and loss stingers.
12. **Zombie voice variety**: idle, alert (they spotted you), attack, death.

### P5 · UI finish
13. **One visual language** for all panels (lobby, chest, workbench, classes, results): same fonts,
    plates, icons; no leftover default Roblox look.
14. **Results and progression**: tokens counting into a visible class progress bar; "next class at N".
15. **Loading / teleport screen** with art and a tip, not a blank screen.

### P6 · Device pass and performance
16. Test on a low-end phone, a tablet, PC and PS5: frame rate, text sizes, button reach, no overlap.
17. Part count and lights budget per floor; streaming of far scenery if needed.

### P7 · Launch
18. Store icon, thumbnails and a short trailer captured from the polished game (`store-visual-brief.md`).
19. Make the experience public: **owner only** (`docs/design/owner-gates.md`).

## Rules that stay

- Robux never skips the game and never buys tokens directly (`economy-robux.md`).
- Every match starts from zero; only tokens, stats and the leaderboard persist.
- Ukrainian first, then Russian and English, for every string.
- No invented asset or sound ids: upload or pick real ones and note them in `HANDOFF.md`.
- One agent publishes at a time, from `master` on GitHub, after the checks in `AGENTS.md`.
