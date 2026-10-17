--!strict
-- Join, leave, spawn, death and the death backpack. Also handles item use (Medkit, Food).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local RemoteNames = require(ReplicatedStorage.Shared.RemoteNames)
local UpgradeDefinitions = require(ReplicatedStorage.Shared.UpgradeDefinitions)
local SfxService = require(script.Parent.SfxService)
local CharacterUtil = require(script.Parent.CharacterUtil)
local CombatService = require(script.Parent.CombatService)
local DamageService = require(script.Parent.DamageService)
local FlashlightService = require(script.Parent.FlashlightService)
local HazardService = require(script.Parent.HazardService)
local InventoryService = require(script.Parent.InventoryService)
local Net = require(script.Parent.Net)
local PlayerDataService = require(script.Parent.PlayerDataService)
local RateLimiter = require(script.Parent.RateLimiter)
local ResourceService = require(script.Parent.ResourceService)
local StateSyncService = require(script.Parent.StateSyncService)

local PlayerLifecycleService = {}

type Backpack = {
	part: BasePart,
	items: { [string]: number },
}

local backpacks: { [Player]: Backpack } = {}
local respawning: { [Player]: boolean } = {}
local interactablesFolder: Folder? = nil
local fallbackDropPosition = Vector3.new(0, GameConfig.World.RoofY + 2, 20)

function PlayerLifecycleService.SetWorld(interactables: Folder, roofDropPosition: Vector3)
	interactablesFolder = interactables
	fallbackDropPosition = roofDropPosition
end

local function destroyBackpack(player: Player)
	local backpack = backpacks[player]
	if backpack then
		backpacks[player] = nil
		backpack.part:Destroy()
		StateSyncService.Request(player)
	end
end

local function isInsideBuilding(position: Vector3): boolean
	local World = GameConfig.World
	local half = World.FloorSize / 2 - 1
	local lowest = World.RoofY - World.FloorCount * World.FloorSpacing - 2
	local onRoof = math.abs(position.X) <= World.RoofSize / 2 and math.abs(position.Z) <= World.RoofSize / 2
	if position.Y >= World.RoofY - 1 then
		return onRoof
	end
	return math.abs(position.X) <= half and math.abs(position.Z) <= half and position.Y >= lowest
end

local function dropBackpack(player: Player, position: Vector3)
	local data = PlayerDataService.Get(player)
	if not data or not interactablesFolder then
		return
	end
	local items: { [string]: number } = {}
	local any = false
	for id, amount in data.inventory do
		if amount > 0 and not GameConfig.DeathProtectedItems[id] then
			items[id] = amount
			data.inventory[id] = 0
			any = true
		end
	end
	if not any then
		return
	end
	-- A new death replaces the old backpack; whatever was in it is gone.
	destroyBackpack(player)
	PlayerDataService.MarkDirty(player)

	local dropAt = if isInsideBuilding(position) then position else fallbackDropPosition
	local part = Instance.new("Part")
	part.Name = "Backpack_" .. tostring(player.UserId)
	part.Size = Vector3.new(2, 2, 1.4)
	part.Color = Color3.fromRGB(200, 120, 40)
	part.Material = Enum.Material.Fabric
	part.Anchored = true
	part.CanCollide = false
	part.Position = dropAt - Vector3.new(0, 1.5, 0)
	part:SetAttribute("InteractType", "Backpack")
	part:SetAttribute("OwnerUserId", player.UserId)

	local light = Instance.new("PointLight")
	light.Color = part.Color
	light.Range = 10
	light.Brightness = 2
	light.Parent = part

	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Take backpack"
	prompt:SetAttribute("ActionKey", "backpack.action")
	prompt.ObjectText = "Your backpack"
	prompt:SetAttribute("ObjectKey", "backpack.object")
	prompt.MaxActivationDistance = GameConfig.PromptActivationDistance
	prompt.RequiresLineOfSight = false
	prompt.Parent = part
	part.Parent = interactablesFolder

	local backpack = {
		part = part,
		items = items,
	}
	backpacks[player] = backpack
	task.delay(GameConfig.BackpackDropLifetimeSeconds, function()
		if backpacks[player] == backpack then
			destroyBackpack(player)
			if player.Parent then
				Net.Notify(player, "backpack.lost", "warning")
			end
		end
	end)
end

function PlayerLifecycleService.RecoverBackpack(player: Player, part: BasePart): (boolean, any)
	local backpack = backpacks[player]
	if not backpack or backpack.part ~= part then
		return false, "backpack.notYours"
	end
	backpacks[player] = nil
	for id, amount in backpack.items do
		InventoryService.ForceAdd(player, id, amount)
	end
	part:Destroy()
	StateSyncService.Request(player)
	Net.Notify(player, "backpack.recovered", "success")
	return true, nil
end

local function onDied(player: Player, character: Model)
	if respawning[player] then
		return
	end
	respawning[player] = true
	local root = character:FindFirstChild("HumanoidRootPart")
	local position = if root and root:IsA("BasePart") then root.Position else fallbackDropPosition
	dropBackpack(player, position)
	FlashlightService.SetOn(player, false)
	HazardService.StopTracking(player)
	StateSyncService.Request(player)
	Net.Notify(player, "death.message", "error")

	task.delay(GameConfig.RespawnDelaySeconds, function()
		respawning[player] = nil
		if player.Parent == Players then
			player:LoadCharacter()
		end
	end)
