--!strict
-- Intentional ground drops: party members can pick them up. Death backpacks stay personal.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local ItemDefinitions = require(ReplicatedStorage.Shared.ItemDefinitions)
local Locale = require(ReplicatedStorage.Shared.Locale)
local RemoteNames = require(ReplicatedStorage.Shared.RemoteNames)
local CharacterUtil = require(script.Parent.CharacterUtil)
local InventoryService = require(script.Parent.InventoryService)
local Net = require(script.Parent.Net)
local RateLimiter = require(script.Parent.RateLimiter)
local StateSyncService = require(script.Parent.StateSyncService)

local DropService = {}

local interactables: Folder? = nil
local nextId = 0

type GroundDrop = {
	part: BasePart,
	itemId: string,
	amount: number,
	ownerUserId: number,
}

local drops: { [BasePart]: GroundDrop } = {}

function DropService.SetInteractables(folder: Folder)
	interactables = folder
end

local function destroyDrop(part: BasePart)
	local entry = drops[part]
	if not entry then
		return
	end
	drops[part] = nil
	if part.Parent then
		part:Destroy()
	end
end

function DropService.Drop(player: Player, itemId: any, amount: any): (boolean, any)
	local dataFolder = interactables
	if not dataFolder then
		return false, nil
	end
	if type(itemId) ~= "string" or not ItemDefinitions.IsValid(itemId) then
		return false, "drop.badItem"
	end
	local def = ItemDefinitions.Items[itemId]
	-- Storable loot only (meds, scrap, electronics…). Tools/weapons stay equipped.
	if not def or not def.storable then
		return false, "drop.cantDrop"
	end
	local count = if type(amount) == "number" then amount else 1
	if not InventoryService.IsPositiveInt(count) or count > 50 then
		return false, "drop.badAmount"
	end
	local root = CharacterUtil.GetRoot(player)
	if not root then
		return false, nil
	end
	if not InventoryService.Remove(player, itemId, count) then
		return false, "drop.none"
	end

	nextId += 1
	local part = Instance.new("Part")
	part.Name = "GroundDrop_" .. tostring(nextId)
	part.Size = Vector3.new(1.6, 0.8, 1.6)
	part.Color = Color3.fromRGB(90, 88, 82)
	part.Material = Enum.Material.Metal
	part.Anchored = true
	part.CanCollide = false
	part.Position = root.Position + root.CFrame.LookVector * 3 - Vector3.new(0, 2.2, 0)
	part:SetAttribute("InteractType", "GroundDrop")
	part:SetAttribute("ItemId", itemId)
	part:SetAttribute("Amount", count)
	part:SetAttribute("DropOwnerUserId", player.UserId)

	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = Locale.T("en", "prompt.pickupDrop")
	prompt:SetAttribute("ActionKey", "prompt.pickupDrop")
	prompt.ObjectText = Locale.T("en", "item." .. itemId .. ".name")
	prompt:SetAttribute("ObjectKey", "item." .. itemId .. ".name")
	prompt.MaxActivationDistance = GameConfig.PromptActivationDistance
	prompt.RequiresLineOfSight = false
	prompt.Parent = part
	part.Parent = dataFolder

	local entry: GroundDrop = {
		part = part,
		itemId = itemId,
		amount = count,
		ownerUserId = player.UserId,
	}
	drops[part] = entry

	local ttl = GameConfig.GroundDropLifetimeSeconds or 120
	task.delay(ttl, function()
		if drops[part] == entry then
			destroyDrop(part)
		end
	end)

	StateSyncService.Request(player)
	Net.Notify(player, { "drop.dropped", Locale.Item(itemId), count }, "info")
	return true, nil
end

function DropService.Pickup(player: Player, part: BasePart): (boolean, any)
	local entry = drops[part]
	if not entry or entry.part ~= part then
		return false, "drop.gone"
	end
	if not InventoryService.CanAdd(player, entry.itemId, entry.amount) then
		return false, "res.full"
	end
	drops[part] = nil
	InventoryService.Add(player, entry.itemId, entry.amount)
	part:Destroy()
	StateSyncService.Request(player)
	Net.Notify(player, { "drop.picked", Locale.Item(entry.itemId), entry.amount }, "success")
	return true, nil
end

function DropService.Start()
	Net.Get(RemoteNames.DropItem).OnServerEvent:Connect(function(player, itemId, amount)
		if not RateLimiter.Allow(player, "DropItem", 0.35) then
			return
		end
		local ok, reason = DropService.Drop(player, itemId, amount)
		if not ok and reason then
			Net.Notify(player, reason, "warning")
		end
	end)
	Players.PlayerRemoving:Connect(function(_player)
		-- Drops stay in the world for teammates; no owner cleanup.
	end)
end

return DropService
