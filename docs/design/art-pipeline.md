# SkylineZero — арт-пайплайн (Blender → Roblox)

Роль: Арт / 3D. Places зараз у Context: `artifacts/places/SkylineZero.rbxlx` (+ Lobby). У `/workspace` коду гри ще немає — після витягу coder’ом очікувати `places/*.rbxlx` або Rojo-дерево.

Секрети (Open Cloud тощо) лише в Context `secrets/` — ніколи в git і ніколи в арт-асети.

---

## 1. Інвентар: арт / аніми / VFX ↔ беклог

Джерело: [bug-backlog.md](./bug-backlog.md). Нижче — лише пункти з візуальним / анімаційним власником і де це живе в place (за знімком `SkylineZero.rbxlx`).

| Беклог | Симптом | Де в place (орієнтир) | Тип фіксу | Блокує ліфти/лут? |
|--------|---------|----------------------|-----------|-------------------|
| Освітлення поверхів: мерехтіння при вході; трохи темніше | Яскравий `Atmosphere.Apply` + багато `PointLight` / neon «Lit» на вежах; різкий контраст дах↔поверх | `Atmosphere` (ClockTime 16.4, Brightness 3, Bloom); `WorldBuilder` / `Scenery.Dress` lit windows; ліхтарі на поверхах | Тюнинг Lighting + менше/м’якше локальне світло; не перезапускати важкий relight на кожен вхід | Ні |
| Дах: прибрати «ботанічний сад»; похмурий пост-апок (TLOU) | Коментар у WorldBuilder: «Survivors' rooftop garden» — planters, bushes, 2 дерева, 14 grass, 10 vines; skyline crowns теж «green roof» | `WorldBuilder` roof block (~planters/trees); `Scenery.Grass/Bush/Tree/Vine` + crown у `Scenery.Dress` | Скоротити зелень на даху; суха/мертва палітра; залишити рідкий overgrowth по краях | Ні |
| Скайбокс / хмарочоси «літають» при погляді вниз | `Scenery.Skyline` ставить `Ruin` з `base.Y = 0`, висоти 250–470; без вуличної плити / щільного низу haze низ обрізається і читається як парячі башти | `Scenery.Skyline` / `Scenery.Building`; haze в `Atmosphere` | Ground/fog plate, подовжити низ корпусів або density/haze; не чіпати gameplay-колізії даху | Ні |
| Дощ + день/ніч | Зараз фіксований пізній день: `ClockTime = 16.4`, без weather loop | лише `Atmosphere.Apply` | Новий lightweight цикл (coder + арт-параметри); Partycle/дощ як VFX | Ні (після атмосфери v0) |
| Удари видно на mobile/tablet (зараз ок на PS5) | `CombatService` тригерить classic `toolanim` = `"Slash"` — залежить від Animate/Tool; touch UI (`AttackButton`) є, але анімація часто не грає на R15/mobile | `CombatService.swing`; клієнт `Attack` / `AttackButton`; SFX `Swing` уже окремо | Власні `Animation` (R15) + `Animator:LoadAnimation` на клієнті/реплікація; не покладатись на `toolanim` | Ні |

Пов’язані (не блокер арт-слайсу, але враховувати):

- Зброя вже вміє Blender-меші через `PropLibrary` + маркери `_Grip_` (`Club` / `Pipe` / `Machete`) — пайплайн мешів нижче.
- Зомбі мають walk/idle через `Animator` (правильний патерн для melee гравця теж).
- Ліфти, завали, лут, HUD, спавн — **не арт**; не чіпати доки coder не закриє ранній беклог.

---

## 2. Практичний пайплайн: Blender → export → Roblox

### Формати

| Тип | Blender | Експорт | У Roblox |
|-----|---------|---------|----------|
| Props / зброя / декор | `.blend` source | **FBX** (або glTF→FBX) | MeshPart / Model у place або Asset Manager upload → `rbxassetid://` |
| Анімації персонажа | Armature + Action (R15-friendly bone names або Roblox rig import) | FBX (baked animation) або Animation Editor у Studio | `Animation` з `AnimationId`; пріоритет Action для ударів |
| Текстури | PNG/TGA 1k–2k max для props | PNG | SurfaceAppearance / TextureId |
| VFX (дощ, іскри удару) | опційно meshes/sprites | PNG sequence / Mesh | ParticleEmitter + Attachment; без важких GPU trails на mobile |

Рекомендація для цього проєкту: **FBX** для мешів і анімацій (Studio імпорт стабільніший). Джерела завжди `.blend` у репо.

### Naming

```
sz_<category>_<name>[_vN]
```

Приклади:

- `sz_wpn_club_v1.blend` → export `sz_wpn_club_v1.fbx`
- `sz_wpn_club_Grip_Marker` (порожня кістка/empty → Part з ім’ям `*_Grip_*` після імпорту)
- `sz_anim_melee_slash_r15_v1`
- `sz_env_roof_rubble_a`
- `sz_vfx_hit_spark_01`

Категорії: `wpn`, `prop`, `env`, `anim`, `vfx`, `char`.

### Де файли живуть під `/workspace`

Після появи репо/Rojo (зараз workspace майже порожній):

```
/workspace/
  art/
    README.md                 # коротко: цей пайплайн + лінк на docs/art-pipeline.md
    blender/                  # тільки .blend + .fbx exports (без .blend1 junk у git за бажанням)
      weapons/
      environment/
      characters/
    textures/                 # PNG, без PSD у git якщо великі
    animations/               # exported FBX / notes з AnimationId після upload
    references/               # moodboards, screens (не секрети)
  places/                     # .rbxlx від coder / sync з artifacts
  src/                        # Rojo (коли з’явиться) — скрипти не класти сюди з арту
```

Context (не git): `artifacts/places/` — робочі знімки places. Арт-документація: `docs/art-pipeline.md` (цей файл).

Правила git:

- Не комітити `secrets/`, API keys, `.roblox_api_key`.
- Великі `.blend`/текстури — ок у `art/` якщо команда так вирішить; інакше LFS або лише exports + Asset IDs у таблиці нижче.
- Після upload у Creator: записувати `rbxassetid` у `art/animations/IDS.md` або `art/blender/ASSET_IDS.md` (без токенів).

### Кроки імпорту (коротко)

1. Модель у Blender: origin на grip/підлогу, scale = studs (1 unit ≈ 1 stud або чіткий Scale у FBX).
2. Export FBX: Apply Transform, forward `-Z`, up `Y` (стандарт Roblox), без зайвих ламп/камер.
3. Studio → Import 3D / Asset Manager → перевірити polycount (mobile: props бажано < ~2–4k tri).
4. Для зброї: Part з ім’ям що містить `_Grip_` (як очікує `CombatService.attachMesh`).
5. Для ударів: завантажити Animation → ID → coder вішає на клієнтський swing (не `toolanim`).
6. Регресія: PC + **mobile/tablet emulator** (Tesтер).

---

## 3. Blender на цій VM

| | |
|--|--|
| Статус | **Встановлено** |
| Версія | **Blender 4.0.2** (`blender --version`) |
| Як ставили | Спочатку `blender` не було в PATH. `sudo apt-get update` + `sudo DEBIAN_FRONTEND=noninteractive apt-get install -y blender` (пакет Ubuntu `blender 4.0.2+dfsg-1ubuntu8`) — успішно. |
| GUI | Headless/cloud VM: CLI є; повний UI залежить від display. Для batch: `blender -b file.blend -P script.py`. |
| Альтернатива якщо apt зламається | Офіційний tarball з blender.org → `/opt/blender` + symlink; або локальний worker з GUI для ригу/анімації. |

Не блокувати беклог очікуванням новішого Blender 4.2+; 4.0.2 достатньо для props/FBX.

---

## 4. Найменший перший арт-слайс (після early backlog coder’а)

**Не блокувати:** ліфти (вивіски/діалог 2–6), завали, підбір електроніки, дроп/скриня.

### Slice A0 — «Atmosphere + roof mood» (рекомендований перший)

Чисто place/скрипт-тюнинг, **без** обов’язкового Blender і без нових Asset ID.

1. **Дах:** прибрати/зрізати rooftop garden (planters + 2 trees + щільний grass); залишити 2–4 сухі кущі/уламки + рідкі vines на краях; палітра leaf → коричнево-сіра.
2. **Освітлення:** знизити глобальну яскравість / outdoor ambient для поверхів; Bloom слабший; уникнути destroy+recreate Lighting на кожен teleport якщо це дає спалах (координація з coder).
3. **Skyline float (мінімум):** додати низьку «вуличну» плиту/туманний диск під кільцем руїн або опустити/подовжити бази `Ruin`, щоб низ не читався в повітрі при look-down.

Acceptance: з даху — похмуро, не «сад»; вниз — башти сидять у серпанку/на землі; вхід на поверх без різкого мерехтіння.

### Slice A1 — «Mobile melee anim» (паралельно або одразу після A0)

1. Одна R15 анімація `sz_anim_melee_slash_r15_v1` (короткий slash ~0.35s).
2. Coder: замість `toolanim` Slash — `Animator:LoadAnimation` + Play на swing (і на AttackButton path).
3. Тестер: mobile + tablet бачать удар; PS5/PC не регресять.