end

local function onCharacterAdded(player: Player, character: Model)
	local humanoid = character:WaitForChild("Humanoid", 10)
	if not humanoid or not humanoid:IsA("Humanoid") then
		return
	end
	humanoid.MaxHealth = GameConfig.StartingHealth
	humanoid.Health = GameConfig.StartingHealth
	HazardService.ResetCharacter(player)
	DamageService.OnCharacterAdded(player)
	CombatService.OnCharacterAdded(player)
	ResourceService.OnReturnedToRoof(player)
	FlashlightService.OnCharacterAdded(player)
	humanoid.Died:Once(function()
		onDied(player, character)
	end)
	StateSyncService.Request(player)
end

local function onPlayerAdded(player: Player)
	local saved = PlayerDataService.Load(player)
	if player.Parent ~= Players then
		return
	end
	local data = PlayerDataService.Get(player)
	if data and data.language then
		player:SetAttribute("Language", data.language)
	end
	-- Language picked in the lobby travels with the teleport.
	local joinData = player:GetJoinData()
	local teleportData = joinData and joinData.TeleportData
	if type(teleportData) == "table" and type(teleportData.languages) == "table" then
		local code = teleportData.languages[tostring(player.UserId)]
		if code == "uk" or code == "ru" or code == "en" then
			player:SetAttribute("Language", code)
		end
	end
	player.CharacterAdded:Connect(function(character)
		onCharacterAdded(player, character)
	end)
	player:LoadCharacter()
	if not saved then
		task.delay(3, function()
			if player.Parent then
				Net.Notify(player, "save.failed", "error")
			end
		end)
	end
end

local function useItem(player: Player, itemId: any)
	if not RateLimiter.Allow(player, "UseItem", GameConfig.InteractionCooldown) then
		return
	end
	if DamageService.IsDowned(player) then
		return
	end
	if itemId == "Medkit" then
		local humanoid = CharacterUtil.GetHumanoid(player)
		if not humanoid then
			return
		end
		if humanoid.Health >= humanoid.MaxHealth then
			Net.Notify(player, "medkit.full", "info")
			return
		end
		if not InventoryService.Remove(player, "Medkit", 1) then
			Net.Notify(player, "medkit.none", "warning")
			return
		end
		humanoid.Health = math.min(humanoid.MaxHealth, humanoid.Health + GameConfig.MedkitHeal)
		SfxService.PlayAtPlayer("Bandage", player)
		Net.Notify(player, { "medkit.used", GameConfig.MedkitHeal }, "success")
	elseif itemId == "Food" then
		if not InventoryService.Has(player, "Food", 1) then
			Net.Notify(player, "food.none", "warning")
			return
		end
		if not HazardService.Feed(player) then
			Net.Notify(player, "food.notHungry", "info")
			return
		end
		InventoryService.Remove(player, "Food", 1)
		SfxService.PlayAtPlayer("Eat", player)
		Net.Notify(player, "food.eaten", "success")
	end
end

function PlayerLifecycleService.Init()
	-- Core part of the state snapshot.
	StateSyncService.RegisterProvider(function(player, snapshot)
		local data = PlayerDataService.Get(player)
		if not data then
			return
		end
		snapshot.inventory = table.clone(data.inventory)
		-- Team chest contents come from StorageService.Init provider (shared).
		snapshot.upgrades = table.clone(data.upgrades)
		snapshot.weight = InventoryService.WeightOf(data.inventory)
		snapshot.maxWeight = InventoryService.GetCapacity(player)
		snapshot.saveEnabled = PlayerDataService.CanSave(player)
		local costs = {}
		for id, def in UpgradeDefinitions.Upgrades do
			costs[id] = UpgradeDefinitions.GetCost(def)
		end
		snapshot.costs = costs
		local backpack = backpacks[player]
		snapshot.backpack = backpack and backpack.part.Position
	end)
end

function PlayerLifecycleService.Start()
	Players.CharacterAutoLoads = false

	Net.Get(RemoteNames.UseItem).OnServerEvent:Connect(useItem)
	Net.Get(RemoteNames.RequestState).OnServerEvent:Connect(function(player)
		if RateLimiter.Allow(player, "RequestState", 1) then
			StateSyncService.Request(player)
		end
	end)
	Net.Get(RemoteNames.SetLanguage).OnServerEvent:Connect(function(player, code)
		if not RateLimiter.Allow(player, "SetLanguage", 0.5) then
			return
		end
		if code ~= "uk" and code ~= "ru" and code ~= "en" then
			return
		end
		local data = PlayerDataService.Get(player)
		if data then
			data.language = code
			PlayerDataService.MarkDirty(player)
		end
		player:SetAttribute("Language", code)
	end)
	Net.Get(RemoteNames.ToggleFlashlight).OnServerEvent:Connect(function(player)
		if RateLimiter.Allow(player, "ToggleFlashlight", 0.3) then
			FlashlightService.Toggle(player)
		end
	end)

	Players.PlayerAdded:Connect(onPlayerAdded)
	for _, player in Players:GetPlayers() do
		task.spawn(onPlayerAdded, player)
	end
	Players.PlayerRemoving:Connect(function(player)
		destroyBackpack(player)
		respawning[player] = nil
		PlayerDataService.Release(player)
	end)
end

return PlayerLifecycleService
