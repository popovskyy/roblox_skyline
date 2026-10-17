# Changelog

Every published build gets an entry: build tag, date, what a player will notice, and what still needs a
check in the game. Newest first. Agents: add your entry in the same commit as the change.

## Unreleased (local) · 17.10

### Barricade blocks roof horde (Phase A1)
- Built Barricade now hard-blocks zombies server-side: thicker boards + pathfinding modifier; horde
  spawn/home stay in the stair shaft (not the roof pad); zombie AI never LoS-`MoveTo` through
  `BarricadeBlock` parts — path fail or blocked goal = stop in place. Client remembers collide=true
  after build so visuals do not reopen the mouth.
- Check in game: build Barricade before ~8–10 min; next horde piles up behind boards; no zombies on the
  roof pad; players can still leave via stairs / vault; floor zombies unchanged.

### Tablet hit animation
- Tablet taps for attack were often marked `processed` by Roblox even on the world (unlike phones), so
  the swing never started; tablets with KeyboardEnabled also skipped the touch HUD. Touch taps now count
  unless they land on a real GUI button; tap slop scales up to ~160 px on large screens; swing/punch
  retries if the Animator is still loading. `UIKit.IsTouch` follows `PreferredInput.Touch`.
- Check in game: tablet short tap = visible swing/punch (portrait and landscape); camera drag still aims;
  jump/hotbar taps do not attack; phone and PS5 unchanged.

## b27 · 17.10 15:20
Ship tag for all b26 work below plus rarity polish: Theme-aligned weapon slot frames, phone hotbar
sizing clear of the thumbstick, workbench shows rarity names and tinted icons (Bat uses the club icon
in blue). Lobby UX polish for the same ship: Records/? sit above the lift card (DisplayOrder 2),
Classes / Records / How sheets and the lift card scale on narrow phones, gamepad X/Y/B ignore
already-processed UI input.

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
- Roof horde: after 8–10 minutes a siren and a warning toast, then 6–10 zombies climb the stairs onto the
  roof (solo 6, +1 per extra player, max 10); repeats every 8–10 minutes. Floor zombies still do not
  respawn. New upgrade Barricade (8 scrap + 2 electronics, needs the Chest): boards across the stair
  mouth so the wave piles up behind them; players can still jump over.
- Check in game: slot colours of all four weapons on PC, phone and PS5 (in hand and not); the Bat in the
  hand (grip and swing look right) and its icon; crafting a Bat; the Fighter still hits harder; the name
  over the slot in uk / ru / en.
- Check in game: swing and punch animations on phone and tablet, and whether zombies take damage from
  taps; keys on floors 3 and 4, carrying two keys, the diamond crate, a key into the chest; the hotbar
  after crafting a Pipe / Machete on a 5-slot phone; the lobby buttons on PC, phone and PS5.
- Check in game: first horde at ~8–10 min (siren + toast, uk/ru/en); wave size solo vs group; fight on
  the roof without a barricade; build Barricade and confirm the next wave is blocked at the stairs;
  floor zombies still stay dead after clear.
- Mid-floor blackout (once per match): after ~3 min, when someone is on floor 2 or 3, lights flicker
  (toast), then ceiling / stair / window lights die for 8–12 s; green exit lamps stay on; power returns
  with a bang and a toast. Prefers floor 2 (has ceiling lamps + flashlight loot). Never after ~7 min so
  it does not overlap the first roof horde. Fire-door event still only in the brainstorm list.
- Check in game: stand on floor 2 after 3 min — warn toast (uk/ru/en), darkness readable via green exits
  / flashlight, power-back toast; confirm it does not fire twice; roof and floor 1 stay lit for players
  not on the blackout floor; horde at 8–10 min still works.
- Polish (code-only): idle nudge on the roof — if you stand still ~45 s before reading the terminal, a soft
  click plays at the terminal and the objective marker bobs harder (once; no toast spam). Toast
  throttling — info/success at most one every 15 s (warning/error still show immediately). Hunger drain
  stays off until you read the terminal or reach a floor. Low-health heartbeat skipped (no suitable sound
  id in SoundConfig/HANDOFF). Better Bat/prop Blender models still open (needs upload).
- Check in game: spawn and AFK on the roof ~45 s (ping + marker bob once); spam loot pickups and confirm
  soft toasts do not stack every second while horde/blackout warnings still appear; hunger bar stays full
  on the roof until terminal or stairs, then drains as before.

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
