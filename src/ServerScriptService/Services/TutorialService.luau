--!strict
-- Tutorial objectives, the emergency terminal note and the tower ending.
-- Each step checks the player's current state, so a step can never get stuck when the action was done earlier.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RemoteNames = require(ReplicatedStorage.Shared.RemoteNames)
local Types = require(ReplicatedStorage.Shared.Types)
local UpgradeDefinitions = require(ReplicatedStorage.Shared.UpgradeDefinitions)
local HazardService = require(script.Parent.HazardService)
local Net = require(script.Parent.Net)
local PlayerDataService = require(script.Parent.PlayerDataService)
local StateSyncService = require(script.Parent.StateSyncService)
local StorageService = require(script.Parent.StorageService)

local TutorialService = {}

local TERMINAL_NOTE_ID = "Terminal01"

type Step = {
	text: string,
	-- Sticky steps depend on permanent progress, so reaching them lets the tutorial jump forward.
	sticky: boolean,
	complete: (player: Player, data: Types.PlayerData) -> boolean,
}

local Steps: { Step } = {
	{
		text = "Знайди аварійний термінал на даху",
		sticky = false,
		complete = function(_, data)
			return data.discoveredNotes[TERMINAL_NOTE_ID] == true
		end,
	},
	{
		text = "Спустись сходами й збери 3 металобрухту на технічному поверсі",
		sticky = false,
		complete = function(player)
			return StorageService.Total(player, "Scrap") >= 3
		end,
	},
	{
		text = "Повернись на дах",
		sticky = false,
		complete = function(player)
			return not HazardService.IsOnExpedition(player)
		end,
	},
	{
		text = "Збудуй сховище (8 металобрухту)",
		sticky = true,
		complete = function(_, data)
			return data.upgrades.StorageCrate
		end,
	},
	{
		text = "Знайди 4 електронні деталі",
		sticky = false,
		complete = function(player)
			return StorageService.Total(player, "Electronics") >= 4
		end,
	},
	{
		text = "Увімкни генератор на даху",
		sticky = true,
		complete = function(_, data)
			return data.upgrades.Generator
		end,
	},
	{
		text = "Знайди кабель і мотор на 4 поверсі, полагодь міст і перейди на сусідню вежу",
		sticky = true,
		complete = function(_, data)
			return data.towerCompleted
		end,
	},
}

local function countActs(data: Types.PlayerData): number
	local acts = 0
	for id, def in UpgradeDefinitions.Upgrades do
		if def.act and data.upgrades[id] then
			acts += 1
		end
	end
	return acts
end

local function evaluate(player: Player, data: Types.PlayerData): number
	local step = math.clamp(data.tutorialStep, 1, #Steps + 1)
	for i = #Steps, 1, -1 do
		if Steps[i].sticky and Steps[i].complete(player, data) then
			step = math.max(step, i + 1)
			break
		end
	end
	while step <= #Steps and Steps[step].complete(player, data) do
		step += 1
	end
	if step ~= data.tutorialStep then
		data.tutorialStep = step
		PlayerDataService.MarkDirty(player)
		if step <= #Steps then
			Net.Notify(player, "Нова ціль: " .. Steps[step].text, "info")
		end
	end
	return step
end

function TutorialService.ReadTerminal(player: Player)
	local data = PlayerDataService.Get(player)
	if not data then
		return
	end
	if not data.discoveredNotes[TERMINAL_NOTE_ID] then
		data.discoveredNotes[TERMINAL_NOTE_ID] = true
		PlayerDataService.MarkDirty(player)
	end
	local acts = countActs(data)
	Net.Get(RemoteNames.ShowNote):FireClient(player, {
		kind = "note",
		title = "Аварійний термінал",
		body = "«Якщо ти це читаєш, дах ще тримається. Генератор не працює, а вентиляція нижче забита. "
			.. "Не спускайся без ліхтаря. Ми пробували дістатися до сусідньої вежі, але міст обвалився. "
			.. "Знайди деталі — можливо, зможеш повернути світло».",
		footer = ("Відновлено систем: %d / 3   (світло, повітря, міст)"):format(acts),
	})
	StateSyncService.Request(player)
end

-- Crossing the finished bridge onto the neighbour roof ends the tower.
local function onZoneChanged(player: Player, newZone: string)
	if newZone ~= "NeighborRoof" then
		return
	end
	local data = PlayerDataService.Get(player)
	if not data or not data.upgrades.Bridge then
		return
	end
	local firstTime = not data.towerCompleted
	data.towerCompleted = true
	PlayerDataService.MarkDirty(player)
	StateSyncService.Request(player)
	if firstTime then
		task.spawn(PlayerDataService.Save, player)
	end
	Net.Get(RemoteNames.ShowNote):FireClient(player, {
		kind = "ending",
		title = "Вежу 1 пройдено!",
		body = "Ти повернув світло, очистив повітря й полагодив міст. Попереду нова вежа і нові поверхи.",
		footer = "Skyline Zero · прототип · Дякуємо за гру!",
	})
end

function TutorialService.Init()
	StateSyncService.RegisterProvider(function(player, snapshot)
		local data = PlayerDataService.Get(player)
		if not data then
			return
		end
		local step = evaluate(player, data)
		snapshot.tutorial = {
			step = step,
			total = #Steps,
			text = if step <= #Steps
				then Steps[step].text
				else "Вежу пройдено. Можеш і далі досліджувати поверхи",
			done = step > #Steps,
		}
		snapshot.acts = countActs(data)
		snapshot.towerCompleted = data.towerCompleted
	end)
end

function TutorialService.Start()
	HazardService.OnZoneChanged(onZoneChanged)
	HazardService.OnReturnedToRoof(function(player)
		StateSyncService.Request(player)
	end)
end

return TutorialService
