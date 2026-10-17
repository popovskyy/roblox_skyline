# SkylineZero — First Session UX

> **Status (17.10, build b34):** Already in the game: lift party size 2–6 (solo lift separate), live goal
> counter, downed-teammate marker + edge arrow, shared team chest/buildings, hold-to-drop, idle roof nudge
> (SFX + marker bob, **no text**), objective marker prefers nearest scrap/electronics on-floor (stairs from
> roof / when floor empty). HUD declutter (b34): **no** `tutorial.new` / `res.collected` toast spam — ЦІЛЬ
> strip is the teacher. Do **not** add the old “party.stored / toast.dropHint” tip spam from §5.
>
> Imported from the Cursor team's notes. Where this doc and the code disagree, the code and `GameConfig` win.


Buildable UX for coder. Locale: **UK primary**, RU/EN parity (existing `Locale` keys). Tone: tense Last-of-Us post-apoc — amber/rust HUD, quiet radio feel. No purple UI, no tip spam, no emoji clusters.

**Aligned with** [game-design-loops.md](./game-design-loops.md) (loot / survival addiction loops — sibling Game Designer). First minutes must *teach the loop by doing it once*, not explain it.

North star check: every element answers “що далі?” without yelling. Pain to kill: spawn → freeze. Win: by ~180s the player has looted, felt progress (`n/m`), and knows the next beat (return / stash / go deeper).

---

## 1. First 60–180 seconds (tower spawn)

**One loop rehearsal:** roof orient → descend → loot (counter ticks) → return. That is the addiction seed from the loops doc; UX only makes each beat obvious.

**Keep existing tutorial steps 1→5**, but make the first three minutes self-steering.

| t | Player sees | Action | Loop beat |
|---|-------------|--------|-----------|
| 0–8s | Intro card (existing `intro.*`) auto-dismisses or Continue | No second modal | Hook / stakes |
| 8–20s | HUD objective only: `tutorial.1` + world marker ▼ on Emergency Terminal | Walk to terminal, Read | Safe hub → why leave |
| ~20–40s | After note close: ЦІЛЬ swaps to `tutorial.2` (**no** `tutorial.new` toast); marker → stairs (`СХОДИ ВНИЗ ↓`) | Stairs down | Commit to expedition |
| 40–120s | Objective shows live scrap: **Металобрухт 0/3** (see §3); nearest scrap gets soft outline + ProximityPrompt `Зібрати` | Loot 3 scrap on tech floor | Loot dopamine (`n/m` ticks) |
| 120–180s | On 3/3: pulse objective → `tutorial.3` + marker roof; no extra popups | Climb back | Return / bank the win |

**Rules**
- Max **1 toast every 15s**; objective line is the persistent teacher.
- No “How to play” re-show in tower if already seen in lobby.
- World signs stay industrial (`СХОДИ ВНИЗ ↓`, `ЛОМ`) — not floating tutorial badges.
- If player idles 45s on roof with step 1 incomplete: single soft ping on terminal (audio + marker bob), not text spam.
- Never block the loop with a second modal mid-loot; counter + marker only.

**Loot priority (tech floor):** scrap nodes first (glow rust/amber). Crowbar rubble only after scrap path is obvious or prompt needs crowbar. First session sells *collect → see number move → want more*, not combat tutorial.

---

## 2. Elevator player-count dialog (Lobby)

**Remove** world signs / lift labels: `1 соло`, `2`, `4`, `6`, and keys `lobby.liftSolo` / `lobby.liftGroup` as door chrome.

**One lift type.** Enter zone → leader opens compact panel (center-bottom, ~320×220, dark concrete + amber border).

```
ЛІФТ
Скільки вас іде?

[ 2 ] [ 3 ] [ 4 ]
[ 5 ] [ 6 ]

У ліфті 1 / 4
Старт через 18
```

| Element | Spec |
|---------|------|
| Buttons | 5 equal tiles, Oswald bold numbers; selected = amber fill, others = charcoal outline |
| Default | 4 (or current party size if already set) |
| Who picks | First rider = leader; others see read-only “Лідер обрав: N” |
| Solo | **No 1** — backlog is 2–6. Solo = play alone with capacity 2 empty seat, or separate “Один” text button under grid if product needs solo (prefer: allow start with 1 rider when countdown ends) |
| Countdown | Existing `lobby.countdown` / `lobby.riders`; full party → `fullCountdown` |
| Exit | Walk out = leave; panel closes |

**World chrome after change:** single sign per cabin door — `ЛІФТ` only. Lobby hint rewrite: step in, then pick size.

---

## 3. Quest loot counter (realtime)

HUD objective line format when step needs a counted resource:

```
Ціль: Електроніка 2/4
Ціль: Металобрухт 1/3
```

| Rule | Detail |
|------|--------|
| Source | `StorageService.Total` (inv + team chest) |
| Update | On every collect / transfer / drop / teammate deposit — same frame as state sync |
| Bug fix | Never stick at `0/3` after pickup; invalidate on `StateChanged` |
| Complete | Flash amber once → swap to next `tutorial.*` |
| Placement | Existing top objective strip; counter is **part of the same string**, not a second widget |

Keys: extend `tutorial.2` / `tutorial.5` to use templates `tutorial.scrapProgress` / `tutorial.elecProgress` (`%d/%d`), or compose client-side: `item.*.name` + ` %d/%d`.

---

## 4. Teammate death / downed marker (mobile)

