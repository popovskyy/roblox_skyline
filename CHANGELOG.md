# Changelog

Every published build gets an entry: build tag, date, what a player will notice, and what still needs a
check in the game. Newest first. Agents: add your entry in the same commit as the change.

## Unreleased — zombie looks

- Floor + roof-horde zombies no longer spawn as bare green R15 bodies. They use **verified free Roblox
  catalog** shirts/pants (5 outfit pairs) + Man Face `86487700`, ashen olive skin, and a slightly
  gaunt Height/Width scale so silhouettes read in dark floors.
- Outfit asset ids (all price 0, creator Roblox): shirts `144076436`, `144076358`, `4047884046`,
  `607785314`, `398633584`; pants `144076760`, `382537569`, `398635338`, `382538503`.
- Skipped Creator Store mesh packs (Drooling Zombie / third-party R15) — either meme look or not
  InsertService-loadable without ownership. No custom FBX upload (cloud has no `.roblox_api_key`).
- Check in game: zombies wear muted jackets/jeans, faces readable, packs look varied; combat/AI unchanged.

## b36 · 18.10 09:15

Tablet swing + rubble room open (owner bugs on live b35).

### Tablet / touch attack swing
- Root cause: stacked AnimationTrack hacks still failed on tablet (clips often never load; hold tracks
  overwrite Motor6D.Transform). World-tap heuristics stayed flaky with `processed` Touch.
- Fix: dedicated **Hit** button (`ui.attack`) on TouchEnabled; local **procedural Motor6D** swing/punch
  on touch (asset clips kept for PC). Attack tip copy points at the button.

### Rubble clears but room stays closed
- Root cause A: F1 SoftWing doorway at `x=-20, z∈[-31,-25]` was sealed by a solid west corridor wall
  (`-20,-35`→`-20,-6`), so clearing the pile never opened the wing.
- Root cause B: SoftRubble dress leaves an invisible colliding host; clear only hid it on the client —
  some devices kept the wall. Server now opens collision/visibility on clear.
- Also: F4 loose debris skips hard-rubble doorways; Collect/Loot prompts gated on `RequiresRubble`.

### Check in game
- Tablet: Hit button visible; arm clearly swings on press (fists or bat).
- F1 SoftWing: clear rubble → walk into SW room for scrap.
- F4 crowbar rubble: clear → walk in (no invisible wall).

## b35 · 17.10 17:27

