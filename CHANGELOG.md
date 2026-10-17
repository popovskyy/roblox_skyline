# Changelog

Every published build gets an entry: build tag, date, what a player will notice, and what still needs a
check in the game. Newest first. Agents: add your entry in the same commit as the change.

## b26 · 17.10 (not published yet)
- Hit, swing and punch animations now play on phones and tablets: taps were discarded as camera
  drags (14 px on Vector3 including Z); tap test is now X/Y only, ~40–96 px and 0.5 s, plus
  reload/retry and Action4 priorities so the swing wins over walk.
- Check in game: short taps vs camera drag on phone/tablet — swing should fire on tap only.
- Keys on floors 3 and 4 can be picked up (no more "inventory full"); several keys can be carried at
  once, and a key fits into the chest even when the chest is full. (The club still cannot go into the chest.)
- Hotbar items keep their slot after crafting or picking up a new weapon, so they no longer seem to
  vanish to page 2; a new item takes the first free slot, and an item left on page 2 moves into a free
  slot on page 1. L1 / R1 on a gamepad skip empty slots.
- Lobby: "Records" (leaderboard up close) and "?" (how to play) buttons; on a gamepad X / Y open them,
  B closes.
- Weapon rarity: Club (common, cream) → Bat (rare, blue) → Pipe (gold) → Machete (diamond, teal). The
  hotbar slot of a weapon is framed in its rarity colour (same colours as the loot crates); in hand the
  frame thickens and the slot takes the tint. The name above the slot, pickup / craft messages and the
  name over crate loot say the rarity ("Бита · Рідкісна зброя"); workbench names are coloured too.
- New weapon: the Bat, 16 damage (club 12, pipe 22, machete 34), 4 hits per zombie instead of the club's
  5. Workbench: 2 scrap. Also in common crates (8%) and rare crates (30%). The pipe and the machete are
  found and crafted exactly as before. The Bat has no model of its own yet: it is the club's model, longer,
  with a blue-grey metal barrel, and the club icon tinted blue.
- Check in game: slot colours of all four weapons on PC, phone and PS5 (in hand and not); the Bat in the
  hand (grip and swing look right) and its icon; crafting a Bat; the Fighter still hits harder; the name
  over the slot in uk / ru / en.
- Check in game: swing and punch animations on phone and tablet, and whether zombies take damage from
  taps; keys on floors 3 and 4, carrying two keys, the diamond crate, a key into the chest; the hotbar
  after crafting a Pipe / Machete on a 5-slot phone; the lobby buttons on PC, phone and PS5.

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
