# SkylineZero — Brainstorm Hooks

Wild but buildable retention ideas. Tone: Last-of-Us scarcity, not tycoon spam. North star: **затягує, не бісить**. Aligned with [game-design-loops.md](./game-design-loops.md) + [first-session-ux.md](./first-session-ux.md).

**Rule:** no second objective in first ~180s; no tip spam; no respawn-after-clear; wider floors stay optional wings, not homework.

---

## Ranked ideas (impact × effort)

Scale: **Impact** / **Effort** = H high · M mid · L low. Sorted best bang-for-buck first.

| # | Idea | Impact | Effort | Why it hooks |
|---|------|--------|--------|--------------|
| 1 | **Near-miss end screen** | H | L | Die / extract with pack ≥70% full or roof &lt;1 floor away → “Ще трохи…” + missed tokens. Instant “one more.” Already in loops §5 — ship it. |
| 2 | **Floor heartbeat** | H | L | Uncleared floor: distant moan / glass tick every ~20–30s. Cleared: dead quiet. Makes no-respawn *feel* like ownership without new systems. |
| 3 | **Drop-under-fire beat** | H | L | When ally downs &lt;30m and you hold a bandage/med: soft pulse on drop UI once. Teaches squad dependency without a tutorial wall. Ships with chest/drop backlog. |
| 4 | **Rare stash flash** | H | M | 1/floor chance: sealed office safe / crash-cart — 3s crowbar, dumps electronics + 1 bandage. Whole squad hears metal screech. Dopamine spike, not drip. |
| 5 | **Elevator “last call”** | H | M | After clear/quota: cabin lights amber, 45s soft countdown hum. Leave early = bank floor; stay = optional wing loot. Creates leave/greed tension. |
| 6 | **Shared crowbar push** | M | L | 2 players on same rubble = shared break bar (loops already). Add one dry line toast once: “Разом швидше.” Squad dependency without new craft. |
| 7 | **Broken radio ping** | H | M | Random mid-run: static VO once — “…floor 12… still warm…” Points toward a marked room with 1 rare mat. Exploration bait; mute if player is in tutorial. |
| 8 | **Roof weather beat** | H | M | First roof touch: wind swell + ash drift + +25 tokens (loops). Session climax you *hear*. Don’t gate tutorial on weather. |
| 9 | **Downed gear gift** | H | M | Downed player’s backpack spills 1–2 slots as party piles (TTL 60s). Alive mates scramble to recover meds. Brutal, fair, co-op sticky. |
| 10 | **Floor event: Blackout** | H | H | Lights die 8–12s on mid+ floors; flashlight / glow sticks / zombie eyes only. Then power returns with a bang. Memorable; needs art+audio. Skip tutorial plate. |
| 11 | **Floor event: Fire door** | M | M | One wing seals for 60s after alarm; team must regroup via other path. Forces formation without soft-locking elevator (call pad stays open). |
| 12 | **Scout flare** | M | M | Craft/find: throw → marks nearest electronics + downed allies through walls 8s. Survival gadget, not DPS stick. |
| 13 | **Quiet step pads** | M | M | Rare loot: tape soles — 1 floor of reduced aggro radius. Feels TLOU; expires so not pay-to-win forever. |
| 14 | **Height ledger** | M | L | End screen: personal best floor + squad best this week (local party, not global leaderboard yet). Soft ego chase. |
| 15 | **Echo cache** | M | H | Leave a marked “we were here” crate for *next* run of same party (1 scrap crumb + note). Meta ghost — cool, defer until stash is solid. |

---

## Floor events (mid+ only)

| Event | Beat | Annoyance guard |
|-------|------|-----------------|
| **Blackout** | Dark spike → panic loot/fight → lights on | Never on tutorial path; telegraph 2s audio before lights die |
| **Fire door** | One wing locks briefly | Elevator + critical path never locked; marker shows alternate |
| **Safe flash** | Rare sealed loot room | Max 1/floor; empty husk if rolled again same visit |
| **Radio ping** | Static points to a room | Optional; ignore = no punish |

