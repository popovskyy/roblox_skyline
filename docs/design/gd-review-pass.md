# SkylineZero — GD Hard Review (pre next code+build)

**Role:** Game Designer · **Date:** 2026-10-17  
**Sources:** `docs/*`, `internal/elevator-modal-b17.md`, `internal/elevator-entry-restore-b18.md`, `internal/roblox-publish-b16.md`, `internal/atmosphere-slice-a4c8070.md`, live PRIVATE [Skyline Zero](https://www.roblox.com/games/128619231370772/Skyline-Zero) (Lobby `128619231370772` / Tower `104145307601846`, last noted **v28**), workspace Luau under `/workspace` (+ place injects). Join may fail: universe **PRIVATE** — owner/invite only.

**Verdict:** Backlog checkmarks lie. Ship has real progress (240 plate, live `n/m`, marker→loot, team chest, drop, rubble server-clear, zombie no-reseed, elevator zone/modal) — and still fails the north star. A cold player still hits cliffs: **solo lift blocked in source**, **scrap 3 → chest needs 8**, **no soft tokens / wrong heal craft**, **F2/F3 loot deserts**, **mobile swing still Classic `toolanim`**. Do not publish “atmosphere done” until first-session clarity and lift solo are green.

**Truth vs claims:** `atmosphere-slice-a4c8070.md` claims WeatherService, TokenService, Scrap×4 bandage / Scrap×6+Elec×2 medkit, idle 45s ping, R15 ToolSlash. **None of that exists in current `/workspace` src or place scripts.** Treat those rows as **not shipped**. Elevator b17/b18 docs claim `MinPartySize = 1` + buttons 1–6 live; **workspace + places still `MinPartySize = 2`**. Prefer live Studio verify before next publish; do not trust backlog `[x]`.

---

## 1. First session clarity — still #1 pain

**Status:** Partial. Live `Металобрухт n/3` + nearest-scrap marker exist. The loop still breaks after return.

| Beat | Spec | Reality | Fail |
|------|------|---------|------|
| 0–20s roof | One objective → terminal; idle 45s soft ping | Objective OK; **no idle ping** in client | Freeze if intro skipped |
| Stairs | World `СХОДИ ВНИЗ ↓` + marker | Present | — |
| Scrap 0/3 | Counter ticks same frame; glow + prompt | HUD + marker fixed | — |
| Return | `tutorial.3` | OK | — |
| Next | Teach bank / craft | `tutorial.4` = build chest **Scrap 8** after collecting **3** | **Cliff:** player thinks quest broken |
| Electronics | Safe path to 4 | Marker OK; F1 open elec thin; F3 elec in **toxic** | Wander / toxic quit |
| Shop / Robux | Locked until return | No shop (OK); also no craft path that matches design | Post-wipe “why replay?” |

**Hard rules still violated**
- Exactly one primary objective — OK until chest cliff invents a silent second grind.
- Teach by doing — chest cost not previewed on the scrap step.
- Max 1 toast / 15s — not verified live; keep as regression gate.

**Acceptance (first session)**
1. Cold player, no Discord: roof → scrap **3/3** → roof in **≤180s**, never stuck >45s without a marker/ping.
2. After 3/3, objective either (a) raises scrap target to **8** before naming the chest, **or** (b) chest cost drops to **≤3–4** scrap for tutorial build. No silent 3→8 gap.
3. Idle 45s on roof step 1 → **exactly one** terminal bob + click; no text spam.
4. Electronics 0/4 completable without entering toxic on the critical path (move ≥4 open/safe elec onto F1–F2 wings).

---

## 2. Elevator — enter, modal 1–6 incl. solo, wait-for-party

**Product lock (prefs + b17):** modal **1–6**, solo allowed. UX doc’s old “no 1” is **overridden**.

| Issue | Severity | Notes |
|-------|----------|-------|
| Enter must work | **blocker** if regressed | b17 broke entry (oversized zone + Active fullscreen dimmer). b18: zone **9×9×9**, dimmer **Active=false**, no Prompt. **Re-test every lobby publish.** |
| Solo in source | **blocker** | `PlacesConfig.MinPartySize = 2` → UI has no `1`. Solo forced to pick 2–6 and wait. |
| Wait-for-party | **high** | Deadline starts on first rider; underfilled party **still launches** at 20s. OK as “timeout start”, bad if UI doesn’t say so. Solo@1 should use **fullCountdown (5s)** (b17 claim; not special-cased clearly when min=2). |
| Non-leader UX | **medium** | Spec: read-only “Лідер обрав: N”. Verify copy + no second pick. |
| World chrome | **medium** | Signs = `ЛІФТ` only; delete solo/group numeric chrome if any remain live. |

**Wait-for-party rules (lock for coder)**
1. Leader picks **N ∈ [1,6]**.
2. Countdown = `countdown` (20) while `#riders < N`; when `#riders ≥ N` → snap to `fullCountdown` (5).
3. If `N == 1` → immediately use `fullCountdown`.
4. Launch with whoever is inside when timer hits (underfill OK). Walk out = leave + cancel leadership if last.
5. Never block thumbstick/jump with modal chrome (`Active=false` on any dimmer; panel not bottom-edge full bleed).

**Acceptance**
1. Mobile + PC: walk into open cabin → modal opens **only inside**; can walk/jump/strafe while modal visible.
2. Buttons **1…6** all selectable; `1` starts ≤5s and teleports solo.
3. Pick `4`, stay alone 20s → still launches (document in UI: riders `1/4` + countdown). Pick `4`, second joins → shortens toward fullCountdown.
4. Second player sees leader’s N, cannot override.
5. No regression of b18 input-eat.

---

## 3. Floor scale 240, loot density, empty-feel risk

**Plate:** `FloorSize = 240` — good vs old ~70 closet. Sprint 10–12s target is the right feel.

**Density audit (code)**

| Floor | Scrap nodes | Electronics | Risk |
|-------|-------------|-------------|------|
| F1 | 18 (+3 on tutorial lane) | 1 open + 2 behind rubble | Tutorial OK; wings under-gated (only **1** rubble) |
| F2 | 20 | **0** | **Empty mid-loop** for elec / craft; medkits raw on floor fights craft scarcity |
| F3 | thin scrap | mostly **toxic** | Feels like punishment, not choice |
| F4 | gated | gated | OK late |

Wider ≠ empty failed on **purpose**, not raw scrap count. F2 is a scrap parking lot with no electronics/rubble decisions. Design soft-cap (~8 scrap meaningful / floor) not enforced — 18–20 nodes invite vacuuming boredom.

**Missing vs loops §1**
- Mid floors: **2–3** rubble wings with a reason each — F1 has 1; F2 has 0.
- Farthest loot → elevator call ≤18s **or** 2nd call panel — tower still stairs-centric; no amber “floor done → elevator” beat (medium for loop rhythm, not tutorial blocker).

**Acceptance**
1. Sprint edge→edge cleared corridor: **10–12s**.
2. Tutorial scrap path round-trip still **≤160 studs** / finishes in 180s window.
3. Mid floor (F2): **≥2** rubble-gated wings; **≥8** electronics reachable without toxic; scrap soft-cap after ~8 pickups (husk/crumb).
4. No floor that is “only scrap, no gate, no threat decision.”

---

## 4. Rubble / electronics / drop / team chest

| System | Code state | Design gap |
|--------|------------|------------|
| Electronics false “завал” | Prompt gated until rubble clear + `res.needRubble` | **Live verify** once; keep as publish gate |
| Rubble collision | Server `openRubblePart` shared | Good — was the co-op grief |
| Break time | Prompt hold ~**1.2s**, instant clear | Spec **3–5s** shared bar, 2 players faster — **not done** |
| Drop | `DropService` TTL 120s, party pickup | Discovery toast once — verify |
| Team chest | Shared `teamStorage` | Label/header locale exist; first-open hint once |

**Acceptance**
1. Uncleared rubble-gated elec: Collect prompt **disabled** or labeled need-rubble — never generic blocked toast.
2. Clear rubble → **both** players walk through same frame; no invisible wall.
3. Hold **3–5s**; two players on same pile share one bar and finish faster.
4. Drop bandage → ally pickup under fire within 120s; death backpack stays personal.
5. A deposit scrap → B sees it in team chest + quest `Total` if applicable.

---

## 5. HUD n/m, death markers, zombie no-reseed

| Item | State | Gate |
|------|-------|------|
| Live `n/m` | Implemented (`scrapProgress` / `elecProgress`) | Must not regress to static `tutorial.2` |
| Marker → loot | Nearest scrap/elec | Retarget ≤0.5s; never stairs while nodes remain |
| Downed marker | `DownedMarkerController` edge + world | Mobile: ≥36px chevron, meters readable; cap 2 |
| Zombie no-reseed | `floorCleared` — no timed respawn | Kill all on F1, wait 90s → **zero** new spawns |

**Acceptance**
1. Pick scrap 1 → HUD shows `1/3` same sync tick.
2. Downed ally off-screen: edge chevron + `N м` on phone.
3. Cleared floor stays quiet for the rest of the visit; re-enter/new run = fresh table.

---

## 6. Atmosphere / weather vs readability

**Shipped in src:** fixed late-afternoon `Atmosphere` (ClockTime 16.4), haze, bloom. Scenery still documents plant-taken ruins — backlog wanted less botanical garden; treat as **tone debt**, not first-session blocker.

**Not shipped:** dynamic rain, day/night (`WeatherService` missing). Do **not** prioritize weather over clarity.

**Readability rules if weather lands**
- Never blackout tutorial plate.
- Rain/dusk: loot glow + objective amber stay above weather noise.
- Interiors: Ambient dim enough for flashlight, never unreadable scrap outlines.
- Skyline must sit on a ground plane when looking down from roof (floating towers = tone break).

**Acceptance (atmosphere for next publish)**
1. No strobing floor lamps on enter.
2. Objective text + loot glow legible at default mobile brightness.
3. Weather **optional** this pass — if shipped, tutorial.1–3 muted / no blackout.

---

## 7. Tokens / medkit craft vs Robux shop fairness

**Brutal fact:** soft **Tokens do not exist**. Medkit **not craftable**. Bandage = `Food 1 + Scrap 1` (design: Scrap **4**). MedkitHeal code **35** (design craft heal **60**). Robux catalog in `economy-robux.md` is paper until craft + token earn exist.

| Rule | Required |
|------|----------|
| F2P full run | Craft bandage/medkit from scrap/elec alone |
| Token earn | Kill 1–2 / clear `10+2×floor` cap 25 / roof +25 once / 15-min **40–70** |
| Robux | Same item defs as craft; 1 pack/run caps; no DPS / floor skip |
| Dual-track heal | Craft = primary; Robux = panic tempo |
| First 180s | **Zero** shop / GamePass prompts |

**Acceptance**
1. Recipes: Bandage Scrap **4** → heal 25; Medkit Scrap **6** + Elec **2** → heal **60** / revive charge.
2. Roof workbench always reachable after tutorial return.
3. Token HUD or end-screen payout matches earn table; no AFK drip.
4. Shop locked until tutorial return; Medkit Pack stats ≡ craft.

---

## 8. Mobile melee / prompts

| Area | State | Risk |
|------|-------|------|
| Hit button | Touch hit control exists | OK surface |
| Swing VFX | Server still Classic **`toolanim=Slash`** | Matches old “PS5 only” bug; Animator ToolSlash **not in src** |
| Interact | Big `Взаємодія` hold button | Keep clear of lift modal / thumbstick |
| Drop | Long-press inventory | Teach once in co-op |
| Prompts | ActivationDistance ~10 | On 240 plate, don’t make scrap need pixel hunting |

**Acceptance**
1. Mobile spectator sees slash/swing on peer ≥8/10 swings (replicated AnimationTrack, not toolanim-only).
2. Interact + hit buttons never cover thumbstick; lift modal leaves bottom controls free (b18).
3. Scrap/rubble prompts trigger at walk-up without camera hunting.

---

## 9. Must-fix before next publish vs nice-to-have

### Must-fix (ordered — blocks publish)

Concrete AC; fail any = no publish.

1. **Elevator enter regression gate (b18)**  
   Walk into cabin on mobile → modal; movement not eaten; zone 9×9×9; dimmer `Active=false`.

2. **Solo 1–6**  
   `MinPartySize = 1`; button **1** present; solo starts via `fullCountdown`; prefs satisfied.

3. **First-session scrap→chest cliff**  
   No 3-scrap return into silent 8-scrap chest. Align cost **or** extend objective to `n/8` before build step.

4. **Idle terminal ping (45s)**  
   Exactly one soft ping if step 1 incomplete.

5. **Electronics critical path without toxic**  
   Four electronics for tutorial reachable on safe/open tiles (F1/F2), marker leads there.

6. **Heal craft = design**  
   Bandage Scrap4; Medkit Scrap6+Elec2; workbench after return; heal numbers match economy doc.

7. **Soft tokens earn (minimal)**  
   Kill/clear/roof payouts live; end screen or HUD shows tokens; no shower.

8. **Mobile melee visible**  
   Replicated swing anim on mobile/tablet viewers.

9. **Live verify co-op packet**  
   Rubble shared open; elec no false завал; drop pickup; team chest shared; `n/m` ticks; downed marker; F1 no zombie reseed 90s.

10. **F2 empty-feel patch**  
    ≥1–2 rubble wings + electronics on F2 so mid floor isn’t scrap-only void.

### Nice-to-have (after publish / next loop)

- Rubble hold 3–5s + shared progress bar  
- Weather / day-night (readability-safe)  
- Skyline botanical cleanup + roof footing  
- Tower elevator amber “floor done” beat / 2nd call panel  
- Near-miss end screen, floor heartbeat, drop-under-fire pulse (brainstorm #1–3)  
- Robux MVP catalog (only after craft+tokens)  
- Token sinks / starter pack UI  
- Scrap soft-cap husks after ~8  
- Height ledger / rare stash flash  

### Explicitly do **not** do before next publish

- Shop in first 180s  
- Parallel meta / battle pass  
- Blackout/fire-door events on tutorial plate  
- Trusting backlog `[x]` without Studio repro  
- Atmosphere-only publish while solo lift + chest cliff still broken  

---

## Publish gate (one paragraph)

**Ship when:** cold solo can board lift (button **1**), finish scrap→return≤180s without the 3→8 cliff, craft a bandage, see tokens after a clear, swing anim reads on mobile, and co-op rubble/chest/drop/`n/m`/no-reseed pass a 2-client smoke. Weather and botanical skyline can wait. Pretty dark lobby with a broken first ten minutes is still a quit.

---

## Refs

- [bug-backlog.md](./bug-backlog.md) · [gap-report.md](./gap-report.md) · [first-session-ux.md](./first-session-ux.md) · [game-design-loops.md](./game-design-loops.md) · [economy-robux.md](./economy-robux.md) · [brainstorm-hooks.md](./brainstorm-hooks.md)  
- Internal: [elevator-modal-b17.md](../internal/elevator-modal-b17.md) · [elevator-entry-restore-b18.md](../internal/elevator-entry-restore-b18.md) · [roblox-publish-b16.md](../internal/roblox-publish-b16.md) · [atmosphere-slice-a4c8070.md](../internal/atmosphere-slice-a4c8070.md)
