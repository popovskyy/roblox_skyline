# SkylineZero — Gap Report (ruthless)

**Дата:** 2026-10-17  
**Метод:** static playtest проти `artifacts/places/*.rbxlx` + звірка з `first-session-ux.md`, `game-design-loops.md`, `bug-backlog.md`. Live Studio/device прогін тут не крутився — дірки нижче підтверджені кодом; severity = impact на first-session quit.

**Вердикт:** зараз гра **вчить погано і карає за спробу кооперативу**. Хто зайшов без Discord — з високою ймовірністю залипне на даху, збере scrap без dopamine-лічильника, впреться в «Прохід завалено» на електроніці, зачистить поверх і отримає зомбі назад через ~45с. Це не «шорсткості» — це quit-in-minute-1 fuel.

Places: `artifacts/places/SkylineZero.rbxlx`, `artifacts/places/SkylineZero_Lobby.rbxlx`.

---

## Severity legend

| Level | Meaning |
|-------|---------|
| **blocker** | Ламає first-session loop або кооп-хук; реліз/плейтест без фіксу = масовий leave |
| **high** | Сильно бісить / ламає backlog acceptance; грають далі з tilt |
| **medium** | Тон, баланс, polish; накопичується в «мех» |

---

## G1 — Онбординг: зайшов — хуй зрозумієш що робити

### G1.1 Live loot counter відсутній (HUD бреше тишею) — **blocker**

- **Що:** UX вимагає `Металобрухт 0/3` → тики на кожен пікап. Код показує лише статичний locale `tutorial.2` («збери 3…») без `n/m`. Пікап дає toast `Зібрано`, але objective strip не рухається → гравець відчуває «застрягло 0/3» / «нічого не сталось».
- **Repro:** Новий гравець → термінал → вниз → зібрати 1 scrap → дивись HUD objective. Очікування: `1/3`. Факт: той самий текст кроку.
- **Suspects:** `TutorialService` (steps без progress fields), `HUDController.onState` (`Lang.T("hud.objective", { ref = s.tutorial.text })`), `Locale` (`tutorial.2` / немає `tutorial.scrapProgress`).
- **Vs docs:** `first-session-ux.md` §3; `game-design-loops.md` §4 aha «counter moves».

### G1.2 Маркер на кроці луту веде на СХОДИ, не на scrap/electronics — **blocker**

- **Що:** Step 2 і step 5 target = `Stairwell/Ramp0_Down`. Гравець вже на тех. поверсі — стрілка тягне назад до сходів. Немає marker/outline на найближчий scrap. First-session dopamine path мертвий.
- **Repro:** Дійди до floor 1 на tutorial.2 → маркер все ще на сходах. Те саме на tutorial.5 (electronics).
- **Suspects:** `ObjectiveMarkerController.targetFor` (`step == 2 or step == 5` → `STAIRS`).
- **Vs docs:** UX §1 «nearest scrap soft outline»; loops «loot glow».

### G1.3 Немає idle soft-ping / самоведення на даху — **high**

- **Що:** UX: idle 45s на даху → один soft ping на terminal. У коді Intro/Tutorial цього throttle-ping не видно як окремої поведінки; якщо гравець пропустив intro card — легко freeze.
- **Repro:** Заспавнись, стій 45–60s без input. Чи є рівно один audio+bob на terminal? Якщо ні / якщо спам — FAIL.
- **Suspects:** `IntroController`, `TutorialController`, `ObjectiveMarkerController` (немає idle timer).

### G1.4 Tutorial step 5 «Find 4 electronics» без навігації до нод — **high**

- **Що:** Після chest build ціль electronics, маркер = stairs. Electronics розкидані / частина за rubble / частина в toxic (F3). Новачок блукає.
- **Repro:** Доведи tutorial до step 5 → слідуй тільки маркеру 2 хв.
- **Suspects:** `ObjectiveMarkerController`, `WorldBuilder` floor electronics layout, `TutorialService` step 5.

---

## G2 — Завали / електроніка (беклог #2) — підтверджено в коді

