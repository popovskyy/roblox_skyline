# Skyline Zero — Slow Survival Loop (design pass)

> **Status (17.10, after b27 code read):** Owner feedback — match feels like a rushed checklist (~15 min), not TLOU/Days Gone roof survival. This doc is the **source of intent** for the next gameplay pass. Live numbers still win in `GameConfig` until a coder lands the table below. **Do not publish** from this doc alone.
>
> **Pipeline lock (owner):**
> 1. **First** — core slow-survival loop (scrap, loot rarity, rubble gates, barricades that work, pacing) + finish `LOCAL_AGENT_STEPS.md` bugs as needed.
> 2. **Only after that plays right** — full Blender visual polish (“вилизано”). See **Phase D** at the end.
>
> Related: [game-design-loops.md](./game-design-loops.md) (older 15‑min / 240‑stud notes — intent only), [first-session-ux.md](./first-session-ux.md), [brainstorm-hooks.md](./brainstorm-hooks.md) (ideas bank, not schedule).

---

## 0. Naming (UK / EN) — read first

| Code id | UK | RU | EN | Role |
|---------|----|----|-----|------|
| **Scrap** | Металобрухт | Металлолом | Scrap | Build / craft backbone |
| **Crowbar** | Лом | Лом | Crowbar | Tool: hard rubble + diamond break-in |
| *(not in code)* | Кирка | Кирка | Pickaxe | **Not implemented.** Soft rubble can use hands / any melee instead |

Owner “немає scrap/лом” almost always means **Scrap (металобрухт)** for the build chain, or confusion with **Лом = Crowbar**. Both exist in b27 code; Scrap is easy to *miss* or *misread*, not absent from spawn tables.

---

## 1. Що зламано зараз / What's broken (evidence)

### 1.1 Feels cheap / rushed

| Cause | Live evidence | Player feel |
|-------|---------------|-------------|
| Tiny floors | `GameConfig.World.FloorSize = 70` — sprint across in ~3 s | Closet, not skyscraper |
| Too few threats | `Zombie.PerFloor = {1,2,3,4}` | Empty rooms → checklist |
| Short build chain | Chest 8 Scrap → Gen 6+4 Elec → Filter/Bridge; F1 alone has **9** Scrap on nodes | Roof trip #1 nearly finishes Act 1 |
| Loot spam | **10** rolled crates + F2 **5 Food + 2 Medkit** open nodes | Trash piles, not decisions |
| Nodes refill | `ResetNodesOnRoofReturn = true` | Infinite farm; scarcity dies |
| Soft scrap look | Scrap = rust `CorrodedMetal` block (`WorldBuilder.nodeLook`) next to `Ruins.RubbleHeap` | “There is no scrap” |
| Tutorial vs map | Tutorial wants Scrap **8** (`TutorialService`); F1 nodes = 9 total if you find **all** random spots | Miss 1–2 nodes → “не вистачає лом/scrap” |
| Barricade useless | Barrier starts `CanCollide = false`; server enables via `HordeService`; AI often `MoveTo` on line-of-sight **bypassing path** (`ZombieService.think`) | Zombies walk through / around; boards feel junk |
| UI / juice noise | Soft toasts, AFK nudge, horde, blackout, classes — systems stacked on a thin loop | “AI slop”: events without weight |

### 1.2 Scrap is not missing from code

**Spawned (nodes):**

| Floor | Scrap nodes (amounts) | Sum |
|-------|----------------------|-----|
| F1 | 2+1+2+1+2+1 | **9** |
| F2 | 2+1+1 | **4** |
| F3 | 2+2+1 | **5** |
| F4 | 2+2+2+1 (needs Generator) | **7** |

Plus crates (`GameConfig.LootTables` Common/Rare roll Scrap). Collect path: `InteractionService` → `ResourceService.Collect`. Crowbar from F1 soft rubble (`F1_Rubble`, `rewardItem = "Crowbar"`, **no** `RequiresTool`).

**Why it feels unobtainable:** camouflage + random placer + pouch-only UI (not hotbar) + RU “металлолом” sounding like “лом”.

