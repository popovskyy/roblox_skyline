# SkylineZero — Game Design Loops

Addiction loops for coder + UX. Tone matches [first-session-ux.md](./first-session-ux.md): dry, amber, one objective line — teach by doing, not by walls. North star: **затягує, не бісить**.

---

## 1. Core loop (timescale)

| Scale | Beat | Player feels |
|-------|------|--------------|
| **~30s** | Enter room → see loot glow / zombie threat → grab 1–2 items OR clear 1–2 hostiles → decide stay/leave | Micro dopamine: number ticks / threat resolved |
| **~3 min** | Full floor: explore → loot quota → clear remaining → hit elevator call | “Floor done” — bank progress |
| **~15 min** | 3–5 floors + 1 stash trip → deeper floor or roof push | Session arc; reason to queue again |

**Canonical chain (never break order of teaching):**

```
explore → loot → (optional fight) → clear floor → elevator → next floor
```

First session (aligned with UX): **roof orient → descend → loot scrap 0/3 → return** by ~180s. Combat is *not* the first teacher; loot counter is.

| Floor role | Explore | Loot target | Clear | Elevator |
|------------|---------|-------------|-------|----------|
| Tutorial tech | Soft markers, 1 rubble gate after scrap path | Scrap **3** (tutorial) | Sparse zombies; no respawn after clear | Return roof / next step via existing tutorial.3+ |
| Mid floors | Full **240** plate, 4–6 rooms / **2–3** rubble wings (§1 footprint) | Electronics + scrap mix (see §2) | Clear = all living zombies dead on that floor | Call pad unlocks when clear **or** when loot quota met (pick one rule — recommend: **quota OR clear**, not both mandatory early) |
| Deep / roof | Scarce loot, high risk | Rare mats + tokens | Commitment zone (no respawn) | Roof = session payoff (§5) |

**Elevator rule (buildable):** After floor clear (all zombies dead) **or** after depositing quota to team chest, call button lights amber. Soft ping once. No second modal.

### Floor footprint (scale) — owner: “tiny square”

**Problem now:** sprint edge→edge ≈ **2s** (~**48 studs** at Roblox default sprint ~24 stud/s). Reads as a closet, not a skyscraper floor.

| Metric | Current (feel) | **Target** |
|--------|----------------|------------|
| Sprint cross (clear corridor, edge→edge) | ~2s | **10–12s** |
| Walk cross (same path) | ~3s | **15–18s** |
| Floor plate (exterior footprint) | ~48×48 studs | **240×240 studs** (±20); rectangle OK **220×280** |
| Playable interior (after walls) | — | ~**200×200** walkable core |
| Vertical floor-to-floor | keep existing | unchanged unless art needs it |

Assumes default Humanoid: walk **16** / sprint **24** stud/s. If game uses custom speeds, keep the **time** targets; recompute studs.

**Wider ≠ empty — loot density**

| Layer | Density target | Notes |
|-------|----------------|-------|
| Scrap / common nodes | **1 per ~900–1100 stud²** of walkable (~**35–45** nodes on 200×200) | Clusters of 2–3 in rooms, not a grid |
| Electronics | **1 per ~3500–4500 stud²** (~**8–12** / floor mid+) | Behind rubble or deeper wings |
| Medkit (raw world) | **0–2** / floor | Craft stays primary (§2) |
| “Interesting point” (room / junction / vista) | every **25–35** studs of path | Breaks long empty hall feel |

Per-floor **yield** stays the table in §2 (4–7 scrap *collected*, not 40). Extra nodes = choice + miss chance, not token shower. Soft-cap: after ~**8** scrap pickups / floor, remaining nodes can be empty husks or 1-scrap crumbs. **Tokens ignore plate size** — still kill/clear/roof only (§2), so the wider building does not inflate soft currency past the Robux-shop earn contract.

**First session still ≤ ~180s (scrap 0/3)**