### G2.1 Електроніка показує Collect → «Прохід завалено» — **blocker**

- **Що:** Ноди з `RequiresRubble` лишають ProximityPrompt увімкненим. `Collect` → `CheckAccess` → `res.blocked` = **«Прохід завалено»**. Гравець чесно тицяє електроніку і чує про завал. Це і є репорт з беклогу.
- **Repro:** Floor 1, НЕ чіпай `F1_Rubble`. Підійди до `F1_Elec_2` / `F1_Elec_3` у roomPP (або наскільки prompt дістає). Trigger Collect → toast «Прохід завалено».
- **Suspects:** `ResourceService.CheckAccess` / `Collect`; `WorldVisualsController.applyResource` (не гасить prompt при uncleared RequiresRubble); `Locale["res.blocked"]`; `WorldBuilder` F1_Elec_2/3.
- **Fix direction (для кодера, не тут):** disable/relabel prompt until rubble cleared; окремий ключ «Спочатку розбери завал», не generic blocked.

### G2.2 Завал «розбирається» тільки візуально на клієнті — серверна колізія лишається — **blocker**

- **Що:** `ClearRubble` лише ставить per-player `cleared[rubbleId]=true` + StateSync. `WorldVisualsController` ховає part і ставить `CanCollide=false` **локально**. Серверний main rubble part лишається collidable. Результат: «натиснув — зникло — вперся в невидиму стіну / rubberband» = «завал неможливо розібрати».
- **Repro:** Clear `F1_Rubble` → спробуй фізично зайти в room. Спостерігай rubberband / block. Другий клієнт: завал досі solid і visible.
- **Suspects:** `ResourceService.ClearRubble`; `WorldVisualsController.applyRubble`; відсутність server-side collision/replicate clear у `WorldBuilder` rubble parts.
- **Co-op grief:** A «відкрив» прохід для себе візуально; B стоїть перед стіною. Squad hook мертвий.

### G2.3 Rubble progress не shared + миттєвий clear (не 3–5s hold) — **high**

- **Що:** Design: shared progress bar, 3–5s crowbar hold, 2 players faster. Code: instant clear, per-player state, no hold channel.
- **Repro:** Два гравці б’ють один завал одночасно — кожен чистить «для себе»; немає спільного бара.
- **Suspects:** `ResourceService.ClearRubble`; `InteractionService` / prompts (`HoldDuration` у WorldBuilder ~1.2 на prompt, але clear logic instant on trigger).

### G2.4 F4 rubble gated Generator+Crowbar — OK, але copy може читатись як «зламаний завал» — **medium**

- **Repro:** До Generator спробуй `F4_Rubble_*` → `res.zoneLocked`. З ломом без Generator — те саме. Переконайся що UI не виглядає як softlock.

---

## G3 — Кооп системи, яких немає (або анти-дизайн)

### G3.1 Немає drop айтемів з інвентаря — **blocker** (для squad hook)

- **Що:** Remotes: є `StorageTransfer`, немає Drop. Є лише death backpack, і він **personal** (`backpack.notYours`). Design/UX: party drop TTL 120s для rescue under fire.
- **Repro:** Відкрий inventory у коопі → шукай Drop / long-press. Немає → не можна кинути bandage downed тіммейту.
- **Suspects:** `InventoryController`, `InventoryService`, `RemoteNames`, `PlayerLifecycleService.dropBackpack` (death-only).

### G3.2 Скриня персональна; PartyService це прямо каже — **blocker**

- **Що:** `PartyService` header comment: *inventory, storage and resource nodes stay personal*. `StorageService` пише в `data.storage` гравця. UX хоче `СКРИНЯ КОМАНДИ` + shared Total для квесту.
- **Repro:** A deposit Scrap → B відкриває chest → порожньо / свій інвентар. Quest Total у B не росте від луту A.
- **Suspects:** `StorageService`, `PartyService`, `PlayerDataService`, UI strings `ui.backpack` / storage (не team).

### G3.3 Немає teammate downed marker (dir + meters) — **high**