### 1.3 Barricades — intended vs live

- **World:** `BarricadeBarrier` + planks + top, attr `BarricadeBlock`, start non-colliding (`WorldBuilder` ~1637–1678).
- **On build:** `HordeService.applyBarricadeCollision(true)` sets server `CanCollide`.
- **Client:** `WorldVisualsController` also forces collide locally (comment admits server starts off).
- **AI hole:** with line of sight, zombies `Humanoid:MoveTo(player)` and **skip** pathfinding; on path fail they still `MoveTo(goal)`. That is the coder bug to fix — not “add a new barricade system.”

---

## 2. Цільова фантазія / Target fantasy

**UK:** Повільний кооп-виживач на даху зруйнованої вежі. Обережний спуск, дефіцит, рішення «лізти глибше чи повернутись», рідкісний хороший лут, барикада що рятує дах. Не швидкий чекліст із тостів.

**EN:** Last of Us / Days Gone mood — careful co-op roof survival. Tension from scarcity and traversal gates, not from UI spam or empty 70‑stud rooms. Win is earned after several roof trips; every crate is a risk/reward choice.

North star (keep): **затягує, не бісить** — slow ≠ unfair; solo must still be able to finish.

---

## 3. Довжина матчу і ритм / Match length & rhythm

| Mode | Target | Calm | Spike |
|------|--------|------|-------|
| **Solo** | **30–45 min** to Bridge win | Roof craft/stash, cleared-floor loot | First zombie pack, toxic wing, diamond break-in, late roof pressure |
| **2–4 co-op** | **25–40 min** | Split soft rubble / carry runs | Contested crates, revive under hunger, mid-match roof threat |

**Beat budget (co-op ~32 min typical):**

| t | Beat |
|---|------|
| 0–3 min | Roof orient → terminal → stairs (hunger still off / soft) |
| 3–10 | F1: soft rubble → scrap path → first chest → optional crowbar room |
| 10–20 | F2–F3: electronics under risk (zombies + toxic); 1–2 serious crates |
| 20–28 | Generator → F4 gate → hard crowbar rubble → Cable/Motor |
| 28–40 | Filter and/or Bridge; barricade matters if roof threat fires |

First session still teaches **one** loop by ~3–4 min (scrap counter → return), but **win** is not at minute 15.

---

## 4. Запропонований цикл / Proposed loop

```
Lobby lift → Roof (safe hub: chest / craft / builds)
  → Stairs down
  → Soft rubble clears a wing (earned path)
  → Scarce Scrap / rare crates (rarity reads)
  → Fight or sneak → optional hard rubble (Crowbar)
  → Return, deposit, build next link
  → Deeper floor only when ready
  → Generator unlocks F4 → Cable/Motor → Bridge win
```

**Build order (unchanged story):** StorageCrate → Generator → AirFilter **or** Bridge (+ Barricade as roof insurance after Chest).

**Traversal (no new Pickaxe item in v1):**

| Gate | Tool | Hold | Behind it |
|------|------|------|-----------|
| Soft rubble | Hands / any melee | 2.5–4 s | Scrap corridor / Common–Rare crate |
| Hard rubble | Crowbar | 4–6 s | Electronics, Motor, Diamond |
| F4 stair gate | Generator built | — | Whole floor (existing) |

**Pickaxe recommendation:** **Do not add Pickaxe yet.** Soft rubble already exists (`ClearRubble` without `RequiresTool`). Reuse it as the “first clear a path” beat (owner’s pickaxe fantasy). Add Pickaxe later only if soft clear needs a distinct start tool fantasy — after loop feels good.

---

## 5. Філософія луту / Loot philosophy

