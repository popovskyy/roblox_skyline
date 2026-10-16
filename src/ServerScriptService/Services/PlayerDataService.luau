--!strict
-- Loads, validates and saves persistent player data.
-- A failed load never overwrites the saved record: saving is turned off for that session instead.

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local ItemDefinitions = require(ReplicatedStorage.Shared.ItemDefinitions)
local UpgradeDefinitions = require(ReplicatedStorage.Shared.UpgradeDefinitions)
local Types = require(ReplicatedStorage.Shared.Types)

type PlayerData = Types.PlayerData
type ItemCounts = Types.ItemCounts

type Session = {
	data: PlayerData,
	canSave: boolean,
	dirty: boolean,
	dataVersion: number, -- version of the record this session last loaded or wrote
	saving: boolean,
}

local PlayerDataService = {}

local sessions: { [Player]: Session } = {}
local store: DataStore? = nil
local storeError: string? = nil

local function keyFor(player: Player): string
	return "Player_" .. tostring(player.UserId)
end

local function isCount(value: any): boolean
	return type(value) == "number" and value == value and value >= 0 and value < math.huge and value % 1 == 0
end

local function emptyCounts(): ItemCounts
	local counts: ItemCounts = {}
	for id in ItemDefinitions.Items do
		counts[id] = 0
	end
	return counts
end

function PlayerDataService.DefaultData(): PlayerData
	local inventory = emptyCounts()
	for id, def in ItemDefinitions.Items do
		inventory[id] = def.startAmount
	end
	local upgrades = {}
	for id in UpgradeDefinitions.Upgrades do
		upgrades[id] = false
	end
	return {
		schemaVersion = GameConfig.SchemaVersion,
		inventory = inventory,
		storage = emptyCounts(),
		upgrades = upgrades,
		flashlightCharge = 0,
		uniqueNodesTaken = {},
		towerCompleted = false,
		tutorialStep = 1,
		discoveredNotes = {},
		ownedPasses = {},
		processedReceipts = {},
	}
end

local function sanitizeCounts(raw: any, fallback: ItemCounts): ItemCounts
	local result = table.clone(fallback)
	if type(raw) ~= "table" then
		return result
	end
	for id in ItemDefinitions.Items do
		local value = raw[id]
		if isCount(value) then
			result[id] = value
		end
	end
	return result
end

local function sanitizeFlags(raw: any): { [string]: boolean }
	local result = {}
	if type(raw) == "table" then
		for key, value in raw do
			if type(key) == "string" and value == true then
				result[key] = true
			end
		end
	end
	return result
end

-- Turns an untrusted stored record into a valid PlayerData, filling gaps with defaults.
local function sanitize(raw: any): PlayerData
	local data = PlayerDataService.DefaultData()
	if type(raw) ~= "table" then
		return data
	end
	data.inventory = sanitizeCounts(raw.inventory, data.inventory)
	data.storage = sanitizeCounts(raw.storage, emptyCounts())
	if type(raw.upgrades) == "table" then
		for id in UpgradeDefinitions.Upgrades do
			data.upgrades[id] = raw.upgrades[id] == true
		end
	end
	if isCount(raw.tutorialStep) and raw.tutorialStep >= 1 then
		data.tutorialStep = raw.tutorialStep
	end
	data.discoveredNotes = sanitizeFlags(raw.discoveredNotes)
	data.uniqueNodesTaken = sanitizeFlags(raw.uniqueNodesTaken)
	data.ownedPasses = sanitizeFlags(raw.ownedPasses)
	data.processedReceipts = sanitizeFlags(raw.processedReceipts)
	local charge = raw.flashlightCharge
	if type(charge) == "number" and charge == charge and charge >= 0 then
		data.flashlightCharge = math.min(charge, GameConfig.FlashlightBatterySeconds)
	end
	data.towerCompleted = raw.towerCompleted == true
	return data
end

local function serialize(data: PlayerData, version: number): { [string]: any }
	return {
		schemaVersion = GameConfig.SchemaVersion,
		dataVersion = version,
		inventory = table.clone(data.inventory),
		storage = table.clone(data.storage),
		upgrades = table.clone(data.upgrades),
		flashlightCharge = data.flashlightCharge,
		uniqueNodesTaken = table.clone(data.uniqueNodesTaken),
		towerCompleted = data.towerCompleted,
		tutorialStep = data.tutorialStep,
		discoveredNotes = table.clone(data.discoveredNotes),
		ownedPasses = table.clone(data.ownedPasses),
		processedReceipts = table.clone(data.processedReceipts),
		updatedAt = os.time(),
	}