- **Що:** Downed: toast `downed.someone` + revive prompt на тілі. Немає screen-edge chevron + `45 м` як у UX §4. На мобайлі downed тіммейт = зник у тумані.
- **Repro:** 2 клієнти; A downed за рогом → B на іншому кінці поверху. Чи є edge marker? Ні.
- **Suspects:** `DamageService` (notify only), `CombatController` (own downed UI), відсутній DownedMarker controller; `Locale` має `marker.here` але не `marker.downed` usage.

### G3.4 Per-player loot nodes у коопі = «ми не в одній грі» — **high**

- **Що:** `ResourceService` comment: co-op players never take each other's loot. Дизайн-хук «разом зачистили / поділили» слабшає; плюс rubble personal (G2.2) = розсинхрон світу.
- **Repro:** A лутає всі F1 scrap → B бачить повні ноди і лутає ті самі. Світ бреше про scarcity.

---

## G4 — Зомбі респаун після зачистки — **blocker**

- **Що:** На `Humanoid.Died` завжди `task.delay(Z.RespawnSeconds, spawnZombie, level)` з `RespawnSeconds = 45`. Немає floor-clear flag. Зачистив → через ~45с знову м’ясо. Карає commitment; loops doc §3 прямо забороняє.
- **Repro:** Вбий усіх на floor 1 → стій 60–90s на тому ж поверсі → нові зомбі. Повтори на floor 2–4.
- **Suspects:** `ZombieService` Died handler; `GameConfig.Zombie.RespawnSeconds` / `PerFloor`.

---

## G5 — Ліфти / лобі vs беклог #1 — **high**

### G5.1 Немає діалогу 2–6; фіксовані кабіни 1 і 4

- **Що:** `PlacesConfig.Lifts`: Solo capacity **1**, GroupA/B/C capacity **4**. Немає UI вибору 2–6. Countdown стартує від першого rider.
- **Repro:** Зайди в Solo lift → capacity 1/1. Group → max 4. Немає панелі «Скільки вас іде?».
- **Suspects:** `PlacesConfig`, `LiftService`, `LobbyWorld.buildLift`, `LobbyClient`; Locale `lobby.liftSolo` / `lobby.liftGroup` (ключі ще живі).

### G5.2 Старі соло/група семантики + hint

- **Що:** Solo accent cyan vs group amber; hint досі «груповий ліфт». Беклог: прибрати «1 соло / 2 / 4 / 6» chrome. У цьому білді числові world-signs 2/6 можуть бути вже зрізані, але **модель кабін 1+4** = той самий UX-борщ.
- **Repro:** Пройди лобі як новачок: чи очевидно що робити і який розмір партії?

---

## G6 — Survival / loot loop gaps vs `game-design-loops.md`

### G6.1 Token economy відсутня повністю — **high** (design/backlog gap)

- **Що:** У `GameConfig` / services немає player Tokens, kill payout, floor clear bonus, roof +25. Слово «token» у коді = internal downed token / tooltip token. Беклог «менше видачі» **немає що нерфити** — системи немає. Маркетинг/meta spend = діра.
- **Repro:** Заверши floor / roof → шукай token counter / payout. Немає.
- **Suspects:** відсутній модуль; `MonetizationConfig` (Robux), не meta tokens.

### G6.2 Heal craft не збігається з design — **high**

- **Що:** Design: Bandage = Scrap 4; Medkit = Scrap 6 + Electronics 2. Code recipes: Bandage = **Food 1 + Scrap 1**; Pipe; Machete. **Medkit не крафтиться.** Floor loot дає Bandage/Medkit RNG. First downed без Food = drought.
- **Repro:** Workbench після tutorial scrap return → що можна зкрафтити? Чи є Medkit?
- **Suspects:** `GameConfig.Recipes`, `CraftService`, `ItemDefinitions`.

### G6.3 Hunger drain під час навчання — **medium**

- **Що:** `HungerDrainBelow = 0.28` ≈ 6 хв до empty нижче даху. Новачок, що блукає через G1, паралельно отримує hunger warning/damage. Annoying stack.
- **Repro:** Блукай 6–8 хв на floor 1 без Food.

