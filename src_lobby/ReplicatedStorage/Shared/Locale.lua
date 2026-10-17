--!strict
-- All player-facing text in Ukrainian, Russian and English.
--
-- The server never sends finished sentences: it sends a message (a key, or { key, args... }) and every
-- client renders it in its own language. Arguments can be plain values or references:
--   Locale.Item("Scrap")      -> the item's name
--   Locale.Upgrade("Bridge")  -> the upgrade's name
--   Locale.Cost({ Scrap = 8 }) -> "8 Scrap + ..."
-- Adding a language: add its code to Languages and a column to every entry below.

local ItemDefinitions = require(script.Parent.ItemDefinitions)

export type Lang = "uk" | "ru" | "en"
export type Message = string | { any }

local Locale = {}

Locale.Languages = { "uk", "ru", "en" } :: { Lang }
Locale.Default = "en" :: Lang
Locale.LanguageNames = { uk = "Українська", ru = "Русский", en = "English" }

type Entry = { uk: string, ru: string, en: string }

local S: { [string]: Entry } = {
	-- Items
	["item.Scrap.name"] = { uk = "Металобрухт", ru = "Металлолом", en = "Scrap" },
	["item.Scrap.desc"] = {
		uk = "Основа для будь-якого поліпшення.",
		ru = "Основа для любого улучшения.",
		en = "The base of every upgrade.",
	},
	["item.Electronics.name"] = { uk = "Електроніка", ru = "Электроника", en = "Electronics" },
	["item.Electronics.desc"] = {
		uk = "Потрібна для генератора й фільтра.",
		ru = "Нужна для генератора и фильтра.",
		en = "Needed for the generator and the filter.",
	},
	["item.Food.name"] = { uk = "Їжа", ru = "Еда", en = "Food" },
	["item.Food.desc"] = {
		uk = "Кожен спуск з'їдає 1 їжу. Без неї через 3 хв почнеш слабшати.",
		ru = "Каждый спуск съедает 1 еду. Без неё через 3 мин начнёшь слабеть.",
		en = "Each descent uses 1 food. Without it you start to weaken after 3 min.",
	},
	["item.Medkit.name"] = { uk = "Аптечка", ru = "Аптечка", en = "Medkit" },
	["item.Medkit.desc"] = {
		uk = "Відновлює 35 здоров'я.",
		ru = "Восстанавливает 35 здоровья.",
		en = "Restores 35 health.",
	},
	["item.Cable.name"] = { uk = "Кабель", ru = "Кабель", en = "Cable" },
	["item.Cable.desc"] = {
		uk = "Рідкісний. Лежить у руїнах 4 поверху. Потрібен для мосту.",
		ru = "Редкий. Лежит в руинах 4 этажа. Нужен для моста.",
		en = "Rare. Found in the ruins of floor 4. Needed for the bridge.",
	},
	["item.Motor.name"] = { uk = "Мотор", ru = "Мотор", en = "Motor" },
	["item.Motor.desc"] = {
		uk = "Рідкісний. Захований за завалами 4 поверху. Потрібен для мосту.",
		ru = "Редкий. Спрятан за завалами 4 этажа. Нужен для моста.",
		en = "Rare. Hidden behind the rubble on floor 4. Needed for the bridge.",
	},
	["item.Crowbar.name"] = { uk = "Лом", ru = "Лом", en = "Crowbar" },
	["item.Crowbar.desc"] = {
		uk = "Розбирає завали з позначкою «Лом».",
		ru = "Разбирает завалы с пометкой «Лом».",
		en = "Clears rubble marked CROWBAR.",
	},
	["item.Flashlight.name"] = { uk = "Ліхтарик", ru = "Фонарик", en = "Flashlight" },
	["item.Flashlight.desc"] = {
		uk = "Вмикається клавішею F. Заряджається біля генератора.",
		ru = "Включается клавишей F. Заряжается у генератора.",
		en = "Toggle with F. Charges next to the generator.",
	},

	-- Upgrades
	["upgrade.StorageCrate.name"] = { uk = "Скриня", ru = "Сундук", en = "Chest" },
	["upgrade.Generator.name"] = { uk = "Генератор", ru = "Генератор", en = "Generator" },
	["upgrade.AirFilter.name"] = {
		uk = "Фільтр повітря",
		ru = "Фильтр воздуха",
		en = "Air filter",
	},
	["upgrade.Bridge.name"] = { uk = "Міст", ru = "Мост", en = "Bridge" },

	-- Generic server replies
	["err.notLoaded"] = {
		uk = "Дані ще не завантажені",
		ru = "Данные ещё не загружены",
		en = "Data is still loading",
	},
	["err.unknownUpgrade"] = {
		uk = "Невідоме поліпшення",
		ru = "Неизвестное улучшение",
		en = "Unknown upgrade",
	},
	["err.tooFar"] = { uk = "Занадто далеко", ru = "Слишком далеко", en = "Too far away" },

	["upgrade.alreadyBuilt"] = {
		uk = "%s уже збудовано",
		ru = "%s уже построено",
		en = "%s is already built",
	},
	["upgrade.requires"] = {
		uk = "Спершу потрібно: %s",
		ru = "Сначала нужно: %s",
		en = "Build this first: %s",
	},
	["upgrade.notEnough"] = {
		uk = "Недостатньо ресурсів. Потрібно: %s",
		ru = "Не хватает ресурсов. Нужно: %s",
		en = "Not enough resources. Needed: %s",
	},
	["upgrade.built"] = { uk = "Збудовано: %s", ru = "Построено: %s", en = "Built: %s" },

	["flash.none"] = {
		uk = "У тебе немає ліхтарика",
		ru = "У тебя нет фонарика",
		en = "You have no flashlight",
	},
	["flash.empty"] = {
		uk = "Батарея розряджена. Заряди ліхтарик біля генератора",
		ru = "Батарея села. Заряди фонарик у генератора",
		en = "Battery is empty. Charge it next to the generator",
	},
	["flash.drained"] = {
		uk = "Ліхтарик розрядився",
		ru = "Фонарик разрядился",
		en = "Flashlight ran out",
	},
	["flash.full"] = {
		uk = "Ліхтарик повністю заряджено",
		ru = "Фонарик полностью заряжен",
		en = "Flashlight fully charged",
	},

	["hazard.fall"] = {
		uk = "Невдале падіння: -%d здоров'я",
		ru = "Неудачное падение: -%d здоровья",
		en = "Hard landing: -%d health",
	},
	["hazard.toxic"] = {
		uk = "ТОКСИЧНЕ ПОВІТРЯ! Виходь із зони або збудуй фільтр",
		ru = "ТОКСИЧНЫЙ ВОЗДУХ! Уходи из зоны или построй фильтр",
		en = "TOXIC AIR! Leave the area or build a filter",
	},
	["hazard.descent"] = {
		uk = "Спуск почався: -%d їжа",
		ru = "Спуск начался: -%d еда",
		en = "Descent started: -%d food",
	},
	["hazard.noFood"] = {
		uk = "Немає їжі! Через %d хв почнеш слабшати",
		ru = "Нет еды! Через %d мин начнёшь слабеть",
		en = "No food! You will start to weaken in %d min",
	},
	["hazard.hungry"] = {
		uk = "Ти голодний і слабшаєш. З'їж їжу або повертайся на дах",
		ru = "Ты голоден и слабеешь. Съешь еду или возвращайся на крышу",
		en = "You are starving. Eat something or go back to the roof",
	},

	["interact.noStorage"] = {
		uk = "Скрині ще немає. Збудуй її за 8 металобрухту",
		ru = "Сундука ещё нет. Построй его за 8 металлолома",
		en = "No chest yet. Build it for 8 scrap",
	},
	["interact.gateLocked"] = {
		uk = "Двері заблоковано. Потрібен генератор на даху",
		ru = "Дверь заблокирована. Нужен генератор на крыше",
		en = "The door is locked. It needs the generator on the roof",
	},

	["backpack.action"] = {
		uk = "Забрати рюкзак",
		ru = "Забрать рюкзак",
		en = "Take backpack",
	},
	["backpack.object"] = { uk = "Твій рюкзак", ru = "Твой рюкзак", en = "Your backpack" },
	["backpack.lost"] = {
		uk = "Твій рюкзак загубився",
		ru = "Твой рюкзак потерялся",
		en = "Your backpack is gone",
	},
	["backpack.notYours"] = {
		uk = "Це не твій рюкзак",
		ru = "Это не твой рюкзак",
		en = "That is not your backpack",
	},
	["backpack.recovered"] = {
		uk = "Рюкзак повернуто",
		ru = "Рюкзак возвращён",
		en = "Backpack recovered",
	},
	["death.message"] = {
		uk = "Ти загинув. Рюкзак лишився там, де ти впав",
		ru = "Ты погиб. Рюкзак остался там, где ты упал",
		en = "You died. Your backpack stayed where you fell",
	},
	["save.failed"] = {
		uk = "Прогрес не завантажився, тому в цій сесії він не збережеться",
		ru = "Прогресс не загрузился, поэтому в этой сессии он не сохранится",
		en = "Progress failed to load, so it will not be saved this session",
	},

	["medkit.full"] = {
		uk = "Здоров'я вже повне",
		ru = "Здоровье уже полное",
		en = "Health is already full",
	},
	["medkit.none"] = { uk = "Немає аптечки", ru = "Нет аптечки", en = "No medkit" },
	["medkit.used"] = {
		uk = "Аптечка: +%d здоров'я",
		ru = "Аптечка: +%d здоровья",
		en = "Medkit: +%d health",
	},
	["food.none"] = { uk = "Немає їжі", ru = "Нет еды", en = "No food" },
	["food.notHungry"] = {
		uk = "Ти не голодний",
		ru = "Ты не голоден",
		en = "You are not hungry",
	},
	["food.eaten"] = {
		uk = "Ти поїв. Голод минув",
		ru = "Ты поел. Голод прошёл",
		en = "You ate. No longer hungry",
	},

	["res.zoneLocked"] = {
		uk = "Ця зона відкриється після поліпшення бази",
		ru = "Эта зона откроется после улучшения базы",
		en = "This area opens after a base upgrade",
	},
	["res.blocked"] = {
		uk = "Прохід завалено",
		ru = "Проход завален",
		en = "The way is blocked",
	},
	["res.empty"] = {
		uk = "Тут уже порожньо",
		ru = "Здесь уже пусто",
		en = "Nothing left here",
	},
	["res.alreadyHave"] = {
		uk = "У тебе вже є цей предмет",
		ru = "У тебя уже есть этот предмет",
		en = "You already have this",
	},
	["res.full"] = {
		uk = "Рюкзак переповнений. Віднеси знахідки на дах",
		ru = "Рюкзак переполнен. Отнеси находки на крышу",
		en = "Backpack is full. Take your finds to the roof",
	},
	["res.collected"] = { uk = "Зібрано: %s +%d", ru = "Собрано: %s +%d", en = "Collected: %s +%d" },
	["rubble.needCrowbar"] = {
		uk = "Потрібен лом. Розбери перший завал на технічному поверсі",
		ru = "Нужен лом. Разбери первый завал на техническом этаже",
		en = "You need a crowbar. Clear the first rubble on the technical floor",
	},
	["rubble.found"] = {
		uk = "Під завалом знайдено: %s",
		ru = "Под завалом найдено: %s",
		en = "Found under the rubble: %s",
	},
	["rubble.cleared"] = {
		uk = "Завал розібрано",
		ru = "Завал разобран",
		en = "Rubble cleared",
	},

	["storage.invalid"] = {
		uk = "Невідома дія",
		ru = "Неизвестное действие",
		en = "Unknown action",
	},
	["storage.notStorable"] = {
		uk = "Цей предмет не можна покласти в скриню",
		ru = "Этот предмет нельзя положить в сундук",
		en = "This item cannot be stored",
	},
	["storage.badAmount"] = {
		uk = "Неправильна кількість",
		ru = "Неверное количество",
		en = "Invalid amount",
	},
	["storage.buildFirst"] = {
		uk = "Спершу збудуй скриню",
		ru = "Сначала построй сундук",
		en = "Build the chest first",
	},
	["storage.tooFar"] = {
		uk = "Підійди ближче до скрині",
		ru = "Подойди ближе к сундуку",
		en = "Move closer to the chest",
	},
	["storage.nothing"] = {
		uk = "Немає що класти",
		ru = "Нечего класть",
		en = "Nothing to put in",
	},
	["storage.full"] = {
		uk = "Скриня заповнена",
		ru = "Сундук заполнен",
		en = "The chest is full",
	},
	["storage.notInStorage"] = {
		uk = "У скрині цього немає",
		ru = "В сундуке этого нет",
		en = "Not in the chest",
	},
	["storage.invFull"] = {
		uk = "Рюкзак переповнений",
		ru = "Рюкзак переполнен",
		en = "Backpack is full",
	},

	-- Tutorial
	["tutorial.1"] = {
		uk = "Знайди аварійний термінал на даху",
		ru = "Найди аварийный терминал на крыше",
		en = "Find the emergency terminal on the roof",
	},
	["tutorial.2"] = {
		uk = "Спустись сходами й збери 3 металобрухту на технічному поверсі",
		ru = "Спустись по лестнице и собери 3 металлолома на техническом этаже",
		en = "Take the stairs down and collect 3 scrap on the technical floor",
	},
	["tutorial.3"] = {
		uk = "Повернись на дах",
		ru = "Вернись на крышу",
		en = "Return to the roof",
	},
	["tutorial.4"] = {
		uk = "Збудуй скриню на даху (8 металобрухту)",
		ru = "Построй сундук на крыше (8 металлолома)",
		en = "Build the chest on the roof (8 scrap)",
	},
	["tutorial.5"] = {
		uk = "Знайди 4 електроніки",
		ru = "Найди 4 электроники",
		en = "Find 4 electronics",
	},
	["tutorial.6"] = {
		uk = "Увімкни генератор на даху",
		ru = "Запусти генератор на крыше",
		en = "Start the generator on the roof",
	},
	["tutorial.7"] = {
		uk = "Знайди кабель і мотор на 4 поверсі, полагодь міст і перейди на сусідню вежу",
		ru = "Найди кабель и мотор на 4 этаже, почини мост и перейди на соседнюю башню",
		en = "Find cable and motors on floor 4, repair the bridge and cross to the next tower",
	},
	["tutorial.done"] = {
		uk = "Вежу пройдено. Можеш і далі досліджувати поверхи",
		ru = "Башня пройдена. Можешь и дальше исследовать этажи",
		en = "Tower complete. Keep exploring if you like",
	},
	["tutorial.new"] = { uk = "Нова ціль: %s", ru = "Новая цель: %s", en = "New objective: %s" },

	-- Notes
	["note.terminal.title"] = {
		uk = "Аварійний термінал",
		ru = "Аварийный терминал",
		en = "Emergency terminal",
	},
	["note.terminal.body"] = {
		uk = "«Якщо ти це читаєш, дах ще тримається. Генератор не працює, а вентиляція нижче забита. Не спускайся без ліхтаря. Ми пробували дістатися до сусідньої вежі, але міст обвалився. Знайди деталі — можливо, зможеш повернути світло».",
		ru = "«Если ты это читаешь, крыша ещё держится. Генератор не работает, а вентиляция ниже забита. Не спускайся без фонаря. Мы пытались добраться до соседней башни, но мост рухнул. Найди детали — может, сумеешь вернуть свет».",
		en = '"If you are reading this, the roof still holds. The generator is dead and the vents below are clogged. Don\'t go down without a light. We tried to reach the next tower, but the bridge collapsed. Find parts — maybe you can bring the power back."',
	},
	["note.terminal.footer"] = {
		uk = "Відновлено систем: %d / 3   (світло, повітря, міст)",
		ru = "Восстановлено систем: %d / 3   (свет, воздух, мост)",
		en = "Systems restored: %d / 3   (power, air, bridge)",
	},
	["ending.title"] = {
		uk = "Вежу 1 пройдено!",
		ru = "Башня 1 пройдена!",
		en = "Tower 1 complete!",
	},
	["ending.body"] = {
		uk = "Ти повернув світло, очистив повітря й полагодив міст. Попереду нова вежа і нові поверхи.",
		ru = "Ты вернул свет, очистил воздух и починил мост. Впереди новая башня и новые этажи.",
		en = "You restored the power, cleared the air and fixed the bridge. A new tower and new floors lie ahead.",
	},
	["ending.footer"] = {
		uk = "Skyline Zero · прототип · Дякуємо за гру!",
		ru = "Skyline Zero · прототип · Спасибо за игру!",
		en = "Skyline Zero · prototype · Thanks for playing!",
	},

	-- World signs and prompts
	["sign.floor"] = { uk = "%d ПОВЕРХ", ru = "%d ЭТАЖ", en = "FLOOR %d" },
	["sign.floor4"] = { uk = "4 ПОВЕРХ · РУЇНИ", ru = "4 ЭТАЖ · РУИНЫ", en = "FLOOR 4 · RUINS" },
	["sign.stairsDown"] = {
		uk = "СХОДИ ВНИЗ ↓",
		ru = "ЛЕСТНИЦА ВНИЗ ↓",
		en = "STAIRS DOWN ↓",
	},
	["sign.crowbar"] = { uk = "ЛОМ", ru = "ЛОМ", en = "CROWBAR" },
	["sign.toxic"] = {
		uk = "⚠ ТОКСИЧНЕ ПОВІТРЯ",
		ru = "⚠ ТОКСИЧНЫЙ ВОЗДУХ",
		en = "⚠ TOXIC AIR",
	},
	["sign.gate"] = {
		uk = "ПОТРІБНЕ ЖИВЛЕННЯ · ГЕНЕРАТОР",
		ru = "НУЖНО ПИТАНИЕ · ГЕНЕРАТОР",
		en = "POWER REQUIRED · GENERATOR",
	},
	["sign.bridgeBroken"] = {
		uk = "МІСТ ЗРУЙНОВАНО",
		ru = "МОСТ РАЗРУШЕН",
		en = "BRIDGE DESTROYED",
	},
	["sign.tower2"] = { uk = "ВЕЖА 2", ru = "БАШНЯ 2", en = "TOWER 2" },

	["prompt.collect"] = { uk = "Зібрати", ru = "Собрать", en = "Collect" },
	["prompt.itemAmount"] = { uk = "%s ×%d", ru = "%s ×%d", en = "%s ×%d" },
	["prompt.clear"] = { uk = "Розібрати", ru = "Разобрать", en = "Clear" },
	["prompt.clearCrowbar"] = {
		uk = "Розібрати ломом",
		ru = "Разобрать ломом",
		en = "Pry with crowbar",
	},
	["prompt.rubble"] = { uk = "Завал", ru = "Завал", en = "Rubble" },
	["prompt.open"] = { uk = "Відкрити", ru = "Открыть", en = "Open" },
	["prompt.gate"] = {
		uk = "Двері на 4 поверх",
		ru = "Дверь на 4 этаж",
		en = "Door to floor 4",
	},
	["prompt.build"] = { uk = "Збудувати", ru = "Построить", en = "Build" },
	["prompt.needs"] = { uk = "Потрібно: %s", ru = "Нужно: %s", en = "Needs: %s" },
	["prompt.read"] = { uk = "Прочитати", ru = "Прочитать", en = "Read" },
	["prompt.terminal"] = {
		uk = "Аварійний термінал",
		ru = "Аварийный терминал",
		en = "Emergency terminal",
	},
	["prompt.costLine"] = { uk = "%s: %s", ru = "%s: %s", en = "%s: %s" },

	-- HUD and menus
	["hud.health"] = { uk = "Здоров'я %d / %d", ru = "Здоровье %d / %d", en = "Health %d / %d" },
	["hud.weight"] = { uk = "Вага %d / %d", ru = "Вес %d / %d", en = "Weight %d / %d" },
	["hud.objective"] = { uk = "Ціль: %s", ru = "Цель: %s", en = "Objective: %s" },
	["hud.systems"] = { uk = "Системи %d/3", ru = "Системы %d/3", en = "Systems %d/3" },
	["hud.toxic"] = {
		uk = "⚠ ТОКСИЧНЕ ПОВІТРЯ",
		ru = "⚠ ТОКСИЧНЫЙ ВОЗДУХ",
		en = "⚠ TOXIC AIR",
	},
	["hud.hungry"] = {
		uk = "⚠ ГОЛОД: з'їж їжу",
		ru = "⚠ ГОЛОД: съешь еду",
		en = "⚠ STARVING: eat food",
	},
	["hud.flashlight"] = {
		uk = "Ліхтарик %s · %d с",
		ru = "Фонарик %s · %d с",
		en = "Flashlight %s · %ds",
	},
	["hud.on"] = { uk = "увімк.", ru = "вкл.", en = "on" },
	["hud.off"] = { uk = "вимк.", ru = "выкл.", en = "off" },

	["ui.interact"] = { uk = "Взаємодія", ru = "Действие", en = "Interact" },
	["ui.flashlight"] = { uk = "Ліхтарик", ru = "Фонарик", en = "Flashlight" },
	["ui.use"] = { uk = "Використати", ru = "Использовать", en = "Use" },
	["ui.eat"] = { uk = "З'їсти", ru = "Съесть", en = "Eat" },
	["ui.storage"] = { uk = "Скриня", ru = "Сундук", en = "Chest" },
	["ui.storageHeader"] = {
		uk = "Скриня %d / %d   ·   рюкзак %d / %d",
		ru = "Сундук %d / %d   ·   рюкзак %d / %d",
		en = "Chest %d / %d   ·   backpack %d / %d",
	},
	["ui.storageRow"] = {
		uk = "%s %s\nз собою %d · у скрині %d",
		ru = "%s %s\nс собой %d · в сундуке %d",
		en = "%s %s\ncarried %d · stored %d",
	},
	["ui.all"] = { uk = "всі", ru = "все", en = "all" },
	["ui.close"] = { uk = "Закрити", ru = "Закрыть", en = "Close" },
	["ui.continue"] = { uk = "Продовжити", ru = "Продолжить", en = "Continue" },
	-- Lobby and party
	["lobby.title"] = { uk = "SKYLINE ZERO", ru = "SKYLINE ZERO", en = "SKYLINE ZERO" },
	-- Kept for older clients; boarding no longer uses fixed Solo/2/4/6 signs.
	["lobby.liftSolo"] = { uk = "ЛІФТ", ru = "ЛИФТ", en = "LIFT" },
	["lobby.liftGroup"] = { uk = "ЛІФТ", ru = "ЛИФТ", en = "LIFT" },
	["lobby.hint"] = {
		uk = "Зайди в ліфт і обери скільки гравців (1–6), щоб піднятися на дах.",
		ru = "Зайди в лифт и выбери сколько игроков (1–6), чтобы подняться на крышу.",
		en = "Step into a lift and pick how many players (1–6) to go up to the roof.",
	},
	["lobby.pickSizeTitle"] = {
		uk = "ЛІФТ",
		ru = "ЛИФТ",
		en = "LIFT",
	},
	["lobby.pickSizeBody"] = {
		uk = "Скільки вас іде? Обери 1–6. Старт, коли таймер закінчиться.",
		ru = "Сколько вас едет? Выбери 1–6. Старт, когда таймер закончится.",
		en = "How many of you are going? Pick 1–6. Leaves when the timer ends.",
	},
	["lobby.pickSizeHint"] = {
		uk = "Обери кількість гравців 1–6",
		ru = "Выбери количество игроков 1–6",
		en = "Pick 1 to 6 players",
	},
	["lobby.sizeChosen"] = {
		uk = "Місць: %d. Чекаємо…",
		ru = "Мест: %d. Ждём…",
		en = "Seats: %d. Waiting…",
	},
	["lobby.badSize"] = {
		uk = "Обери від 1 до 6 гравців",
		ru = "Выбери от 1 до 6 игроков",
		en = "Pick between 1 and 6 players",
	},
	["lobby.pickSolo"] = { uk = "Один", ru = "Один", en = "Solo" },
	["lobby.leaderPicked"] = {
		uk = "Лідер обрав: %d",
		ru = "Лидер выбрал: %d",
		en = "Leader chose: %d",
	},
	["lobby.howTitle"] = { uk = "ЯК ГРАТИ", ru = "КАК ИГРАТЬ", en = "HOW TO PLAY" },
	["lobby.howBody"] = {
		uk = "1. Спускайся з даху на поверхи й збирай ресурси.\n2. Повертайся на дах і будуй поліпшення.\n3. Генератор, фільтр і міст — три кроки до втечі.\n4. Бережи себе: падіння, отрута й голод небезпечні.",
		ru = "1. Спускайся с крыши на этажи и собирай ресурсы.\n2. Возвращайся на крышу и строй улучшения.\n3. Генератор, фильтр и мост — три шага к побегу.\n4. Береги себя: падения, яд и голод опасны.",
		en = "1. Go down from the roof and collect resources.\n2. Bring them back up and build upgrades.\n3. Generator, filter and bridge: three steps to escape.\n4. Stay alive: falls, toxic air and hunger hurt.",
	},
	["lobby.leaders"] = {
		uk = "ВЕЖІ ПРОЙДЕНО",
		ru = "БАШНИ ПРОЙДЕНЫ",
		en = "TOWERS COMPLETED",
	},
	["lobby.leadersEmpty"] = { uk = "Поки що ніхто", ru = "Пока никто", en = "Nobody yet" },
	["lobby.joined"] = {
		uk = "Ти в ліфті. Старт за %d с",
		ru = "Ты в лифте. Старт через %d с",
		en = "You are in the lift. Starting in %d s",
	},
	["lobby.left"] = {
		uk = "Ти вийшов з ліфта",
		ru = "Ты вышел из лифта",
		en = "You left the lift",
	},
	["lobby.full"] = {
		uk = "Ліфт заповнений",
		ru = "Лифт заполнен",
		en = "This lift is full",
	},
	["lobby.starting"] = { uk = "Їдемо нагору!", ru = "Поехали наверх!", en = "Going up!" },
	["lobby.notPublished"] = {
		uk = "Гру ще не опубліковано, тому ліфт не працює. Опублікуй обидва place і впиши PlaceId",
		ru = "Игра ещё не опубликована, поэтому лифт не работает. Опубликуй оба place и впиши PlaceId",
		en = "The game is not published yet, so lifts are off. Publish both places and set the PlaceIds",
	},
	["lobby.studio"] = {
		uk = "У Studio телепорт не працює. Перевір ліфти в опублікованій грі",
		ru = "В Studio телепорт не работает. Проверь лифты в опубликованной игре",
		en = "Teleports do not work in Studio. Test the lifts in the published game",
	},
	["lobby.failed"] = {
		uk = "Не вдалося запустити гру. Спробуй ще раз",
		ru = "Не удалось запустить игру. Попробуй ещё раз",
		en = "Could not start the game. Please try again",
	},
	["lobby.countdown"] = { uk = "Старт через %d", ru = "Старт через %d", en = "Starting in %d" },
	["lobby.riders"] = { uk = "У ліфті %d / %d", ru = "В лифте %d / %d", en = "In the lift %d / %d" },
	["lobby.teleporting"] = {
		uk = "Піднімаємось на дах…",
		ru = "Поднимаемся на крышу…",
		en = "Going up to the roof…",
	},
	["party.built"] = { uk = "%s збудував: %s", ru = "%s построил: %s", en = "%s built: %s" },
	["party.leader"] = { uk = "Лідер групи: %s", ru = "Лидер группы: %s", en = "Party leader: %s" },
	["marker.here"] = { uk = "Сюди · %d м", ru = "Сюда · %d м", en = "Here · %d m" },
	["prompt.locked"] = { uk = "🔒 Спершу: %s", ru = "🔒 Сначала: %s", en = "🔒 First: %s" },
	["ui.toLobby"] = { uk = "В лобі", ru = "В лобби", en = "Lobby" },

	["ui.weightEach"] = { uk = "вага %d", ru = "вес %d", en = "weight %d" },
}

