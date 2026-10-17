# SkylineZero — Nuance Test Pass (2026-10-17 b)

**Method:** static / code review against **GitHub `main` tip `cb58a55` (build `b18 · elevator-entry-restore`)**. Cross-checked docs + elevator notes (`elevator-modal-b17`, `elevator-entry-restore-b18`, `roblox-publish-b16`).  
**Live join:** [Skyline Zero](https://www.roblox.com/games/128619231370772/Skyline-Zero) universe **PRIVATE** — this agent **could not join**. Items marked **JOIN-BLOCKED** need a human/device pass on v28 (or whatever is currently Published).  
**Workspace trap:** local `/workspace` and store `artifacts/places` are still **`b15` / `e31c367`**. Do **not** test or publish from that tree. Source of truth = GitHub.

**Verdict:** Backlog checkboxes are **lying by completeness**. Most G1–G8 *code holes* from the first gap-report are patched on `cb58a55`, but lobby ENTER is still fragile, mobile drop is double-firing, tokens are invisible, and co-op still feels like two solo games sharing a chest. Do **not** treat “all [x]” as ship.

---

## Severity legend

| Level | Meaning |
|-------|---------|
| **blocker** | Breaks lobby start or first-session loop; publish = leave |
| **high** | Strong tilt / acceptance fail; play continues angry |
| **medium** | Tone / balance / polish debt |
| **fixed-in-code** | Prior gap present in old build; **gone in `cb58a55`** — still **JOIN-BLOCKED** live verify |
| **join-blocked** | Needs live/device; cannot close from static alone |

---

## Top 15 for coder (ordered)

### 1. Elevator ENTER — residual sticky modal race — **blocker** (lobby)

- **Repro:** Walk into cabin → modal opens → walk out **before** picking → walk near cabin again. Or: enter, leave within one network tick of `OpenLiftSizePick`.
- **Suspect:** `LobbyClient.client.lua` `OpenLiftSizePick.OnClientEvent` → `setPickVisible(true)` **ignores** `LiftPickOpen`. Server `clearPickPrompt` clears attributes on leave; late remote re-opens modal with **dead** buttons (`ChooseSize` needs `LiftPickId`). Panel `Active = true`, no dismiss — on short phones can still eat mid-screen touch.
- **Expected:** Remote open only if still inside + `LiftPickOpen`; else ignore. Closing path: attribute false always hides, remote cannot reopen alone.
- **Live note:** b17 fullscreen Active dimmer = “cannot enter” (fixed b18 zone `9×9×9`, dimmer `Active=false`). This race is the **next** ENTER class bug. **JOIN-BLOCKED** confirm on Published lobby.

### 2. Lift countdown HUD sits on mobile jump/thumbstick — **high**

- **Repro:** Pick size → countdown panel at `Position (0.5, 1, -24)` while still in cabin.
- **Suspect:** `LobbyClient` `LiftCountdown` / `UIKit.Panel` (default Active frame over bottom chrome).
- **Expected:** Upper or side stack; never cover touch controls. Same class of bug as b17.

### 3. Long-press drop then `Activated` uses/equips — **high** (mobile)

- **Repro:** Long-press hotbar stack → item drops → finger up also fires `Activated` → `activateSlot` on same slot (now empty or next stack).
- **Suspect:** `InventoryController` — `InputBegan` delay drop **and** `Activated` → `activateSlot` with no “didDrop” guard.
- **Expected:** If long-press fired drop, suppress the following activate.

### 4. Tokens earn with **no HUD and no sink** — **high** (quit-after-wipe)

- **Repro:** Kill / clear floor / roof → toast `tokens.earned` → scan HUD for balance / shop. Nothing.
- **Suspect:** `TokenService` + snapshot `tokens`; **zero** reads in `HUDController` / inventory UI. No spend path in tower.
- **Expected:** Persistent token readout + at least one obvious sink, or stop toasting phantom currency.
- Backlog “менше видачі” is meaningless while the meter is invisible.

### 5. Per-player loot nodes still on — **high** (co-op feel)

- **Repro:** A loots all F1 scrap → B sees full nodes and loots the same piles.
- **Suspect:** `ResourceService` header + `depleted` per player; `PartyService` still says resource nodes stay personal.
- **Expected:** Shared world scarcity **or** honest UI that loot is personal. Current state = “we’re not in one game.”

### 6. Modal is **1–6 Solo**; UX doc wanted **2–6** — **high** (product / copy)

- **Repro:** Enter lift → grid includes Solo/`Один`.
- **Suspect:** `PlacesConfig.MinPartySize = 1`; `LobbyClient` solo tile; Locale `lobby.hint` / `pickSizeBody` say 1–6. Conflicts with `first-session-ux.md` §2 (prefer no 1).
- **Expected:** Product call: either lock 2–6 + empty-seat solo start, or update UX docs. Don’t ship mixed messaging.

### 7. Melee anim — code improved, live unproven — **high** / **JOIN-BLOCKED**

- **Repro (needed):** Mobile swing ×10; second client watches arms. Tablet same.
- **Suspect:** `CombatService.playSlashAnim` + client `CombatController.playLocalSlash` (`rbxassetid://522635514`). Classic `toolanim` kept as fallback.
- **Expected:** Local + replicated slash on phone/tablet/PC, not PS5-only.
- Residual risks: R15-only asset; server `Animator` create edge cases; spectator replication must be live-checked.

### 8. Drop pickup has **no party gate** — **medium→high** if public ever

- **Repro:** Drop bandage → non-party player picks it (comment claims party-only).
- **Suspect:** `DropService.Pickup` — no `PartyService` check.
- **Expected:** Party-only (or design-documented free-for-all). Private reserved servers mask this today.

### 9. Rubble clear still not shared hold / 3–5s bar — **medium**

- **Repro:** Two players hit same rubble — instant open after `HoldDuration` 1.2s prompt; no shared progress bar.
- **Suspect:** `WorldBuilder` `addPrompt(..., 1.2)`; `ResourceService.ClearRubble` instant shared open (collision fix is good).
- **Expected:** Design loops: 3–5s crowbar, shared bar, 2 players faster. Server collision clear = **fixed-in-code** vs old G2.2.

### 10. Toast spam — no 15s throttle — **medium**

- **Repro:** Rapid pickups / token kills / party.stored → toast stack.
- **Suspect:** `HUDController` toast (cap 4, no time gate); lobby toasts same.
- **Expected:** UX max 1 toast / 15s for non-critical; objective line carries progress.

### 11. Weather vs Atmosphere brightness fight — **medium** (flicker risk)

- **Repro:** Stand on roof / enter floor while ClockTime crosses dusk/night thresholds; watch lamp bloom.
- **Suspect:** `WeatherService` sets `Lighting.Brightness` every Heartbeat; `Atmosphere.Apply` set base grade once. Starts **raining immediately**.
- **Expected:** One owner of Brightness; rain not permanent dusk spam; no strobe on floor entry (lamps already softened — good).

### 12. Second rider during pick gets **zero** feedback — **medium**

- **Repro:** Leader in cabin with modal open; teammate steps in before size chosen.
- **Suspect:** `LiftService.tick` — while `capacity == nil` and `pendingLeader` set, other players inside are ignored (no toast, no “лідер обирає”).
- **Expected:** UX read-only “Лідер обрав: N” / “обирає…”.

### 13. Electronics behind rubble: prompt **disabled** (no “спочатку завал” affordance) — **medium**

- **Repro:** If activation distance reaches a gated node, prompt is off (`setPrompt(false, needRubble…)` never shows because Enabled=false).
- **Suspect:** `WorldVisualsController.applyResource`.
- **Expected:** False `res.blocked` toast = **fixed-in-code**. Prefer visible disabled/relabeled prompt or only nodes behind collision. Don’t reintroduce Collect→«Прохід завалено».

### 14. Publish / tree desync — **blocker** (process)

- **Repro:** Open `/workspace` or store `artifacts/places` → `Build = b15`. GitHub + notes = b18 / lobby v28.
- **Suspect:** Cloud agent workspace not fetched; artifacts not refreshed after inject.
- **Expected:** Coder works from `cb58a55+`; regenerate `.rbxlx` before next publish; print build string on join.

### 15. Hunger drain while lost on F1 — **medium** (minute-1 stack)

- **Repro:** Wander tutorial ~6+ min without Food → hunger damage while still learning.
- **Suspect:** `GameConfig` hunger drain; stacks with any remaining marker/onboarding miss.
- **Expected:** Softer drain until tutorial.done, or earlier Food on scrap path.

---

## Prior gap-report blockers — still in code?

Review target: **`cb58a55`**, not workspace b15.

| ID | Was | In `cb58a55`? | Notes |
|----|-----|---------------|-------|
| G1.1 live `n/m` | blocker | **fixed-in-code** | `HUDController.objectiveLine` + `tutorial.scrapProgress` / `elecProgress` |
| G1.2 marker→stairs | blocker | **fixed-in-code** | `nearestResource` on steps 2/5 |
| G1.3 idle 45s ping | high | **fixed-in-code** | `ObjectiveMarkerController` idle ping |
| G1.4 elec nav | high | **fixed-in-code** | marker→electronics |
| G2.1 elec «завалено» | blocker | **fixed-in-code** | prompt gated; `res.needRubble`; room fallback no longer dumps to open floor |
| G2.2 client-only rubble | blocker | **fixed-in-code** | `openRubblePart` server CanCollide + `ClearedShared` |
| G2.3 shared hold bar | high | **still present** | see Top #9 |
| G3.1 no drop | blocker | **fixed-in-code** | `DropService` + long-press (buggy activate — Top #3) |
| G3.2 personal chest | blocker | **fixed-in-code** | `teamStorage` in `StorageService` |
| G3.3 downed marker | high | **fixed-in-code** | `DownedMarkerController` |
| G3.4 per-player loot | high | **still present** | Top #5 |
| G4 zombie respawn | blocker | **fixed-in-code** | no timed respawn; `floorCleared` + tokens |
| G5 lifts 2–6 / signs | high | **partial** | modal 1–6; signs stripped to ЛІФТ; ENTER residual Top #1–2 |
| G6.1 tokens missing | high | **partial** | earn exists; **no HUD/sink** Top #4 |
| G6.2 heal craft | high | **fixed-in-code** | Bandage Scrap4; Medkit Scrap6+Elec2 |
| G8 melee mobile | high | **partial** | Animator path; **JOIN-BLOCKED** Top #7 |
| G9 atmosphere | medium | **mostly fixed-in-code** | footing + city ground; botanical toned down; weather exists (Top #11) |

---

## Elevator ENTER + modal 1–6 (dedicated)

| Check | Code (`b18`) | Live |
|-------|----------------|------|
| Zone size / non-blocking | `9×9×9`, CanCollide/Query/Touch false | **JOIN-BLOCKED** |
| No fullscreen Active dimmer | dimmer inset, `Active=false` | **JOIN-BLOCKED** |
| Modal 1–6 + Solo | yes (`MinPartySize=1`) | **JOIN-BLOCKED** |
| `OpenLiftSizePick` + attributes | both | race → Top #1 |
| Solo short countdown | `fullCountdown` on size==1 | **JOIN-BLOCKED** |
| Old 1/2/4/6 world signs | gone; billboard is `n / capacity` only | **JOIN-BLOCKED** |
| Hint copy | 1–6 | OK vs current product, not vs UX §2 |

**Reported live ENTER break** matches b17 (oversized zone + Active fullscreen). b18 addresses that class. **Do not ship another lobby without a phone walk-in test.** Residual Top #1–2 are enough to recreate “can’t use lift” reports.

---

## Cross-platform

| Item | Status |
|------|--------|
| Mobile prompts (ProximityPrompt + InteractionController touch button) | Present; **JOIN-BLOCKED** readability |
| Melee self anim | Local Animator play — likely OK on phone |
| Melee spectator anim | Server play — **JOIN-BLOCKED** |
| Lift modal vs thumbstick | Improved vs b17; countdown + sticky modal still risks |
| Drop on touch | Exists; **double-fire** Top #3 |
| Downed edge chevron | Sized ~120×40; may crowd safe area — live check |
| Console focus on lift modal | **JOIN-BLOCKED** |

---

## Minute-1 quit smells (updated)

Still real on `cb58a55`:

1. Lobby modal race / bottom countdown → bounce before tower.  
2. Tokens toast with nowhere to look / spend → “why replay?”  
3. Co-op loot duplication → squad hook soft.  
4. Drop long-press misfires → bandage yeeted then wrong action.  
5. Toast pile (loot + tokens + party.stored).  
6. Hunger while lost.  
7. Instant rubble (better than invisible wall, still not the designed beat).  
8. Weather always-on rain at start — tone OK until it feels like a particle tax.

Mostly dead vs first gap-report (if Published matches GH): stuck `0/3`, marker→stairs, elec «завалено», ghost rubble, zombie return, no drop/chest/marker.

---

## JOIN-BLOCKED checklist (human / Studio)

- [ ] Lobby v28+: walk into lift on **phone** — enter, pick 1, pick 4, cancel by walking out, re-enter  
- [ ] Modal never traps touch; countdown not over jump  
- [ ] Tower: scrap HUD `1/3` ticks; marker on scrap not stairs  
- [ ] F1 rubble → walk through on **two clients**  
- [ ] Gated electronics: no «Прохід завалено»  
- [ ] Clear floor 1 → AFK 90s → no respawn  
- [ ] Mobile melee self + spectator  
- [ ] Long-press drop without accidental use  
- [ ] Downed marker dir + meters on phone  
- [ ] Pitch-down skyline footing  
- [ ] Confirm on-screen build string = `b18 · elevator-entry-restore`

---

## Refs

- GitHub tip: `cb58a55` — https://github.com/popovskyy/roblox_skyline  
- [gap-report.md](./gap-report.md) (append Pass 2026-10-17 b)  
- [bug-backlog.md](./bug-backlog.md) — treat [x] as “attempted”, not “verified live”  
- internal: `elevator-entry-restore-b18.md`, `elevator-modal-b17.md`