### G6.4 Empty / uneven floors — **medium**

- **Що:** F2 майже лише scrap (мало electronics); F3 electronics у toxic; F1 має tutorial density. Ризик «сірий поверх» якщо scrap уже depleted (і ResetNodesOnRoofReturn refill тільки після даху — OK) але clear→wait через zombie respawn робить floor feel restless, не owned.
- **Suspects:** `WorldBuilder` floor populate; `ZombieService`.

### G6.5 Elevator-in-tower progression відсутній як loop beat — **medium**

- **Що:** Loops doc говорить elevator call після clear/quota. У tower прогрес = stairs між floors + roof return. Немає «elevator light amber» beat. Не блокер tutorial, але loop rhythm з доки не зібраний.

---

## G7 — UX gaps vs `first-session-ux.md` (коротко)

| UX requirement | In build? | Gap |
|----------------|-----------|-----|
| Live `n/m` in objective | No | G1.1 |
| Scrap outline + marker | Marker wrong target | G1.2 |
| Lift dialog 2–6 | No | G5 |
| Remove liftSolo/Group chrome | Keys remain; cabin model 1/4 | G5 |
| Team chest label + shared | Personal storage | G3.2 |
| Item drop discovery toast | No drop | G3.1 |
| Downed marker dir+m | No | G3.3 |
| Max 1 toast / 15s | Needs live verify | open |
| Idle 45s terminal ping | Not found | G1.3 |

---

## G8 — Крос-платформа melee anim — **high**

- **Що:** Server swing створює classic `StringValue toolanim=Slash` у Tool. Це залежить від default Animate. На частині клієнтів (часто mobile/tablet / custom animate) slash не грає; PS5/default часто OK — збігається з репортом «видно лише на PS5».
- **Repro:** Mobile swing ×10; PC spectator дивиться на руки. Немає slash track → FAIL.
- **Suspects:** `CombatService.swing` (toolanim); `CombatController` (touch hit button only fires remote); немає replicated AnimationTrack для viewers.

---

## G9 — Атмосфера (беклог) — **medium** (quit-lite, tone break)

### G9.1 «Ботанічний сад» на скайлайні — by design у коді

- **Що:** `Scenery` прямо: *ruined high-rises taken over by plants*, green roof + trees на crown. Беклог хоче TLOU-похмурість без botanical vibe.
- **Suspects:** `Scenery.Dress` / green roof block; `Atmosphere` warm golden ClockTime 16.4 (не night cycle).

### G9.2 Немає динамічної погоди / день-ніч

- **Що:** `Atmosphere` ставить фіксований ClockTime; немає rain system.
- **Suspects:** `Atmosphere.lua` only.

### G9.3 Skyline «літає» при погляді вниз — **medium** (потребує live camera check)

- **Що:** `Scenery.Skyline` ставить ruins на Y=0 relative center, не на ground plane даху вежі (tower RoofY=396). Ймовірний floating towers artifact при pitch-down з даху.
- **Repro:** Стань на tower roof → дивись вниз/в далечінь на skyline.
- **Suspects:** `Scenery.Skyline`, `WorldBuilder` roof placement, lobby `LobbyWorld` skyline call.

---

## G10 — Minute-1 quit list (без пріоритету беклогу — чистий feel)

1. Немає live `n/m` → лут не винагороджує мозок.  
2. Маркер веде не туди.  
3. Електроніка каже «завалено».  
4. Завал «зник» але стіна лишилась / тіммейт не проходить.  
5. Зачистив поверх — зомбі повернулись.  
6. Тіммейт downed — немає маркера, немає drop хілу, скриня не спільна → game over відчувається несправедливо.  
7. Лобі: соло/4 без вибору 2–6 — плутанина хто з ким їде.  
8. Mobile: б’єш — рук не видно.  
9. Немає token chase / medkit craft → після першого вайпу «навіщо ще раз?».  
10. Скайлайн-сад ламає тон, який продає маркетинг.

---

## Concrete script suspects (spot-check index)