end

function PlayerDataService.Init()
	local ok, result = pcall(function()
		return DataStoreService:GetDataStore(GameConfig.DataStoreName)
	end)
	if ok then
		store = result
	else
		storeError = tostring(result)
		warn("[PlayerData] DataStore unavailable, progress will not be saved:", storeError)
	end
end

-- Returns true when real saved data (or a confirmed new player) was loaded.
function PlayerDataService.Load(player: Player): boolean
	local session: Session = {
		data = PlayerDataService.DefaultData(),
		canSave = false,
		dirty = false,
		dataVersion = 0,
		saving = false,
	}

	if store then
		local activeStore = store :: DataStore
		for attempt = 1, GameConfig.DataRetryAttempts do
			local ok, result = pcall(function()
				return activeStore:GetAsync(keyFor(player))
			end)
			if ok then
				session.data = sanitize(result)
				if type(result) == "table" and isCount(result.dataVersion) then
					session.dataVersion = result.dataVersion
				end
				session.canSave = true
				break
			end
			warn(("[PlayerData] Load attempt %d failed for %s: %s"):format(attempt, player.Name, tostring(result)))
			local message = tostring(result)
			if message:find("StudioAccessToApisNotAllowed") or message:find("403") then
				-- Studio without API access: retrying will not help, so start right away without saving.
				warn("[PlayerData] Enable Game Settings > Security > Studio Access to API Services to test saving")
				break
			end
			if attempt < GameConfig.DataRetryAttempts then
				task.wait(GameConfig.DataRetryDelaySeconds * attempt)
			end
		end
	end

	if player.Parent ~= Players then
		return false
	end
	sessions[player] = session
	return session.canSave
end

function PlayerDataService.Get(player: Player): PlayerData?
	local session = sessions[player]
	return session and session.data
end

function PlayerDataService.CanSave(player: Player): boolean
	local session = sessions[player]
	return session ~= nil and session.canSave
end

function PlayerDataService.MarkDirty(player: Player)
	local session = sessions[player]
	if session then
		session.dirty = true
	end
end

function PlayerDataService.Save(player: Player): boolean
	local session = sessions[player]
	if not session or not session.canSave or not store then
		return false
	end
	if not session.dirty then
		return true
	end
	if session.saving then
		return false
	end
	session.saving = true
	session.dirty = false
	local activeStore = store :: DataStore

	local saved = false
	for attempt = 1, GameConfig.DataRetryAttempts do
		local conflict = false
		local newVersion = session.dataVersion
		local ok, err = pcall(function()
			activeStore:UpdateAsync(keyFor(player), function(old: any)
				conflict = false
				-- Another server wrote a newer record: never replace it with this older state.
				if type(old) == "table" and isCount(old.dataVersion) and old.dataVersion > session.dataVersion then
					conflict = true
					return nil
				end
				newVersion = session.dataVersion + 1
				return serialize(session.data, newVersion)
			end)
		end)
		if ok then
			if conflict then
				warn(("[PlayerData] Newer record exists for %s, saving disabled for this session"):format(player.Name))
				session.canSave = false
			else
				session.dataVersion = newVersion
				saved = true
			end
			break
		end
		warn(("[PlayerData] Save attempt %d failed for %s: %s"):format(attempt, player.Name, tostring(err)))
		if attempt < GameConfig.DataRetryAttempts then
			task.wait(GameConfig.DataRetryDelaySeconds * attempt)
		end
	end

	if not saved and session.canSave then
		session.dirty = true -- try again on the next autosave
	end
	session.saving = false
	return saved
end

function PlayerDataService.Release(player: Player)
	local session = sessions[player]
	if not session then
		return
	end
	-- Wait for an in-flight autosave so the final save is not skipped.
	local waited = 0
	while session.saving and waited < 10 do
		waited += task.wait(0.1)
	end
	PlayerDataService.Save(player)
	sessions[player] = nil
end

function PlayerDataService.Start()
	task.spawn(function()
		while true do
			task.wait(GameConfig.AutosaveIntervalSeconds)
			for player in sessions do
				task.spawn(PlayerDataService.Save, player)
			end
		end
	end)

	game:BindToClose(function()
		local pending = 0
		for player in sessions do
			pending += 1
			task.spawn(function()
				PlayerDataService.Release(player)
				pending -= 1
			end)
		end
		local started = os.clock()
		while pending > 0 and os.clock() - started < 25 do
			task.wait(0.1)
		end
	end)
end

function PlayerDataService.GetStoreError(): string?
	return storeError
end

return PlayerDataService