Merge publish of roadmap-continue (PR #4): Phase D FBX packs live via real PropLibrary ids + heartbeat SFX. Creator Hub Public still owner-only.

### Phase D live (PC upload)
- Regenerated `Weapons.fbx` / `InteriorProps.fbx` / `RoofProps.fbx` (Bat, Crowbar, crates, nodes, rubble, boards) from continue branch.
- Owner PC `upload_model.sh` printed real ids — pasted into `PropLibrary.ASSETS`: Weapons **91152894600749**, InteriorProps **97341263879744**. WorldBuilder Has()-dress can load them.
- Bat worn-cream SVG/PNG still in repo; hotbar may keep Club image id until a separate Image upload.

### Heartbeat low-HP SFX
- Owner id `9043365842` in `SoundConfig.Sounds.Heartbeat`; `VitalsController` loops it while HP ≤ 30.
- Check in game: take damage to ≤30 HP — soft heartbeat loop; heal / down / match end — stops.

### Still owner
- Creator Hub Public / store art approve — do not flip without owner OK.
- Optional: Bat.png Image upload → `ItemDefinitions.Bat.iconImage`; RoofProps `.rbxm` re-import in Studio.

## b34 · 17.10 19:30

Final-pass ship: HUD declutter + Phase D scaffold + launch prep docs. Phase A A1–A10 already live (b28–b32).

### HUD declutter (P0)
- Quieter tower HUD: no toast on every pickup (`res.collected`), tutorial step (`tutorial.new`), rubble
  clear, food/medkit success, flash full, class/party spawn, weapon replace, drop, or key-used.
- **Kept:** Scrap≠Лом one-shot, attack / eat / medkit hints, horde, hazards, downed/revive, build/craft,
  party.built, rubble reward (Crowbar), loot break-in, food/medkit none warnings.
- Blackout: **one** warning at telegraph (copy mentions flashlight / green exits); restore is SFX only.
- Toast cap: **1 soft + 1 danger** (touch: 1 total). Soft toasts silenced while intro card is up (+2 s).
- Lobby: same concurrent cap only.
- Check in game: roof start = intro → terminal → one ЦІЛЬ, no toast pile; pick Scrap → tip only (no
  «зібрано» spam); blackout = one warning; danger still readable.
- Fix: attack teach tip no longer lost if first Floor zone lands during intro soft-silence (retry until
  shown). Eat hint stays once/match (no re-fire after hunger recovers).

### Phase D scaffold + Has()-dress
- Blender `build_weapons.py`: **WeaponBat** + **WeaponCrowbar**. CombatService MESHES + Part LOOKS fallback.
- Interior props: crates / ScrapNode / ElectronicsNode / Soft-HardRubble / BarricadeBoards.
- WorldBuilder dresses those props when `PropLibrary.Has` (after a real upload); grey-box Parts otherwise.
- **No invented PropLibrary ids.** Upload blocked on Cloud VM (no Blender CLI / API key) — owner PC path in
  `blender/README.md` + `HANDOFF.md`.
- Block 1 verify: A1–A8 / §8 knobs still match design; no retune.

### Launch prep (docs only)
- `marketing-draft.md` status + fantasy aligned to live roof→down→back→bridge; Creator Hub still owner gate.
- Store art checklist points at `assets/store/icon-512.png` + `thumbnail-1920x1080.png` (Art approve first).
- Heartbeat SFX: blocker noted in `HANDOFF.md` + `SoundConfig` comment — **no fake SoundId**.
- ROADMAP: Blocks 0–1 done / verified; B2 upload pending owner PC; Launch = owner Public.

## b33 · 17.10 19:05
### Lobby: gamepad opens Classes
- On a controller, **L1 / LB** opens the Classes panel (same toggle as the Класи button). X still
  opens Records, Y How to play, B closes. A pad glyph badge appears on the Classes button while a
  gamepad is the last input. Lobby-only — tower L1 stays hotbar after teleport.
- Check in game (PS5 / Xbox / any pad in Studio): press L1 in the lobby — Classes sheet opens;
  press again or B to close; X and Y still open Records / How; badge visible only on gamepad input.

## b32 · 17.10 18:55
C-gate hardening: horde QA switch, Scrap≠Лом tip same beat, louder Gold/Diamond opens. No balance
retune, no Blender.

### Horde kill-switch (A10)
- `GameConfig.Horde.Enabled` (default `true`). When `false`, no siren and no waves; Barricade boards still
  harden on purchase. Each wave re-checks the flag (mid-match QA flip stops further waves).
- Check in game: normal match still gets first horde ~8–10 min; with `Enabled = false` (Studio/config) —
  whole match with no siren/wave.

### First Scrap tip visible same beat (A9)
- `hint.scrapNotCrowbar` bypasses the 15 s soft-toast throttle so it is not delayed behind "collected".
- Force tip flushes any queued soft toast first (so a pending "зібрано" after `tutorial.new` is not wiped).
- Check in game: after a soft toast, pick first Scrap within 15 s — both "зібрано" and Scrap≠Лом show
  together (uk/ru/en). Cold first-Scrap path still stacks both.

### Gold / Diamond open louder (§10.5)
- Stronger camera shake, denser burst, longer/louder banner; one open ding on Gold/Diamond (no double
  Diamond upgrade SFX). Common/Rare unchanged.
- Check in game: open Common vs Gold/Diamond — rare tiers clearly out-read three Commons; party still sees
  the banner; shared empty crates unchanged.

## b31 · 17.10 16:50
Hotbar item tooltip / touch action caption actually readable (structure fix, not another paint tweak).

### Hotbar tooltip no longer smeared
- Root cause: name plate was a `TextLabel` with `UIPadding` + `UIStroke` + `TextStroke` on itself —
  Roblox smears Cyrillic that way (b28–b30 only darkened the plate). Now same as ЦІЛЬ: black
  `Frame` plate + child `TextLabel` (Semi, no text stroke). Touch interact caption same fix.
- Check in game: tap Club / Food / Medkit — "Дубинка · Звичайна зброя" / "Їжа · З'їсти" crisp like
  the top ЦІЛЬ strip; touch action label above the round button sharp too.

## b30 · 17.10 16:40
Rubble hold-to-clear, stair roof lip, sharp hotbar tooltip, hide default Health bar.

### Rubble hold-to-clear works
- Soft / hard rubble piles lived under the floor folder, so `InteractionService` silently ignored
  the ProximityPrompt (`IsDescendantOf(Interactables)` failed). Piles now parent under Interactables.
  Soft = hold 3 s (hands); hard = hold 5 s + Crowbar. Path opens / Crowbar reward as before.
- Check in game: F1 soft wing — hold E / action button ~3 s until the pile vanishes and scrap behind
  is reachable; Crowbar room soft-clears and gives Лом; F4 hard rubble needs Crowbar + 5 s hold.

### Stair descent: no floating roof chunk
- Not texture Z-fight: slab hole was too tight, so a roof/ceiling lip (and a ceiling panel in the
  shaft) popped into view while walking down. Hole padded past the shaft; mouth inset 1.2; ceiling
  props skipped inside the stair volume; metal lift 0.15.
- Check in game: walk roof → F1 → F2 looking up the shaft — no floating concrete chunk at the mouth.

### Sharp selected-item tooltip
- Hotbar "Їжа · З'їсти" (and all slot tooltips / touch action caption): pure black plate, TextStroke
  0.1, TextSize 18 on touch, no TextScaled. Slot count labels same stroke treatment.
- Check in game: tap Food on phone — amber text crisp on black; Medkit / weapons too.

### No yellow top-right Health meter
- Roblox default Health CoreGui (yellow bar by the menu, looked like a second weight) is disabled.
  Keep bottom "Вага x / 20" and centre ЦІЛЬ strip; custom vitals stay.
- Check in game: top-right only the ☰ menu — no yellow bar next to it.

## b29 · 17.10 16:22
Stair Z-fighting + sharp eat prompt (owner retest after b28).

### No more stair/passage floor flicker
- Root cause was geometry, not the flashlight: diamond-plate ramps used `length + 0.6` and sat
  coplanar on the concrete slab at the stair mouth (classic Z-fighting). Ramps now exact-span,
  sit 0.08 above the slab, start inside an inset hole; landings lifted the same way; interior /
  outer wall bases dig slightly into the slab so wall/floor seams do not flicker.
- Check in game: stand at the F1 stair mouth and walk the ramps — no jagged diamond/concrete
  flicker; corridor wall bases stay clean. Flashlight still no strobe (b28).

### Sharp "Їжа · З'їсти" hotbar prompt
- Eat/use tooltip was soft amber on a semi-transparent plate. Now opaque `PanelSolid`, dark
  TextStroke, taller plate, TextSize 16 on touch. Touch world-action caption uses the same plate.
- Check in game: tap Food on phone — "Їжа · З'їсти" (and Medkit use) crisp; action-button caption
  sharp too.

## b28 · 17.10 16:08
Phase A slow-survival loop + LOCAL fixes (tablet anim, flashlight, weapon replace, readable plates).

### Dim flashlight, no corridor flicker (LOCAL #2)
- Flashlight SpotLight no longer casts shadows (and is a bit dimmer); window shafts also force
  Shadows=false. Entering a passage should not strobe.
- Check in game: walk into F1 west corridor / doorways with flashlight on — no flicker; beam still
  lights the room.

### Readable item plates and objective strip (LOCAL #4–#5)
- Hotbar tooltip, selected slots and pouch chips use a denser near-black plate so rarity/name text
  stays readable on phone/tablet. Objective strip wraps long uk/ru/en goals and grows with the text
  instead of spilling past the plate; toasts denser + wrap too.
- Check in game: tap a weapon on phone — name/rarity readable; long goal (tutorial.7) fully inside
  the black plate in uk, ru and en.

### Better melee replaces weaker (LOCAL #3)
- Picking up or crafting a stronger melee (Club→Bat→Pipe→Machete) removes weaker ones from the
  backpack; a weaker duplicate is refused. Equipped hand switches to the new weapon when the old one
  was held. Server-only (loot, craft, class grants).
- Check in game: craft Bat with Club — only Bat remains, still in hand; cannot hold Club+Pipe together.

### Loot rarity, shared crates, slower build (Phase A5–A8)
- Fewer crates; opening one empties it for the whole party. Loot tables: Common crumbs only (no Bat);
  Rare carries Bat; Gold/Diamond keep identity; lower upgrade chance; F1 odds Common-heavy. Build costs
  up (Chest 10 / Gen 8+5 / Filter 6+6 / Bridge 12); Barricade cheaper (6+1). Bat craft 5 scrap, Pipe 6.
  Tutorial 10 scrap / 5 electronics. Zombies 2/4/5/6 (solo −1), WalkSpeed 10, Aggro 32.
- Check in game: co-op — teammate cannot re-loot an opened crate; Common feels weak vs Rare/Gold;
  Chest needs a full F1 trip; Barricade is affordable insurance; floors feel more populated.

### Scrap path, soft rubble, scarcity (Phase A2–A4)
- Scrap nodes are larger, warmer metal with a glow; F1 has fixed scrap by the stairs (6) plus 2 behind a
  new soft-rubble wing; F1 Crowbar room stays soft clear. Soft rubble hold 3 s, Crowbar/hard 5 s. F2 soft
  wing gates food/scrap; open Food/Medkit spam cut. Per-floor scrap budgets trimmed; nodes no longer
  refill on roof return. First Scrap pickup explains Scrap ≠ Crowbar (uk/ru/en).
- Check in game: find glowing scrap on F1 without a wiki; clear soft rubble (no tool) for the wing;
  Crowbar room still gives Лом; return to roof — scrap nodes stay empty; hard rubble still needs Crowbar.

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