Do **not** force full-plate clear for tutorial.

| Beat | Budget | Layout rule |
|------|--------|-------------|
| Stairs → first scrap | ≤ **25s** walk | 3 scrap on a **marked corridor** within **~80–100 studs** of stairs |
| Scrap 0→3 | ≤ **60s** total loot | All 3 on that corridor / adjacent alcoves; glow + counter (UX) |
| Return to roof | rest of 180s | Stairs stay obvious; side wings **optional** (rubble / no marker) |

Tutorial tech floor can be the full 240 plate, but **critical path length** (stairs → 3 scrap → stairs) ≈ **120–160 studs** round trip, not a full perimeter lap.

**Impact: elevators, rubble, zombies**

| System | Change with wider plate |
|--------|-------------------------|
| **Elevators** | Keep **1 bank** on the plate (lobby side / core). Max walk from farthest room to call pad: **≤ 18s** sprint (~**430** studs path — if longer, add **2nd call panel** mid-wing, same shaft). Do not add a second shaft until art asks. Cabin capacity dialog (backlog #1) unchanged. |
| **Rubble** | **2–3** gates per mid floor creating wings (not a maze). **0** rubble on tutorial scrap corridor. Break time still **3–5s** (§3). Behind each gate: electronics / shortcut / med — never dead end. Space gates **≥ 40 studs** apart so clear→loot still readable. |
| **Zombies** | Scale by **rooms / wings**, not area². Tutorial path: **4–6**. Mid floor: **12–18** (was ~tiny-floor count × ~2.5–3). Deep: **18–24** + **0–2** elites. Pack size **2–4**; no respawn after clear (§3). Telegraphs still 1–2s. |
| **~3 min floor** | Still the target for “done” (quota **or** clear → elevator). Wider plate adds optional loot wings, not mandatory homework. |

**Coder acceptance (scale)**

1. Sprint edge→edge on a cleared corridor: **10–12s** (not ~2s).  
2. Tutorial scrap 0/3 still finishes inside the UX **~180s** window.  
3. Mid floor has **≥ 2** rubble-gated wings with a reason behind each.  
4. Farthest loot → elevator call ≤ **18s** sprint (or second call panel).

---

## 2. Loot economy

### Resources

| Item | Role | First-session source | Ongoing source |
|------|------|----------------------|----------------|
| Scrap / Металобрухт | Tutorial + craft bulk | Tech floor nodes (glow) | Every floor, common |
| Electronics / Електроніка | Mid objective + craft rare | Deeper rooms / locked after rubble | Mid+ floors |
| Medkit / bandages | Survive | Rare floor drop + craft | Craft primary (see below) |
| Tokens (soft) | Meta / convenience spend — **not** Robux | Small clear bonus | Floor clear + roof; **nerf current**; see Robux compat below |
| Robux shop | Paid survival convenience (Economist owns SKU) | Lobby / hub shop | See [economy-robux.md](./economy-robux.md) when present — loops do not redefine prices |

### Target rates (per player-equivalent, 4-stack; solo ≈ ×1.25 drop, not ×4)

| Resource | Per floor (cleared) | Per 15-min run | Notes |
|----------|---------------------|----------------|-------|
| Scrap | 4–7 | 18–30 | Common; fills craft |
| Electronics | 1–3 | 5–10 | Gate mid crafts |
| Medkit (raw) | 0–1 | 1–3 | Prefer craft over floor spam |
| Tokens | **8–15** | **40–70** | Soft only; wider plate must **not** multiply this (density ≠ payout) |

**Token rebalance (concrete levers) — keep Robux shop useful:**

| Lever | After | Why (vs Robux) |
|-------|-------|----------------|
| Per zombie kill | **1–2** max; elites **5** | Soft drip; never funds a full “win kit” mid-floor |
| Floor clear | **10 + 2×floorIndex** (cap **+25**) | Main soft earn; still scarce vs a 15-min comfort pack |
| Roof / session end | **+25** once per successful roof touch | Visible soft payoff; not a Robux substitute |
| Idle / AFK | **0** | — |
| Wider floor bonus | **None** | Extra rooms ≠ extra tokens; kill/clear formulas stay flat |

**Soft vs Robux — hard boundaries (loops side; SKU detail in economy doc)**

| Rule | Spec |
|------|------|
| F2P viable | Full run completable with craft + floor loot alone; Robux never required for elevator, clear, or roof |
| Tokens buy | Cosmetics, small conveniences, **slow** meta (e.g. backpack +1 over many runs) — Economist lists exact SKUs |
| Robux shop | **Useful survival** (med refill, ammo pack, revive charge, death-insurance stash) — not junk crates; **not** permanent damage/HP/loot-luck edges that F2P cannot match |
| Heal dual-track | Craft (scrap/electronics) = primary sustain; Robux heals = **tempo / panic buy** when materials dry; token heals if any = weaker or slower than Robux pack |
| Earn sink ratio | ~**40–70** tokens / 15 min ⇒ a meaningful soft convenience should cost **≥ 1–2 runs** of that earn; if Economist sets cheaper, they own the sink — loops keep earn side fixed |
| No P2W | No Robux-only weapons, no exclusive floor skips that skip risk, no paid zombie delete. Cosmetics + consumable tempo OK |

Cross-links (do not edit those files from this role): [economy-robux.md](./economy-robux.md) · [brainstorm-hooks.md](./brainstorm-hooks.md). Floor scale (§1) and token nerf stay compatible with whatever SKUs they lock — **earn table above is the contract**.

### Craft — heals (scarcity with fairness)

| Recipe | Cost | Output | Unlock |
|--------|------|--------|--------|
| Bandage | Scrap **4** | Heal **25** | Always (after tutorial return) |
| Medkit | Scrap **6** + Electronics **2** | Heal **60** / revive charge **1** | After first electronics objective |

**Fairness:** craft station on roof/safe hub always available; never lock heals behind RNG-only floors. Scarcity = materials, not “no station”.

### Shared team chest + drop

| Rule | Spec |
|------|------|
| Chest | One inventory per party; deposits count for quest `Total` (UX §3) |
| Cap | e.g. **24** slots team / **8** backpack personal |
| Drop | World pile, party-only pickup, TTL **120s**, prompt `Підібрати` |
| Hook | Full backpack mid-fight → drop ammo/med for downed ally = squad dependency (§5) |

Discovery copy: UX owns strings; design only requires **one** first-time toast each for chest + drop (already in UX).

---

## 3. Survival tension

**Scarcity without unfairness**

| Do | Don’t |
|----|-------|
| Predictable craft costs | Random wipe with no agency |
| Loud telegraph before ambush (audio 1–2s) | Instant spawn behind player |
| Rubble as *soft gate* (time + crowbar) | Invisible walls / unbreakable rubble (current bug) |
| Ammo/heal drought on deep floors | Empty dry floors with nothing to decide |

**Rubble = gating, not grief**

| Spec | Value |
|------|-------|
| Break time | **3–5s** hold (crowbar); 2 players = faster (shared progress bar) |
| Behind rubble | Always a *reason*: electronics node, shortcut, medkit, or elevator side path |
| Fail state | Never false “завал” on electronics pickup (backlog bug) — separate prompts |

**Zombie no-respawn after clear (commitment)**

| Rule | Effect |
|------|--------|
| Floor starts with fixed spawn table | Players can count risk |
| On clear: **no respawn** for rest of visit | Safe to loot thoroughly → addictive “we own this floor” |
| Re-enter later / new run | Fresh table |
| First floor included | Same rule (backlog) |

Tension comes from **going deeper before you’re ready**, not from zombies popping back after you paid the clear cost.

---

## 4. First-session “aha” moments (always know next action)

Keep UX timeline; design meaning of each beat:

| t | Aha | Next action (one line) |
|---|-----|------------------------|
| 0–20s | “Це дах / термінал — чому ми тут” | Walk to terminal |
| ~40s | “Треба вниз” | Stairs marker |
| First scrap pickup | **Counter moves** `1/3` | Keep looting nearest glow |
| 3/3 | “Прогрес = повернутись” | Roof marker |
| Deposit / chest | “Команда ділиться лутом” | Open team chest once |
| First clear + elevator light | “Поверх закінчено → далі” | Call elevator |
| First craft bandage | “Хілки не з повітря — крафт” | Spend scrap |

**Hard rule:** at every moment exactly **one** primary objective string (UX). Design never adds a second parallel quest in first 3 minutes.

---

## 5. Hooks — queue another run

| Hook | Mechanic | Feel |
|------|----------|------|
| **Near-miss** | Die / extract with backpack **≥70% full** or roof **<1 floor** away → end screen: “Ще трохи…” + show missed token/roof bonus | “one more” |
| **Squad dependency** | Revive needs medkit/bandages from chest or drop; downed marker (UX) | Can’t ghost the team |
| **Roof payoff** | Weather/skyline beat (art backlog) + **+25 tokens** + unique vista; first roof = short dry VO/text once | Session climax |
| **Floor ownership** | Cleared floor stays quiet (no respawn) — contrast with next uncleared floor noise | Rhythm addiction |
| **Shared stash growth** | Team chest visible fill over run | Collective progress |

End-of-run screen (minimal): floors cleared · tokens · best loot · **CTA: Знову / Лобі** — no essay.

---

## 6. What NOT to do

| Anti-pattern | Why it kills addiction |
|--------------|------------------------|
| Tutorial walls / multi-modals mid-loot | Breaks 30s loop |
| HUD spam (toasts <15s, tip stacks) | Teaches ignore UI |
| Empty floors (no loot, no threat, no gate) | Dead air → leave |
| Mandatory clear **and** full loot before elevator early game | Feels like homework |
| Token showers | Nothing to chase |
| Respawn zombies after clear | Punishes commitment |
| Personal-only chest in co-op | Kills squad hook |
| “How to play” re-show in tower | UX forbid |
| Purple coach marks / emoji tips | Tone break |

---

## 7. Priority implementation (respects bug backlog order)

Do **not** skip elevators. Feature design rides on backlog sequence; balance numbers land when their backlog row is open.

| Order | Backlog block | Design payload to ship with the fix |
|-------|---------------|-------------------------------------|
| **1** | Ліфти: remove old signs; dialog 2–6 | Party size is the co-op hook; UX panel spec as-is |
| **2** | Завали + electronics false block; **drop**; **team chest** | Rubble times §3; chest/drop rules §2; fix pickup friction first |
| **3** | Quest counter realtime; death marker | Aha ticks §4; squad hook §5 |
| **4** | No zombie respawn after clear | Commitment rule §3 — all floors |
| **5** | Atmosphere / roof / skybox / weather | Roof payoff visual; keep +25 tokens when gameplay balance ships |
| **6** | Onboarding clarity; **med craft**; **token nerf** | §§2–4 numbers; first-session path already in UX |
| **7** | Cross-plat hit anims | No loop change; readability of combat |

**Coder note:** While on steps 1–4, do not invent parallel meta systems. Loop numbers in §2–3 are targets for step 6, except: drop + team chest + no-respawn + live counter ship with their earlier backlog rows using these rules as acceptance.

### Acceptance (design)

1. New player finishes loot→return by ~180s (UX).  
2. Cleared floor stays empty of new zombies.  
3. Tokens ~half of “shower” feel; craft is main heal source.  
4. Elevator path always obvious after clear or quota.  
5. Teammate can receive a dropped medkit under fire.  
6. Floor plate hits §1 footprint targets (10–12s sprint cross; tutorial path still short).
