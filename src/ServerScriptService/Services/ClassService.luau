--!strict
-- Applies the class each player picked in the lobby (read from the meta save, so it cannot be faked):
-- sets the "Class" attribute, adds the starting items and boosts walk speed. Other perks are read where
-- they apply (Combat: damage, BaseUpgrade: costs, Flashlight: drain, clients: revive hold, resource glow).
-- Loading never delays the player's spawn; the class arrives a moment later.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Classes = require(ReplicatedStorage.Shared.Classes)
local MetaProgress = require(ReplicatedStorage.Shared.MetaProgress)
local CharacterUtil = require(script.Parent.CharacterUtil)
local InventoryService = require(script.Parent.InventoryService)
local Net = require(script.Parent.Net)
local PlayerDataService = require(script.Parent.PlayerDataService)
local StateSyncService = require(script.Parent.StateSyncService)

local ClassService = {}

local BASE_WALK_SPEED = 16

local function applySpeed(player: Player)
	local humanoid = CharacterUtil.GetHumanoid(player)
	local def = Classes.Of(player)
	if humanoid then
		humanoid.WalkSpeed = BASE_WALK_SPEED * (if def and def.walkSpeed then def.walkSpeed else 1)
	end
end

local function giveStartItems(player: Player, def: Classes.ClassDef)
	local data = PlayerDataService.Get(player)
	if not data or not def.startItems then
		return
	end
	for itemId, amount in def.startItems do
		if amount <= 0 then
			data.inventory[itemId] = 0
		else
			InventoryService.ForceAdd(player, itemId, amount)
		end
	end
	StateSyncService.Request(player)
end

local function load(player: Player)
	local meta = MetaProgress.Load(player.UserId)
	if player.Parent ~= Players then
		return
	end
	local def = Classes.Get(meta.selected)
	if not def or not meta.classes[def.id] then
		return
	end
	player:SetAttribute("Class", def.id)
	giveStartItems(player, def)
	applySpeed(player)
	Net.Notify(player, { "class.playing", { ref = "class." .. def.id .. ".name" } }, "info")
end

function ClassService.OnPlayerLoaded(player: Player)
	task.spawn(load, player)
end

-- Fresh character (also after a respawn): class speed again.
function ClassService.OnCharacterAdded(player: Player)
	applySpeed(player)
end

-- A new match on this server: the class's starting items again.
function ClassService.OnReset(player: Player)
	local def = Classes.Of(player)
	if def then
		giveStartItems(player, def)
	end
end

return ClassService
