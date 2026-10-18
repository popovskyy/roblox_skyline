--!strict
-- Dropping items on the ground for teammates. The item leaves the inventory at once and lies at the
-- player's feet as a small glowing bundle with a "Pick up" prompt; anyone can take it.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local ItemDefinitions = require(ReplicatedStorage.Shared.ItemDefinitions)
local Locale = require(ReplicatedStorage.Shared.Locale)
local RemoteNames = require(ReplicatedStorage.Shared.RemoteNames)
local CharacterUtil = require(script.Parent.CharacterUtil)
local DamageService = require(script.Parent.DamageService)
local InventoryService = require(script.Parent.InventoryService)
local Net = require(script.Parent.Net)
local RateLimiter = require(script.Parent.RateLimiter)
local SfxService = require(script.Parent.SfxService)
local StateSyncService = require(script.Parent.StateSyncService)

local DropService = {}

local folder: Instance? = nil
local counter = 0

function DropService.SetFolder(interactables: Instance)
	folder = interactables
end

local function makeBundle(itemId: string, amount: number, position: Vector3): BasePart
	local def = ItemDefinitions.Items[itemId]
	counter += 1
	local part = Instance.new("Part")
	part.Name = "Drop_" .. counter
	part.Size = Vector3.new(1.4, 1, 1.4)
	part.Anchored = true
	part.CanCollide = false
	part.Color = def.color
	part.Material = Enum.Material.SmoothPlastic
	part.CFrame = CFrame.new(position) * CFrame.Angles(0, math.random() * math.pi * 2, 0)
	part:SetAttribute("InteractType", "Drop")
	part:SetAttribute("ItemId", itemId)
	part:SetAttribute("Amount", amount)

	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(255, 214, 140)
	light.Range = 6
	light.Brightness = 0.8
	light.Parent = part

	-- The item's icon floating above, so it reads from a distance.
	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.fromScale(2, 2)
	billboard.StudsOffset = Vector3.new(0, 1.6, 0)
	billboard.LightInfluence = 0
	billboard.MaxDistance = 60
	billboard.Parent = part
	local image = Instance.new("ImageLabel")
	image.Size = UDim2.fromScale(1, 1)
	image.BackgroundTransparency = 1
	image.Image = def.iconImage or ""
	image.ImageColor3 = def.iconTint or Color3.new(1, 1, 1)
	image.Parent = billboard

	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = Locale.T("en", "prompt.pickUp")
	prompt:SetAttribute("ActionKey", "prompt.pickUp")
	prompt:SetAttribute("ObjectKey", "prompt.itemAmount")
	prompt:SetAttribute("ObjectArg1", "@item." .. itemId .. ".name")
	prompt:SetAttribute("ObjectArg2", amount)
	prompt.ObjectText = Locale.T("en", "prompt.itemAmount", Locale.Item(itemId), amount)
	prompt.HoldDuration = 0.3
	prompt.MaxActivationDistance = GameConfig.PromptActivationDistance
	prompt.RequiresLineOfSight = false
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.Parent = part
	return part
end

-- Drops `amount` of an item (or the whole stack when amount is "all").
local function drop(player: Player, itemId: any, amount: any)
	if not RateLimiter.Allow(player, "Drop", 0.3) then
		return
	end
	if DamageService.IsDowned(player) or not ItemDefinitions.IsValid(itemId) then
		return
	end
	local root = CharacterUtil.GetRoot(player)
	local have = InventoryService.GetCount(player, itemId)
	if not root or not folder or have <= 0 then
		return
	end
	local count = if amount == "all" then have elseif InventoryService.IsPositiveInt(amount) then amount else 0
	count = math.min(count, have)
	if count <= 0 or not InventoryService.Remove(player, itemId, count) then
		return
	end
	-- On the floor just in front of the player.
	local ahead = root.Position + root.CFrame.LookVector * 2.5
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { player.Character :: Instance }
	local hit = workspace:Raycast(ahead + Vector3.new(0, 2, 0), Vector3.new(0, -12, 0), params)
	local position = if hit then hit.Position + Vector3.new(0, 0.5, 0) else root.Position - Vector3.new(0, 2.5, 0)
	makeBundle(itemId, count, position).Parent = folder
	SfxService.Play("Pickup", position, 0.6)
	StateSyncService.RequestAll()
	-- No drop.done toast: world bundle + pouch tick are enough.
end

-- Picking a bundle up (called by InteractionService).
function DropService.PickUp(player: Player, bundle: BasePart): (boolean, any)
	local itemId = bundle:GetAttribute("ItemId")
	local amount = bundle:GetAttribute("Amount")
	if not ItemDefinitions.IsValid(itemId) or not InventoryService.IsPositiveInt(amount) or not bundle.Parent then
		return false, nil
	end
	local id = itemId :: string
	local count = amount :: number
	if not InventoryService.CanAdd(player, id, count) then
		return false, "res.full"
	end
	local position = bundle.Position
	bundle:Destroy()
	InventoryService.Add(player, id, count)
	SfxService.Play("Pickup", position, 0.8)
	StateSyncService.RequestAll()
	-- No res.collected toast (HUD declutter).
	return true, nil
end

function DropService.Start()
	Net.Get(RemoteNames.DropItem).OnServerEvent:Connect(drop)
end

return DropService
