--!strict
-- All player-facing text in Ukrainian, Russian and English.
--
-- The server never sends finished sentences: it sends a message (a key, or { key, args... }) and every
-- client renders it in its own language. Arguments can be plain values or references:
--   Locale.Item("Scrap")      -> the item's name (weapons add their rarity: "Bat · Rare weapon")
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
		uk = "Іржаві шматки металу для будівництва на даху. Це не лом-інструмент.",
		ru = "Ржавые куски металла для построек на крыше. Это не лом-инструмент.",
		en = "Rusty metal for roof builds. Not the crowbar tool.",
	},
	["item.Electronics.name"] = { uk = "Електроніка", ru = "Электроника", en = "Electronics" },
	["item.Electronics.desc"] = {
		uk = "Потрібна для генератора й фільтра.",
		ru = "Нужна для генератора и фильтра.",
		en = "Needed for the generator and the filter.",
	},
	["item.Food.name"] = { uk = "Їжа", ru = "Еда", en = "Food" },
	["item.Food.desc"] = {
		uk = "Наповнює ситість. Коли вона порожня, починаєш слабшати.",
		ru = "Наполняет сытость. Когда она пуста, начинаешь слабеть.",
		en = "Fills your hunger meter. When it runs out you start to weaken.",
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
		uk = "Інструмент: розбирає тверді завали. Не плутай із металобрухтом.",
		ru = "Инструмент: разбирает твёрдые завалы. Не путай с металлоломом.",
		en = "Tool: clears hard rubble. Not the same as Scrap.",
	},
	["item.Flashlight.name"] = { uk = "Ліхтарик", ru = "Фонарик", en = "Flashlight" },
	["item.Flashlight.desc"] = {
		uk = "Візьми в руку й тапни, або F / кнопка Y. Заряджається біля генератора.",
		ru = "Возьми в руку и тапни, или F / кнопка Y. Заряжается у генератора.",
		en = "Hold it and tap, or press F / Y. Charges next to the generator.",
	},

	["item.Club.name"] = { uk = "Дубина", ru = "Дубина", en = "Club" },
	["item.Club.desc"] = {
		uk = "Стара добра дубина. Б'є слабко, але завжди з тобою.",
		ru = "Старая добрая дубина. Бьёт слабо, но всегда с тобой.",
		en = "A trusty club. Weak, but always with you.",
	},
	["item.Bat.name"] = { uk = "Бита", ru = "Бита", en = "Bat" },
	["item.Bat.desc"] = {
		uk = "Алюмінієва бита з цвяхами. Б'є сильніше за дубину.",
		ru = "Алюминиевая бита с гвоздями. Бьёт сильнее дубины.",
		en = "An aluminium bat with nails. Hits harder than the club.",
	},
	["item.Pipe.name"] = { uk = "Труба", ru = "Труба", en = "Pipe" },
	["item.Pipe.desc"] = {
		uk = "Важка сталева труба. Б'є майже вдвічі сильніше за дубину.",
		ru = "Тяжёлая стальная труба. Бьёт почти вдвое сильнее дубины.",
		en = "A heavy steel pipe. Hits almost twice as hard as the club.",
	},
	["item.Machete.name"] = { uk = "Мачете", ru = "Мачете", en = "Machete" },
	["item.Machete.desc"] = {
		uk = "Швидке й гостре. Найкраща зброя проти зомбі.",
		ru = "Быстрое и острое. Лучшее оружие против зомби.",
		en = "Fast and sharp. The best tool against zombies.",
	},
	-- Weapon rarity, shown next to the weapon's name (gender-free on purpose: "Мачете · Діамантова зброя").
	["rarity.Common"] = { uk = "Звичайна зброя", ru = "Обычное оружие", en = "Common weapon" },
	["rarity.Rare"] = { uk = "Рідкісна зброя", ru = "Редкое оружие", en = "Rare weapon" },
	["rarity.Gold"] = { uk = "Золота зброя", ru = "Золотое оружие", en = "Gold weapon" },
	["rarity.Diamond"] = {
		uk = "Діамантова зброя",
		ru = "Алмазное оружие",
		en = "Diamond weapon",
	},
	["item.Bandage.name"] = { uk = "Бинт", ru = "Бинт", en = "Bandage" },
	["item.Bandage.desc"] = {
		uk = "Ним можна підняти пораненого тіммейта.",
		ru = "Им можно поднять раненого тиммейта.",
		en = "Use it to get a downed teammate back on their feet.",
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
	["upgrade.Barricade.name"] = { uk = "Барикада", ru = "Баррикада", en = "Barricade" },

	["horde.warning"] = {
		uk = "Сирена! Орда піднімається сходами!",
		ru = "Сирена! Орда поднимается по лестнице!",
		en = "Siren! A horde is coming up the stairs!",
	},

	-- Single blackout toast (telegraph). Lights dim + restore SFX replace former on/off toasts.
	["event.blackout.warn"] = {
		uk = "Світло мигає… Ліхтар або зелені виходи!",
		ru = "Свет мигает… Фонарь или зелёные выходы!",
		en = "Lights flicker… Flashlight or green exits!",
	},
	["event.blackout.on"] = {
		uk = "БЛЕКАУТ! Ліхтар або зелені виходи.",
		ru = "БЛЭКАУТ! Фонарь или зелёные выходы.",
		en = "BLACKOUT! Use a flashlight or the green exits.",
	},
	["event.blackout.off"] = {
		uk = "Живлення повернулося.",
		ru = "Питание вернулось.",
		en = "Power is back.",
	},

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
		uk = "Недостатньо ресурсів. Потрібно: %s. Рахуються рюкзаки всіх на даху і скриня",
		ru = "Не хватает ресурсов. Нужно: %s. Считаются рюкзаки всех на крыше и сундук",
		en = "Not enough resources. Needed: %s. Backpacks of everyone on the roof and the chest count",
	},
	["team.chippedIn"] = {
		uk = "Ти вклав у будівництво: %s ×%d",
		ru = "Ты вложил в постройку: %s ×%d",
		en = "You chipped in: %s ×%d",
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
		uk = "Скрині ще немає. Збудуй її за 10 металобрухту",
		ru = "Сундука ещё нет. Построй его за 10 металлолома",
		en = "No chest yet. Build it for 10 scrap",
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
		uk = "Спустись сходами й збери 10 металобрухту на технічному поверсі",
		ru = "Спустись по лестнице и собери 10 металлолома на техническом этаже",
		en = "Take the stairs down and collect 10 scrap on the technical floor",
	},
	["tutorial.3"] = {
		uk = "Повернись на дах",
		ru = "Вернись на крышу",
		en = "Return to the roof",
	},
	["tutorial.4"] = {
		uk = "Збудуй скриню на даху (10 металобрухту)",
		ru = "Построй сундук на крыше (10 металлолома)",
		en = "Build the chest on the roof (10 scrap)",
	},
	["tutorial.5"] = {
		uk = "Знайди 5 електроніки",
		ru = "Найди 5 электроники",
		en = "Find 5 electronics",
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
	["hud.hunger"] = { uk = "Ситість %d", ru = "Сытость %d", en = "Food %d" },
	["hud.hungerWord"] = { uk = "Ситість", ru = "Сытость", en = "Fullness" },
	["hud.goal"] = { uk = "ЦІЛЬ", ru = "ЦЕЛЬ", en = "GOAL" },
	["hud.lowHealth"] = { uk = "МАЛО ЗДОРОВ'Я", ru = "МАЛО ЗДОРОВЬЯ", en = "LOW HEALTH" },
	["hud.starving"] = { uk = "ГОЛОД -1 HP/с", ru = "ГОЛОД -1 HP/с", en = "STARVING -1 HP/s" },
	["hud.toxicBadge"] = { uk = "ТОКСИН", ru = "ТОКСИН", en = "TOXIC" },
	["hud.downedBadge"] = { uk = "ВПАВ", ru = "УПАЛ", en = "DOWN" },
	["class.Medic.name"] = { uk = "Медик", ru = "Медик", en = "Medic" },
	["class.Medic.desc"] = {
		uk = "Старт з 2 бинтами, піднімає тіммейтів удвічі швидше",
		ru = "Старт с 2 бинтами, поднимает тиммейтов вдвое быстрее",
		en = "Starts with 2 bandages, revives teammates twice as fast",
	},
	["class.Scout.name"] = { uk = "Розвідник", ru = "Разведчик", en = "Scout" },
	["class.Scout.desc"] = {
		uk = "Бігає на 15% швидше, ліхтарик тримає довше",
		ru = "Бегает на 15% быстрее, фонарик держит дольше",
		en = "Runs 15% faster, flashlight lasts longer",
	},
	["class.Fighter.name"] = { uk = "Боєць", ru = "Боец", en = "Fighter" },
	["class.Fighter.desc"] = {
		uk = "Старт з трубою замість дубини, +15% шкоди",
		ru = "Старт с трубой вместо дубины, +15% урона",
		en = "Starts with a pipe instead of a club, +15% damage",
	},
	["class.Mechanic.name"] = { uk = "Механік", ru = "Механик", en = "Mechanic" },
	["class.Mechanic.desc"] = {
		uk = "Споруди на 20% дешевші, бачить ресурси поруч крізь стіни",
		ru = "Постройки на 20% дешевле, видит ресурсы рядом сквозь стены",
		en = "Buildings 20% cheaper, sees nearby resources through walls",
	},
	["class.none.name"] = { uk = "Без класу", ru = "Без класса", en = "No class" },
	["class.playing"] = { uk = "Твій клас: %s", ru = "Твой класс: %s", en = "Your class: %s" },
	["lobby.classes"] = { uk = "Класи", ru = "Классы", en = "Classes" },
	["lobby.classBuy"] = { uk = "Відкрити · %d", ru = "Открыть · %d", en = "Unlock · %d" },
	["lobby.classPick"] = { uk = "Вибрати", ru = "Выбрать", en = "Pick" },
	["lobby.classPicked"] = { uk = "Вибрано", ru = "Выбрано", en = "Picked" },
	["lobby.classNoTokens"] = {
		uk = "Не вистачає жетонів. Їх дають за кожен матч",
		ru = "Не хватает жетонов. Их дают за каждый матч",
		en = "Not enough tokens. You earn them every match",
	},
	["lobby.classBought"] = {
		uk = "Клас відкрито: %s",
		ru = "Класс открыт: %s",
		en = "Class unlocked: %s",
	},
	["hud.medkitHint"] = {
		uk = "Мало здоров'я: візьми аптечку в руку й тапни. Нові є на 2 поверсі, у скринях і на верстаку",
		ru = "Мало здоровья: возьми аптечку в руку и тапни. Новые есть на 2 этаже, в сундуках и на верстаке",
		en = "Low health: hold a medkit and tap. More on floor 2, in crates and at the workbench",
	},
	["hud.eatHint"] = { uk = "Поїж щось", ru = "Поешь что-нибудь", en = "Eat something" },
	["hud.bag"] = { uk = "Ще", ru = "Ещё", en = "More" },
	["downed.sub"] = {
		uk = "Напарник може підняти тебе бинтом",
		ru = "Напарник может поднять тебя бинтом",
		en = "A teammate can revive you with a bandage",
	},
	["downed.hasBandage"] = { uk = "має бинт", ru = "есть бинт", en = "has bandage" },
	["downed.noBandage"] = { uk = "без бинта", ru = "без бинта", en = "no bandage" },
	["downed.meters"] = { uk = "%d м", ru = "%d м", en = "%d m" },
	["prompt.pickUp"] = { uk = "Підняти", ru = "Поднять", en = "Pick up" },
	["drop.done"] = { uk = "Викинуто: %s ×%d", ru = "Выброшено: %s ×%d", en = "Dropped: %s ×%d" },
	["hint.dropTouch"] = {
		uk = "Утримуй слот, щоб викинути предмет для тіммейта",
		ru = "Удерживай слот, чтобы выбросить предмет для тиммейта",
		en = "Hold a slot to drop the item for a teammate",
	},
	["hint.dropPc"] = {
		uk = "G — викинути предмет у руці",
		ru = "G — выбросить предмет в руке",
		en = "G drops the item in hand",
	},
	["hud.stairs"] = { uk = "Сходи · %d м", ru = "Лестница · %d м", en = "Stairs · %d m" },
	["pad.hit"] = {
		uk = "удар / використати",
		ru = "удар / использовать",
		en = "hit / use",
	},
	["pad.light"] = { uk = "ліхтарик", ru = "фонарик", en = "flashlight" },
	["pad.medkit"] = { uk = "аптечка", ru = "аптечка", en = "medkit" },
	["pad.food"] = { uk = "їжа", ru = "еда", en = "food" },
	["lobby.lift"] = {
		uk = "Ліфт на %d гравців",
		ru = "Лифт на %d игроков",
		en = "Lift for %d",
	},
	["lobby.leaveLift"] = { uk = "Вийти з ліфта", ru = "Выйти из лифта", en = "Leave lift" },
	["lobby.fullFaster"] = {
		uk = "Ліфт повний: відлік у 3 рази швидший",
		ru = "Лифт полный: отсчёт в 3 раза быстрее",
		en = "Lift full: countdown 3× faster",
	},
	["lobby.boardSolo"] = { uk = "СОЛО", ru = "СОЛО", en = "SOLO" },
	["lobby.boardGroup"] = { uk = "ГРУПА · %d/%d", ru = "ГРУППА · %d/%d", en = "GROUP · %d/%d" },
	["lobby.pickSize"] = {
		uk = "Скільки гравців?",
		ru = "Сколько игроков?",
		en = "How many players?",
	},
	["lobby.tokensWord"] = { uk = "жетонів", ru = "жетонов", en = "tokens" },
	["lobby.records"] = { uk = "Рекорди", ru = "Рекорды", en = "Records" },
	["lobby.recordsTitle"] = { uk = "РЕКОРДИ", ru = "РЕКОРДЫ", en = "RECORDS" },
	["lobby.recordsYou"] = { uk = "ти", ru = "ты", en = "you" },
	["lobby.recordsLoading"] = { uk = "Завантажуємо…", ru = "Загружаем…", en = "Loading…" },
	["lobby.recordsNote"] = {
		uk = "Табло оновлюється раз на %d с",
		ru = "Табло обновляется раз в %d с",
		en = "The board updates every %d s",
	},
	["lobby.how1Title"] = {
		uk = "Дах — ваша база",
		ru = "Крыша — ваша база",
		en = "The roof is your base",
	},
	["lobby.how1"] = {
		uk = "Ліфт везе вас на дах хмарочоса. Тут безпечно, тут ви й будуєте.",
		ru = "Лифт везёт вас на крышу небоскрёба. Здесь безопасно, здесь вы и строите.",
		en = "The lift takes you to the skyscraper roof. It's safe there, and that's where you build.",
	},
	["lobby.how2Title"] = {
		uk = "Спускайся по поверхах",
		ru = "Спускайся по этажам",
		en = "Go down the floors",
	},
	["lobby.how2"] = {
		uk = "Збирай ресурси та їжу, відкривай скрині з лутом і неси все на дах.",
		ru = "Собирай ресурсы и еду, открывай сундуки с лутом и неси всё на крышу.",
		en = "Collect resources and food, open loot crates and carry it all back up.",
	},
	["lobby.how3Title"] = { uk = "Бережися", ru = "Берегись", en = "Stay alive" },
	["lobby.how3"] = {
		uk = "Зомбі й токсичне повітря ранять. Не забувай їсти. Впалого напарника піднімають бинтом.",
		ru = "Зомби и токсичный воздух ранят. Не забывай есть. Упавшего напарника поднимают бинтом.",
		en = "Zombies and toxic air hurt. Remember to eat. A downed teammate is revived with a bandage.",
	},
	["lobby.how4Title"] = {
		uk = "Будуй на даху",
		ru = "Строй на крыше",
		en = "Build on the roof",
	},
	["lobby.how4"] = {
		uk = "Спершу Скриня, потім Генератор, а з ним Фільтр повітря і Міст.",
		ru = "Сначала Сундук, потом Генератор, а с ним Фильтр воздуха и Мост.",
		en = "First the Chest, then the Generator, which unlocks the Air filter and the Bridge.",
	},
	["lobby.how5Title"] = { uk = "Перейди міст", ru = "Перейди мост", en = "Cross the bridge" },
	["lobby.how5"] = {
		uk = "Міст веде з даху геть. Перейдіть його — і ви перемогли.",
		ru = "Мост ведёт с крыши прочь. Перейдите его — и вы победили.",
		en = "The bridge is the way off the roof. Cross it and you win.",
	},
	["lobby.howTokens"] = {
		uk = "Жетони дають за найглибший поверх забігу (не за кожен підбір чи вбивство); перемога — удвічі більше. За жетони відкриваються класи.",
		ru = "Жетоны дают за самый глубокий этаж забега (не за каждый подбор или убийство); победа — вдвое больше. За жетоны открываются классы.",
		en = "Tokens come from the deepest floor you reach (not every pickup or kill); a win doubles them. Tokens unlock classes.",
	},
	["menu.title"] = { uk = "МЕНЮ", ru = "МЕНЮ", en = "MENU" },
	["menu.resume"] = { uk = "Продовжити", ru = "Продолжить", en = "Resume" },
	["menu.howTo"] = { uk = "Як грати", ru = "Как играть", en = "How to play" },
	["menu.leave"] = { uk = "Покинути забіг", ru = "Покинуть забег", en = "Leave run" },
	["leave.title"] = {
		uk = "Покинути забіг?",
		ru = "Покинуть забег?",
		en = "Leave this run?",
	},
	["leave.body"] = {
		uk = "Ти повернешся в лобі. Усе зібране в цьому забігу пропаде. Напарники продовжать без тебе.",
		ru = "Ты вернёшься в лобби. Всё собранное в этом забеге пропадёт. Напарники продолжат без тебя.",
		en = "You'll return to the lobby. Everything from this run is lost. Your teammates keep playing.",
	},
	["leave.stay"] = { uk = "Залишитися", ru = "Остаться", en = "Stay" },
	["leave.hold"] = {
		uk = "Тримай, щоб вийти",
		ru = "Держи, чтобы выйти",
		en = "Hold to leave",
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
	["ui.chestHint"] = {
		uk = "Натисни на предмет, щоб перекласти його",
		ru = "Нажми на предмет, чтобы переложить его",
		en = "Tap an item to move it across",
	},
	["ui.backpack"] = { uk = "Рюкзак", ru = "Рюкзак", en = "Backpack" },
	["ui.emptyBackpack"] = {
		uk = "У рюкзаку нічого класти",
		ru = "В рюкзаке нечего класть",
		en = "Nothing to put away",
	},
	["ui.emptyChest"] = { uk = "Скриня порожня", ru = "Сундук пуст", en = "The chest is empty" },
	["ui.all"] = { uk = "всі", ru = "все", en = "all" },
	["ui.close"] = { uk = "Закрити", ru = "Закрыть", en = "Close" },
	["ui.continue"] = { uk = "Продовжити", ru = "Продолжить", en = "Continue" },
	-- Lobby and party
	["lobby.title"] = { uk = "SKYLINE ZERO", ru = "SKYLINE ZERO", en = "SKYLINE ZERO" },
	["lobby.liftSolo"] = { uk = "ЛІФТ · СОЛО", ru = "ЛИФТ · СОЛО", en = "LIFT · SOLO" },
	["lobby.liftGroup"] = {
		uk = "ЛІФТ · ГРУПА ДО 4",
		ru = "ЛИФТ · ГРУППА ДО 4",
		en = "LIFT · PARTY OF 4",
	},
	["lobby.hint"] = {
		uk = "Зайди в ліфт, щоб піднятися на дах. Разом з друзями — у груповий ліфт.",
		ru = "Зайди в лифт, чтобы подняться на крышу. С друзьями — в групповой лифт.",
		en = "Step into a lift to go up to the roof. Bring friends into a party lift.",
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
	["ui.attack"] = { uk = "Удар", ru = "Удар", en = "Hit" },
	["downed.title"] = { uk = "ТИ ВПАВ", ru = "ТЫ УПАЛ", en = "YOU'RE DOWN" },
	["downed.wait"] = {
		uk = "Тіммейт може підняти тебе бинтом · %d с",
		ru = "Тиммейт может поднять тебя бинтом · %d с",
		en = "A teammate can lift you with a bandage · %d s",
	},
	["downed.someone"] = {
		uk = "%s поранений! Підніми його бинтом",
		ru = "%s ранен! Подними его бинтом",
		en = "%s is down! Lift them with a bandage",
	},
	["revive.action"] = { uk = "Підняти", ru = "Поднять", en = "Revive" },
	["revive.needBandage"] = { uk = "Потрібен бинт", ru = "Нужен бинт", en = "You need a bandage" },
	["revive.revivedBy"] = { uk = "%s підняв тебе!", ru = "%s поднял тебя!", en = "%s got you up!" },
	["revive.youRevived"] = { uk = "Ти підняв: %s", ru = "Ты поднял: %s", en = "You revived %s" },
	["craft.title"] = { uk = "Верстак", ru = "Верстак", en = "Workbench" },
	["craft.button"] = { uk = "Зробити", ru = "Сделать", en = "Craft" },
	["craft.done"] = { uk = "Зроблено: %s", ru = "Сделано: %s", en = "Crafted: %s" },
	["craft.tooFar"] = {
		uk = "Підійди до верстака",
		ru = "Подойди к верстаку",
		en = "Go to the workbench",
	},
	["craft.unknown"] = {
		uk = "Невідомий рецепт",
		ru = "Неизвестный рецепт",
		en = "Unknown recipe",
	},
	["craft.haveIt"] = {
		uk = "У тебе вже є така зброя",
		ru = "У тебя уже есть такое оружие",
		en = "You already have this weapon",
	},
	["prompt.workbench"] = { uk = "Верстак", ru = "Верстак", en = "Workbench" },
	["prompt.craft"] = { uk = "Крафт", ru = "Крафт", en = "Craft" },
	["loot.Common"] = { uk = "Звичайний ящик", ru = "Обычный ящик", en = "Common crate" },
	["loot.Rare"] = { uk = "Рідкісний ящик", ru = "Редкий ящик", en = "Rare crate" },
	["loot.Gold"] = { uk = "Золотий ящик", ru = "Золотой ящик", en = "Gold crate" },
	["loot.Diamond"] = {
		uk = "Діамантовий ящик",
		ru = "Алмазный ящик",
		en = "Diamond crate",
	},
	["loot.found"] = { uk = "Знайдено: %s", ru = "Найдено: %s", en = "Found: %s" },
	["loot.empty"] = { uk = "Ящик порожній", ru = "Ящик пуст", en = "The crate is empty" },
	["loot.locked"] = {
		uk = "Замкнено. Потрібен ключ або лом",
		ru = "Заперто. Нужен ключ или лом",
		en = "Locked. You need a key or a crowbar",
	},
	["loot.breakIn"] = {
		uk = "Ти зламав замок. Шум привабив зомбі!",
		ru = "Ты взломал замок. Шум привлёк зомби!",
		en = "You broke the lock. The noise drew zombies!",
	},
	["loot.keyUsed"] = { uk = "Ключ підійшов", ru = "Ключ подошёл", en = "The key fits" },
	["prompt.unlock"] = { uk = "Ключ або лом", ru = "Ключ или лом", en = "Key or crowbar" },
	["loot.banner.Gold"] = {
		uk = "%s відкрив ЗОЛОТУ скриню!",
		ru = "%s открыл ЗОЛОТОЙ сундук!",
		en = "%s opened a GOLD chest!",
	},
	["loot.banner.Diamond"] = {
		uk = "%s відкрив ДІАМАНТОВУ скриню!",
		ru = "%s открыл АЛМАЗНЫЙ сундук!",
		en = "%s opened a DIAMOND chest!",
	},
	["item.Key.name"] = { uk = "Ключ", ru = "Ключ", en = "Key" },
	["item.Key.desc"] = {
		uk = "Відкриває діамантову скриню без шуму.",
		ru = "Открывает алмазный сундук без шума.",
		en = "Opens a diamond chest quietly.",
	},

	["downed.waitTeam"] = {
		uk = "Чекай, поки тіммейт підніме тебе бинтом",
		ru = "Жди, пока тиммейт поднимет тебя бинтом",
		en = "Wait for a teammate to lift you with a bandage",
	},
	["gameover.title"] = { uk = "ВИ ПРОГРАЛИ", ru = "ВЫ ПРОИГРАЛИ", en = "YOU LOST" },
	["gameover.body"] = {
		uk = "Ніхто не встояв на ногах. Вежа перемогла цього разу.",
		ru = "Никто не устоял на ногах. Башня победила в этот раз.",
		en = "Nobody is left standing. The tower wins this time.",
	},
	["gameover.footer"] = {
		uk = "Повертаємось у лобі…",
		ru = "Возвращаемся в лобби…",
		en = "Back to the lobby…",
	},
	["hint.attackTouch"] = {
		uk = "Натисни «Удар», щоб вдарити. Зброю вибери в інвентарі внизу.",
		ru = "Нажми «Удар», чтобы ударить. Оружие выбери в инвентаре внизу.",
		en = "Press Hit to attack. Pick a weapon from the inventory below.",
	},
	["hint.attackPc"] = {
		uk = "Клікни мишкою, щоб ударити. Зброя: клавіші 1–0.",
		ru = "Кликни мышкой, чтобы ударить. Оружие: клавиши 1–0.",
		en = "Click to hit. Weapons: keys 1–0.",
	},
	["hint.attackPad"] = {
		uk = "R2 — удар. L1/R1 — вибрати зброю.",
		ru = "R2 — удар. L1/R1 — выбрать оружие.",
		en = "R2 to hit. L1/R1 to pick a weapon.",
	},
	["hint.scrapNotCrowbar"] = {
		uk = "Металобрухт — для будівництва на даху. Лом — окремий інструмент для завалів.",
		ru = "Металлолом — для построек на крыше. Лом — отдельный инструмент для завалов.",
		en = "Scrap is for roof builds. The Crowbar is a separate tool for rubble.",
	},
	["inv.weaponReplaced"] = {
		uk = "Нова зброя замінила стару слабшу.",
		ru = "Новое оружие заменило старое слабое.",
		en = "New weapon replaced your weaker one.",
	},
	["results.floor"] = {
		uk = "Найглибший поверх (жетони)",
		ru = "Самый глубокий этаж (жетоны)",
		en = "Deepest floor (tokens)",
	},
	["results.chests"] = {
		uk = "Відкрито скринь",
		ru = "Открыто сундуков",
		en = "Chests opened",
	},
	["results.zombies"] = { uk = "Убито зомбі", ru = "Убито зомби", en = "Zombies killed" },
	["results.builds"] = { uk = "Збудовано", ru = "Построено", en = "Built" },
	["results.revives"] = {
		uk = "Піднято тіммейтів",
		ru = "Поднято тиммейтов",
		en = "Teammates lifted",
	},
	["results.winBonus"] = { uk = "Перемога ×%d", ru = "Победа ×%d", en = "Victory ×%d" },
	["results.earned"] = { uk = "+%d жетонів", ru = "+%d жетонов", en = "+%d tokens" },
	["results.total"] = {
		uk = "Усього жетонів: %d",
		ru = "Всего жетонов: %d",
		en = "Total tokens: %d",
	},
	["results.best"] = {
		uk = "Найкраща скриня: %s",
		ru = "Лучший сундук: %s",
		en = "Best chest: %s",
	},
	["results.lostSub"] = {
		uk = "Жетони за матч усе одно твої.",
		ru = "Жетоны за матч всё равно твои.",
		en = "You keep the tokens you earned.",
	},
	["lobby.tokens"] = { uk = "Жетони: %d", ru = "Жетоны: %d", en = "Tokens: %d" },
	["intro.kicker"] = { uk = "SKYLINE ZERO", ru = "SKYLINE ZERO", en = "SKYLINE ZERO" },
	["intro.title"] = { uk = "МІСТО ВПАЛО", ru = "ГОРОД ПАЛ", en = "THE CITY FELL" },
	["intro.body"] = {
		uk = "Пів року тому місто накрила катастрофа. Вулиці поглинули зарості й заражені. Ти прокинувся на даху хмарочоса, на останньому безпечному місці. Унизу темно, отруйно й повно зомбі, але лише там є все, щоб вибратися.",
		ru = "Полгода назад город накрыла катастрофа. Улицы поглотили заросли и заражённые. Ты очнулся на крыше небоскрёба, в последнем безопасном месте. Внизу темно, ядовито и полно зомби, но только там есть всё, чтобы выбраться.",
		en = "Six months ago the city fell. The streets belong to the overgrowth and the infected now. You woke up on a skyscraper roof, the last safe place. Down below it is dark, toxic and crawling with zombies, but that is where everything you need to escape is.",
	},
	["intro.goal1"] = {
		uk = "Спускайся поверхами й збирай ресурси",
		ru = "Спускайся по этажам и собирай ресурсы",
		en = "Go down the floors and scavenge",
	},
	["intro.goal2"] = {
		uk = "Складай знахідки в скриню на даху",
		ru = "Складывай находки в сундук на крыше",
		en = "Store your finds in the chest on the roof",
	},
	["intro.goal3"] = {
		uk = "Збудуй генератор, фільтр і міст",
		ru = "Построй генератор, фильтр и мост",
		en = "Build the generator, the filter and the bridge",
	},
	["intro.goal4"] = {
		uk = "Перейди мостом на сусідню вежу, і ти вільний",
		ru = "Перейди по мосту на соседнюю башню, и ты свободен",
		en = "Cross the bridge to the next tower to escape",
	},
	["intro.goal5"] = {
		uk = "Пораненого піднімає тіммейт з бинтом. Упадуть усі, і гру програно",
		ru = "Раненого поднимает тиммейт с бинтом. Упадут все, и игра проиграна",
		en = "A teammate with a bandage can lift you up. If everyone falls, you lose",
	},
	["intro.start"] = { uk = "ПОЧАТИ", ru = "НАЧАТЬ", en = "START" },
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
	local def = ItemDefinitions.Get(itemId)
	return { ref = "item." .. itemId .. ".name", rarity = def and def.rarity }
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
		if type(arg.rarity) == "string" then
			return ("%s · %s"):format(raw(lang, arg.ref), raw(lang, "rarity." .. arg.rarity))
		end
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

-- "Bat · Rare weapon" for weapons, the plain name for everything else.
function Locale.ItemWithRarity(lang: Lang, itemId: string): string
	return resolveArg(lang, Locale.Item(itemId))
end

function Locale.ItemDesc(lang: Lang, itemId: string): string
	return raw(lang, "item." .. itemId .. ".desc")
end

function Locale.UpgradeName(lang: Lang, upgradeId: string): string
	return raw(lang, "upgrade." .. upgradeId .. ".name")
end

-- The language a player reads in: the one picked in the Roblox menu (Player.LocaleId), English otherwise.
function Locale.ForPlayer(player: Player): Lang
	return Locale.Resolve(player.LocaleId)
end

return Locale
