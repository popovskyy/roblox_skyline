--!strict
-- Tutorial objectives, the emergency terminal note and the tower ending.
-- Each step checks the player's current state, so a step can never get stuck when the action was done earlier.

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local PlacesConfig = require(ReplicatedStorage.Shared.PlacesConfig)
local RemoteNames = require(ReplicatedStorage.Shared.RemoteNames)
local Types = require(ReplicatedStorage.Shared.Types)
local UpgradeDefinitions = require(ReplicatedStorage.Shared.UpgradeDefinitions)
local CharacterUtil = require(script.Parent.CharacterUtil)
local HazardService = require(script.Parent.HazardService)
local MatchStatsService = require(script.Parent.MatchStatsService)
local Net = require(script.Parent.Net)
local PlayerDataService = require(script.Parent.PlayerDataService)
local SfxService = require(script.Parent.SfxService)
local StateSyncService = require(script.Parent.StateSyncService)
local StorageService = require(script.Parent.StorageService)

local TutorialService = {}

local TERMINAL_NOTE_ID = "Terminal01"
local idleSeconds: { [Player]: number } = {}
local idleNudged: { [Player]: boolean } = {}

type Step = {
	text: string, -- Locale key
	-- Sticky steps depend on permanent progress, so reaching them lets the tutorial jump forward.
	sticky: boolean,
	complete: (player: Player, data: Types.PlayerData) -> boolean,
	-- Collecting steps: how many the player has (carried + in the chest) and how many are needed,
	-- shown live in the HUD as "2/4".
	progress: ((player: Player) -> (number, number))?,
}

local Steps: { Step } = {
	{
		text = "tutorial.1",
		sticky = false,
		complete = function(_, data)
			return data.discoveredNotes[TERMINAL_NOTE_ID] == true
		end,
	},
	{
		text = "tutorial.2",
		sticky = false,
		-- Chest costs 10 Scrap: shared F1 path (3×4) + soft wing (3) = 15.
		complete = function(player)
			return StorageService.Total(player, "Scrap") >= 10
		end,
		progress = function(player)
			return math.min(StorageService.Total(player, "Scrap"), 10), 10
		end,
	},
	{
		text = "tutorial.3",
		sticky = false,
		complete = function(player)
			return not HazardService.IsOnExpedition(player)
		end,
	},
	{
		text = "tutorial.4",
		sticky = true,
		complete = function(_, data)
			return data.upgrades.StorageCrate
		end,
	},
	{
		text = "tutorial.5",
		sticky = false,
		complete = function(player)
			return StorageService.Total(player, "Electronics") >= 5
		end,
		progress = function(player)
			return math.min(StorageService.Total(player, "Electronics"), 5), 5
		end,
	},
	{
		text = "tutorial.6",
		sticky = true,
		complete = function(_, data)
			return data.upgrades.Generator
		end,
	},
	{
		text = "tutorial.7",
		sticky = true,
		complete = function(_, data)
			return data.towerCompleted
		end,
		progress = function(player)
			local have = math.min(StorageService.Total(player, "Cable"), 4)
				+ math.min(StorageService.Total(player, "Motor"), 2)
			return have, 6
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
		-- No tutorial.new toast: ЦІЛЬ strip + marker already teach the new step.
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
	-- Reading the note counts as the first meaningful action: hunger can start draining.
	HazardService.UnlockHunger(player)
	idleNudged[player] = true
	idleSeconds[player] = 0
	local acts = countActs(data)
	Net.Get(RemoteNames.ShowNote):FireClient(player, {
		kind = "note",
		title = "note.terminal.title",
		body = "note.terminal.body",
		footer = { "note.terminal.footer", acts },
	})
	StateSyncService.Request(player)
end

-- Lobby leaderboard: towers completed per player (one tower for now, so the value is 1).
local function recordCompletion(player: Player)
	local ok, err = pcall(function()
		local store = DataStoreService:GetOrderedDataStore(PlacesConfig.LeaderboardStoreName)
		store:UpdateAsync(tostring(player.UserId), function(old)
			return math.max(tonumber(old) or 0, 1)
		end)
	end)
	if not ok then
		warn("[Tutorial] leaderboard update failed:", err)
	end
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
		task.spawn(recordCompletion, player)
	end
	-- The results screen shows the win and the doubled tokens.
	task.spawn(MatchStatsService.Finish, player, true, true)
end

function TutorialService.Init()
	StateSyncService.RegisterProvider(function(player, snapshot)
		local data = PlayerDataService.Get(player)
		if not data then
			return
		end
		local step = evaluate(player, data)
		local current = Steps[step]
		local have, need = nil, nil
		if current and current.progress then
			have, need = current.progress(player)
		end
		snapshot.tutorial = {
			have = have,
			need = need,
			step = step,
			total = #Steps,
			text = if step <= #Steps then Steps[step].text else "tutorial.done",
			done = step > #Steps,
		}
		snapshot.acts = countActs(data)
		snapshot.towerCompleted = data.towerCompleted
	end)
end

local function findTerminal(): BasePart?
	local world = workspace:FindFirstChild(GameConfig.World.FolderName)
	local folder = world and world:FindFirstChild("Interactables")
	local terminal = folder and folder:FindFirstChild("EmergencyTerminal")
	if terminal and terminal:IsA("BasePart") then
		return terminal
	end
	return nil
end

-- Soft ping + marker bob if the player freezes on the roof before reading the terminal.
local function updateIdleNudge(player: Player, dt: number)
	if idleNudged[player] then
		return
	end
	local data = PlayerDataService.Get(player)
	if not data or data.tutorialStep > 1 or data.discoveredNotes[TERMINAL_NOTE_ID] then
		idleNudged[player] = true
		return
	end
	if HazardService.GetZone(player) ~= "Roof" then
		idleSeconds[player] = 0
		return
	end
	local root = CharacterUtil.GetRoot(player)
	if not root then
		idleSeconds[player] = 0
		return
	end
	local velocity = root.AssemblyLinearVelocity
	local horizontal = Vector3.new(velocity.X, 0, velocity.Z).Magnitude
	if horizontal > GameConfig.IdleNudgeMoveSpeed then
		idleSeconds[player] = 0
		return
	end
	local idle = (idleSeconds[player] or 0) + dt
	idleSeconds[player] = idle
	if idle < GameConfig.IdleNudgeSeconds then
		return
	end
	idleNudged[player] = true
	local terminal = findTerminal()
	if terminal then
		-- Soft UI ping at the terminal (Click is already in SoundConfig; no new asset id).
		SfxService.Play("Click", terminal, 1.1)
	end
	-- Client marker reads this and bobs harder for a few seconds.
	player:SetAttribute("ObjectiveNudge", os.clock())
end

function TutorialService.Start()
	HazardService.OnZoneChanged(onZoneChanged)
	HazardService.OnReturnedToRoof(function(player)
		StateSyncService.Request(player)
	end)
	local accumulator = 0
	RunService.Heartbeat:Connect(function(dt)
		accumulator += dt
		if accumulator < 0.5 then
			return
		end
		local step = accumulator
		accumulator = 0
		for _, player in Players:GetPlayers() do
			updateIdleNudge(player, step)
		end
	end)
	Players.PlayerRemoving:Connect(function(player)
		idleSeconds[player] = nil
		idleNudged[player] = nil
	end)
end

return TutorialService