- **Rarity must matter:** Common = sustain crumbs; Rare = mats + chance of Bat; Gold = Elec + heals + Pipe chance; Diamond = Cable/Motor-adjacent + Machete (locked).
- **Cut junk:** open-world Food/Medkit piles; duplicate weapons → Scrap conversion already OK; Common crates that spit only Food.
- **Scrap = scarce backbone:** fixed per-floor **yield budget**, no roof refill for Scrap/Electronics nodes.
- **Crates = decisions:** fewer, louder, shared empty for the whole party (aligns with `LOCAL_AGENT_STEPS` #6).

### Cut / keep (loot sources)

| Cut or nerf | Keep / sharpen |
|-------------|----------------|
| F2 five Food nodes + two Medkits on floor | Food from Rare+ crates + start Food |
| 2–3 crates every floor | **1** crate F1–F2, **1–2** F3, **1** open + **1** Diamond F4 |
| `ResetNodesOnRoofReturn` for Scrap/Elec | Unique tools still unique; optional Food refill only if needed |
| Bat craft at Scrap **2** | Bat Rare crate / Scrap **5** craft |
| Crowbar as “build material” confusion | Locale clarify: Scrap ≠ Лом (toast once on first Scrap) |

### Per-floor Scrap budget (nodes only, before crates)

| Floor | Now (approx) | Target yield | Notes |
|-------|--------------|--------------|-------|
| F1 | 9 | **6–8** visible near path + **2** behind soft rubble | Tutorial 8 Scrap = one careful F1 + crumbs, not three roof farms |
| F2 | 4 | **3–4** | Residential = Food/crates more than scrap |
| F3 | 5 | **2–3** safe + **0** forced in toxic | Elec is the prize |
| F4 | 7 | **4–5** after Generator | Cable/Motor are the prize |

### Crate table intent (GameConfig.LootTables)

| Tier | Should give | Should not spam |
|------|-------------|-----------------|
| Common | Scrap 1–2; Food 0–1 @ low chance; Bandage rare | Bat, Pipe, Medkit |
| Rare | Scrap 1–3; Electronics 1; Bandage; Bat chance | Free Machete |
| Gold | Electronics 2–3; Medkit chance; Pipe chance; Key chance | Scrap as main fill |
| Diamond | Electronics 2–4; Cable 1; Medkit; Machete chance | Open without Key/Crowbar |

---

## 6. Загроза / Threat

| System | Rule |
|--------|------|
| **Floor zombies** | No respawn after clear (keep). Raise counts with floor role, not area². Solo slightly fewer than 4‑stack. |
| **Toxic** | Keep F3 east toxic; AirFilter matters mid-late. |
| **Barricade** | **Hard block** at roof stair mouth for horde/climbers. Server `CanCollide = true` for all `BarricadeBlock` parts from the moment Barricade is owned. Zombies never LoS-`MoveTo` through those parts; if path fails → idle / attack in place behind boards. Optional later: slow shred HP on boards — **not** v1. |
| **Horde** | Keep only if barricade works; first wave still ~8–10 min so early teaching stays calm. If barricade still fails QA → **disable Horde** until fixed (do not ship “siren into free kill”). |

### Barricade rule for coder (acceptance)

1. After Barricade purchase, every `BarricadeBlock` part has **server** `CanCollide = true` (not client-only).
2. `ZombieService`: if goal is on the other side of a barricade segment, **do not** fall back to naked `MoveTo(goal)`; repath or stop.
3. Horde with barricade: spawn **behind** boards (already in `HordeService.spawnPositions`); they must **not** appear on the roof playable pad.
4. Players can still vault/leave via stairs (player collision OK); zombies `AgentCanJump = false` stays.

---

## 7. Keep vs cut / delay

| Keep (core) | Cut / delay until loop is good |
|-------------|-------------------------------|
| Chest → Gen → Filter / Bridge | Expanding **Classes** (keep Fighter Pipe start; no new class work) |
| Shared team chest + hold-to-drop | New floor events beyond one blackout |
| Crowbar hard rubble + Diamond lock | **Pickaxe item** (use soft rubble instead) |
| No floor zombie respawn | 240‑stud floor rewrite (optional later; pacing via gates + scarcity first) |
| Toxic F3 + Generator F4 gate | Token meta / Robux SKUs |
| Tutorial one-objective line | Tip spam, second HUD teachers |
| `LOCAL_AGENT_STEPS` bug fixes | Publishing / store push |
| Horde **after** barricade proven | Horde if barricade still cosmetic |
| Blackout once (tone: telegraph only) | More blackouts / fire-door events |

---

## 8. Таблиця чисел / Config number table (recommended)

Propose into `GameConfig` / `UpgradeDefinitions` / `WorldBuilder` counts — **owner OK before coder lands**.

| Lever | Current | Proposed | Why |
|-------|---------|----------|-----|
| `World.FloorSize` | 70 | **70 keep for now** | Gates + scarcity fix feel first; widen later |
| `Zombie.PerFloor` | 1,2,3,4 | **2, 4, 5, 6** (solo −1 each, min 1) | Presence without horde spam |
| `Zombie.WalkSpeed` | 11 | **10** | Flee / kite readable |
| `Zombie.AggroRange` | 45 | **32** | Less “magnet across plate” |
| `ResetNodesOnRoofReturn` | true | **false** for Scrap/Elec (or false globally) | Scarcity |
| Tutorial Scrap target | 8 | **6** then Chest cost 6 **or** keep 8 with F1 guaranteed 8 on marked path | First loop completable |
| `StorageCrate` cost | Scrap 8 | **Scrap 10** | Second trip or full F1 commitment |
| `Generator` cost | 6 Scrap + 4 Elec | **8 Scrap + 5 Elec** | Mid-match goal |
| `AirFilter` | 5+5 | **6 Scrap + 6 Elec** | Parallel to Bridge pressure |
| `Bridge` | 10 Scrap + 4 Cable + 2 Motor | **12 Scrap + 4 Cable + 2 Motor** | Late sink |
| `Barricade` | 8 Scrap + 2 Elec | **6 Scrap + 1 Elec** | Affordable insurance before first horde |
| Crate count / floor | 2–3 | **1 / 1 / 1–2 / 1+Diamond** | Matches LOCAL step #6 |
| `Loot.TierOdds` F1 | 80/18/2/0 | **88/11/1/0** | Common dominates early |
| `Loot.TierOdds` F4 | 35/35/20/10 | **25/35/25/15** | Deep floors reward risk |
| `Loot.UpgradeChance` | 0.12 | **0.08** | Fewer free upgrades |
| Common Bat chance | 0.08 | **0** | Bat starts at Rare |
| Recipes Bat | Scrap 2 | **Scrap 5** | Craft is a decision |
| Recipes Pipe | Scrap 4 | **Scrap 6** | |
| Soft rubble hold | 1.2 s prompt | **3.0 s** | Feels like work |
| Hard rubble hold | 1.2 | **5.0 s** + Crowbar | Matches diamond break-in weight |
| `Horde.FirstDelayMin/Max` | 480–600 | keep **after** barricade fix | Calm teaching window |
| Hunger | as now | keep | Already supports slow play |

**Fairness:** co-op shares rubble/chest/builds (already). Solo gets −1 zombie/floor and same node budgets (not ×1.25 loot inflation — scarcity is the fantasy).

---

## 9. Backlog після LOCAL_AGENT_STEPS / Ordered implementation

**Lock:** finish tablet anim (#1) and other LOCAL bugs in parallel with Phase A only when they block playtests; **gameplay loop before Blender polish**.

### Phase A — Core loop (severity order)

| # | Sev | Task | Notes |
|---|-----|------|-------|
| A1 | **P0** | Barricade server collision + zombie AI never soft-clips stair mouth | `HordeService` + `ZombieService` + acceptance §6 |
| A2 | **P0** | Scrap readability + F1 guaranteed path (marker / placement near stairs) | WorldBuilder placer; not a new item |
| A3 | **P0** | Soft rubble gates on F1–F2 wings (reuse `ClearRubble`, no Pickaxe) | Owner “кирка” fantasy without new tool |
| A4 | **P0** | Turn off Scrap/Elec roof refill; set per-floor scrap budgets | `GameConfig` + ResourceService |
| A5 | **P1** | Fewer crates + **party-shared** opened state | LOCAL #6 + ResourceService.opened |
| A6 | **P1** | Retune LootTables (cut Common Bat/Food spam; rarity identity) | GameConfig table §5 |
| A7 | **P1** | Raise upgrade costs + tutorial Scrap target alignment | UpgradeDefinitions + TutorialService |
| A8 | **P1** | Zombie counts / aggro / speed | GameConfig.Zombie |
| A9 | **P2** | Locale one-shot: Scrap ≠ Лом | Locale + first Scrap toast |
| A10 | **P2** | Horde QA gate — disable if A1 fails | HordeService flag |

### Phase B — LOCAL_AGENT_STEPS remainder (as needed)

Continue #2–#5 (lighting flicker, weapon replace, blur, text overflow) whenever they block “can we feel the loop.”

### Phase C — Playtest gate (owner)

Solo + 2–3 co-op: match length in band §3; barricade stops horde; F1 scrap path obvious; crates feel rare; Bridge not before ~25 min co-op.

### Phase D — Blender visual polish (**only after Phase C**)

**Do not start modeling until the loop feels good.** Workflow already in repo:

1. Edit / run headless Blender: `blender/build_weapons.py`, `build_interior_props.py`, `build_roof_props.py` (`sz_blender.py` helpers).
2. Export FBX under `assets/models/`.
3. Upload: `bash scripts/upload_model.sh <file.fbx> <name>` → prints asset id (`HANDOFF.md`).
4. Paste id into `PropLibrary.ASSETS` (today: InteriorProps `76157686296384`, Weapons `126001413949023`). Roof props via `RoofProps.rbxm` → `ReplicatedStorage.Models`.
5. **Never invent asset ids.** Icons: owner rejected cheap 3D icon look — prefer worn SVG/`build_icons.py` path if icons change.

**Replace priority (ugly → clean):**

| Priority | What | Why | Script / hook |
|----------|------|-----|----------------|
| 1 | **WeaponBat** mesh | Bat reuses `WeaponClub` (`CombatService.MESHES`) | `build_weapons.py` — add Bat; stop Club tint hack |
| 2 | Crowbar held mesh | Crowbar is a plain Part block, not Blender | weapons pack or simple metal prop |
| 3 | Loot crates (Common→Diamond) | WorldBuilder part crates read as toys | new props or interior Boxes variant + tier trim |
| 4 | Scrap / Electronics nodes | Rust cubes blend into rubble | small distinct meshes + glow discipline |
| 5 | Soft / hard rubble piles | Slate blocks + chunks | dedicated Rubble prop; Crowbar sign stay |
| 6 | Barricade boards | Thin WoodPlanks slab | roof or interior boarded-door prop |
| 7 | Roof junk / upgrade pads | Functional but blocky | `build_roof_props.py` already has Storage/Gen/Filter/Bridge — refresh quality |
| 8 | Interior filler | Sofa/Bed/… already in InteriorProps | raise fidelity after weapons/crates |

---

## 10. Acceptance (design)

1. New player finds Scrap on F1 without wiki; counter moves; Chest build needs a real trip, not pocket change.
2. Soft rubble is the first “earned path”; Crowbar is mid/late, not confused with Scrap.
3. Built Barricade stops roof horde on server (video: zombies stuck in shaft).
4. Co-op Bridge win typically **≥ 25 min**; solo **≥ 30 min** without AFK.
5. Opening a Gold/Diamond crate feels louder than clearing three Commons.
6. No Blender rework scheduled until owner signs Phase C.

---

## 11. Owner one-pager (UK)

Гра зараз коротка і «порожня», бо поверхі малі за змістом (мало загрози, багато їжі/ящиків, металобрухт маскується під сміття, ноди оновлюються з даху, барикада не тримає AI). У коді Scrap і Лом **є**; проблема в помітності, темпі й правилах. Ціль — повільний кооп 25–40 хв: завал → дефіцитний брухт → рідкісні ящики → Chest→Gen→Filter/Bridge, барикада як твердий блок. Кирку як новий предмет не додаємо — м’який завал уже є. Спочатку петля + баги з `LOCAL_AGENT_STEPS`, **потім** Blender «вилизано».