| Area | Scripts (in place ModuleScripts) |
|------|----------------------------------|
| Lifts | Lobby: `LiftService`, `LobbyWorld`, `PlacesConfig`, `LobbyClient`, `Locale` |
| Rubble / electronics | `ResourceService`, `WorldBuilder`, `WorldVisualsController`, `InteractionService`, `Locale` |
| Quest HUD | `TutorialService`, `HUDController`, `ObjectiveMarkerController`, `Locale` |
| Zombie respawn | `ZombieService`, `GameConfig.Zombie` |
| Team chest / drop | `StorageService`, `PartyService`, `InventoryController`, `RemoteNames` (missing Drop) |
| Downed marker | `DamageService`, `CombatController` (gap: no marker module) |
| Melee anim | `CombatService`, `CombatController` |
| Heal/tokens | `GameConfig.Recipes`, `CraftService`; tokens **missing** |
| Atmosphere | `Atmosphere`, `Scenery` |

---

## Рекомендований порядок фіксу для first-session fun

Беклог лишається законом порядку для кодера. З точки зору **quit rate**, після ліфтів (#1) найкритичніше пакетом #2+#3+#4:

1. Ліфти 2–6 (беклог)  
2. Rubble server-clear + electronics prompt fix + drop + team chest  
3. Live `n/m` + marker→loot + downed marker  
4. Zombie no-respawn after clear  
5. Потім atmosphere / onboarding polish / med craft / tokens / mobile anim  

Якщо зробити тільки атмосферу раніше за counter+rubble — гра залишиться красивою і все одно бісить.

---

## Посилання

- [test-plan.md](./test-plan.md) — чеклісти + adversarial §5  
- [bug-backlog.md](./bug-backlog.md)  
- [first-session-ux.md](./first-session-ux.md)  
- [game-design-loops.md](./game-design-loops.md)  

---

## Pass 2026-10-17 b (nuance / pre-publish)

**Source:** GitHub `cb58a55` (`b18 · elevator-entry-restore`). Live PRIVATE — join not available to tester. Workspace/artifacts still on **b15** — ignore for this pass. Full write-up: [nuance-test-pass.md](./nuance-test-pass.md).

### Still open (do not mark backlog done from checkboxes alone)

| Sev | Item | Suspect |
|-----|------|---------|
| blocker | Lift modal can stick open via late `OpenLiftSizePick` after walk-out (ENTER class) | `LobbyClient`, `LiftService.beginPick` |
| high | Lift countdown panel over mobile touch controls | `LobbyClient` `LiftCountdown` |
| high | Long-press drop also fires slot `Activated` | `InventoryController` |
| high | Tokens toast with no HUD / sink | `TokenService`, missing HUD |
| high | Per-player resource nodes (co-op scarcity lie) | `ResourceService`, `PartyService` |
| high | Product 1–6 Solo vs UX 2–6 | `PlacesConfig.MinPartySize` |
| high | Melee mobile/spectator — code path only | `CombatService` / `CombatController` — **JOIN-BLOCKED** |
| medium | Drop pickup not party-gated | `DropService.Pickup` |
| medium | Rubble no shared 3–5s progress bar | `ClearRubble`, prompt Hold 1.2 |
| medium | No toast 15s throttle | HUD / lobby toast |
| medium | Weather Brightness fights Atmosphere; rain starts on | `WeatherService` |
| medium | Second rider silent during size pick | `LiftService.tick` |
| process | Publish/tree desync b15 workspace vs b18 GH | fetch + reinject places |

### Closed in `cb58a55` vs original G-list (still need live smoke)

G1.1 live `n/m`, G1.2 marker→loot, G1.3 idle ping, G2.1 false «завалено», G2.2 server rubble collision, G3.1 drop exists, G3.2 team chest, G3.3 downed marker, G4 no zombie respawn after clear, G6.2 bandage/medkit recipes, G9 skyline footing / weather module present.

Elevator: b17 ENTER break explained and addressed in b18 (zone + non-Active dimmer); **residual races above replace it as the lobby ship gate**.