Дощ/день-ніч — **A2**, після A0 (потрібен стабільний lighting baseline).

### Поза слайсом (пізніше)

- Кастомні weapon meshes v2 у Blender (pipeline уже підготовлений `_Grip_`).
- Hit spark VFX (легкий ParticleEmitter).
- Повна weather система.

---

## 5. Hand-off

| Кому | Що |
|------|----|
| Coder | Не чіпати арт-слайс поки early elevators/loot не зелені; для A1 — хук під AnimationId замість `toolanim`. |
| Designer | Палітра/контраст HUD після темніших поверхів. |
| Tester | Чеклист: дах mood, look-down skyline, floor enter flicker, mobile hit anim. |
| Coordinator | Places: sync `artifacts/places/` ↔ `/workspace/places/` коли репо оживе. |
| Marketer | Store icon/banner: [marketing-draft.md](./marketing-draft.md) §3 + майбутній [store-visual-brief.md](./store-visual-brief.md) / `media/marketing/`. Арт дає 3D/tower stills лише в пост-апок палітрі (нижче). |

Опційний scaffold у репо: `/workspace/art/` (див. структуру вище).

---

## 6. Вирівнювання з маркетингом (stills / thumb) — не блокер пайплайну

Marketer веде briefs + mocks у `docs/store-visual-brief.md` і `media/marketing/`. Арт **не чекає** на них для A0/A1; якщо просять tower stills або є слот після A0 — той самий look, що й беклог «не botanical garden».

**Так (для іконки / банера / still):**
- Силует зруйнованого хмарочоса, dusk/overcast, рідкі amber вікна, далекий мертвий skyline.
- Дах = бетон, метал, антени, сухий overgrowth по краях — не planters/дерева «сад».
- Колір: ash / concrete grey / cold amber / muted teal haze (як у marketing-draft §3).
- Кадр: ledge / elevator shaft / look-down на skyline що **сидить у серпанку**, не «літає».

**Ні:** соковита зелень даху, greenhouse vibe, cartoon undead face, neon/purple glow, кров-колаж.

**Доставка stills (коли попросять):** PNG у `media/marketing/` (або `/workspace/art/references/store/`) з іменами `sz_still_roof_dusk_v1.png`, `sz_still_skyline_lookdown_v1.png`. Джерело: Studio play-solo після A0 **або** Blender blockout вежі — без перебудови цілої мапи. Поки brief відсутній — не генерувати пачку моків; чекати запит marketer’а.

---

## 7. Масштаб footprint (owner) — арт підтримує, coder веде layout

**Поточний знімок place:** `GameConfig.World` ≈ `FloorSize = 70`, `RoofSize = 100` (квадратний «маленький» поверх). Owner хоче **ширший footprint** поверхів/корпусу — не крихітний square. Це **layout/coder** (константи + WorldBuilder); арт не блокує й не перебудовує мапу.

Коли coder розширить розміри, арт-припущення такі:

| Що | На малому (зараз) | На ширшому footprint |
|----|-------------------|----------------------|
| Читабельність вежі | Один компактний дах | Силует лишається **одна вежа**: край даху/парапет/антени читаються з відстані; уникати «плаского поля» без вертикальних якорей |
| Overgrowth (A0) | Рідкі vines/кущі по краях | Не засівати всю площу травою — denseness **на периметрі + біля пробоїв**, середина = бетон/шлях/геймплей |
| Skyline / float | Кільце руїн 230–420 від центру | Якщо вежа ширша — `keepClear` / мін. дистанція skyline мають рости з footprint; ground/fog plate масштабувати під новий низ |
| Props / зброя | Stud scale 1:1 | **Не** масштабувати зброю/пропси під поверх — лише env dress (вікна, ivy length, rubble clusters) |
| Lighting / haze | Density 0.28 ok на 70–100 | На більшій площі трохи сильніший haze або дальніші lit-windows, щоб середина не виглядала «порожнім ангаром» при тому ж Brightness |
| Stills / thumb | Квадратний дах у кадрі | Ширший дах ок — кадр тримає **вертикаль** (шахта ліфта, край, сусідня вежа), не top-down park |

**Не робити з арту:** чекати фінальних чисел FloorSize/RoofSize перед A0; дублювати layout-роботу coder’а; заповнювати більший дах «садом», щоб не виглядав порожнім.

Коли в place з’являться нові значення — оновити цей § одним рядком (`FloorSize` / `RoofSize` actual). Доти орієнтир: ширше за 70/100, пост-апок вежа лишається читабельною.