For each **downed** teammate (not fully dead), living allies get a **screen-edge + world** marker.

| Spec | Value |
|------|-------|
| World | Billboard: amber `▼` + name (truncate 10) + `45 м` |
| Off-screen | Edge chevron pointing toward them; same `45 м` |
| Size | Min touch-safe: billboard ≥ 140×84 px equiv; distance text ≥ 18sp; chevron ≥ 36×36 |
| Color | Amber `255,196,64` on near-black stroke — match objective marker |
| Cap | Show closest 2 if many downed |
| Copy | Reuse `downed.someone` as one toast; marker uses `marker.downed` = `%s · %d м` |
| Hide | When revived, self, or >250 m |

No health bars on marker. No purple. Pulse gently 1 Hz when <30 m.

---

## 5. Shared team chest + item drop — discovery

**Team chest (after build / when exists)**
- Label above pad: `СКРИНЯ КОМАНДИ` (was personal vibe).
- First open per player: one footer line in storage UI — “Спільна для всієї групи”.
- Header: `Скриня команди %d / %d · рюкзак %d / %d`.
- When teammate deposits: tiny toast `%s поклав: %s` (throttle 3s).

**Item drop**
- Inventory: long-press / Drop action → world pile with prompt `Підібрати` + item name.
- First time player opens backpack in co-op: one toast “Можеш кинути річ на землю — тіммейт підбере”.
- Dropped pile: dull metal mesh, no loot-crate rainbow; lifetime visible only to party.

**Discovery path (no wiki):** objective still drives scrap → return → build chest; drop taught only when inventory full or first co-op session.

---

## 6. Visual / tone guardrails

- Palette: charcoal, rust, warm amber accent (existing Theme / Glow). Never purple/indigo gradients.
- Fonts: Oswald display + Montserrat body (already in Theme).
- Motion: marker bob, objective flash on progress, lift button select — that’s enough.
- Voice: short, dry, in-world (`Ціль:…`, terminal prose). Avoid “Nice job!”, checkmarks rows, coach marks.

---

## Copy strings (new / changed)

All keys: `{ uk, ru, en }`.

### Lobby lift
| Key | uk | ru | en |
|-----|----|----|-----|
| `lobby.liftTitle` | ЛІФТ | ЛИФТ | LIFT |
| `lobby.liftAsk` | Скільки вас іде? | Сколько вас идёт? | How many of you? |
| `lobby.liftPicked` | Лідер обрав: %d | Лидер выбрал: %d | Leader chose: %d |
| `lobby.hint` | Зайди в ліфт і обери розмір групи (2–6). | Зайди в лифт и выбери размер группы (2–6). | Step into the lift and pick party size (2–6). |
| `lobby.liftSign` | ЛІФТ | ЛИФТ | LIFT |

**Delete from world:** old `lobby.liftSolo`, `lobby.liftGroup` door labels; numeric “1 соло / 2 / 4 / 6” parts.

### Progress objectives
| Key | uk | ru | en |
|-----|----|----|-----|
| `tutorial.scrapProgress` | Металобрухт %d/%d | Металлолом %d/%d | Scrap %d/%d |
| `tutorial.elecProgress` | Електроніка %d/%d | Электроника %d/%d | Electronics %d/%d |

(`hud.objective` stays `Ціль: %s` wrapping the above.)

### Downed marker
| Key | uk | ru | en |
|-----|----|----|-----|
| `marker.downed` | %s · %d м | %s · %d м | %s · %d m |

### Team chest + drop
| Key | uk | ru | en |
|-----|----|----|-----|
| `ui.teamStorage` | Скриня команди | Сундук команды | Team chest |
| `ui.teamStorageHeader` | Скриня команди %d / %d   ·   рюкзак %d / %d | Сундук команды %d / %d   ·   рюкзак %d / %d | Team chest %d / %d   ·   backpack %d / %d |
| `ui.teamChestHint` | Спільна для всієї групи. Натисни предмет, щоб перекласти. | Общий для всей группы. Нажми предмет, чтобы переложить. | Shared by the whole squad. Tap an item to move it. |
| `sign.teamChest` | СКРИНЯ КОМАНДИ | СУНДУК КОМАНДЫ | TEAM CHEST |
| `party.stored` | %s поклав: %s | %s положил: %s | %s stored: %s |
| `prompt.drop` | Кинути | Выбросить | Drop |
| `prompt.pickupDrop` | Підібрати | Поднять | Pick up |
| `toast.dropHint` | Можеш кинути річ на землю — тіммейт підбере. | Можешь выбросить вещь на землю — тиммейт подберёт. | Drop an item on the ground — a teammate can pick it up. |

### Keep as-is (already good)
`tutorial.1–7`, `intro.*`, `note.terminal.*`, `prompt.collect`, `downed.*`, `marker.here`, `lobby.countdown`, `lobby.riders`, `lobby.starting`.  
(`tutorial.new` Locale key may remain; **do not fire** — DIE’d in HUD declutter.)

---

## Coder acceptance (short)

1. New player completes one loot→return beat by ~180s without asking chat (loops doc: first addiction seed).  
2. Lobby: no old capacity signs; dialog picks 2–6 cleanly on mobile.  
3. Electronics/scrap objective ticks `n/m` live on every pickup.  
4. Downed ally: dir + meters readable on phone.  
5. Team chest labeled shared; drop discoverable once without a manual.
