# Changelog

Every published build gets an entry: build tag, date, what a player will notice, and what still needs a
check in the game. Newest first. Agents: add your entry in the same commit as the change.

## b25 · 17.10
- Classes, bought with tokens in the lobby ("Класи" button under the tokens) and picked before the lift:
  Medic 60 (2 extra bandages, revives twice as fast), Scout 80 (15% faster, flashlight lasts longer),
  Fighter 100 (pipe instead of club, +15% damage), Mechanic 120 (buildings 20% cheaper, nearby resources
  glow through walls). The tower reads the class from the save, so it cannot be faked.
- The goal marker leads to the nearest scrap / electronics / cable / motor on your floor instead of the
  stairs (stairs only from the roof or when the floor has none left).
- Check in game: buying with enough and too few tokens, the class message on arrival, each perk.

## b24 · 17.10
Published from this repository again after an older parallel version (made by Cursor from an old place
file) had replaced the live game.
- Team play: one shared chest and one set of buildings for the whole team; rubble cleared by anyone is
  gone for everyone (electronics behind it unlock for all).
- Drop items: hold a hotbar slot (or a pouch counter for one resource) to drop it; G on PC, B on a
  gamepad drops what is in hand. Anyone can pick it up.
- Downed teammate: red marker over them with name and metres, arrow on the screen edge when off screen.
- Goal counter updates live ("3/8" scrap, "2/4" electronics, cable+motor "x/6"). First goal now asks for
  8 scrap, enough for the chest.
- Zombies no longer respawn.
- Lobby: one solo lift and three group lifts; the leader picks 2–6 players on the lift card. Boards say
  "SOLO" / "GROUP · 2/4".
- Lighting: interior lamps no longer cast shadows (they flickered), interiors slightly darker.
- Roof and city: muted, dying greenery instead of a garden; a city ground with streets so the skyline does
  not float; day/night cycle (one day = 24 minutes) and rain showers with sound.
- Medkit recipe at the workbench (2 bandages + food); a hint where to find medkits the first time health
  is low. Tokens per match roughly halved.
- Check in game: all of the above; hit animations on phone/tablet.

## b23 · 17.10
- Tap, click and R2 all go through one handler: weapon swing, use food/medkit, flashlight, or punch.

## b22 · 17.10
- Results screen drawn on top of the downed screen; menu button and marker drawn without missing glyphs;
  tap-to-punch detection rewritten.

## b20–b21 · 17.10
- New HUD from `docs/design/HUD_SPEC.md`: segmented health, hunger bar, state badges, vignettes, 8/6-slot hotbar,
  pouch and weight, ☰ menu with hold-to-leave, downed screen, round action and flashlight buttons on
  phones, gamepad hints, stairs label, lobby lift card and tokens.

## b19 · 17.10
- Fixed the client crashing on start (b15–b18: no pickups, no hotbar). Unarmed punch with its own
  animation; first-descent hint on how to attack.

## b16–b18 · 17.10
- Collapsed ceiling holes, smashed windows, rubble heaps, cables. Tokens and the results screen. Lamps
  along the stairwell.

## b13–b15 · 16–17.10
- Hold/swing animations, any hotbar item in hand, resource pouch, vector icons, loot crate rarity and
  effects, locked diamond crates, QA fixes.