local function entry(key: string): Entry?
	return S[key]
end

function Locale.Has(key: string): boolean
	return S[key] ~= nil
end

-- Normalises a Roblox LocaleId ("uk-ua", "ru-ru", "en-us") or a saved code to one of our languages.
function Locale.Resolve(code: any): Lang
	if type(code) ~= "string" then
		return Locale.Default
	end
	local prefix = string.lower(string.sub(code, 1, 2))
	if prefix == "uk" or prefix == "ru" or prefix == "en" then
		return prefix :: Lang
	end
	return Locale.Default
end

function Locale.IsLanguage(code: any): boolean
	return code == "uk" or code == "ru" or code == "en"
end

-- Argument references, resolved in the reader's language.
function Locale.Item(itemId: string): { [string]: any }
	return { ref = "item." .. itemId .. ".name" }
end

function Locale.Upgrade(upgradeId: string): { [string]: any }
	return { ref = "upgrade." .. upgradeId .. ".name" }
end

function Locale.Cost(cost: { [string]: number }): { [string]: any }
	return { cost = cost }
end

local function raw(lang: Lang, key: string): string
	local e = entry(key)
	if not e then
		return key
	end
	return (e :: any)[lang] or e.en
end

local function resolveArg(lang: Lang, arg: any): any
	if type(arg) ~= "table" then
		return arg
	end
	if type(arg.ref) == "string" then
		return raw(lang, arg.ref)
	end
	if type(arg.cost) == "table" then
		local parts = {}
		for _, itemId in ItemDefinitions.Order do
			local amount = arg.cost[itemId]
			if type(amount) == "number" then
				table.insert(parts, ("%d %s"):format(amount, raw(lang, "item." .. itemId .. ".name")))
			end
		end
		return table.concat(parts, " + ")
	end
	return ""