Wider-floor note: events live in **wings**, not on the scrap corridor. Critical path stays short (loops §1).

---

## Rare loot moments

| Moment | Feel | Build note |
|--------|------|------------|
| Sealed safe / crash-cart | Whole squad converges | Shared break + loud audio |
| Elite corpse “dog tag” | 1 electronics + story scrap | Only after elite kill; no farm loop |
| Roof first-touch cache | Vista + token spike | Once per successful roof |

Avoid: rainbow crates, timed robux chests, daily login spam.

---

## Squad dependency beats

1. Revive needs bandage/med from chest or ground drop.  
2. Drop pulse when ally is down nearby.  
3. Dual crowbar on rubble.  
4. Downed backpack spill (idea #9).  
5. Elevator capacity 2–6 already forces “wait for the slow one.”

Never: forced trade menus, vote-kick mid-floor, or “carry my stuff” chores in first session.

---

## “One more run” hooks (minimal set)

| Hook | Trigger | CTA |
|------|---------|-----|
| Near-miss | Pack full / roof close | `Знову` |
| Height ledger | New PB floor | `Ще вище` |
| Shared chest half-full | End with unused scrap | “Chest still hungry” one line |
| Radio unfinished | Ignored ping this run | Soft “signal still out there” — once |

End screen stays: floors · tokens · best loot · **Знову / Лобі**. No essay.

---

## Survival gadgets (TLOU, not tycoon)

Craft or rare find. **Consumable or 1-floor**. No upgrade trees, no 40-item belt.

| Gadget | Fantasy | Loop fit |
|--------|---------|----------|
| **Scout flare** | See through walls briefly | Find electronics / downed |
| **Quiet step pads** | Sneak one floor | Scarcity decision |
| **Glow stick cluster** | Light a blackout wing | Pairs with Blackout event |
| **Crowbar wrap** | +faster rubble once | Shared break synergy |
| **Field bandage kit** | Craft 2 bandages cheaper once | Heals stay craft-primary |

**Don’t:** auto-turrets, coin generators, pet drones, permanent +damage passives.

---

## Conflict flags

| Idea | Conflicts with | Fix / defer |
|------|----------------|-------------|
| Blackout / Fire door | Clearer onboarding | **Mid+ floors only**; mute during tutorial.1–3 |
| Elevator last-call countdown | Wider plate “optional wings” | Countdown starts only after quota/clear; wings stay optional greed |
| Radio ping objective | “One objective line” rule | Never replace HUD objective — ambient audio + optional world mark only |
| Echo cache (cross-run) | Team chest not shipped | Defer until backlog chest/drop done |
| Quiet pads permanent | Fairness / Robux creep | Expire after 1 floor always |
| Height global leaderboard | Onboarding clarity, toxicity | Party-local PB first |
| Extra floor events density | 240 plate + ~3 min floor | Cap **1 event / floor**; never on scrap corridor |

---

## Premium survival fantasy (for Economist — price elsewhere)

Hand-off only. No shop design here. See sibling `docs/economy-robux.md`.

1. **Ash-filter respirator** — cosmetic breath + soft muff on blackout audio; no stat advantage. Fantasy: you look like you survived the first week.  
2. **Emergency satchel skin** — team-chest / backpack visual (patched canvas + amber buckle). Same slots; squad reads “prepared.”  
3. **Signal flare pack (3)** — consumable: same as Scout flare craft, but pre-bundled; **does not** out-DPS free craft, only skips scrap cost for that run.

Economist: price vs token sinks; keep craft path for free players so premium is convenience/identity, not a wall.

---

## Ship order (suggestion)

1. Near-miss end screen + floor heartbeat + drop-under-fire (rides existing backlog).  
2. Rare stash flash + dual crowbar toast.  
3. Elevator last-call + roof weather beat.  
4. One mid-floor event (Blackout **or** Fire door — pick one first).  
5. Scout flare / quiet pads after craft station exists.  
6. Echo cache last.

Coder still owns backlog order (elevators → rubble/chest → counters → no-respawn). Hooks above ride those rows; don’t invent parallel meta.