end

function Locale.T(lang: Lang, key: string, ...: any): string
	local text = raw(lang, key)
	local count = select("#", ...)
	if count == 0 then
		return text
	end
	local args = table.pack(...)
	for i = 1, count do
		args[i] = resolveArg(lang, args[i])
	end
	local ok, result = pcall(string.format, text, table.unpack(args, 1, count))
	return if ok then result else text
end

-- Renders a message sent by the server: a key, or { key, arg1, arg2, ... }.
function Locale.Format(lang: Lang, message: any): string
	if type(message) == "string" then
		return Locale.T(lang, message)
	end
	if type(message) == "table" and type(message[1]) == "string" then
		return Locale.T(lang, message[1], table.unpack(message, 2))
	end
	return ""
end

function Locale.ItemName(lang: Lang, itemId: string): string
	return raw(lang, "item." .. itemId .. ".name")
end

function Locale.ItemDesc(lang: Lang, itemId: string): string
	return raw(lang, "item." .. itemId .. ".desc")
end

function Locale.UpgradeName(lang: Lang, upgradeId: string): string
	return raw(lang, "upgrade." .. upgradeId .. ".name")
end

-- The language a player reads in: their saved choice, else their Roblox locale.
function Locale.ForPlayer(player: Player): Lang
	local chosen = player:GetAttribute("Language")
	if Locale.IsLanguage(chosen) then
		return chosen :: Lang
	end
	return Locale.Resolve(player.LocaleId)
end

return Locale
